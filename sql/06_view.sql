-- 06_view.sql
-- View untuk katalog, dashboard, dan laporan. Jalankan SETELAH 05.
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 06_view.sql
--
-- Semua angka dihitung dari data asli (tidak ada saldo yang diketik manual).
-- View hanya untuk dibaca (SELECT); jangan di-INSERT/UPDATE lewat view.
BEGIN;

-- ---------------------------------------------------------------------
-- PERPUSTAKAAN
-- ---------------------------------------------------------------------

-- Katalog OPAC: satu baris per judul + jumlah eksemplar tersedia
CREATE VIEW v_katalog_buku AS
SELECT b.id,
       b.isbn,
       b.judul,
       b.tahun_terbit,
       p.nama AS penerbit,
       (SELECT string_agg(pn.nama, ', ' ORDER BY pn.nama)
          FROM buku_penulis bp JOIN penulis pn ON pn.id = bp.penulis_id
         WHERE bp.buku_id = b.id) AS penulis,
       (SELECT string_agg(k.nama, ', ' ORDER BY k.nama)
          FROM buku_kategori bk JOIN kategori_buku k ON k.id = bk.kategori_id
         WHERE bk.buku_id = b.id) AS kategori,
       coalesce(e.total, 0)    AS total_eksemplar,
       coalesce(e.tersedia, 0) AS tersedia
FROM buku b
LEFT JOIN penerbit p ON p.id = b.penerbit_id
LEFT JOIN (SELECT buku_id,
                  count(*)::integer AS total,
                  (count(*) FILTER (WHERE status = 'tersedia'))::integer AS tersedia
             FROM eksemplar
            GROUP BY buku_id) e ON e.buku_id = b.id;

-- Eksemplar yang sedang dipinjam. Keterlambatan DIHITUNG dari jatuh_tempo,
-- bukan disimpan sebagai status tetap.
CREATE VIEW v_pinjaman_aktif AS
SELECT pi.id            AS pinjaman_item_id,
       p.id             AS pinjaman_id,
       a.id             AS anggota_id,
       a.nomor_kartu,
       u.nama           AS nama_anggota,
       b.judul,
       e.kode           AS kode_eksemplar,
       p.tanggal_pinjam,
       p.jatuh_tempo,
       (p.jatuh_tempo < now()) AS terlambat,
       CASE WHEN p.jatuh_tempo < now()
            THEN (now()::date - p.jatuh_tempo::date) ELSE 0 END AS hari_terlambat
FROM pinjaman_item pi
JOIN pinjaman  p ON p.id = pi.pinjaman_id
JOIN anggota   a ON a.id = p.anggota_id
JOIN pengguna  u ON u.id = a.pengguna_id
JOIN eksemplar e ON e.id = pi.eksemplar_id
JOIN buku      b ON b.id = e.buku_id
WHERE pi.tanggal_kembali IS NULL;

CREATE VIEW v_keterlambatan AS
SELECT * FROM v_pinjaman_aktif WHERE terlambat ORDER BY hari_terlambat DESC;

-- Rekap eksemplar per status
CREATE VIEW v_rekap_eksemplar AS
SELECT status, count(*)::integer AS jumlah
FROM eksemplar
GROUP BY status;

-- Sirkulasi per bulan
CREATE VIEW v_sirkulasi_bulanan AS
SELECT date_trunc('month', p.tanggal_pinjam)::date AS bulan,
       count(DISTINCT p.id)::integer               AS jumlah_pinjaman,
       count(pi.id)::integer                       AS jumlah_buku_dipinjam,
       (count(pi.id) FILTER (WHERE pi.tanggal_kembali IS NOT NULL))::integer
                                                   AS jumlah_dikembalikan
FROM pinjaman p
JOIN pinjaman_item pi ON pi.pinjaman_id = p.id
GROUP BY date_trunc('month', p.tanggal_pinjam)
ORDER BY bulan DESC;

-- ---------------------------------------------------------------------
-- LABORATORIUM
-- ---------------------------------------------------------------------

-- Daftar aset lengkap (untuk tabel inventaris dan filter)
CREATE VIEW v_aset_lab AS
SELECT a.id,
       a.kode,
       b.nama  AS barang,
       k.nama  AS kategori,
       a.klasifikasi,
       a.kondisi,
       a.status,
       l.kode  AS lokasi,
       a.nomor_seri,
       a.tanggal_perolehan,
       a.nilai_perolehan
FROM aset_lab a
JOIN barang_lab   b ON b.id = a.barang_id
JOIN kategori_lab k ON k.id = b.kategori_id
LEFT JOIN lokasi_lab l ON l.id = a.lokasi_id;

-- Rekap per kategori. total_nilai hanya menjumlah nilai yang tercatat;
-- aset_tanpa_nilai menunjukkan data yang belum lengkap (bukan dianggap nol).
CREATE VIEW v_rekap_aset_kategori AS
SELECT k.nama AS kategori,
       count(*)::integer AS total,
       (count(*) FILTER (WHERE a.klasifikasi = 'baru'))::integer       AS unit_baru,
       (count(*) FILTER (WHERE a.klasifikasi = 'lama'))::integer       AS unit_lama,
       (count(*) FILTER (WHERE a.kondisi = 'baik'))::integer           AS baik,
       (count(*) FILTER (WHERE a.kondisi = 'rusak_ringan'))::integer   AS rusak_ringan,
       (count(*) FILTER (WHERE a.kondisi = 'rusak_berat'))::integer    AS rusak_berat,
       (count(*) FILTER (WHERE a.status = 'aktif'))::integer           AS aktif,
       (count(*) FILTER (WHERE a.status = 'dalam_servis'))::integer    AS dalam_servis,
       (count(*) FILTER (WHERE a.status = 'afkir'))::integer           AS afkir,
       sum(a.nilai_perolehan)                                          AS total_nilai,
       (count(*) FILTER (WHERE a.nilai_perolehan IS NULL))::integer    AS aset_tanpa_nilai
FROM aset_lab a
JOIN barang_lab   b ON b.id = a.barang_id
JOIN kategori_lab k ON k.id = b.kategori_id
GROUP BY k.id, k.nama
ORDER BY k.nama;

-- Isi setiap meja PC-01 s/d PC-30 (meja kosong tetap tampil). Aset afkir tidak dihitung.
CREATE VIEW v_isi_meja AS
SELECT l.id AS lokasi_id,
       l.kode,
       l.nama,
       count(a.id)::integer AS jumlah_aset,
       (count(a.id) FILTER (WHERE a.kondisi <> 'baik'))::integer AS perlu_perhatian,
       string_agg(b.nama || ' (' || a.kode || ')', ', ' ORDER BY b.nama) AS daftar_aset
FROM lokasi_lab l
LEFT JOIN aset_lab   a ON a.lokasi_id = l.id AND a.status <> 'afkir'
LEFT JOIN barang_lab b ON b.id = a.barang_id
WHERE l.jenis = 'meja_pc'
GROUP BY l.id, l.kode, l.nama
ORDER BY l.kode;

-- Usulan/transaksi lab beserta pelaku (antrean Waka: status 'diajukan';
-- antrean Kepala Sekolah: status 'diverifikasi')
CREATE VIEW v_usulan_lab AS
SELECT t.id,
       t.kode,
       t.jenis,
       t.tanggal,
       t.status,
       pu.nama AS pengusul,
       pv.nama AS verifikator,
       t.diverifikasi_pada,
       ps.nama AS penyetuju,
       t.disetujui_pada,
       t.alasan,
       coalesce((SELECT sum(i.jumlah) FROM transaksi_lab_item i
                  WHERE i.transaksi_id = t.id), 0)::integer AS total_unit
FROM transaksi_lab t
JOIN pengguna pu ON pu.id = t.pengusul_id
LEFT JOIN pengguna pv ON pv.id = t.verifikator_id
LEFT JOIN pengguna ps ON ps.id = t.penyetuju_id;

-- ---------------------------------------------------------------------
-- DASHBOARD EKSEKUTIF (satu baris)
-- ---------------------------------------------------------------------
CREATE VIEW v_ringkasan_eksekutif AS
SELECT
    (SELECT count(*) FROM aset_lab WHERE status <> 'afkir')::integer                  AS total_aset,
    (SELECT count(*) FROM aset_lab WHERE status <> 'afkir' AND klasifikasi = 'baru')::integer AS unit_baru,
    (SELECT count(*) FROM aset_lab WHERE status <> 'afkir' AND klasifikasi = 'lama')::integer AS unit_lama,
    (SELECT count(*) FROM aset_lab WHERE status <> 'afkir' AND kondisi = 'baik')::integer         AS kondisi_baik,
    (SELECT count(*) FROM aset_lab WHERE status <> 'afkir' AND kondisi = 'rusak_ringan')::integer AS kondisi_rusak_ringan,
    (SELECT count(*) FROM aset_lab WHERE status <> 'afkir' AND kondisi = 'rusak_berat')::integer  AS kondisi_rusak_berat,
    (SELECT sum(nilai_perolehan) FROM aset_lab WHERE status <> 'afkir')               AS total_nilai_tercatat,
    (SELECT count(*) FROM aset_lab WHERE status <> 'afkir' AND nilai_perolehan IS NULL)::integer AS aset_tanpa_nilai,
    (SELECT count(*) FROM transaksi_lab WHERE status = 'diajukan')::integer           AS usulan_menunggu_waka,
    (SELECT count(*) FROM transaksi_lab WHERE status = 'diverifikasi')::integer       AS usulan_menunggu_kepsek,
    (SELECT count(*) FROM buku)::integer                                              AS total_judul,
    (SELECT count(*) FROM eksemplar)::integer                                         AS total_eksemplar,
    (SELECT count(*) FROM pinjaman_item WHERE tanggal_kembali IS NULL)::integer       AS pinjaman_aktif,
    (SELECT count(*) FROM v_keterlambatan)::integer                                   AS pinjaman_terlambat;

COMMIT;
