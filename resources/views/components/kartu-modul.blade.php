@props(['judul', 'deskripsi', 'ikon' => 'bi-grid', 'rute' => null, 'label' => 'Buka Modul'])
<div class="kartu kartu-modul">
    <i class="bi {{ $ikon }} ikon" aria-hidden="true"></i>
    <h2>{{ $judul }}</h2>
    <p>{{ $deskripsi }}</p>
    <div class="aksi">
        @if ($rute)
            <a href="{{ route($rute) }}" class="btn btn-utama">{{ $label }}</a>
        @else
            <span class="lencana lencana-netral">Segera hadir</span>
        @endif
    </div>
</div>
