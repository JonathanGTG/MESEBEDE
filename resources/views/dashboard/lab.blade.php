@extends('layouts.app')

@section('judul', 'Dashboard Laboratorium')
@section('deskripsi', 'Ringkasan inventaris laboratorium komputer.')

@section('isi')
@php $angka = fn ($n) => number_format((int) $n, 0, ',', '.'); @endphp
<div class="row g-3 mb-4">
    <div class="col-6 col-xl-2"><x-kartu-statistik judul="Total Unit" ikon="bi-pc-display" :nilai="$angka($r->total_aset)" /></div>
    <div class="col-6 col-xl-2"><x-kartu-statistik judul="Unit Baru" ikon="bi-stars" :nilai="$angka($r->unit_baru)" /></div>
    <div class="col-6 col-xl-2"><x-kartu-statistik judul="Unit Lama" ikon="bi-clock-history" :nilai="$angka($r->unit_lama)" /></div>
    <div class="col-6 col-xl-2"><x-kartu-statistik judul="Kondisi Baik" ikon="bi-check-circle" :nilai="$angka($r->kondisi_baik)" /></div>
    <div class="col-6 col-xl-2"><x-kartu-statistik judul="Rusak Ringan" ikon="bi-exclamation-circle" :nilai="$angka($r->kondisi_rusak_ringan)" /></div>
    <div class="col-6 col-xl-2"><x-kartu-statistik judul="Rusak Berat" ikon="bi-x-circle" :nilai="$angka($r->kondisi_rusak_berat)" /></div>
</div>

<div class="kartu">
    <h2 class="h6 fw-bold mb-3">Aset Terbaru</h2>
    @if (count($asetTerbaru) > 0)
        <div class="table-responsive">
            <table class="tabel-data table align-middle mb-0">
                <thead><tr><th>Kode</th><th>Barang</th><th>Lokasi</th><th>Kondisi</th><th>Status</th></tr></thead>
                <tbody>
                @foreach ($asetTerbaru as $a)
                    <tr>
                        <td>{{ $a->kode }}</td>
                        <td>{{ $a->barang }}</td>
                        <td>{{ $a->lokasi ?? '-' }}</td>
                        <td>
                            <x-lencana-status :jenis="['baik' => 'sukses', 'rusak_ringan' => 'peringatan', 'rusak_berat' => 'bahaya'][$a->kondisi] ?? 'netral'">
                                {{ str_replace('_', ' ', ucfirst($a->kondisi)) }}
                            </x-lencana-status>
                        </td>
                        <td>{{ str_replace('_', ' ', ucfirst($a->status)) }}</td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
    @else
        <x-kosong pesan="Belum ada aset. Tambah aset akan tersedia di fase berikutnya." />
    @endif
</div>
@endsection
