@extends('layouts.app')

@section('judul', 'Dashboard Sarpras')
@section('deskripsi', 'Antrean verifikasi dan kondisi fasilitas sekolah.')

@section('isi')
@php $angka = fn ($n) => number_format((int) $n, 0, ',', '.'); @endphp
<div class="row g-3">
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Menunggu Verifikasi" ikon="bi-inbox"
            :nilai="$angka($r->usulan_menunggu_waka)" keterangan="Usulan dari Pengurus Lab" />
    </div>
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Total Aset Lab" ikon="bi-pc-display" :nilai="$angka($r->total_aset)" />
    </div>
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Perlu Perhatian" ikon="bi-exclamation-triangle"
            :nilai="$angka($r->kondisi_rusak_ringan + $r->kondisi_rusak_berat)"
            keterangan="Aset rusak ringan atau rusak berat" />
    </div>
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Judul Buku" ikon="bi-book" :nilai="$angka($r->total_judul)"
            :keterangan="$angka($r->total_eksemplar) . ' eksemplar'" />
    </div>
</div>
@endsection
