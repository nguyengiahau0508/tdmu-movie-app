<?php

namespace App\Http\Controllers;

use App\Models\Genre;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class GenreController extends Controller
{
    public function index()
    {
        return Genre::query()->orderBy('id')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100', 'unique:genres,name'],
            'slug' => ['required', 'string', 'max:120', 'unique:genres,slug'],
        ]);

        $genre = Genre::create($data);

        return response()->json($genre, 201);
    }

    public function show(Genre $genre)
    {
        return $genre;
    }

    public function update(Request $request, Genre $genre)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100', Rule::unique('genres', 'name')->ignore($genre->id)],
            'slug' => ['sometimes', 'required', 'string', 'max:120', Rule::unique('genres', 'slug')->ignore($genre->id)],
        ]);

        $genre->update($data);

        return $genre;
    }

    public function destroy(Genre $genre)
    {
        $genre->delete();

        return response()->noContent();
    }
}
