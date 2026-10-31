@extends('layouts.dasar')

@section('judul', 'Beranda')

@section('isi')
    <p class="text-uppercase small fw-semibold mb-2" style="color:#618A48">Sistem Layanan Sekolah</p>
    <h1 class="fw-bold mb-3">Satu Sistem untuk Lab Komputer dan Perpustakaan</h1>
    <p class="text-secondary mb-4" style="max-width:40rem">
        Kelola inventaris laboratorium dan layanan perpustakaan SMK Al Razi Sinar Harapan dalam satu aplikasi.
    </p>
    <a href="{{ route('login') }}" class="btn btn-lg text-white" style="background:#365B43">Masuk ke Sistem</a>
@endsection
