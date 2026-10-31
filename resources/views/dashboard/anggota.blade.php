@extends('layouts.app')

@section('judul', 'Beranda')
@section('deskripsi', 'Kartu perpustakaan dan pinjaman Anda.')

@section('isi')
<div class="row g-3">
    <div class="col-lg-5">
        @if ($kartu)
            <div class="kartu-anggota">
                <div class="small text-uppercase opacity-75">Kartu Perpustakaan</div>
                <div class="nomor my-2">{{ $kartu->nomor_kartu }}</div>
                <div class="fw-semibold">{{ auth()->user()->nama }}</div>
                <div class="small opacity-75">
                    {{ auth()->user()->peran->nama }}
                    @if ($profil?->nisn) &middot; NISN {{ $profil->nisn }}
                    @elseif ($profil?->nip) &middot; NIP {{ $profil->nip }}
                    @elseif ($profil?->nuptk) &middot; NUPTK {{ $profil->nuptk }}
                    @endif
                </div>
                <div class="mt-3"><span class="lencana lencana-sukses">Status: {{ ucfirst($kartu->status) }}</span></div>
            </div>
        @else
            <div class="kartu">
                <h2 class="h6 fw-bold">Kartu Perpustakaan</h2>
                <x-kosong :pesan="$pesan ?? 'Kartu belum tersedia.'" />
            </div>
        @endif
    </div>

    <div class="col-lg-7">
        <div class="kartu h-100">
            <h2 class="h6 fw-bold mb-3">Pinjaman Aktif</h2>
            @if (count($pinjaman) > 0)
                <div class="table-responsive">
                    <table class="tabel-data table align-middle mb-0">
                        <thead><tr><th>Buku</th><th>Jatuh tempo</th><th>Status</th></tr></thead>
                        <tbody>
                        @foreach ($pinjaman as $p)
                            <tr>
                                <td>{{ $p->judul }}<br><small class="text-secondary">{{ $p->kode_eksemplar }}</small></td>
                                <td>{{ \Illuminate\Support\Carbon::parse($p->jatuh_tempo)->format('d-m-Y') }}</td>
                                <td>
                                    @if ($p->terlambat)
                                        <x-lencana-status jenis="bahaya">Terlambat</x-lencana-status>
                                    @else
                                        <x-lencana-status jenis="info">Dipinjam</x-lencana-status>
                                    @endif
                                </td>
                            </tr>
                        @endforeach
                        </tbody>
                    </table>
                </div>
            @else
                <x-kosong pesan="Anda tidak sedang meminjam buku." />
            @endif
        </div>
    </div>
</div>
@endsection
