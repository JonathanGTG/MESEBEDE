-- 03_skema_lab.sql
-- Modul Laboratorium Komputer. Jalankan SETELAH 01_skema_umum.sql.
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 03_skema_lab.sql
--
-- Ringkasan desain:
--   barang_lab = master jenis barang (tanpa saldo jumlah)
--   aset_lab   = satu baris per unit fisik; semua rekap dihitung dari sini
--   Pengusul tidak boleh memverifikasi/menyetujui usulannya sendiri
--   (dijaga CHECK di database).
BEGIN;

CREATE TABLE kategori_lab (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nama        VARCHAR(100) NOT NULL UNIQUE,
    keterangan  TEXT,
    aktif       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(0) NOT NULL DEFAULT now()
);

CREATE TABLE barang_lab (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kategori_id  BIGINT       NOT NULL REFERENCES kategori_lab(id),
    nama         VARCHAR(150) NOT NULL,
    merk         VARCHAR(80),
    tipe         VARCHAR(80),
    satuan       VARCHAR(20)  NOT NULL DEFAULT 'unit',
    keterangan   TEXT,
    aktif        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at   TIMESTAMP(0) NOT NULL DEFAULT now()
);
CREATE INDEX ON barang_lab (kategori_id);
CREATE INDEX ON barang_lab (nama);

CREATE TABLE lokasi_lab (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode        VARCHAR(20)  NOT NULL UNIQUE,      -- PC-01 ... PC-30, GUDANG, SERVIS
    nama        VARCHAR(100) NOT NULL,
    jenis       VARCHAR(20)  NOT NULL
                CHECK (jenis IN ('meja_pc', 'gudang', 'servis', 'lainnya')),
    keterangan  TEXT,
    aktif       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at  TIMESTAMP(0) NOT NULL DEFAULT now()
);

-- Aset fisik: satu baris = satu unit
CREATE TABLE aset_lab (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    barang_id          BIGINT      NOT NULL REFERENCES barang_lab(id),
    kode               VARCHAR(40) NOT NULL UNIQUE,
    nomor_seri         VARCHAR(80),
    klasifikasi        VARCHAR(10) NOT NULL CHECK (klasifikasi IN ('baru', 'lama')),
    kondisi            VARCHAR(20) NOT NULL DEFAULT 'baik'
                       CHECK (kondisi IN ('baik', 'rusak_ringan', 'rusak_berat')),
    status             VARCHAR(20) NOT NULL DEFAULT 'aktif'
                       CHECK (status IN ('aktif', 'dalam_servis', 'afkir')),
    lokasi_id          BIGINT REFERENCES lokasi_lab(id),
    tanggal_perolehan  DATE,
    jenis_perolehan    VARCHAR(20) NOT NULL DEFAULT 'pembelian'
                       CHECK (jenis_perolehan IN ('pembelian', 'hibah', 'lainnya')),
    nilai_perolehan    NUMERIC(14,2) CHECK (nilai_perolehan IS NULL OR nilai_perolehan >= 0),
    vendor             VARCHAR(150),
    catatan            TEXT,
    created_at         TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP(0) NOT NULL DEFAULT now()
);
-- nilai_perolehan boleh NULL = belum tercatat (bukan nol)
-- nomor seri unik hanya jika diisi
CREATE UNIQUE INDEX ON aset_lab (nomor_seri) WHERE nomor_seri IS NOT NULL;
CREATE INDEX ON aset_lab (barang_id);
CREATE INDEX ON aset_lab (lokasi_id);
CREATE INDEX ON aset_lab (status);
CREATE INDEX ON aset_lab (kondisi);
CREATE INDEX ON aset_lab (klasifikasi);

-- Transaksi / usulan
CREATE TABLE transaksi_lab (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kode               VARCHAR(40) NOT NULL UNIQUE,
    jenis              VARCHAR(20) NOT NULL
                       CHECK (jenis IN ('pengadaan', 'barang_masuk', 'servis',
                                        'mutasi_lokasi', 'afkir', 'lainnya')),
    tanggal            DATE        NOT NULL DEFAULT CURRENT_DATE,
    status             VARCHAR(20) NOT NULL DEFAULT 'draft'
                       CHECK (status IN ('draft', 'diajukan', 'diverifikasi', 'dikembalikan',
                                         'disetujui', 'ditolak', 'selesai')),
    pengusul_id        BIGINT      NOT NULL REFERENCES pengguna(id),
    verifikator_id     BIGINT REFERENCES pengguna(id),
    diverifikasi_pada  TIMESTAMP(0),
    penyetuju_id       BIGINT REFERENCES pengguna(id),
    disetujui_pada     TIMESTAMP(0),
    vendor_penerima    VARCHAR(150),
    alasan             TEXT,
    catatan            TEXT,
    created_at         TIMESTAMP(0) NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP(0) NOT NULL DEFAULT now(),
    -- pemisahan tugas: pengusul tidak boleh memverifikasi/menyetujui sendiri
    CHECK (verifikator_id IS NULL OR verifikator_id <> pengusul_id),
    CHECK (penyetuju_id   IS NULL OR penyetuju_id   <> pengusul_id)
);
CREATE INDEX ON transaksi_lab (status);
CREATE INDEX ON transaksi_lab (pengusul_id);
CREATE INDEX ON transaksi_lab (tanggal);
CREATE INDEX ON transaksi_lab (jenis);

-- Rincian barang per transaksi
CREATE TABLE transaksi_lab_item (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaksi_id  BIGINT  NOT NULL REFERENCES transaksi_lab(id) ON DELETE CASCADE,
    barang_id     BIGINT  NOT NULL REFERENCES barang_lab(id),
    jumlah        INTEGER NOT NULL CHECK (jumlah > 0),
    klasifikasi   VARCHAR(10) CHECK (klasifikasi IS NULL OR klasifikasi IN ('baru', 'lama')),
    kondisi       VARCHAR(20) CHECK (kondisi IS NULL
                                     OR kondisi IN ('baik', 'rusak_ringan', 'rusak_berat')),
    harga_satuan  NUMERIC(14,2) CHECK (harga_satuan IS NULL OR harga_satuan >= 0),
    catatan       TEXT
);
CREATE INDEX ON transaksi_lab_item (transaksi_id);
CREATE INDEX ON transaksi_lab_item (barang_id);

-- Aset fisik yang terdampak oleh suatu rincian transaksi
CREATE TABLE transaksi_lab_aset (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id             BIGINT      NOT NULL REFERENCES transaksi_lab_item(id) ON DELETE CASCADE,
    aset_id             BIGINT      NOT NULL REFERENCES aset_lab(id),
    aksi                VARCHAR(20) NOT NULL
                        CHECK (aksi IN ('masuk', 'mutasi_lokasi', 'servis_keluar',
                                        'servis_kembali', 'ubah_kondisi', 'afkir')),
    kondisi_sebelum     VARCHAR(20) CHECK (kondisi_sebelum IS NULL
                                           OR kondisi_sebelum IN ('baik', 'rusak_ringan', 'rusak_berat')),
    kondisi_sesudah     VARCHAR(20) CHECK (kondisi_sesudah IS NULL
                                           OR kondisi_sesudah IN ('baik', 'rusak_ringan', 'rusak_berat')),
    lokasi_sebelum_id   BIGINT REFERENCES lokasi_lab(id),
    lokasi_sesudah_id   BIGINT REFERENCES lokasi_lab(id),
    catatan             TEXT
);
CREATE INDEX ON transaksi_lab_aset (item_id);
CREATE INDEX ON transaksi_lab_aset (aset_id);

-- Riwayat verifikasi Waka dan persetujuan Kepala Sekolah
CREATE TABLE persetujuan_lab (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaksi_id  BIGINT       NOT NULL REFERENCES transaksi_lab(id) ON DELETE CASCADE,
    pelaku_id     BIGINT       NOT NULL REFERENCES pengguna(id),
    tahap         VARCHAR(30)  NOT NULL
                  CHECK (tahap IN ('verifikasi_waka', 'persetujuan_kepsek')),
    keputusan     VARCHAR(10)  NOT NULL
                  CHECK (keputusan IN ('setuju', 'tolak', 'kembalikan')),
    catatan       TEXT,
    created_at    TIMESTAMP(0) NOT NULL DEFAULT now(),
    -- tolak/kembalikan wajib disertai catatan
    CHECK (keputusan = 'setuju' OR length(btrim(coalesce(catatan, ''))) > 0)
);
CREATE INDEX ON persetujuan_lab (transaksi_id);
CREATE INDEX ON persetujuan_lab (pelaku_id);

COMMIT;
