<?php

namespace App\Http\Controllers;

use App\Models\MovieGenre;
use Illuminate\Http\Request;

class MovieGenreController extends Controller
{
    public function index()
    {
        return MovieGenre::query()->orderBy('movie_id')->orderBy('genre_id')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
            'genre_id' => ['required', 'integer', 'exists:genres,id'],
        ]);

        $exists = MovieGenre::query()
            ->where('movie_id', $data['movie_id'])
            ->where('genre_id', $data['genre_id'])
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The movie-genre relation already exists.',
            ], 422);
        }

        $movieGenre = MovieGenre::create($data);

        return response()->json($movieGenre, 201);
    }

    public function show(int $movieId, int $genreId)
    {
        return MovieGenre::query()
            ->where('movie_id', $movieId)
            ->where('genre_id', $genreId)
            ->firstOrFail();
    }

    public function update(Request $request, int $movieId, int $genreId)
    {
        $pair = MovieGenre::query()
            ->where('movie_id', $movieId)
            ->where('genre_id', $genreId)
            ->firstOrFail();

        $data = $request->validate([
            'movie_id' => ['sometimes', 'required', 'integer', 'exists:movies,id'],
            'genre_id' => ['sometimes', 'required', 'integer', 'exists:genres,id'],
        ]);

        $targetMovieId = $data['movie_id'] ?? $pair->movie_id;
        $targetGenreId = $data['genre_id'] ?? $pair->genre_id;
        $exists = MovieGenre::query()
            ->where('movie_id', $targetMovieId)
            ->where('genre_id', $targetGenreId)
            ->where(function ($query) use ($movieId, $genreId) {
                $query->where('movie_id', '!=', $movieId)
                    ->orWhere('genre_id', '!=', $genreId);
            })
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The movie-genre relation already exists.',
            ], 422);
        }

        if (! empty($data)) {
            MovieGenre::query()
                ->where('movie_id', $movieId)
                ->where('genre_id', $genreId)
                ->update([
                    'movie_id' => $targetMovieId,
                    'genre_id' => $targetGenreId,
                ]);
        }

        return MovieGenre::query()
            ->where('movie_id', $targetMovieId)
            ->where('genre_id', $targetGenreId)
            ->firstOrFail();
    }

    public function destroy(int $movieId, int $genreId)
    {
        MovieGenre::query()
            ->where('movie_id', $movieId)
            ->where('genre_id', $genreId)
            ->firstOrFail();

        MovieGenre::query()
            ->where('movie_id', $movieId)
            ->where('genre_id', $genreId)
            ->delete();

        return response()->noContent();
    }
}
