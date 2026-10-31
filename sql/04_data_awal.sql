-- 04_data_awal.sql
-- Data awal master. Jalankan SETELAH 01, 02, 03.
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 04_data_awal.sql
-- Aman dijalankan ulang (ON CONFLICT DO NOTHING).
-- Akun pengguna TIDAK dibuat di sini: password harus di-hash oleh Laravel
-- (dibuat nanti lewat tinker/seeder pada Fase 2-4).
BEGIN;

INSERT INTO peran (kode, nama) VALUES
    ('admin',           'Administrator'),
    ('kepala_sekolah',  'Kepala Sekolah'),
    ('waka_sarpras',    'Wakil Kepala Sekolah Sarana dan Prasarana'),
    ('pengurus_lab',    'Pengurus Laboratorium'),
    ('pengurus_perpus', 'Pengurus Perpustakaan'),
    ('guru',            'Guru'),
    ('siswa',           'Siswa')
ON CONFLICT (kode) DO NOTHING;

-- Lokasi lab: meja PC-01 s/d PC-30, gudang, servis
INSERT INTO lokasi_lab (kode, nama, jenis)
SELECT 'PC-' || lpad(n::text, 2, '0'),
       'Meja PC-' || lpad(n::text, 2, '0'),
       'meja_pc'
FROM generate_series(1, 30) AS n
ON CONFLICT (kode) DO NOTHING;

INSERT INTO lokasi_lab (kode, nama, jenis) VALUES
    ('GUDANG', 'Gudang Lab',    'gudang'),
    ('SERVIS', 'Tempat Servis', 'servis')
ON CONFLICT (kode) DO NOTHING;

INSERT INTO kategori_lab (nama) VALUES
    ('Komputer'), ('Monitor'), ('Keyboard'), ('Mouse'),
    ('Meja'), ('Kursi'), ('Jaringan'), ('Lainnya')
ON CONFLICT (nama) DO NOTHING;

INSERT INTO kategori_buku (nama) VALUES
    ('Buku Pelajaran'), ('Referensi Kejuruan'), ('Fiksi'),
    ('Non-Fiksi'), ('Referensi Umum')
ON CONFLICT (nama) DO NOTHING;

-- Aturan pinjam SEMENTARA (belum dikonfirmasi mitra)
INSERT INTO aturan_pinjam (kunci, nilai, keterangan, sudah_dikonfirmasi) VALUES
    ('lama_pinjam_hari',      7, 'Lama pinjam (hari)',                    FALSE),
    ('maks_buku_per_anggota', 3, 'Maksimal eksemplar dipinjam sekaligus', FALSE),
    ('maks_perpanjangan',     1, 'Maksimal perpanjangan per pinjaman',    FALSE),
    ('denda_per_hari',        0, 'Denda per hari (Rp); 0 = tanpa denda',  FALSE)
ON CONFLICT (kunci) DO NOTHING;

COMMIT;
