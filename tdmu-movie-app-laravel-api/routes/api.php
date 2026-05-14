<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\EpisodeController;
use App\Http\Controllers\GenreController;
use App\Http\Controllers\MovieController;
use App\Http\Controllers\MovieGenreController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\WatchHistoryController;
use App\Http\Controllers\WatchlistController;
use Illuminate\Support\Facades\Route;

Route::get('media/{path}', function (string $path) {
    if (!\Illuminate\Support\Facades\Storage::disk('public')->exists($path)) {
        abort(404);
    }
    return \Illuminate\Support\Facades\Storage::disk('public')->response($path);
})->where('path', '.*');

Route::prefix('auth')->group(function (): void {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);

    Route::middleware('auth.jwt')->group(function (): void {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('logout', [AuthController::class, 'logout']);
    });
});

Route::middleware('auth.jwt')->group(function (): void {
    Route::apiResource('watchlists', WatchlistController::class);
    Route::apiResource('watch-history', WatchHistoryController::class)
        ->parameters(['watch-history' => 'watchHistory']);
    Route::apiResource('reviews', ReviewController::class)->except(['index', 'show']);
});

Route::apiResource('users', UserController::class);
Route::apiResource('genres', GenreController::class)->only(['index', 'show']);
Route::apiResource('movies', MovieController::class)->only(['index', 'show']);
Route::apiResource('episodes', EpisodeController::class)->only(['index', 'show']);
Route::apiResource('reviews', ReviewController::class)->only(['index', 'show']);

Route::middleware(['auth.jwt', 'admin'])->prefix('admin')->group(function (): void {
    Route::apiResource('genres', GenreController::class)->except(['index', 'show']);
    Route::apiResource('movies', MovieController::class)->except(['index', 'show']);
    Route::apiResource('episodes', EpisodeController::class)->except(['index', 'show']);
});

Route::get('movie-genres', [MovieGenreController::class, 'index']);
Route::post('movie-genres', [MovieGenreController::class, 'store']);
Route::get('movie-genres/{movieId}/{genreId}', [MovieGenreController::class, 'show']);
Route::match(['put', 'patch'], 'movie-genres/{movieId}/{genreId}', [MovieGenreController::class, 'update']);
Route::delete('movie-genres/{movieId}/{genreId}', [MovieGenreController::class, 'destroy']);
