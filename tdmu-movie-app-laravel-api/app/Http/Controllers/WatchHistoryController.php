<?php

namespace App\Http\Controllers;

use App\Models\WatchHistory;
use Illuminate\Http\Request;

class WatchHistoryController extends Controller
{
    public function index()
    {
        return WatchHistory::query()->orderBy('id')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
            'episode_id' => ['nullable', 'integer', 'exists:episodes,id'],
            'watched_seconds' => ['sometimes', 'integer', 'min:0'],
            'duration_seconds' => ['sometimes', 'integer', 'min:0'],
            'is_finished' => ['sometimes', 'boolean'],
        ]);

        $data['watched_seconds'] = $data['watched_seconds'] ?? 0;
        $data['duration_seconds'] = $data['duration_seconds'] ?? 0;
        $data['is_finished'] = $data['is_finished'] ?? false;

        $exists = WatchHistory::query()
            ->where('user_id', $data['user_id'])
            ->where('movie_id', $data['movie_id'])
            ->where('episode_id', $data['episode_id'] ?? null)
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'Watch history record already exists for this content.',
            ], 422);
        }

        $watchHistory = WatchHistory::create($data);

        return response()->json($watchHistory, 201);
    }

    public function show(WatchHistory $watchHistory)
    {
        return $watchHistory;
    }

    public function update(Request $request, WatchHistory $watchHistory)
    {
        $data = $request->validate([
            'user_id' => ['sometimes', 'required', 'integer', 'exists:users,id'],
            'movie_id' => ['sometimes', 'required', 'integer', 'exists:movies,id'],
            'episode_id' => ['nullable', 'integer', 'exists:episodes,id'],
            'watched_seconds' => ['sometimes', 'integer', 'min:0'],
            'duration_seconds' => ['sometimes', 'integer', 'min:0'],
            'is_finished' => ['sometimes', 'boolean'],
        ]);

        $userId = $data['user_id'] ?? $watchHistory->user_id;
        $movieId = $data['movie_id'] ?? $watchHistory->movie_id;
        $episodeId = array_key_exists('episode_id', $data) ? $data['episode_id'] : $watchHistory->episode_id;

        $exists = WatchHistory::query()
            ->where('user_id', $userId)
            ->where('movie_id', $movieId)
            ->where('episode_id', $episodeId)
            ->where('id', '!=', $watchHistory->id)
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'Watch history record already exists for this content.',
            ], 422);
        }

        $watchHistory->update($data);

        return $watchHistory;
    }

    public function destroy(WatchHistory $watchHistory)
    {
        $watchHistory->delete();

        return response()->noContent();
    }
}
