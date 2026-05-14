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
use App\Http\Controllers\PaymentController;
use Illuminate\Support\Facades\Route;

Route::get('media/{path}', function (string $path) {
    if (!\Illuminate\Support\Facades\Storage::disk('public')->exists($path)) {
        abort(404);
    }
    
    $fullPath = \Illuminate\Support\Facades\Storage::disk('public')->path($path);
    $size = filesize($fullPath);
    $mime = mime_content_type($fullPath) ?: 'application/octet-stream';
    
    $headers = [
        'Content-Type' => $mime,
        'Accept-Ranges' => 'bytes',
    ];

    if (request()->hasHeader('Range')) {
        $range = request()->header('Range');
        preg_match('/bytes=(\d+)-(\d*)/', $range, $matches);
        $start = intval($matches[1] ?? 0);
        $end = (isset($matches[2]) && $matches[2] !== '') ? intval($matches[2]) : $size - 1;
        
        $length = $end - $start + 1;
        $headers['Content-Range'] = "bytes $start-$end/$size";
        $headers['Content-Length'] = $length;
        
        return response()->stream(function () use ($fullPath, $start, $end) {
            $stream = fopen($fullPath, 'rb');
            fseek($stream, $start);
            $buffer = 1024 * 8; // 8KB chunks
            $pos = $start;
            while (!feof($stream) && $pos <= $end) {
                $read = min($buffer, $end - $pos + 1);
                echo fread($stream, $read);
                flush();
                $pos += $read;
            }
            fclose($stream);
        }, 206, $headers);
    }

    $headers['Content-Length'] = $size;
    return response()->file($fullPath, $headers);
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
    Route::post('payment/momo/create', [PaymentController::class, 'createPayment']);
});

Route::post('payment/momo/ipn', [PaymentController::class, 'ipn']);

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
