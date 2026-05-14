<?php

namespace App\Http\Controllers;

use App\Models\Episode;
use App\Services\MediaStorageService;
use Illuminate\Http\Request;

class EpisodeController extends Controller
{
    public function __construct(private readonly MediaStorageService $mediaStorage) {}

    public function index(Request $request)
    {
        $query = Episode::query();

        if ($request->filled('movie_id')) {
            $query->where('movie_id', $request->input('movie_id'));
        }

        return $query->orderBy('season_number')
            ->orderBy('episode_number')
            ->get();
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
            'video_qualities' => ['sometimes', 'array'],
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

        // Xử lý upload file cho từng chất lượng
        $qualities = $request->input('video_qualities', []);
        if (is_array($qualities)) {
            foreach ($qualities as $label => $url) {
                $fileKey = 'quality_file_' . str_replace(' ', '_', $label);
                if ($request->hasFile($fileKey)) {
                    $qualities[$label] = $this->mediaStorage->storeUploadedFile($request->file($fileKey), 'episodes/videos/' . $label);
                }
            }
            $data['video_qualities'] = $qualities;
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
            'video_qualities' => ['sometimes', 'array'],
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

        // Xử lý upload file cho từng chất lượng
        if ($request->has('video_qualities')) {
            $qualities = $request->input('video_qualities', []);
            $oldQualities = $episode->video_qualities ?? [];
            
            foreach ($qualities as $label => $url) {
                $fileKey = 'quality_file_' . str_replace(' ', '_', $label);
                if ($request->hasFile($fileKey)) {
                    // Xóa file cũ nếu có nhãn trùng
                    $oldUrl = $oldQualities[$label] ?? null;
                    if ($oldUrl) {
                        $this->mediaStorage->deleteByUrl($oldUrl);
                    }
                    $qualities[$label] = $this->mediaStorage->storeUploadedFile($request->file($fileKey), 'episodes/videos/' . $label);
                }
            }
            $data['video_qualities'] = $qualities;
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
