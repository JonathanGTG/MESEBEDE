@props(['judul', 'nilai', 'keterangan' => null, 'ikon' => 'bi-bar-chart'])
<div class="kartu kartu-stat">
    <i class="bi {{ $ikon }} ikon" aria-hidden="true"></i>
    <p class="judul">{{ $judul }}</p>
    <div class="nilai">{{ $nilai }}</div>
    @if ($keterangan) <p class="ket">{{ $keterangan }}</p> @endif
</div>
