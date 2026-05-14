<?php

namespace App\Http\Controllers;

use App\Models\Movie;
use App\Services\MediaStorageService;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MovieController extends Controller
{
    public function __construct(private readonly MediaStorageService $mediaStorage) {}

    public function index()
    {
        return Movie::query()->orderBy('id')->get();
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
        ]);

        if ($request->hasFile('poster_file')) {
            $data['poster_url'] = $this->mediaStorage->storeUploadedFile($request->file('poster_file'), 'movies/posters');
        }
        if ($request->hasFile('backdrop_file')) {
            $data['backdrop_url'] = $this->mediaStorage->storeUploadedFile($request->file('backdrop_file'), 'movies/backdrops');
        }

        unset($data['poster_file'], $data['backdrop_file']);

        $movie = Movie::create($data);

        return response()->json($movie, 201);
    }

    public function show(Movie $movie)
    {
        return $movie;
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

        unset($data['poster_file'], $data['backdrop_file']);

        $movie->update($data);

        return $movie;
    }

    public function destroy(Movie $movie)
    {
        $this->mediaStorage->deleteByUrl($movie->poster_url);
        $this->mediaStorage->deleteByUrl($movie->backdrop_url);
        $movie->delete();

        return response()->noContent();
    }
}
