<?php

use App\Http\Controllers\EpisodeController;
use App\Http\Controllers\GenreController;
use App\Http\Controllers\MovieController;
use App\Http\Controllers\MovieGenreController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\WatchHistoryController;
use App\Http\Controllers\WatchlistController;
use Illuminate\Support\Facades\Route;

Route::apiResource('users', UserController::class);
Route::apiResource('genres', GenreController::class);
Route::apiResource('movies', MovieController::class);
Route::apiResource('episodes', EpisodeController::class);
Route::apiResource('watchlists', WatchlistController::class);
Route::apiResource('watch-history', WatchHistoryController::class)
    ->parameters(['watch-history' => 'watchHistory']);
Route::apiResource('reviews', ReviewController::class);

Route::get('movie-genres', [MovieGenreController::class, 'index']);
Route::post('movie-genres', [MovieGenreController::class, 'store']);
Route::get('movie-genres/{movieId}/{genreId}', [MovieGenreController::class, 'show']);
Route::match(['put', 'patch'], 'movie-genres/{movieId}/{genreId}', [MovieGenreController::class, 'update']);
Route::delete('movie-genres/{movieId}/{genreId}', [MovieGenreController::class, 'destroy']);
