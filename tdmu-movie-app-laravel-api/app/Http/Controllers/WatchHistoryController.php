<?php

namespace App\Http\Controllers;

use App\Models\WatchHistory;
use Illuminate\Http\Request;

class WatchHistoryController extends Controller
{
    public function index(Request $request)
    {
        return WatchHistory::where('user_id', $request->user()->id)
            ->with(['movie', 'episode'])
            ->orderBy('updated_at', 'desc')
            ->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
            'episode_id' => ['nullable', 'integer', 'exists:episodes,id'],
            'watched_seconds' => ['required', 'integer', 'min:0'],
            'duration_seconds' => ['required', 'integer', 'min:0'],
            'is_finished' => ['sometimes', 'boolean'],
        ]);

        $watchHistory = WatchHistory::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'movie_id' => $data['movie_id'],
                'episode_id' => $data['episode_id'] ?? null,
            ],
            [
                'watched_seconds' => $data['watched_seconds'],
                'duration_seconds' => $data['duration_seconds'],
                'is_finished' => $data['is_finished'] ?? false,
            ]
        );

        return response()->json($watchHistory, 201);
    }

    public function show(WatchHistory $watchHistory, Request $request)
    {
        if ($watchHistory->user_id !== $request->user()->id) {
            abort(403);
        }
        return $watchHistory->load(['movie', 'episode']);
    }

    public function update(Request $request, WatchHistory $watchHistory)
    {
        if ($watchHistory->user_id !== $request->user()->id) {
            abort(403);
        }

        $data = $request->validate([
            'watched_seconds' => ['sometimes', 'integer', 'min:0'],
            'duration_seconds' => ['sometimes', 'integer', 'min:0'],
            'is_finished' => ['sometimes', 'boolean'],
        ]);

        $watchHistory->update($data);

        return $watchHistory;
    }

    public function destroy(WatchHistory $watchHistory, Request $request)
    {
        if ($watchHistory->user_id !== $request->user()->id) {
            abort(403);
        }
        $watchHistory->delete();

        return response()->noContent();
    }
}
