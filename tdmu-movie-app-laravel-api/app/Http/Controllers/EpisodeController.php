<?php

namespace App\Http\Controllers;

use App\Models\Episode;
use Illuminate\Http\Request;

class EpisodeController extends Controller
{
    public function index()
    {
        return Episode::query()->orderBy('id')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
            'season_number' => ['sometimes', 'integer', 'min:1'],
            'episode_number' => ['required', 'integer', 'min:1'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'duration' => ['nullable', 'integer', 'min:0'],
            'video_url' => ['required', 'string', 'max:500'],
            'thumbnail_url' => ['nullable', 'string', 'max:500'],
        ]);

        $data['season_number'] = $data['season_number'] ?? 1;

        $exists = Episode::query()
            ->where('movie_id', $data['movie_id'])
            ->where('season_number', $data['season_number'])
            ->where('episode_number', $data['episode_number'])
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The episode order already exists for this movie.',
            ], 422);
        }

        $episode = Episode::create($data);

        return response()->json($episode, 201);
    }

    public function show(Episode $episode)
    {
        return $episode;
    }

    public function update(Request $request, Episode $episode)
    {
        $data = $request->validate([
            'movie_id' => ['sometimes', 'required', 'integer', 'exists:movies,id'],
            'season_number' => ['sometimes', 'integer', 'min:1'],
            'episode_number' => ['sometimes', 'required', 'integer', 'min:1'],
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'duration' => ['nullable', 'integer', 'min:0'],
            'video_url' => ['sometimes', 'required', 'string', 'max:500'],
            'thumbnail_url' => ['nullable', 'string', 'max:500'],
        ]);

        $movieId = $data['movie_id'] ?? $episode->movie_id;
        $seasonNumber = $data['season_number'] ?? $episode->season_number;
        $episodeNumber = $data['episode_number'] ?? $episode->episode_number;

        $exists = Episode::query()
            ->where('movie_id', $movieId)
            ->where('season_number', $seasonNumber)
            ->where('episode_number', $episodeNumber)
            ->where('id', '!=', $episode->id)
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The episode order already exists for this movie.',
            ], 422);
        }

        $episode->update($data);

        return $episode;
    }

    public function destroy(Episode $episode)
    {
        $episode->delete();

        return response()->noContent();
    }
}
