<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Profil extends Model
{
    protected $table = 'profil';

    // Kunci utama tabel profil adalah pengguna_id (bukan id)
    protected $primaryKey = 'pengguna_id';
    public $incrementing = false;

    protected $fillable = [
        'pengguna_id', 'npm', 'nisn', 'nis', 'nip', 'nuptk',
        'telepon', 'kelas', 'jurusan', 'alamat',
    ];

    public function pengguna(): BelongsTo
    {
        return $this->belongsTo(Pengguna::class, 'pengguna_id');
    }
}
