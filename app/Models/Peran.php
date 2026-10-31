<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Peran extends Model
{
    protected $table = 'peran';

    protected $fillable = ['kode', 'nama'];

    public function pengguna(): HasMany
    {
        return $this->hasMany(Pengguna::class, 'peran_id');
    }
}
