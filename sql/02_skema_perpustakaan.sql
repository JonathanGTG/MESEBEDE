-- 02_skema_perpustakaan.sql
-- Modul Perpustakaan. Jalankan SETELAH 01_skema_umum.sql.
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 02_skema_perpustakaan.sql
--
-- Ringkasan desain:
--   buku       = data judul (metadata)
--   eksemplar  = salinan fisik; jumlah tersedia DIHITUNG dari status eksemplar
--   Satu eksemplar hanya boleh punya satu pinjaman aktif (indeks unik parsial
--   pada pinjaman_item).
BEGIN;

CREATE TABLE kategori_buku (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama        VARCHAR(100) NOT NULL UNIQUE,
    keterangan  TEXT,
    aktif       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(0) NOT NULL DEFAULT now()
);

CREATE TABLE penerbit (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama        VARCHAR(150) NOT NULL UNIQUE,
    alamat      TEXT,
    kontak      VARCHAR(100),
    created_at  TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(0) NOT NULL DEFAULT now()
);

CREATE TABLE penulis (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama        VARCHAR(150) NOT NULL,
    biografi    TEXT,
    created_at  TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(0) NOT NULL DEFAULT now()
);

CREATE TABLE buku (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn          VARCHAR(20) UNIQUE,
    judul         VARCHAR(255) NOT NULL,
    deskripsi     TEXT,
    penerbit_id   BIGINT REFERENCES penerbit(id),
    tahun_terbit  SMALLINT CHECK (tahun_terbit IS NULL OR tahun_terbit BETWEEN 1000 AND 2100),
    edisi         VARCHAR(50),
    bahasa        VARCHAR(30),
    sampul        VARCHAR(255),
    created_at    TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP(0) NOT NULL DEFAULT now()
);
CREATE INDEX ON buku (judul);
CREATE INDEX ON buku (penerbit_id);

-- Satu buku boleh punya banyak penulis dan banyak kategori
CREATE TABLE buku_penulis (
    buku_id     BIGINT NOT NULL REFERENCES buku(id) ON DELETE CASCADE,
    penulis_id  BIGINT NOT NULL REFERENCES penulis(id),
    PRIMARY KEY (buku_id, penulis_id)
);
CREATE INDEX ON buku_penulis (penulis_id);

CREATE TABLE buku_kategori (
    buku_id      BIGINT NOT NULL REFERENCES buku(id) ON DELETE CASCADE,
    kategori_id  BIGINT NOT NULL REFERENCES kategori_buku(id),
    PRIMARY KEY (buku_id, kategori_id)
);
CREATE INDEX ON buku_kategori (kategori_id);

CREATE TABLE eksemplar (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    buku_id       BIGINT      NOT NULL REFERENCES buku(id),
    kode          VARCHAR(40) NOT NULL UNIQUE,
    barcode       VARCHAR(60) UNIQUE,
    kondisi       VARCHAR(20) NOT NULL DEFAULT 'baik'
                  CHECK (kondisi IN ('baik', 'rusak_ringan', 'rusak_berat', 'hilang')),
    status        VARCHAR(20) NOT NULL DEFAULT 'tersedia'
                  CHECK (status IN ('tersedia', 'dipinjam', 'rusak', 'hilang', 'ditarik')),
    rak           VARCHAR(50),
    tanggal_masuk DATE,
    created_at    TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at    TIMESTAMP(0) NOT NULL DEFAULT now()
);
CREATE INDEX ON eksemplar (buku_id);
CREATE INDEX ON eksemplar (status);
CREATE INDEX ON eksemplar (buku_id, status);

-- Aturan pinjam. Nilai awal SEMENTARA sampai dikonfirmasi mitra.
CREATE TABLE aturan_pinjam (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kunci               VARCHAR(50)  NOT NULL UNIQUE,
    nilai               INTEGER      NOT NULL CHECK (nilai >= 0),
    keterangan          VARCHAR(200),
    sudah_dikonfirmasi  BOOLEAN      NOT NULL DEFAULT FALSE,
    updated_at          TIMESTAMP(0) NOT NULL DEFAULT now()
);

-- Keanggotaan Guru/Siswa
CREATE TABLE anggota (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pengguna_id    BIGINT      NOT NULL UNIQUE REFERENCES pengguna(id),
    nomor_kartu    VARCHAR(30) NOT NULL UNIQUE,
    status         VARCHAR(20) NOT NULL DEFAULT 'aktif'
                   CHECK (status IN ('aktif', 'nonaktif', 'ditangguhkan')),
    tanggal_terbit DATE        NOT NULL DEFAULT CURRENT_DATE,
    created_at     TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP(0) NOT NULL DEFAULT now()
);

-- Pengajuan pinjam (dari anggota)
CREATE TABLE pengajuan (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anggota_id     BIGINT      NOT NULL REFERENCES anggota(id),
    status         VARCHAR(20) NOT NULL DEFAULT 'menunggu'
                   CHECK (status IN ('menunggu', 'disetujui', 'ditolak',
                                     'dibatalkan', 'terpenuhi')),
    ditinjau_oleh  BIGINT REFERENCES pengguna(id),
    ditinjau_pada  TIMESTAMP(0),
    catatan        TEXT,
    created_at     TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP(0) NOT NULL DEFAULT now(),
    -- keputusan petugas wajib punya pelaku dan waktu
    CHECK (status IN ('menunggu', 'dibatalkan')
           OR (ditinjau_oleh IS NOT NULL AND ditinjau_pada IS NOT NULL))
);
CREATE INDEX ON pengajuan (anggota_id);
CREATE INDEX ON pengajuan (status);

CREATE TABLE pengajuan_item (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pengajuan_id  BIGINT   NOT NULL REFERENCES pengajuan(id) ON DELETE CASCADE,
    buku_id       BIGINT   NOT NULL REFERENCES buku(id),
    jumlah        SMALLINT NOT NULL DEFAULT 1 CHECK (jumlah > 0),
    UNIQUE (pengajuan_id, buku_id)
);
CREATE INDEX ON pengajuan_item (buku_id);

-- Pinjaman aktual (setelah buku fisik diserahkan)
CREATE TABLE pinjaman (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pengajuan_id   BIGINT REFERENCES pengajuan(id),
    anggota_id     BIGINT       NOT NULL REFERENCES anggota(id),
    petugas_id     BIGINT       NOT NULL REFERENCES pengguna(id),
    tanggal_pinjam TIMESTAMP(0) NOT NULL DEFAULT now(),
    jatuh_tempo    TIMESTAMP(0) NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'aktif'
                   CHECK (status IN ('aktif', 'sebagian_kembali', 'selesai')),
    perpanjangan   SMALLINT     NOT NULL DEFAULT 0 CHECK (perpanjangan >= 0),
    catatan        TEXT,
    created_at     TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at     TIMESTAMP(0) NOT NULL DEFAULT now(),
    CHECK (jatuh_tempo > tanggal_pinjam)
);
CREATE INDEX ON pinjaman (anggota_id);
CREATE INDEX ON pinjaman (status);
CREATE INDEX ON pinjaman (pengajuan_id);
CREATE INDEX ON pinjaman (jatuh_tempo) WHERE status <> 'selesai';

CREATE TABLE pinjaman_item (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pinjaman_id      BIGINT      NOT NULL REFERENCES pinjaman(id) ON DELETE CASCADE,
    eksemplar_id     BIGINT      NOT NULL REFERENCES eksemplar(id),
    kondisi_keluar   VARCHAR(20) NOT NULL DEFAULT 'baik'
                     CHECK (kondisi_keluar IN ('baik', 'rusak_ringan', 'rusak_berat', 'hilang')),
    tanggal_kembali  TIMESTAMP(0),
    kondisi_kembali  VARCHAR(20)
                     CHECK (kondisi_kembali IS NULL
                            OR kondisi_kembali IN ('baik', 'rusak_ringan', 'rusak_berat', 'hilang')),
    catatan_kembali  TEXT,
    -- jika sudah kembali, kondisi saat kembali wajib diisi
    CHECK (tanggal_kembali IS NULL OR kondisi_kembali IS NOT NULL)
);
CREATE INDEX ON pinjaman_item (pinjaman_id);
CREATE INDEX ON pinjaman_item (eksemplar_id);

-- Aturan inti: satu eksemplar hanya boleh punya SATU pinjaman yang belum kembali
CREATE UNIQUE INDEX ON pinjaman_item (eksemplar_id) WHERE tanggal_kembali IS NULL;

COMMIT;
