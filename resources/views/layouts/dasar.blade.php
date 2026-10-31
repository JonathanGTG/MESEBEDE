<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('judul', 'Sistem Terpadu SMK Al Razi')</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="{{ asset('css/app-theme.css') }}" rel="stylesheet">
</head>
<body>
<nav class="navbar bg-white border-bottom">
    <div class="container">
        <a class="navbar-brand fw-semibold" style="color:var(--color-primary)" href="{{ route('beranda') }}">SMK Al Razi Sinar Harapan</a>
        @auth
            <form method="POST" action="{{ route('logout') }}" class="m-0">
                @csrf
                <button class="btn btn-outline-secondary btn-sm">Keluar</button>
            </form>
        @endauth
    </div>
</nav>
<main class="container py-5">
    @yield('isi')
</main>
</body>
</html>
