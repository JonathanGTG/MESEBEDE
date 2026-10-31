<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;

class Pengguna extends Authenticatable
{
    protected $table = 'pengguna';

    protected $fillable = ['peran_id', 'nama', 'email', 'password', 'aktif'];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'password'       => 'hashed',   // otomatis di-hash saat disimpan
            'aktif'          => 'boolean',
            'login_terakhir' => 'datetime',
        ];
    }

    public function peran(): BelongsTo
    {
        return $this->belongsTo(Peran::class, 'peran_id');
    }

    public function profil(): HasOne
    {
        return $this->hasOne(Profil::class, 'pengguna_id');
    }

    /** Cek apakah pengguna memiliki salah satu peran (berdasarkan kode peran). */
    public function punyaPeran(string ...$kode): bool
    {
        return in_array($this->peran?->kode, $kode, true);
    }
}
