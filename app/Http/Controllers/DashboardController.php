<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class DashboardController extends Controller
{
    /** /dashboard: mengalihkan ke dashboard sesuai peran. */
    public function arahkan(): RedirectResponse
    {
        $rute = match (auth()->user()->peran->kode) {
            'admin'           => 'admin.dashboard',
            'kepala_sekolah'  => 'kepsek.dashboard',
            'waka_sarpras'    => 'waka.dashboard',
            'pengurus_lab'    => 'lab.dashboard',
            'pengurus_perpus' => 'perpus.dashboard',
            default           => 'anggota.dashboard',   // guru dan siswa
        };

        return redirect()->route($rute);
    }

    /** Admin: halaman pemilih modul (Module Switcher). */
    public function admin(): View
    {
        return view('dashboard.admin');
    }

    public function kepsek(): View
    {
        return view('dashboard.kepsek', ['r' => $this->ringkasan()]);
    }

    public function waka(): View
    {
        return view('dashboard.waka', ['r' => $this->ringkasan()]);
    }

    public function lab(): View
    {
        return view('dashboard.lab', [
            'r'           => $this->ringkasan(),
            'asetTerbaru' => DB::select(
                'SELECT kode, barang, kondisi, status, lokasi FROM v_aset_lab ORDER BY id DESC LIMIT 5'
            ),
        ]);
    }

    public function perpus(): View
    {
        $menunggu = DB::selectOne("SELECT count(*)::integer AS n FROM pengajuan WHERE status = 'menunggu'")->n;

        return view('dashboard.perpus', [
            'r'        => $this->ringkasan(),
            'menunggu' => $menunggu,
            'terlambat' => DB::select(
                'SELECT nama_anggota, judul, hari_terlambat FROM v_keterlambatan LIMIT 5'
            ),
        ]);
    }

    /** Guru dan siswa: kartu perpustakaan + pinjaman aktif. */
    public function anggota(): View
    {
        $id    = auth()->id();
        $kartu = null;
        $pesan = null;

        try {
            // Kartu terbit otomatis jika data identitas lengkap (FR-46).
            DB::select('SELECT terbitkan_kartu(CAST(? AS bigint))', [$id]);
            $kartu = DB::selectOne(
                'SELECT nomor_kartu, status, tanggal_terbit FROM anggota WHERE pengguna_id = ?', [$id]
            );
        } catch (QueryException $e) {
            report($e);
            $pesan = 'Kartu perpustakaan belum dapat diterbitkan karena data identitas Anda belum lengkap. Hubungi Admin.';
        }

        return view('dashboard.anggota', [
            'kartu'    => $kartu,
            'pesan'    => $pesan,
            'profil'   => DB::selectOne('SELECT nisn, nip, nuptk, kelas FROM profil WHERE pengguna_id = ?', [$id]),
            'pinjaman' => DB::select(
                'SELECT judul, kode_eksemplar, jatuh_tempo, terlambat FROM v_pinjaman_aktif
                 WHERE anggota_id = (SELECT id FROM anggota WHERE pengguna_id = ?)
                 ORDER BY jatuh_tempo', [$id]
            ),
        ]);
    }

    /** Satu baris ringkasan dari view v_ringkasan_eksekutif. */
    private function ringkasan(): object
    {
        return DB::selectOne('SELECT * FROM v_ringkasan_eksekutif');
    }
}
