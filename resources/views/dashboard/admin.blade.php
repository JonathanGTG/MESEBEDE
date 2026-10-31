@extends('layouts.app')

@section('judul', 'Pilih Modul')
@section('deskripsi', 'Halo, ' . auth()->user()->nama . '. Pilih modul yang ingin dikelola.')

@section('isi')
<div class="row g-3">
    <div class="col-md-6 col-xl-3">
        <x-kartu-modul judul="Modul Laboratorium" ikon="bi-pc-display"
            deskripsi="Inventaris aset, lokasi meja PC-01 sampai PC-30, dan usulan pengadaan."
            rute="lab.dashboard" />
    </div>
    <div class="col-md-6 col-xl-3">
        <x-kartu-modul judul="Modul Perpustakaan" ikon="bi-book"
            deskripsi="Katalog buku, eksemplar, peminjaman, dan pengembalian."
            rute="perpus.dashboard" />
    </div>
    <div class="col-md-6 col-xl-3">
        <x-kartu-modul judul="Kelola Pengguna" ikon="bi-people"
            deskripsi="Akun, peran, dan status keaktifan pengguna." />
    </div>
    <div class="col-md-6 col-xl-3">
        <x-kartu-modul judul="Laporan Terpadu" ikon="bi-file-earmark-text"
            deskripsi="Ringkasan laporan laboratorium dan perpustakaan." />
    </div>
</div>
@endsection
