@extends('layouts.dasar')

@section('judul', 'Akses ditolak')

@section('isi')
    <div class="text-center py-5">
        <p class="display-4 fw-bold mb-1" style="color:var(--color-danger)">403</p>
        <h1 class="h4">Akses ditolak</h1>
        <p class="text-secondary">{{ $exception->getMessage() ?: 'Anda tidak memiliki akses ke halaman ini.' }}</p>
        <a href="{{ auth()->check() ? route('dashboard') : route('beranda') }}" class="btn btn-utama">Kembali</a>
    </div>
@endsection
