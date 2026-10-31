<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Pemakaian di route:  ->middleware('peran:admin,pengurus_lab')
 * Dicek di backend pada setiap request; menyembunyikan menu saja tidak cukup.
 */
class PastikanPeran
{
    public function handle(Request $request, Closure $next, string ...$kode): Response
    {
        $pengguna = $request->user();

        // Akun dinonaktifkan Admin saat sesi masih berjalan: langsung dikeluarkan.
        if (! $pengguna || ! $pengguna->aktif) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('login')
                ->withErrors(['email' => 'Sesi berakhir atau akun tidak aktif.']);
        }

        if (! $pengguna->punyaPeran(...$kode)) {
            abort(403, 'Anda tidak memiliki akses ke halaman ini.');
        }

        return $next($request);
    }
}
