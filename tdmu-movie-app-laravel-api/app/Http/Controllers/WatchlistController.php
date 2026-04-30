<?php

namespace App\Http\Controllers;

use App\Models\Watchlist;
use Illuminate\Http\Request;

class WatchlistController extends Controller
{
    public function index()
    {
        return Watchlist::query()->orderBy('id')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
        ]);

        $exists = Watchlist::query()
            ->where('user_id', $data['user_id'])
            ->where('movie_id', $data['movie_id'])
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The movie is already in the user watchlist.',
            ], 422);
        }

        $watchlist = Watchlist::create($data);

        return response()->json($watchlist, 201);
    }

    public function show(Watchlist $watchlist)
    {
        return $watchlist;
    }

    public function update(Request $request, Watchlist $watchlist)
    {
        $data = $request->validate([
            'user_id' => ['sometimes', 'required', 'integer', 'exists:users,id'],
            'movie_id' => ['sometimes', 'required', 'integer', 'exists:movies,id'],
        ]);

        $userId = $data['user_id'] ?? $watchlist->user_id;
        $movieId = $data['movie_id'] ?? $watchlist->movie_id;

        $exists = Watchlist::query()
            ->where('user_id', $userId)
            ->where('movie_id', $movieId)
            ->where('id', '!=', $watchlist->id)
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The movie is already in the user watchlist.',
            ], 422);
        }

        $watchlist->update($data);

        return $watchlist;
    }

    public function destroy(Watchlist $watchlist)
    {
        $watchlist->delete();

        return response()->noContent();
    }
}
