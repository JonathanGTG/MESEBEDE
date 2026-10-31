<header class="topbar">
    <button class="btn btn-outline-secondary d-lg-none" type="button"
            data-bs-toggle="offcanvas" data-bs-target="#menuMobil" aria-label="Buka menu">
        <i class="bi bi-list"></i>
    </button>
    <div class="pengguna">
        <strong>{{ auth()->user()->nama }}</strong><br>
        <small>{{ auth()->user()->peran->nama }}</small>
    </div>
</header>
