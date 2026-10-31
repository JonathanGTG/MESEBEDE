-- 01_skema_umum.sql
-- Tabel umum: peran, pengguna, profil, notifikasi, log_aktivitas
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 01_skema_umum.sql
-- Tidak ada DROP. Jalankan sekali pada database kosong.
--
-- Catatan: kolom email, password, remember_token, created_at, updated_at
-- sengaja tetap berbahasa Inggris karena itu nama standar Laravel.
BEGIN;

CREATE TABLE peran (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode        VARCHAR(30)  NOT NULL UNIQUE
                CHECK (kode IN ('admin', 'kepala_sekolah', 'waka_sarpras',
                                'pengurus_lab', 'pengurus_perpus', 'guru', 'siswa')),
    nama        VARCHAR(60)  NOT NULL,
    created_at  TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(0) NOT NULL DEFAULT now()
);

CREATE TABLE pengguna (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    peran_id        BIGINT       NOT NULL REFERENCES peran(id),
    nama            VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    password        VARCHAR(255) NOT NULL,      -- hash Laravel, bukan teks biasa
    aktif           BOOLEAN      NOT NULL DEFAULT TRUE,
    login_terakhir  TIMESTAMP(0),
    remember_token  VARCHAR(100),
    created_at      TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at      TIMESTAMP(0) NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ON pengguna (lower(email));
CREATE INDEX ON pengguna (peran_id);
CREATE INDEX ON pengguna (aktif);

-- Identitas resmi. Semua nomor boleh kosong, tetapi harus unik jika diisi.
CREATE TABLE profil (
    pengguna_id  BIGINT PRIMARY KEY REFERENCES pengguna(id) ON DELETE CASCADE,
    npm          VARCHAR(20) UNIQUE,
    nisn         VARCHAR(10) UNIQUE CHECK (nisn IS NULL OR nisn ~ '^[0-9]{10}$'),
    nis          VARCHAR(20) UNIQUE,
    nip          VARCHAR(25) UNIQUE,
    nuptk        VARCHAR(20) UNIQUE,
    telepon      VARCHAR(20),
    kelas        VARCHAR(30),
    jurusan      VARCHAR(60),
    alamat       TEXT,
    created_at   TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at   TIMESTAMP(0) NOT NULL DEFAULT now()
);

CREATE TABLE notifikasi (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pengguna_id  BIGINT       NOT NULL REFERENCES pengguna(id) ON DELETE CASCADE,
    judul        VARCHAR(150) NOT NULL,
    pesan        TEXT         NOT NULL,
    tautan       VARCHAR(255),
    dibaca_pada  TIMESTAMP(0),
    created_at   TIMESTAMP(0) NOT NULL DEFAULT now()
);
CREATE INDEX ON notifikasi (pengguna_id, dibaca_pada);

-- Audit log. Tidak boleh diubah/dihapus (dijaga trigger di file 05).
CREATE TABLE log_aktivitas (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pengguna_id  BIGINT REFERENCES pengguna(id) ON DELETE SET NULL,
    modul        VARCHAR(30) NOT NULL,       -- admin / lab / perpus
    aksi         VARCHAR(40) NOT NULL,       -- tambah / ubah / hapus / setuju ...
    objek        VARCHAR(60) NOT NULL,       -- nama tabel yang terdampak
    objek_id     BIGINT,
    keterangan   TEXT,
    data         JSONB,                      -- nilai lama/baru
    ip           VARCHAR(45),
    created_at   TIMESTAMP(0) NOT NULL DEFAULT now()
);
CREATE INDEX ON log_aktivitas (created_at DESC);
CREATE INDEX ON log_aktivitas (pengguna_id);
CREATE INDEX ON log_aktivitas (modul, aksi);
CREATE INDEX ON log_aktivitas (objek, objek_id);

COMMIT;
