-- 09_demo_explain.sql
-- Demo optimasi query untuk laporan/presentasi (materi Pemrosesan dan Optimasi Query).
-- Jalankan SETELAH 07: psql -U postgres -d smk_alrazi -f 09_demo_explain.sql
--
-- AMAN: semuanya di dalam transaksi yang di-ROLLBACK (PostgreSQL mendukung
-- DDL transaksional), jadi 100.000 buku uji dan penghapusan indeks tidak
-- tersimpan. Indeks asli kembali seperti semula.
--
-- Cara membaca hasil: cari "Seq Scan" (baca seluruh tabel) pada pemeriksaan
-- pertama dan "Bitmap Index Scan" pada pemeriksaan kedua, lalu bandingkan
-- "Execution Time". Salin kedua hasil ke laporan.
BEGIN;

-- Data uji
INSERT INTO buku (judul)
SELECT 'Buku Uji Nomor ' || n FROM generate_series(1, 100000) AS n;
ANALYZE buku;

-- Pemeriksaan 1: TANPA indeks trigram
DROP INDEX idx_buku_judul_trgm;
\echo '=== SEBELUM indeks (tanpa idx_buku_judul_trgm) ==='
EXPLAIN (ANALYZE, BUFFERS) SELECT id, judul FROM buku WHERE judul ILIKE '%nomor 77777%';

-- Pemeriksaan 2: DENGAN indeks trigram
CREATE INDEX idx_buku_judul_trgm ON buku USING gin (judul gin_trgm_ops);
ANALYZE buku;
\echo '=== SESUDAH indeks (idx_buku_judul_trgm) ==='
EXPLAIN (ANALYZE, BUFFERS) SELECT id, judul FROM buku WHERE judul ILIKE '%nomor 77777%';

-- Pemeriksaan 3: pencarian ISBN memakai indeks unik bawaan constraint
\echo '=== Pencarian ISBN (indeks unik dari constraint UNIQUE) ==='
EXPLAIN (ANALYZE) SELECT id FROM buku WHERE isbn = '9786020000000';

ROLLBACK;
