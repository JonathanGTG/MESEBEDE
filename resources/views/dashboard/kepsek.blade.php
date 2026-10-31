@extends('layouts.app')

@section('judul', 'Dashboard Eksekutif')
@section('deskripsi', 'Ringkasan laboratorium dan perpustakaan. Semua angka dihitung langsung dari database.')

@section('isi')
@php
    $angka = fn ($n) => number_format((int) $n, 0, ',', '.');
    $total = max(1, (int) $r->total_aset);
@endphp

@if ($r->total_aset == 0 && $r->total_judul == 0)
    <div class="kartu mb-4"><x-kosong pesan="Belum ada data untuk periode ini. Angka muncul setelah aset lab dan buku dicatat." /></div>
@endif

<div class="row g-3 mb-4">
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Total Aset Lab" ikon="bi-pc-display"
            :nilai="$angka($r->total_aset)" keterangan="Tidak termasuk aset afkir" />
    </div>
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Unit Baru : Lama" ikon="bi-bar-chart-steps"
            :nilai="$r->unit_baru . ' : ' . $r->unit_lama" keterangan="Rasio unit baru terhadap unit lama" />
    </div>
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Nilai Aset Tercatat" ikon="bi-cash-stack"
            :nilai="$r->total_nilai_tercatat !== null ? 'Rp ' . $angka($r->total_nilai_tercatat) : 'Belum ada'"
            :keterangan="$r->aset_tanpa_nilai . ' aset belum memiliki nilai perolehan'" />
    </div>
    <div class="col-sm-6 col-xl-3">
        <x-kartu-statistik judul="Menunggu Persetujuan Akhir" ikon="bi-hourglass-split"
            :nilai="$angka($r->usulan_menunggu_kepsek)" keterangan="Usulan yang sudah diverifikasi Waka" />
    </div>
</div>

<div class="row g-3">
    <div class="col-lg-7">
        <div class="kartu h-100">
            <h2 class="h6 fw-bold">Kondisi Aset Lab</h2>
            @if ($r->total_aset > 0)
                <div class="kondisi-bar my-3" role="img" aria-label="Perbandingan kondisi aset">
                    <span class="baik"   style="width: {{ $r->kondisi_baik / $total * 100 }}%"></span>
                    <span class="ringan" style="width: {{ $r->kondisi_rusak_ringan / $total * 100 }}%"></span>
                    <span class="berat"  style="width: {{ $r->kondisi_rusak_berat / $total * 100 }}%"></span>
                </div>
                <div class="d-flex flex-wrap gap-2">
                    <x-lencana-status jenis="sukses">Baik: {{ $r->kondisi_baik }}</x-lencana-status>
                    <x-lencana-status jenis="peringatan">Rusak ringan: {{ $r->kondisi_rusak_ringan }}</x-lencana-status>
                    <x-lencana-status jenis="bahaya">Rusak berat: {{ $r->kondisi_rusak_berat }}</x-lencana-status>
                </div>
            @else
                <x-kosong pesan="Belum ada aset tercatat." />
            @endif
        </div>
    </div>
    <div class="col-lg-5">
        <div class="kartu h-100">
            <h2 class="h6 fw-bold">Perpustakaan</h2>
            <dl class="row mb-0">
                <dt class="col-7 fw-normal text-secondary">Judul buku</dt><dd class="col-5 text-end fw-semibold">{{ $angka($r->total_judul) }}</dd>
                <dt class="col-7 fw-normal text-secondary">Eksemplar</dt><dd class="col-5 text-end fw-semibold">{{ $angka($r->total_eksemplar) }}</dd>
                <dt class="col-7 fw-normal text-secondary">Pinjaman aktif</dt><dd class="col-5 text-end fw-semibold">{{ $angka($r->pinjaman_aktif) }}</dd>
                <dt class="col-7 fw-normal text-secondary">Terlambat</dt><dd class="col-5 text-end fw-semibold">{{ $angka($r->pinjaman_terlambat) }}</dd>
            </dl>
        </div>
    </div>
</div>
@endsection
