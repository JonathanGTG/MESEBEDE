<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('judul', 'Dashboard') | SMK Al Razi</title>
    {{-- Bootstrap lewat CDN. Untuk demo tanpa internet, unduh dan simpan di public/vendor. --}}
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="{{ asset('css/app-theme.css') }}" rel="stylesheet">
</head>
<body>
<div class="app-shell">
    {{-- Sidebar desktop --}}
    <aside class="sidebar-desktop d-none d-lg-block" aria-label="Menu utama">
        @include('partials.sidebar')
    </aside>

    {{-- Sidebar mobile (drawer) --}}
    <div class="offcanvas offcanvas-start d-lg-none" tabindex="-1" id="menuMobil" aria-label="Menu utama">
        <div class="offcanvas-header pb-0">
            <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Tutup menu"></button>
        </div>
        <div class="offcanvas-body p-0">
            @include('partials.sidebar')
        </div>
    </div>

    <div class="app-main">
        @include('partials.topbar')
        <main class="app-content">
            <div class="halaman-kepala">
                <h1>@yield('judul')</h1>
                @hasSection('deskripsi') <p>@yield('deskripsi')</p> @endif
            </div>
            @yield('isi')
        </main>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
