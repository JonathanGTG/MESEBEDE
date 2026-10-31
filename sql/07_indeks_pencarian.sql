-- 07_indeks_pencarian.sql
-- Indeks tambahan untuk pencarian teks (katalog OPAC dan inventaris lab).
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 07_indeks_pencarian.sql
--
-- Pencarian seperti  judul ILIKE '%pemrograman%'  tidak bisa memakai indeks
-- biasa (B-tree) karena ada tanda % di depan, sehingga PostgreSQL membaca
-- seluruh tabel (Seq Scan). Indeks GIN dengan pg_trgm mengatasinya.
-- Lihat bukti sebelum/sesudah di 09_demo_explain.sql.
--
-- Butuh ekstensi pg_trgm (ikut terpasang di installer PostgreSQL Windows).
-- Jika error "extension pg_trgm is not available", beri tahu saya.
BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_buku_judul_trgm      ON buku       USING gin (judul gin_trgm_ops);
CREATE INDEX idx_penulis_nama_trgm    ON penulis    USING gin (nama  gin_trgm_ops);
CREATE INDEX idx_barang_lab_nama_trgm ON barang_lab USING gin (nama  gin_trgm_ops);

COMMIT;
