<?php

use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\DashboardController;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

// Halaman welcome. Pengguna yang sudah login langsung ke dashboard.
Route::get('/', fn () => Auth::check() ? redirect()->route('dashboard') : view('welcome'))
    ->name('beranda');

// Hanya untuk yang belum login
Route::middleware('guest')->group(function () {
    Route::get('/login', [LoginController::class, 'tampil'])->name('login');
    Route::post('/login', [LoginController::class, 'proses'])->middleware('throttle:5,1');
});

// Hanya untuk yang sudah login
Route::middleware('auth')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'arahkan'])->name('dashboard');
    Route::post('/logout', [LoginController::class, 'keluar'])->name('logout');

    // Nama rute memakai awalan area (admin., lab., dst.); sidebar membacanya.
    Route::middleware('peran:admin')->prefix('admin')->name('admin.')->group(function () {
        Route::get('/', [DashboardController::class, 'admin'])->name('dashboard');
    });

    Route::middleware('peran:kepala_sekolah')->prefix('kepsek')->name('kepsek.')->group(function () {
        Route::get('/', [DashboardController::class, 'kepsek'])->name('dashboard');
    });

    Route::middleware('peran:waka_sarpras')->prefix('waka')->name('waka.')->group(function () {
        Route::get('/', [DashboardController::class, 'waka'])->name('dashboard');
    });

    // Admin boleh membuka modul lab dan perpustakaan lewat Module Switcher
    Route::middleware('peran:pengurus_lab,admin')->prefix('lab')->name('lab.')->group(function () {
        Route::get('/', [DashboardController::class, 'lab'])->name('dashboard');
    });

    Route::middleware('peran:pengurus_perpus,admin')->prefix('perpus')->name('perpus.')->group(function () {
        Route::get('/', [DashboardController::class, 'perpus'])->name('dashboard');
    });

    Route::middleware('peran:guru,siswa')->prefix('anggota')->name('anggota.')->group(function () {
        Route::get('/', [DashboardController::class, 'anggota'])->name('dashboard');
    });
});
