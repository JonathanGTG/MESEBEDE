@extends('layouts.dasar')

@section('judul', 'Masuk')

@section('isi')
<div class="row justify-content-center">
    <div class="col-md-5 col-lg-4">
        <div class="card border shadow-sm">
            <div class="card-body p-4">
                <h1 class="h4 mb-1">Masuk</h1>
                <p class="text-secondary small mb-4">Gunakan akun yang diberikan Admin.</p>

                <form method="POST" action="{{ route('login') }}" novalidate>
                    @csrf
                    <div class="mb-3">
                        <label for="email" class="form-label">Email</label>
                        <input type="email" id="email" name="email" value="{{ old('email') }}"
                               class="form-control @error('email') is-invalid @enderror" autofocus required>
                        @error('email') <div class="invalid-feedback">{{ $message }}</div> @enderror
                    </div>
                    <div class="mb-3">
                        <label for="password" class="form-label">Password</label>
                        <input type="password" id="password" name="password"
                               class="form-control @error('password') is-invalid @enderror" required>
                        @error('password') <div class="invalid-feedback">{{ $message }}</div> @enderror
                    </div>
                    <div class="form-check mb-3">
                        <input class="form-check-input" type="checkbox" id="ingat" name="ingat" value="1">
                        <label class="form-check-label" for="ingat">Ingat saya</label>
                    </div>
                    <button class="btn w-100 text-white" style="background:#365B43">Masuk</button>
                </form>
            </div>
        </div>
    </div>
</div>
@endsection
