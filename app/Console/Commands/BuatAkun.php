<?php

namespace App\Console\Commands;

use App\Models\Pengguna;
use App\Models\Peran;
use Illuminate\Console\Command;

class BuatAkun extends Command
{
    protected $signature = 'akun:buat {email : Email akun} {peran : Kode peran} {--nama= : Nama lengkap}';

    protected $description = 'Membuat akun pengguna. Password diminta lewat prompt (tidak muncul di layar/riwayat).';

    public function handle(): int
    {
        $email = mb_strtolower(trim($this->argument('email')));

        if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->error('Format email tidak valid.');
            return self::FAILURE;
        }

        if (Pengguna::whereRaw('lower(email) = ?', [$email])->exists()) {
            $this->error("Email {$email} sudah terdaftar.");
            return self::FAILURE;
        }

        $peran = Peran::where('kode', $this->argument('peran'))->first();
        if (! $peran) {
            $this->error('Peran tidak dikenal. Pilihan: ' . Peran::pluck('kode')->implode(', '));
            return self::FAILURE;
        }

        $password = (string) $this->secret('Password (minimal 8 karakter)');
        $ulangi   = (string) $this->secret('Ulangi password');

        if (strlen($password) < 8 || $password !== $ulangi) {
            $this->error('Password kurang dari 8 karakter atau konfirmasi tidak sama.');
            return self::FAILURE;
        }

        Pengguna::create([
            'peran_id' => $peran->id,
            'nama'     => $this->option('nama') ?: $peran->nama,
            'email'    => $email,
            'password' => $password,   // di-hash otomatis oleh cast 'hashed'
            'aktif'    => true,
        ]);

        $this->info("Akun {$email} ({$peran->kode}) berhasil dibuat.");
        return self::SUCCESS;
    }
}
