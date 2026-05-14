<?php

namespace App\Http\Controllers;

use App\Models\Movie;
use App\Services\MediaStorageService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MovieController extends Controller
{
    public function __construct(private readonly MediaStorageService $mediaStorage) {}

    public function index(Request $request)
    {
        $query = Movie::query();

        // Admin might want to see all, but users should only see published ones
        // For simplicity in this MVP, we can just show published to everyone on public index
        if (!$request->user() || $request->user()->role !== 'admin') {
            $query->where('is_published', true);
        }

        if ($request->filled('q')) {
            $query->where(function ($q) use ($request) {
                $q->where('title', 'like', '%' . $request->input('q') . '%')
                  ->orWhere('description', 'like', '%' . $request->input('q') . '%');
            });
        }

        if ($request->filled('genre')) {
            $query->whereHas('genres', function ($q) use ($request) {
                $genre = $request->input('genre');
                if (is_numeric($genre)) {
                    $q->where('genres.id', $genre);
                } else {
                    $q->where('genres.slug', $genre);
                }
            });
        }

        if ($request->filled('type')) {
            $query->where('type', $request->input('type'));
        }

        if ($request->filled('unwatched') && $request->boolean('unwatched') && $request->user()) {
            $query->whereDoesntHave('watchHistories', function ($q) use ($request) {
                $q->where('user_id', $request->user()->id);
            });
        }

        if ($request->filled('sort')) {
            if ($request->input('sort') === 'rating_desc') {
                $query->orderBy('rating_avg', 'desc');
            } elseif ($request->input('sort') === 'newest') {
                $query->orderBy('id', 'desc');
            }
        } else {
            $query->orderBy('id', 'desc');
        }

        return $query->with('genres')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:255', 'unique:movies,slug'],
            'description' => ['nullable', 'string'],
            'poster_url' => ['nullable', 'string', 'max:255'],
            'backdrop_url' => ['nullable', 'string', 'max:255'],
            'poster_file' => ['nullable', 'file', 'image', 'max:10240'],
            'backdrop_file' => ['nullable', 'file', 'image', 'max:10240'],
            'release_year' => ['nullable', 'integer'],
            'country' => ['nullable', 'string', 'max:100'],
            'duration' => ['nullable', 'integer', 'min:0'],
            'type' => ['sometimes', Rule::in(['single', 'series'])],
            'rating_avg' => ['sometimes', 'numeric', 'between:0,10'],
            'rating_count' => ['sometimes', 'integer', 'min:0'],
            'is_published' => ['sometimes', 'boolean'],
            'genres' => ['sometimes', 'array'],
            'genres.*' => ['integer', 'exists:genres,id'],
        ]);

        if ($request->hasFile('poster_file')) {
            $data['poster_url'] = $this->mediaStorage->storeUploadedFile($request->file('poster_file'), 'movies/posters');
        }
        if ($request->hasFile('backdrop_file')) {
            $data['backdrop_url'] = $this->mediaStorage->storeUploadedFile($request->file('backdrop_file'), 'movies/backdrops');
        }

        $genres = $data['genres'] ?? [];
        unset($data['poster_file'], $data['backdrop_file'], $data['genres']);

        $movie = Movie::create($data);
        $movie->genres()->sync($genres);

        return response()->json($movie->load('genres'), 201);
    }

    public function show(Movie $movie)
    {
        return $movie->load('genres');
    }

    public function update(Request $request, Movie $movie)
    {
        $data = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'slug' => ['sometimes', 'required', 'string', 'max:255', Rule::unique('movies', 'slug')->ignore($movie->id)],
            'description' => ['nullable', 'string'],
            'poster_url' => ['nullable', 'string', 'max:255'],
            'backdrop_url' => ['nullable', 'string', 'max:255'],
            'poster_file' => ['nullable', 'file', 'image', 'max:10240'],
            'backdrop_file' => ['nullable', 'file', 'image', 'max:10240'],
            'release_year' => ['nullable', 'integer'],
            'country' => ['nullable', 'string', 'max:100'],
            'duration' => ['nullable', 'integer', 'min:0'],
            'type' => ['sometimes', Rule::in(['single', 'series'])],
            'rating_avg' => ['sometimes', 'numeric', 'between:0,10'],
            'rating_count' => ['sometimes', 'integer', 'min:0'],
            'is_published' => ['sometimes', 'boolean'],
            'genres' => ['sometimes', 'array'],
            'genres.*' => ['integer', 'exists:genres,id'],
        ]);

        if ($request->hasFile('poster_file')) {
            $data['poster_url'] = $this->mediaStorage->replaceUploadedFile(
                $movie->poster_url,
                $request->file('poster_file'),
                'movies/posters'
            );
        }
        if ($request->hasFile('backdrop_file')) {
            $data['backdrop_url'] = $this->mediaStorage->replaceUploadedFile(
                $movie->backdrop_url,
                $request->file('backdrop_file'),
                'movies/backdrops'
            );
        }

        if ($request->has('genres')) {
            $movie->genres()->sync($request->input('genres'));
        }

        unset($data['poster_file'], $data['backdrop_file'], $data['genres']);

        $movie->update($data);

        return $movie->load('genres');
    }

    public function destroy(Movie $movie)
    {
        $this->mediaStorage->deleteByUrl($movie->poster_url);
        $this->mediaStorage->deleteByUrl($movie->backdrop_url);
        $movie->delete();

        return response()->noContent();
    }
}
