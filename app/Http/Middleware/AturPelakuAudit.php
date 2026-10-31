<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

/**
 * Memberi tahu PostgreSQL siapa pengguna yang sedang login, supaya trigger
 * audit (trigger_log) dapat mengisi log_aktivitas.pengguna_id.
 * Nilai dibaca trigger lewat current_setting('app.pengguna_id').
 */
class AturPelakuAudit
{
    public function handle(Request $request, Closure $next): Response
    {
        $id = Auth::id();

        if ($id) {
            DB::select("SELECT set_config('app.pengguna_id', ?, false)", [(string) $id]);
        }

        try {
            return $next($request);
        } finally {
            if ($id) {
                DB::select("SELECT set_config('app.pengguna_id', '', false)");
            }
        }
    }
}
