<?php

namespace App\Http\Controllers;

use App\Models\Watchlist;
use Illuminate\Http\Request;

class WatchlistController extends Controller
{
    public function index(Request $request)
    {
        return Watchlist::where('user_id', $request->user()->id)->with('movie')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
        ]);

        $watchlist = Watchlist::firstOrCreate([
            'user_id' => $request->user()->id,
            'movie_id' => $data['movie_id'],
        ]);

        return response()->json($watchlist, 201);
    }

    public function show(Watchlist $watchlist, Request $request)
    {
        if ($watchlist->user_id !== $request->user()->id) {
            abort(403);
        }
        return $watchlist;
    }

    public function update(Request $request, Watchlist $watchlist)
    {
        if ($watchlist->user_id !== $request->user()->id) {
            abort(403);
        }

        $data = $request->validate([
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
        ]);

        $watchlist->update($data);

        return $watchlist;
    }

    public function destroy(Watchlist $watchlist, Request $request)
    {
        if ($watchlist->user_id !== $request->user()->id) {
            abort(403);
        }
        $watchlist->delete();

        return response()->noContent();
    }
}
