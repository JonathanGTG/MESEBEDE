{{-- Pemakaian: <x-lencana-status jenis="sukses">Tersedia</x-lencana-status>
     jenis: sukses | peringatan | bahaya | info | netral. Selalu pakai teks, bukan warna saja. --}}
@props(['jenis' => 'netral'])
<span class="lencana lencana-{{ $jenis }}">{{ $slot }}</span>
