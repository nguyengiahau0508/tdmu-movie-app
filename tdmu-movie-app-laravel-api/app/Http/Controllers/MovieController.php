<?php

namespace App\Http\Controllers;

use App\Models\Movie;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MovieController extends Controller
{
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
            'release_year' => ['nullable', 'integer'],
            'country' => ['nullable', 'string', 'max:100'],
            'duration' => ['nullable', 'integer', 'min:0'],
            'type' => ['sometimes', Rule::in(['single', 'series'])],
            'rating_avg' => ['sometimes', 'numeric', 'between:0,10'],
            'rating_count' => ['sometimes', 'integer', 'min:0'],
            'is_published' => ['sometimes', 'boolean'],
        ]);

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
            'release_year' => ['nullable', 'integer'],
            'country' => ['nullable', 'string', 'max:100'],
            'duration' => ['nullable', 'integer', 'min:0'],
            'type' => ['sometimes', Rule::in(['single', 'series'])],
            'rating_avg' => ['sometimes', 'numeric', 'between:0,10'],
            'rating_count' => ['sometimes', 'integer', 'min:0'],
            'is_published' => ['sometimes', 'boolean'],
        ]);

        $movie->update($data);

        return $movie;
    }

    public function destroy(Movie $movie)
    {
        $movie->delete();

        return response()->noContent();
    }
}
