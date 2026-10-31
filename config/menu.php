<?php

// Menu sidebar per area. 'rute' => null berarti halaman belum dibuat
// (tampil abu-abu dengan label "Segera"). Saat fasenya selesai, isi nama rutenya.
return [
    'admin' => ['judul' => 'Administrasi', 'item' => [
        ['label' => 'Pilih Modul',          'rute' => 'admin.dashboard', 'ikon' => 'bi-grid'],
        ['label' => 'Kelola Pengguna',      'rute' => null, 'ikon' => 'bi-people'],
        ['label' => 'Laporan Terpadu',      'rute' => null, 'ikon' => 'bi-file-earmark-text'],
        ['label' => 'Audit Log',            'rute' => null, 'ikon' => 'bi-journal-text'],
        ['label' => 'Backup dan Panduan',   'rute' => null, 'ikon' => 'bi-hdd'],
    ]],
    'kepsek' => ['judul' => 'Kepala Sekolah', 'item' => [
        ['label' => 'Dashboard Eksekutif',  'rute' => 'kepsek.dashboard', 'ikon' => 'bi-speedometer2'],
        ['label' => 'Persetujuan Akhir',    'rute' => null, 'ikon' => 'bi-check2-square'],
        ['label' => 'Laporan Resmi',        'rute' => null, 'ikon' => 'bi-file-earmark-text'],
    ]],
    'waka' => ['judul' => 'Sarana dan Prasarana', 'item' => [
        ['label' => 'Dashboard Sarpras',    'rute' => 'waka.dashboard', 'ikon' => 'bi-speedometer2'],
        ['label' => 'Antrean Verifikasi',   'rute' => null, 'ikon' => 'bi-inbox'],
        ['label' => 'Inventaris Lab',       'rute' => null, 'ikon' => 'bi-pc-display'],
        ['label' => 'Koleksi Perpustakaan', 'rute' => null, 'ikon' => 'bi-book'],
        ['label' => 'Laporan Sarpras',      'rute' => null, 'ikon' => 'bi-file-earmark-text'],
    ]],
    'lab' => ['judul' => 'Laboratorium Komputer', 'item' => [
        ['label' => 'Dashboard Lab',        'rute' => 'lab.dashboard', 'ikon' => 'bi-speedometer2'],
        ['label' => 'Daftar Aset',          'rute' => null, 'ikon' => 'bi-pc-display'],
        ['label' => 'Master Barang',        'rute' => null, 'ikon' => 'bi-box-seam'],
        ['label' => 'Pemetaan Meja',        'rute' => null, 'ikon' => 'bi-grid-3x3-gap'],
        ['label' => 'Transaksi dan Usulan', 'rute' => null, 'ikon' => 'bi-arrow-left-right'],
        ['label' => 'Stock Opname',         'rute' => null, 'ikon' => 'bi-clipboard-check'],
        ['label' => 'Laporan Lab',          'rute' => null, 'ikon' => 'bi-file-earmark-text'],
    ]],
    'perpus' => ['judul' => 'Perpustakaan', 'item' => [
        ['label' => 'Dashboard Perpustakaan', 'rute' => 'perpus.dashboard', 'ikon' => 'bi-speedometer2'],
        ['label' => 'Katalog Buku',         'rute' => null, 'ikon' => 'bi-book'],
        ['label' => 'Eksemplar',            'rute' => null, 'ikon' => 'bi-upc-scan'],
        ['label' => 'Permintaan Pinjam',    'rute' => null, 'ikon' => 'bi-inbox'],
        ['label' => 'Peminjaman',           'rute' => null, 'ikon' => 'bi-box-arrow-up-right'],
        ['label' => 'Pengembalian',         'rute' => null, 'ikon' => 'bi-box-arrow-in-down-left'],
        ['label' => 'Laporan Sirkulasi',    'rute' => null, 'ikon' => 'bi-file-earmark-text'],
    ]],
    'anggota' => ['judul' => 'Portal Perpustakaan', 'item' => [
        ['label' => 'Beranda',              'rute' => 'anggota.dashboard', 'ikon' => 'bi-house'],
        ['label' => 'Katalog Buku',         'rute' => null, 'ikon' => 'bi-book'],
        ['label' => 'Pinjaman Saya',        'rute' => null, 'ikon' => 'bi-bookmark-check'],
        ['label' => 'Kartu Perpustakaan',   'rute' => null, 'ikon' => 'bi-credit-card-2-front'],
    ]],
];
