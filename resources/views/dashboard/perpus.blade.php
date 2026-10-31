@extends('layouts.app')

@section('judul', 'Dashboard Perpustakaan')
@section('deskripsi', 'Ringkasan koleksi dan sirkulasi perpustakaan.')

@section('isi')
@php $angka = fn ($n) => number_format((int) $n, 0, ',', '.'); @endphp
<div class="row g-3 mb-4">
    <div class="col-6 col-xl-3"><x-kartu-statistik judul="Judul Buku" ikon="bi-book" :nilai="$angka($r->total_judul)" /></div>
    <div class="col-6 col-xl-3"><x-kartu-statistik judul="Eksemplar" ikon="bi-upc-scan" :nilai="$angka($r->total_eksemplar)" /></div>
    <div class="col-6 col-xl-3"><x-kartu-statistik judul="Sedang Dipinjam" ikon="bi-box-arrow-up-right" :nilai="$angka($r->pinjaman_aktif)" /></div>
    <div class="col-6 col-xl-3"><x-kartu-statistik judul="Permintaan Menunggu" ikon="bi-inbox" :nilai="$angka($menunggu)" /></div>
</div>

<div class="kartu">
    <h2 class="h6 fw-bold mb-3">Pinjaman Terlambat ({{ $angka($r->pinjaman_terlambat) }})</h2>
    @if (count($terlambat) > 0)
        <div class="table-responsive">
            <table class="tabel-data table align-middle mb-0">
                <thead><tr><th>Anggota</th><th>Buku</th><th>Keterlambatan</th></tr></thead>
                <tbody>
                @foreach ($terlambat as $t)
                    <tr>
                        <td>{{ $t->nama_anggota }}</td>
                        <td>{{ $t->judul }}</td>
                        <td><x-lencana-status jenis="bahaya">Terlambat {{ $t->hari_terlambat }} hari</x-lencana-status></td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
    @else
        <x-kosong pesan="Tidak ada pinjaman yang terlambat." />
    @endif
</div>
@endsection
