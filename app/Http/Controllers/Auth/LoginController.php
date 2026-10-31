<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\Pengguna;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class LoginController extends Controller
{
    public function tampil(): View
    {
        return view('auth.login');
    }

    public function proses(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ], [
            'email.required'    => 'Email wajib diisi.',
            'email.email'       => 'Format email tidak valid.',
            'password.required' => 'Password wajib diisi.',
        ]);

        // 'aktif' => true membuat akun nonaktif gagal login. Pesan galatnya
        // sengaja sama dengan password salah agar tidak membocorkan info akun.
        $kredensial = [
            'email'    => mb_strtolower($data['email']),
            'password' => $data['password'],
            'aktif'    => true,
        ];

        if (! Auth::attempt($kredensial, $request->boolean('ingat'))) {
            return back()
                ->withInput($request->only('email'))
                ->withErrors(['email' => 'Email atau password salah, atau akun tidak aktif.']);
        }

        $request->session()->regenerate();   // cegah session fixation

        Pengguna::whereKey(Auth::id())->update(['login_terakhir' => now()]);

        return redirect()->intended(route('dashboard'));
    }

    public function keluar(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('beranda');
    }
}
