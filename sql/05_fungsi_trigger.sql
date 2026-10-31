-- 05_fungsi_trigger.sql
-- Fungsi (stored function) dan trigger PL/pgSQL. Jalankan SETELAH 01-04.
-- Jalankan: psql -U postgres -d smk_alrazi -v ON_ERROR_STOP=1 -f 05_fungsi_trigger.sql
--
-- Setiap fungsi yang mengubah beberapa tabel berjalan ATOMIK: jika ada
-- RAISE EXCEPTION, semua perubahan di dalam pemanggilan itu dibatalkan
-- (materi Manajemen Transaksi: atomicity).
--
-- Mencatat pelaku audit log: Laravel memanggil, di dalam transaksi yang sama,
--   SELECT set_config('app.pengguna_id', '<id pengguna login>', true);
-- Jika tidak diatur, kolom pengguna_id pada log_aktivitas berisi NULL.
BEGIN;

-- =====================================================================
-- 1. Sequence
-- =====================================================================
CREATE SEQUENCE seq_kartu     START 1;
CREATE SEQUENCE seq_kode_aset START 1;

-- =====================================================================
-- 2. Trigger: isi updated_at otomatis
-- =====================================================================
CREATE FUNCTION trigger_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'peran', 'pengguna', 'profil',
        'kategori_buku', 'penerbit', 'penulis', 'buku', 'eksemplar',
        'aturan_pinjam', 'anggota', 'pengajuan', 'pinjaman',
        'kategori_lab', 'barang_lab', 'lokasi_lab', 'aset_lab', 'transaksi_lab'
    ] LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_updated_at BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION trigger_updated_at()', t);
    END LOOP;
END;
$$;

-- =====================================================================
-- 3. Trigger: audit log otomatis
-- =====================================================================
CREATE FUNCTION trigger_log() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
    v_modul    text    := TG_ARGV[0];
    v_pelaku   bigint  := NULLIF(current_setting('app.pengguna_id', true), '')::bigint;
    v_abaikan  text[]  := ARRAY['password', 'remember_token', 'updated_at', 'login_terakhir'];
    v_lama     jsonb;
    v_baru     jsonb;
    v_beda     jsonb   := '{}'::jsonb;
    k          text;
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO log_aktivitas (pengguna_id, modul, aksi, objek, objek_id, keterangan, data)
        VALUES (v_pelaku, v_modul, 'tambah', TG_TABLE_NAME, NEW.id,
                'Data baru ditambahkan',
                jsonb_build_object('baru', to_jsonb(NEW) - v_abaikan));

    ELSIF TG_OP = 'UPDATE' THEN
        v_lama := to_jsonb(OLD) - v_abaikan;
        v_baru := to_jsonb(NEW) - v_abaikan;
        FOR k IN SELECT jsonb_object_keys(v_baru) LOOP
            IF v_baru -> k IS DISTINCT FROM v_lama -> k THEN
                v_beda := v_beda || jsonb_build_object(
                    k, jsonb_build_object('lama', v_lama -> k, 'baru', v_baru -> k));
            END IF;
        END LOOP;
        IF v_beda = '{}'::jsonb THEN
            RETURN NULL;              -- tidak ada perubahan berarti, tidak dicatat
        END IF;
        INSERT INTO log_aktivitas (pengguna_id, modul, aksi, objek, objek_id, keterangan, data)
        VALUES (v_pelaku, v_modul, 'ubah', TG_TABLE_NAME, NEW.id,
                'Data diubah', v_beda);

    ELSE  -- DELETE
        INSERT INTO log_aktivitas (pengguna_id, modul, aksi, objek, objek_id, keterangan, data)
        VALUES (v_pelaku, v_modul, 'hapus', TG_TABLE_NAME, OLD.id,
                'Data dihapus',
                jsonb_build_object('lama', to_jsonb(OLD) - v_abaikan));
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_log AFTER INSERT OR UPDATE OR DELETE ON pengguna
    FOR EACH ROW EXECUTE FUNCTION trigger_log('admin');
CREATE TRIGGER trg_log AFTER INSERT OR UPDATE OR DELETE ON aset_lab
    FOR EACH ROW EXECUTE FUNCTION trigger_log('lab');
CREATE TRIGGER trg_log AFTER INSERT OR UPDATE OR DELETE ON transaksi_lab
    FOR EACH ROW EXECUTE FUNCTION trigger_log('lab');
CREATE TRIGGER trg_log AFTER INSERT OR UPDATE OR DELETE ON eksemplar
    FOR EACH ROW EXECUTE FUNCTION trigger_log('perpus');
CREATE TRIGGER trg_log AFTER INSERT OR UPDATE OR DELETE ON pinjaman
    FOR EACH ROW EXECUTE FUNCTION trigger_log('perpus');
CREATE TRIGGER trg_log AFTER INSERT OR UPDATE OR DELETE ON pengajuan
    FOR EACH ROW EXECUTE FUNCTION trigger_log('perpus');

-- Audit log tidak boleh diubah atau dihapus (FR-52).
-- Konsekuensi: pengguna tidak dihapus, cukup dinonaktifkan (aktif = FALSE).
CREATE FUNCTION trigger_log_terkunci() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'log_aktivitas tidak boleh diubah atau dihapus';
END;
$$;

CREATE TRIGGER trg_log_terkunci BEFORE UPDATE OR DELETE ON log_aktivitas
    FOR EACH ROW EXECUTE FUNCTION trigger_log_terkunci();

-- =====================================================================
-- 4. Trigger penjaga integritas
-- =====================================================================
-- Eksemplar tidak boleh ditandai 'tersedia' selama masih ada pinjaman aktif
CREATE FUNCTION trigger_eksemplar_tersedia() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM pinjaman_item
               WHERE eksemplar_id = NEW.id AND tanggal_kembali IS NULL) THEN
        RAISE EXCEPTION 'Eksemplar % masih dipinjam, tidak boleh berstatus tersedia', NEW.kode;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_tersedia BEFORE UPDATE OF status ON eksemplar
    FOR EACH ROW WHEN (NEW.status = 'tersedia' AND OLD.status <> 'tersedia')
    EXECUTE FUNCTION trigger_eksemplar_tersedia();

-- Aset afkir tidak boleh diaktifkan kembali atau dipindahkan
CREATE FUNCTION trigger_aset_afkir() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status <> 'afkir' OR NEW.lokasi_id IS DISTINCT FROM OLD.lokasi_id THEN
        RAISE EXCEPTION 'Aset % sudah afkir dan tidak boleh diaktifkan atau dipindahkan', OLD.kode;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_afkir BEFORE UPDATE ON aset_lab
    FOR EACH ROW WHEN (OLD.status = 'afkir')
    EXECUTE FUNCTION trigger_aset_afkir();

-- =====================================================================
-- 5. Fungsi bantu
-- =====================================================================
CREATE FUNCTION jumlah_tersedia(p_buku_id bigint) RETURNS integer
LANGUAGE sql STABLE AS $$
    SELECT count(*)::integer FROM eksemplar
    WHERE buku_id = p_buku_id AND status = 'tersedia';
$$;

CREATE FUNCTION nilai_aturan(p_kunci text) RETURNS integer
LANGUAGE plpgsql STABLE AS $$
DECLARE
    v integer;
BEGIN
    SELECT nilai INTO v FROM aturan_pinjam WHERE kunci = p_kunci;
    IF v IS NULL THEN
        RAISE EXCEPTION 'Aturan pinjam "%" belum ada di tabel aturan_pinjam', p_kunci;
    END IF;
    RETURN v;
END;
$$;

-- =====================================================================
-- 6. PERPUSTAKAAN
-- =====================================================================

-- 6a. Terbitkan kartu perpustakaan (nomor otomatis, FR-46)
--     Siswa wajib punya NISN; guru wajib punya NIP atau NUPTK.
CREATE FUNCTION terbitkan_kartu(p_pengguna_id bigint) RETURNS varchar
LANGUAGE plpgsql AS $$
DECLARE
    v_kode   text;
    v_aktif  boolean;
    v_nisn   text;
    v_nip    text;
    v_nuptk  text;
    v_kartu  varchar;
BEGIN
    SELECT r.kode, p.aktif INTO v_kode, v_aktif
    FROM pengguna p JOIN peran r ON r.id = p.peran_id
    WHERE p.id = p_pengguna_id;

    IF v_kode IS NULL THEN
        RAISE EXCEPTION 'Pengguna % tidak ditemukan', p_pengguna_id;
    END IF;
    IF NOT v_aktif THEN
        RAISE EXCEPTION 'Akun pengguna % tidak aktif', p_pengguna_id;
    END IF;
    IF v_kode NOT IN ('guru', 'siswa') THEN
        RAISE EXCEPTION 'Kartu perpustakaan hanya untuk guru dan siswa';
    END IF;

    -- sudah punya kartu: kembalikan yang lama
    SELECT nomor_kartu INTO v_kartu FROM anggota WHERE pengguna_id = p_pengguna_id;
    IF FOUND THEN
        RETURN v_kartu;
    END IF;

    SELECT nisn, nip, nuptk INTO v_nisn, v_nip, v_nuptk
    FROM profil WHERE pengguna_id = p_pengguna_id;

    IF v_kode = 'siswa' AND v_nisn IS NULL THEN
        RAISE EXCEPTION 'Data siswa belum lengkap: NISN wajib diisi';
    END IF;
    IF v_kode = 'guru' AND v_nip IS NULL AND v_nuptk IS NULL THEN
        RAISE EXCEPTION 'Data guru belum lengkap: NIP atau NUPTK wajib diisi';
    END IF;

    v_kartu := 'PRP-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('seq_kartu')::text, 6, '0');
    INSERT INTO anggota (pengguna_id, nomor_kartu) VALUES (p_pengguna_id, v_kartu);
    RETURN v_kartu;
END;
$$;

-- 6b. Catat peminjaman aktual (FR-41, FR-42)
--     Mengembalikan id pinjaman baru.
CREATE FUNCTION buat_pinjaman(
    p_anggota_id    bigint,
    p_petugas_id    bigint,
    p_eksemplar_ids bigint[],
    p_pengajuan_id  bigint DEFAULT NULL
) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE
    v_peran      text;
    v_aktif      boolean;
    v_status_ang text;
    v_jumlah     integer;
    v_lama       integer;
    v_maks       integer;
    v_sedang     integer;
    v_ada        integer;
    v_tersedia   integer;
    v_peng       pengajuan%ROWTYPE;
    v_id         bigint;
BEGIN
    -- petugas harus pengurus perpustakaan (atau admin) yang aktif
    SELECT r.kode, p.aktif INTO v_peran, v_aktif
    FROM pengguna p JOIN peran r ON r.id = p.peran_id WHERE p.id = p_petugas_id;
    IF v_peran IS NULL OR NOT v_aktif OR v_peran NOT IN ('pengurus_perpus', 'admin') THEN
        RAISE EXCEPTION 'Hanya pengurus perpustakaan yang boleh mencatat peminjaman';
    END IF;

    SELECT status INTO v_status_ang FROM anggota WHERE id = p_anggota_id;
    IF v_status_ang IS NULL THEN
        RAISE EXCEPTION 'Anggota % tidak ditemukan', p_anggota_id;
    END IF;
    IF v_status_ang <> 'aktif' THEN
        RAISE EXCEPTION 'Keanggotaan tidak aktif (status: %)', v_status_ang;
    END IF;

    v_jumlah := coalesce(array_length(p_eksemplar_ids, 1), 0);
    IF v_jumlah = 0 THEN
        RAISE EXCEPTION 'Pilih minimal satu eksemplar';
    END IF;
    IF (SELECT count(DISTINCT x) FROM unnest(p_eksemplar_ids) AS x) <> v_jumlah THEN
        RAISE EXCEPTION 'Daftar eksemplar berisi duplikat';
    END IF;

    -- batas jumlah buku per anggota
    v_lama := nilai_aturan('lama_pinjam_hari');
    v_maks := nilai_aturan('maks_buku_per_anggota');
    SELECT count(*)::integer INTO v_sedang
    FROM pinjaman_item pi JOIN pinjaman p ON p.id = pi.pinjaman_id
    WHERE p.anggota_id = p_anggota_id AND pi.tanggal_kembali IS NULL;
    IF v_sedang + v_jumlah > v_maks THEN
        RAISE EXCEPTION 'Melebihi batas pinjam: sedang % buku, mengajukan %, maksimal %',
            v_sedang, v_jumlah, v_maks;
    END IF;

    -- kunci eksemplar (urut id agar tidak deadlock) lalu cek ketersediaan
    SELECT count(*)::integer, count(*) FILTER (WHERE status = 'tersedia')::integer
    INTO v_ada, v_tersedia
    FROM (SELECT id, status FROM eksemplar
          WHERE id = ANY (p_eksemplar_ids) ORDER BY id FOR UPDATE) x;
    IF v_ada <> v_jumlah THEN
        RAISE EXCEPTION 'Ada eksemplar yang tidak ditemukan';
    END IF;
    IF v_tersedia <> v_jumlah THEN
        RAISE EXCEPTION 'Ada eksemplar yang tidak berstatus tersedia';
    END IF;

    -- jika berasal dari pengajuan, pengajuan harus sudah disetujui
    IF p_pengajuan_id IS NOT NULL THEN
        SELECT * INTO v_peng FROM pengajuan WHERE id = p_pengajuan_id FOR UPDATE;
        IF NOT FOUND OR v_peng.anggota_id <> p_anggota_id THEN
            RAISE EXCEPTION 'Pengajuan % tidak cocok dengan anggota', p_pengajuan_id;
        END IF;
        IF v_peng.status <> 'disetujui' THEN
            RAISE EXCEPTION 'Pengajuan belum disetujui (status: %)', v_peng.status;
        END IF;
    END IF;

    INSERT INTO pinjaman (pengajuan_id, anggota_id, petugas_id, jatuh_tempo)
    VALUES (p_pengajuan_id, p_anggota_id, p_petugas_id,
            now() + make_interval(days => v_lama))
    RETURNING id INTO v_id;

    INSERT INTO pinjaman_item (pinjaman_id, eksemplar_id, kondisi_keluar)
    SELECT v_id, e.id, e.kondisi FROM eksemplar e WHERE e.id = ANY (p_eksemplar_ids);

    UPDATE eksemplar SET status = 'dipinjam' WHERE id = ANY (p_eksemplar_ids);

    IF p_pengajuan_id IS NOT NULL THEN
        UPDATE pengajuan SET status = 'terpenuhi' WHERE id = p_pengajuan_id;
    END IF;

    RETURN v_id;
END;
$$;

-- 6c. Catat pengembalian satu eksemplar (FR-43)
--     Hanya kondisi 'baik' yang membuat eksemplar tersedia kembali.
--     Rusak ringan/berat -> status 'rusak' (menunggu pemeriksaan petugas).
CREATE FUNCTION kembalikan_buku(
    p_pinjaman_item_id bigint,
    p_kondisi          text,
    p_catatan          text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    v_item pinjaman_item%ROWTYPE;
BEGIN
    IF p_kondisi NOT IN ('baik', 'rusak_ringan', 'rusak_berat', 'hilang') THEN
        RAISE EXCEPTION 'Kondisi "%" tidak valid', p_kondisi;
    END IF;

    SELECT * INTO v_item FROM pinjaman_item WHERE id = p_pinjaman_item_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item pinjaman % tidak ditemukan', p_pinjaman_item_id;
    END IF;
    IF v_item.tanggal_kembali IS NOT NULL THEN
        RAISE EXCEPTION 'Item pinjaman % sudah dikembalikan', p_pinjaman_item_id;
    END IF;

    UPDATE pinjaman_item
    SET tanggal_kembali = now(), kondisi_kembali = p_kondisi, catatan_kembali = p_catatan
    WHERE id = p_pinjaman_item_id;

    UPDATE eksemplar
    SET kondisi = p_kondisi,
        status  = CASE p_kondisi
                    WHEN 'baik'   THEN 'tersedia'
                    WHEN 'hilang' THEN 'hilang'
                    ELSE 'rusak'
                  END
    WHERE id = v_item.eksemplar_id;

    UPDATE pinjaman
    SET status = CASE
                   WHEN EXISTS (SELECT 1 FROM pinjaman_item
                                WHERE pinjaman_id = v_item.pinjaman_id
                                  AND tanggal_kembali IS NULL)
                   THEN 'sebagian_kembali' ELSE 'selesai' END
    WHERE id = v_item.pinjaman_id;
END;
$$;

-- 6d. Perpanjang pinjaman (aturan masih sementara)
CREATE FUNCTION perpanjang_pinjaman(p_pinjaman_id bigint) RETURNS timestamp
LANGUAGE plpgsql AS $$
DECLARE
    v_pin  pinjaman%ROWTYPE;
    v_maks integer := nilai_aturan('maks_perpanjangan');
    v_baru timestamp(0);
BEGIN
    SELECT * INTO v_pin FROM pinjaman WHERE id = p_pinjaman_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pinjaman % tidak ditemukan', p_pinjaman_id;
    END IF;
    IF v_pin.status = 'selesai' THEN
        RAISE EXCEPTION 'Pinjaman sudah selesai';
    END IF;
    IF v_pin.perpanjangan >= v_maks THEN
        RAISE EXCEPTION 'Batas perpanjangan (%) sudah tercapai', v_maks;
    END IF;

    v_baru := v_pin.jatuh_tempo + make_interval(days => nilai_aturan('lama_pinjam_hari'));
    UPDATE pinjaman SET jatuh_tempo = v_baru, perpanjangan = perpanjangan + 1
    WHERE id = p_pinjaman_id;
    RETURN v_baru;
END;
$$;

-- =====================================================================
-- 7. LABORATORIUM
-- =====================================================================

-- 7a. Tambah banyak aset sekaligus: satu baris per unit fisik (FR-24)
--     Mengembalikan daftar id aset yang dibuat.
CREATE FUNCTION tambah_aset_lab(
    p_barang_id        bigint,
    p_jumlah           integer,
    p_klasifikasi      text,
    p_kondisi          text,
    p_jenis_perolehan  text,
    p_tanggal          date,
    p_nilai            numeric,
    p_vendor           text,
    p_lokasi_id        bigint
) RETURNS SETOF bigint
LANGUAGE plpgsql AS $$
BEGIN
    IF p_jumlah IS NULL OR p_jumlah < 1 OR p_jumlah > 500 THEN
        RAISE EXCEPTION 'Jumlah unit harus 1 sampai 500';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM barang_lab WHERE id = p_barang_id AND aktif) THEN
        RAISE EXCEPTION 'Barang % tidak ditemukan atau tidak aktif', p_barang_id;
    END IF;

    RETURN QUERY
    INSERT INTO aset_lab (barang_id, kode, klasifikasi, kondisi, jenis_perolehan,
                          tanggal_perolehan, nilai_perolehan, vendor, lokasi_id)
    SELECT p_barang_id,
           'AST-' || lpad(nextval('seq_kode_aset')::text, 6, '0'),
           p_klasifikasi, p_kondisi, p_jenis_perolehan,
           p_tanggal, p_nilai, p_vendor, p_lokasi_id
    FROM generate_series(1, p_jumlah)
    RETURNING id;
END;
$$;

-- 7b. Ajukan (atau ajukan ulang) usulan ke Waka Sarpras
CREATE FUNCTION ajukan_transaksi_lab(p_transaksi_id bigint, p_pelaku_id bigint)
RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    t transaksi_lab%ROWTYPE;
BEGIN
    SELECT * INTO t FROM transaksi_lab WHERE id = p_transaksi_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaksi % tidak ditemukan', p_transaksi_id;
    END IF;
    IF t.pengusul_id <> p_pelaku_id THEN
        RAISE EXCEPTION 'Hanya pengusul yang boleh mengajukan usulannya';
    END IF;
    IF t.status NOT IN ('draft', 'dikembalikan', 'ditolak') THEN
        RAISE EXCEPTION 'Usulan berstatus % tidak dapat diajukan', t.status;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM transaksi_lab_item WHERE transaksi_id = p_transaksi_id) THEN
        RAISE EXCEPTION 'Usulan belum memiliki rincian barang';
    END IF;

    UPDATE transaksi_lab
    SET status = 'diajukan',
        verifikator_id = NULL, diverifikasi_pada = NULL,
        penyetuju_id   = NULL, disetujui_pada    = NULL
    WHERE id = p_transaksi_id;
END;
$$;

-- 7c. Verifikasi Waka dan persetujuan Kepala Sekolah
--     tahap: 'verifikasi_waka' | 'persetujuan_kepsek'
--     keputusan: 'setuju' | 'tolak' | 'kembalikan'
--     Kepala Sekolah hanya boleh setuju atau tolak; Waka boleh ketiganya.
CREATE FUNCTION keputusan_lab(
    p_transaksi_id bigint,
    p_pelaku_id    bigint,
    p_tahap        text,
    p_keputusan    text,
    p_catatan      text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    t        transaksi_lab%ROWTYPE;
    v_peran  text;
    v_aktif  boolean;
BEGIN
    SELECT * INTO t FROM transaksi_lab WHERE id = p_transaksi_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaksi % tidak ditemukan', p_transaksi_id;
    END IF;

    SELECT r.kode, p.aktif INTO v_peran, v_aktif
    FROM pengguna p JOIN peran r ON r.id = p.peran_id WHERE p.id = p_pelaku_id;
    IF v_peran IS NULL OR NOT v_aktif THEN
        RAISE EXCEPTION 'Pelaku tidak valid atau tidak aktif';
    END IF;
    IF p_pelaku_id = t.pengusul_id THEN
        RAISE EXCEPTION 'Pengusul tidak boleh memutuskan usulannya sendiri';
    END IF;
    IF p_keputusan NOT IN ('setuju', 'tolak', 'kembalikan') THEN
        RAISE EXCEPTION 'Keputusan "%" tidak valid', p_keputusan;
    END IF;
    IF p_keputusan <> 'setuju' AND length(btrim(coalesce(p_catatan, ''))) = 0 THEN
        RAISE EXCEPTION 'Catatan wajib diisi untuk keputusan %', p_keputusan;
    END IF;

    IF p_tahap = 'verifikasi_waka' THEN
        IF v_peran <> 'waka_sarpras' THEN
            RAISE EXCEPTION 'Verifikasi hanya boleh dilakukan Waka Sarpras';
        END IF;
        IF t.status <> 'diajukan' THEN
            RAISE EXCEPTION 'Usulan berstatus %, bukan diajukan', t.status;
        END IF;
        UPDATE transaksi_lab
        SET status = CASE p_keputusan WHEN 'setuju' THEN 'diverifikasi'
                                      WHEN 'tolak'  THEN 'ditolak'
                                      ELSE 'dikembalikan' END,
            verifikator_id = p_pelaku_id, diverifikasi_pada = now()
        WHERE id = p_transaksi_id;

    ELSIF p_tahap = 'persetujuan_kepsek' THEN
        IF v_peran <> 'kepala_sekolah' THEN
            RAISE EXCEPTION 'Persetujuan akhir hanya boleh dilakukan Kepala Sekolah';
        END IF;
        IF t.status <> 'diverifikasi' THEN
            RAISE EXCEPTION 'Usulan belum diverifikasi Waka (status: %)', t.status;
        END IF;
        IF p_keputusan = 'kembalikan' THEN
            RAISE EXCEPTION 'Kepala Sekolah hanya dapat menyetujui atau menolak';
        END IF;
        UPDATE transaksi_lab
        SET status = CASE p_keputusan WHEN 'setuju' THEN 'disetujui' ELSE 'ditolak' END,
            penyetuju_id = p_pelaku_id, disetujui_pada = now()
        WHERE id = p_transaksi_id;

    ELSE
        RAISE EXCEPTION 'Tahap "%" tidak valid', p_tahap;
    END IF;

    INSERT INTO persetujuan_lab (transaksi_id, pelaku_id, tahap, keputusan, catatan)
    VALUES (p_transaksi_id, p_pelaku_id, p_tahap, p_keputusan, p_catatan);
END;
$$;

-- 7d. Terapkan usulan yang sudah disetujui ke inventaris.
--     Inventaris hanya berubah di sini, setelah persetujuan akhir (FR-30).
--       pengadaan : membuat aset baru di GUDANG sesuai rincian
--       afkir     : menandai aset yang terdaftar di transaksi_lab_aset sebagai afkir
CREATE FUNCTION selesaikan_transaksi_lab(p_transaksi_id bigint, p_pelaku_id bigint)
RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
    t         transaksi_lab%ROWTYPE;
    r         transaksi_lab_item%ROWTYPE;
    v_peran   text;
    v_aktif   boolean;
    v_gudang  bigint;
    v_terdaftar integer;
BEGIN
    SELECT * INTO t FROM transaksi_lab WHERE id = p_transaksi_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaksi % tidak ditemukan', p_transaksi_id;
    END IF;
    IF t.status <> 'disetujui' THEN
        RAISE EXCEPTION 'Usulan belum disetujui Kepala Sekolah (status: %)', t.status;
    END IF;

    SELECT r2.kode, p.aktif INTO v_peran, v_aktif
    FROM pengguna p JOIN peran r2 ON r2.id = p.peran_id WHERE p.id = p_pelaku_id;
    IF v_peran IS NULL OR NOT v_aktif OR v_peran <> 'pengurus_lab' THEN
        RAISE EXCEPTION 'Hanya pengurus lab yang boleh menyelesaikan transaksi';
    END IF;

    IF t.jenis = 'pengadaan' THEN
        SELECT id INTO v_gudang FROM lokasi_lab WHERE kode = 'GUDANG';
        FOR r IN SELECT * FROM transaksi_lab_item WHERE transaksi_id = p_transaksi_id LOOP
            INSERT INTO transaksi_lab_aset (item_id, aset_id, aksi, kondisi_sesudah, lokasi_sesudah_id)
            SELECT r.id, a, 'masuk', coalesce(r.kondisi, 'baik'), v_gudang
            FROM tambah_aset_lab(r.barang_id, r.jumlah,
                                 coalesce(r.klasifikasi, 'baru'),
                                 coalesce(r.kondisi, 'baik'),
                                 'pembelian', current_date, r.harga_satuan,
                                 t.vendor_penerima, v_gudang) AS a;
        END LOOP;

    ELSIF t.jenis = 'afkir' THEN
        FOR r IN SELECT * FROM transaksi_lab_item WHERE transaksi_id = p_transaksi_id LOOP
            SELECT count(*)::integer INTO v_terdaftar
            FROM transaksi_lab_aset WHERE item_id = r.id AND aksi = 'afkir';
            IF v_terdaftar <> r.jumlah THEN
                RAISE EXCEPTION 'Rincian % butuh % aset, yang terdaftar %',
                    r.id, r.jumlah, v_terdaftar;
            END IF;
        END LOOP;

        UPDATE aset_lab SET status = 'afkir', lokasi_id = NULL
        WHERE id IN (SELECT ta.aset_id
                     FROM transaksi_lab_aset ta
                     JOIN transaksi_lab_item i ON i.id = ta.item_id
                     WHERE i.transaksi_id = p_transaksi_id AND ta.aksi = 'afkir');

    ELSE
        RAISE EXCEPTION 'Transaksi jenis % tidak memerlukan persetujuan', t.jenis;
    END IF;

    UPDATE transaksi_lab SET status = 'selesai' WHERE id = p_transaksi_id;
END;
$$;

COMMIT;
