<?php

namespace App\Http\Controllers;

use App\Models\Episode;
use App\Services\MediaStorageService;
use Illuminate\Http\Request;

class EpisodeController extends Controller
{
    public function __construct(private readonly MediaStorageService $mediaStorage) {}

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
            'video_url' => ['required_without:video_file', 'string', 'max:500'],
            'thumbnail_url' => ['nullable', 'string', 'max:500'],
            'video_file' => ['required_without:video_url', 'file', 'mimes:mp4,mov,mkv,webm', 'max:512000'],
            'thumbnail_file' => ['nullable', 'file', 'image', 'max:10240'],
        ]);

        $data['season_number'] = $data['season_number'] ?? 1;

        if ($request->hasFile('video_file')) {
            $data['video_url'] = $this->mediaStorage->storeUploadedFile($request->file('video_file'), 'episodes/videos');
        }
        if ($request->hasFile('thumbnail_file')) {
            $data['thumbnail_url'] = $this->mediaStorage->storeUploadedFile($request->file('thumbnail_file'), 'episodes/thumbnails');
        }

        unset($data['video_file'], $data['thumbnail_file']);

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
            'video_file' => ['nullable', 'file', 'mimes:mp4,mov,mkv,webm', 'max:512000'],
            'thumbnail_file' => ['nullable', 'file', 'image', 'max:10240'],
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

        if ($request->hasFile('video_file')) {
            $data['video_url'] = $this->mediaStorage->replaceUploadedFile(
                $episode->video_url,
                $request->file('video_file'),
                'episodes/videos'
            );
        }
        if ($request->hasFile('thumbnail_file')) {
            $data['thumbnail_url'] = $this->mediaStorage->replaceUploadedFile(
                $episode->thumbnail_url,
                $request->file('thumbnail_file'),
                'episodes/thumbnails'
            );
        }

        unset($data['video_file'], $data['thumbnail_file']);

        $episode->update($data);

        return $episode;
    }

    public function destroy(Episode $episode)
    {
        $this->mediaStorage->deleteByUrl($episode->video_url);
        $this->mediaStorage->deleteByUrl($episode->thumbnail_url);
        $episode->delete();

        return response()->noContent();
    }
}
