@php
    use Illuminate\Support\Str;
    $namaRute = request()->route()?->getName() ?? '';
    $area     = Str::before($namaRute, '.');
    $menu     = config("menu.$area");
    $adalahAdmin = auth()->user()->punyaPeran('admin');
@endphp
<nav class="sidebar-isi">
    <div class="sidebar-merek">
        SMK Al Razi
        <small>Sinar Harapan</small>
    </div>

    {{-- Admin yang sedang di dalam modul lab/perpus bisa kembali ke pemilih modul --}}
    @if ($adalahAdmin && $area !== 'admin')
        <a href="{{ route('admin.dashboard') }}" class="menu-item"><i class="bi bi-arrow-left"></i> Pilih Modul</a>
    @endif

    @if ($menu)
        <div class="sidebar-judul">{{ $menu['judul'] }}</div>
        @foreach ($menu['item'] as $item)
            @if ($item['rute'])
                <a href="{{ route($item['rute']) }}"
                   class="menu-item {{ request()->routeIs($item['rute']) ? 'aktif' : '' }}"
                   @if (request()->routeIs($item['rute'])) aria-current="page" @endif>
                    <i class="bi {{ $item['ikon'] }}"></i> {{ $item['label'] }}
                </a>
            @else
                <span class="menu-item nonaktif" aria-disabled="true">
                    <i class="bi {{ $item['ikon'] }}"></i> {{ $item['label'] }}
                    <span class="segera">Segera</span>
                </span>
            @endif
        @endforeach
    @endif

    <div class="sidebar-bawah">
        <form method="POST" action="{{ route('logout') }}">
            @csrf
            <button class="menu-item w-100 border-0 bg-transparent text-start"><i class="bi bi-box-arrow-left"></i> Keluar</button>
        </form>
    </div>
</nav>
