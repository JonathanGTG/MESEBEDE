-- 08_uji_alur.sql
-- Uji otomatis semua fungsi dan trigger. Jalankan SETELAH 01-07.
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 08_uji_alur.sql
--
-- AMAN: seluruh skrip berakhir dengan ROLLBACK, jadi tidak ada data uji yang
-- tersimpan (hanya nomor identity/sequence yang terpakai, tidak berbahaya).
-- Hasil: baris "OK" untuk tiap pemeriksaan; "GAGAL" menghentikan skrip.
-- Skrip hanya memakai data buatannya sendiri sehingga aman dijalankan juga
-- ketika database sudah berisi data.
BEGIN;

-- Pembantu: pernyataan ini HARUS ditolak oleh database
CREATE FUNCTION pg_temp.harus_gagal(p_sql text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    BEGIN
        EXECUTE p_sql;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '  OK, ditolak: %', SQLERRM;
        RETURN;
    END;
    RAISE EXCEPTION 'GAGAL: seharusnya ditolak -> %', p_sql;
END;
$$;

-- Pembantu: kondisi HARUS benar
CREATE FUNCTION pg_temp.harus(p_kondisi boolean, p_pesan text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
    IF p_kondisi IS NOT TRUE THEN
        RAISE EXCEPTION 'GAGAL: %', p_pesan;
    END IF;
    RAISE NOTICE '  OK: %', p_pesan;
END;
$$;

DO $$
DECLARE
    v_admin bigint; v_kepsek bigint; v_waka bigint; v_lab bigint;
    v_perpus bigint; v_guru bigint; v_siswa bigint;
    v_kartu varchar; v_anggota bigint;
    v_buku bigint; v_eks bigint[]; v_pin bigint; v_pin2 bigint;
    v_item1 bigint; v_item2 bigint;
    v_kat bigint; v_barang bigint; v_aset bigint[]; v_tx bigint; v_ti bigint;
    v_jumlah_awal integer; v_tgl timestamp;
BEGIN
    -- ---------------------------------------------------------------
    RAISE NOTICE '== Akun uji';
    INSERT INTO pengguna (peran_id, nama, email, password)
    SELECT r.id, 'Uji ' || r.kode, r.kode || '@uji.test', 'bukan-hash-asli' FROM peran r;
    SELECT id INTO v_admin  FROM pengguna WHERE email = 'admin@uji.test';
    SELECT id INTO v_kepsek FROM pengguna WHERE email = 'kepala_sekolah@uji.test';
    SELECT id INTO v_waka   FROM pengguna WHERE email = 'waka_sarpras@uji.test';
    SELECT id INTO v_lab    FROM pengguna WHERE email = 'pengurus_lab@uji.test';
    SELECT id INTO v_perpus FROM pengguna WHERE email = 'pengurus_perpus@uji.test';
    SELECT id INTO v_guru   FROM pengguna WHERE email = 'guru@uji.test';
    SELECT id INTO v_siswa  FROM pengguna WHERE email = 'siswa@uji.test';
    PERFORM pg_temp.harus(v_siswa IS NOT NULL, '7 akun uji dibuat');
    PERFORM pg_temp.harus(
        (SELECT count(*) FROM pengguna WHERE email LIKE '%@uji.test') = 7, 'ada tepat 7 akun uji');
    PERFORM pg_temp.harus_gagal(
        'INSERT INTO pengguna (peran_id, nama, email, password)
         SELECT id, ''Dobel'', ''ADMIN@uji.test'', ''x'' FROM peran LIMIT 1');

    -- ---------------------------------------------------------------
    RAISE NOTICE '== Kartu perpustakaan';
    INSERT INTO profil (pengguna_id) VALUES (v_siswa), (v_guru);
    PERFORM pg_temp.harus_gagal(format('SELECT terbitkan_kartu(%s)', v_siswa));   -- belum ada NISN
    PERFORM pg_temp.harus_gagal(format('SELECT terbitkan_kartu(%s)', v_guru));    -- belum ada NIP/NUPTK
    PERFORM pg_temp.harus_gagal(format('SELECT terbitkan_kartu(%s)', v_admin));   -- bukan anggota
    PERFORM pg_temp.harus_gagal(
        format('UPDATE profil SET nisn = ''123'' WHERE pengguna_id = %s', v_siswa)); -- NISN harus 10 digit
    UPDATE profil SET nisn = '1234567890' WHERE pengguna_id = v_siswa;
    v_kartu := terbitkan_kartu(v_siswa);
    PERFORM pg_temp.harus(v_kartu LIKE 'PRP-%', 'nomor kartu dibuat otomatis: ' || v_kartu);
    PERFORM pg_temp.harus(terbitkan_kartu(v_siswa) = v_kartu, 'panggilan kedua mengembalikan kartu yang sama');
    SELECT id INTO v_anggota FROM anggota WHERE pengguna_id = v_siswa;

    -- ---------------------------------------------------------------
    RAISE NOTICE '== Peminjaman dan pengembalian';
    INSERT INTO buku (judul) VALUES ('Buku Uji') RETURNING id INTO v_buku;
    INSERT INTO eksemplar (buku_id, kode)
    SELECT v_buku, 'UJI-' || g FROM generate_series(1, 4) g;
    SELECT array_agg(id ORDER BY id) INTO v_eks FROM eksemplar WHERE buku_id = v_buku;
    PERFORM pg_temp.harus(jumlah_tersedia(v_buku) = 4, '4 eksemplar tersedia');

    PERFORM pg_temp.harus_gagal(    -- petugas bukan pengurus perpustakaan
        format('SELECT buat_pinjaman(%s, %s, ARRAY[%s]::bigint[])', v_anggota, v_lab, v_eks[1]));
    v_pin := buat_pinjaman(v_anggota, v_perpus, ARRAY[v_eks[1], v_eks[2]]);
    PERFORM pg_temp.harus(jumlah_tersedia(v_buku) = 2, 'setelah pinjam 2, tersedia tinggal 2');
    PERFORM pg_temp.harus(
        (SELECT status FROM eksemplar WHERE id = v_eks[1]) = 'dipinjam', 'status eksemplar menjadi dipinjam');
    PERFORM pg_temp.harus_gagal(    -- eksemplar yang sama dipinjam dua kali
        format('SELECT buat_pinjaman(%s, %s, ARRAY[%s]::bigint[])', v_anggota, v_perpus, v_eks[1]));
    PERFORM pg_temp.harus_gagal(    -- melebihi batas 3 buku (sedang 2, minta 2 lagi)
        format('SELECT buat_pinjaman(%s, %s, ARRAY[%s, %s]::bigint[])',
               v_anggota, v_perpus, v_eks[3], v_eks[4]));
    PERFORM pg_temp.harus_gagal(    -- dipaksa tersedia padahal masih dipinjam
        format('UPDATE eksemplar SET status = ''tersedia'' WHERE id = %s', v_eks[1]));
    PERFORM pg_temp.harus_gagal(    -- indeks unik: dua pinjaman aktif untuk satu eksemplar
        format('INSERT INTO pinjaman_item (pinjaman_id, eksemplar_id) VALUES (%s, %s)', v_pin, v_eks[1]));

    SELECT id INTO v_item1 FROM pinjaman_item WHERE pinjaman_id = v_pin AND eksemplar_id = v_eks[1];
    SELECT id INTO v_item2 FROM pinjaman_item WHERE pinjaman_id = v_pin AND eksemplar_id = v_eks[2];
    PERFORM kembalikan_buku(v_item1, 'baik');
    PERFORM pg_temp.harus(
        (SELECT status FROM eksemplar WHERE id = v_eks[1]) = 'tersedia', 'kembali baik -> eksemplar tersedia');
    PERFORM pg_temp.harus(
        (SELECT status FROM pinjaman WHERE id = v_pin) = 'sebagian_kembali', 'pinjaman sebagian kembali');
    PERFORM kembalikan_buku(v_item2, 'rusak_ringan', 'Sampul sobek');
    PERFORM pg_temp.harus(
        (SELECT status FROM eksemplar WHERE id = v_eks[2]) = 'rusak', 'kembali rusak -> TIDAK otomatis tersedia');
    PERFORM pg_temp.harus(
        (SELECT status FROM pinjaman WHERE id = v_pin) = 'selesai', 'semua kembali -> pinjaman selesai');
    PERFORM pg_temp.harus_gagal(format('SELECT kembalikan_buku(%s, ''baik'')', v_item1));  -- sudah kembali
    PERFORM pg_temp.harus_gagal(format('SELECT perpanjang_pinjaman(%s)', v_pin));          -- sudah selesai

    v_pin2 := buat_pinjaman(v_anggota, v_perpus, ARRAY[v_eks[3]]);
    v_tgl := (SELECT jatuh_tempo FROM pinjaman WHERE id = v_pin2);
    PERFORM perpanjang_pinjaman(v_pin2);
    PERFORM pg_temp.harus(
        (SELECT jatuh_tempo FROM pinjaman WHERE id = v_pin2) > v_tgl, 'perpanjangan menambah jatuh tempo');
    PERFORM pg_temp.harus_gagal(format('SELECT perpanjang_pinjaman(%s)', v_pin2));         -- batas 1 kali

    -- simulasi keterlambatan
    UPDATE pinjaman SET tanggal_pinjam = now() - interval '10 days',
                        jatuh_tempo    = now() - interval '3 days'
    WHERE id = v_pin2;
    PERFORM pg_temp.harus(
        (SELECT count(*) FROM v_keterlambatan WHERE anggota_id = v_anggota) = 1, 'v_keterlambatan mendeteksi pinjaman terlambat');
    PERFORM pg_temp.harus(
        (SELECT tersedia FROM v_katalog_buku WHERE id = v_buku) = 2
        AND (SELECT total_eksemplar FROM v_katalog_buku WHERE id = v_buku) = 4,
        'v_katalog_buku: total 4, tersedia 2');

    -- ---------------------------------------------------------------
    RAISE NOTICE '== Aset lab';
    SELECT id INTO v_kat FROM kategori_lab WHERE nama = 'Komputer';
    INSERT INTO barang_lab (kategori_id, nama) VALUES (v_kat, 'PC Uji') RETURNING id INTO v_barang;
    SELECT array_agg(x) INTO v_aset
    FROM tambah_aset_lab(v_barang, 5, 'baru', 'baik', 'pembelian', current_date, NULL, 'Vendor Uji',
                         (SELECT id FROM lokasi_lab WHERE kode = 'PC-01')) AS x;
    PERFORM pg_temp.harus(array_length(v_aset, 1) = 5, 'input 5 unit membuat 5 record aset');
    PERFORM pg_temp.harus(
        (SELECT count(DISTINCT kode) FROM aset_lab WHERE id = ANY (v_aset)) = 5, 'kode aset unik semua');
    PERFORM pg_temp.harus_gagal(format(
        'SELECT tambah_aset_lab(%s, 0, ''baru'', ''baik'', ''pembelian'', current_date, NULL, NULL, NULL)', v_barang));

    -- ---------------------------------------------------------------
    RAISE NOTICE '== Usulan afkir: Pengurus Lab -> Waka -> Kepala Sekolah';
    INSERT INTO transaksi_lab (kode, jenis, pengusul_id, alasan)
    VALUES ('TRX-UJI-1', 'afkir', v_lab, 'Rusak berat') RETURNING id INTO v_tx;
    INSERT INTO transaksi_lab_item (transaksi_id, barang_id, jumlah)
    VALUES (v_tx, v_barang, 1) RETURNING id INTO v_ti;
    INSERT INTO transaksi_lab_aset (item_id, aset_id, aksi) VALUES (v_ti, v_aset[1], 'afkir');

    PERFORM pg_temp.harus_gagal(format('SELECT ajukan_transaksi_lab(%s, %s)', v_tx, v_waka));   -- bukan pengusul
    PERFORM pg_temp.harus_gagal(format(
        'SELECT keputusan_lab(%s, %s, ''verifikasi_waka'', ''setuju'')', v_tx, v_waka));         -- masih draft
    PERFORM ajukan_transaksi_lab(v_tx, v_lab);
    PERFORM pg_temp.harus_gagal(format(
        'SELECT keputusan_lab(%s, %s, ''verifikasi_waka'', ''setuju'')', v_tx, v_lab));          -- pengusul sendiri
    PERFORM pg_temp.harus_gagal(format(
        'SELECT keputusan_lab(%s, %s, ''verifikasi_waka'', ''kembalikan'')', v_tx, v_waka));     -- tanpa catatan
    PERFORM pg_temp.harus_gagal(format(
        'SELECT keputusan_lab(%s, %s, ''persetujuan_kepsek'', ''setuju'')', v_tx, v_kepsek));    -- belum diverifikasi

    PERFORM keputusan_lab(v_tx, v_waka, 'verifikasi_waka', 'kembalikan', 'Lengkapi alasan');
    PERFORM pg_temp.harus((SELECT status FROM transaksi_lab WHERE id = v_tx) = 'dikembalikan', 'Waka dapat mengembalikan usulan');
    PERFORM ajukan_transaksi_lab(v_tx, v_lab);
    PERFORM pg_temp.harus((SELECT verifikator_id FROM transaksi_lab WHERE id = v_tx) IS NULL, 'ajukan ulang mereset verifikasi');
    PERFORM keputusan_lab(v_tx, v_waka, 'verifikasi_waka', 'setuju');
    PERFORM pg_temp.harus((SELECT status FROM transaksi_lab WHERE id = v_tx) = 'diverifikasi', 'status diverifikasi');

    PERFORM pg_temp.harus_gagal(format(
        'SELECT keputusan_lab(%s, %s, ''persetujuan_kepsek'', ''kembalikan'', ''x'')', v_tx, v_kepsek)); -- kepsek tidak bisa kembalikan
    PERFORM pg_temp.harus_gagal(format(
        'SELECT keputusan_lab(%s, %s, ''persetujuan_kepsek'', ''setuju'')', v_tx, v_waka));              -- bukan kepsek
    PERFORM pg_temp.harus_gagal(format(
        'SELECT selesaikan_transaksi_lab(%s, %s)', v_tx, v_lab));                                        -- belum disetujui
    PERFORM pg_temp.harus((SELECT status FROM aset_lab WHERE id = v_aset[1]) = 'aktif', 'inventaris belum berubah sebelum persetujuan akhir');

    PERFORM keputusan_lab(v_tx, v_kepsek, 'persetujuan_kepsek', 'setuju', 'Disetujui');
    PERFORM selesaikan_transaksi_lab(v_tx, v_lab);
    PERFORM pg_temp.harus((SELECT status FROM aset_lab WHERE id = v_aset[1]) = 'afkir', 'aset menjadi afkir setelah disetujui');
    PERFORM pg_temp.harus((SELECT lokasi_id FROM aset_lab WHERE id = v_aset[1]) IS NULL, 'aset afkir tidak punya lokasi');
    PERFORM pg_temp.harus((SELECT status FROM transaksi_lab WHERE id = v_tx) = 'selesai', 'transaksi selesai');
    PERFORM pg_temp.harus((SELECT count(*) FROM persetujuan_lab WHERE transaksi_id = v_tx) = 3, 'riwayat persetujuan tercatat (3 keputusan)');
    PERFORM pg_temp.harus_gagal(format('UPDATE aset_lab SET status = ''aktif'' WHERE id = %s', v_aset[1]));
    PERFORM pg_temp.harus_gagal(format(            -- pemisahan tugas dijaga CHECK
        'UPDATE transaksi_lab SET verifikator_id = pengusul_id WHERE id = %s', v_tx));

    RAISE NOTICE '== Usulan pengadaan';
    INSERT INTO transaksi_lab (kode, jenis, pengusul_id, vendor_penerima, alasan)
    VALUES ('TRX-UJI-2', 'pengadaan', v_lab, 'Vendor Uji', 'Tambah PC') RETURNING id INTO v_tx;
    INSERT INTO transaksi_lab_item (transaksi_id, barang_id, jumlah, harga_satuan)
    VALUES (v_tx, v_barang, 3, 5000000);
    SELECT count(*) INTO v_jumlah_awal FROM aset_lab WHERE barang_id = v_barang;
    PERFORM ajukan_transaksi_lab(v_tx, v_lab);
    PERFORM keputusan_lab(v_tx, v_waka, 'verifikasi_waka', 'setuju');
    PERFORM keputusan_lab(v_tx, v_kepsek, 'persetujuan_kepsek', 'setuju');
    PERFORM pg_temp.harus((SELECT count(*) FROM aset_lab WHERE barang_id = v_barang) = v_jumlah_awal, 'aset belum bertambah sebelum diselesaikan');
    PERFORM selesaikan_transaksi_lab(v_tx, v_lab);
    PERFORM pg_temp.harus((SELECT count(*) FROM aset_lab WHERE barang_id = v_barang) = v_jumlah_awal + 3, 'pengadaan 3 unit menambah 3 aset');
    PERFORM pg_temp.harus(
        (SELECT count(*) FROM aset_lab a JOIN lokasi_lab l ON l.id = a.lokasi_id
          WHERE a.barang_id = v_barang AND l.kode = 'GUDANG' AND a.nilai_perolehan = 5000000) = 3, 'aset baru masuk GUDANG dengan nilai perolehan');

    -- ---------------------------------------------------------------
    RAISE NOTICE '== Audit log';
    PERFORM set_config('app.pengguna_id', v_lab::text, true);
    UPDATE aset_lab SET catatan = 'diperiksa' WHERE id = v_aset[2];
    PERFORM pg_temp.harus(
        (SELECT count(*) FROM log_aktivitas
          WHERE objek = 'aset_lab' AND objek_id = v_aset[2] AND aksi = 'ubah' AND pengguna_id = v_lab) = 1,
        'perubahan aset tercatat atas nama pengguna yang login');
    PERFORM pg_temp.harus(
        (SELECT count(*) FROM log_aktivitas WHERE objek = 'eksemplar' AND modul = 'perpus') > 0, 'perubahan eksemplar tercatat');
    PERFORM pg_temp.harus(
        (SELECT count(*) FROM log_aktivitas WHERE data::text LIKE '%bukan-hash-asli%') = 0, 'password tidak bocor ke log');
    PERFORM pg_temp.harus_gagal('UPDATE log_aktivitas SET aksi = ''palsu''');
    PERFORM pg_temp.harus_gagal('DELETE FROM log_aktivitas');

    -- ---------------------------------------------------------------
    RAISE NOTICE '== View dashboard';
    PERFORM pg_temp.harus((SELECT count(*) FROM v_ringkasan_eksekutif) = 1, 'v_ringkasan_eksekutif menghasilkan 1 baris');
    PERFORM pg_temp.harus((SELECT count(*) FROM v_isi_meja) = 30, 'v_isi_meja menampilkan 30 meja');
    PERFORM pg_temp.harus((SELECT count(*) FROM v_rekap_aset_kategori WHERE kategori = 'Komputer') = 1, 'v_rekap_aset_kategori berjalan');

    RAISE NOTICE '== SEMUA UJI LULUS';
END;
$$;

ROLLBACK;
