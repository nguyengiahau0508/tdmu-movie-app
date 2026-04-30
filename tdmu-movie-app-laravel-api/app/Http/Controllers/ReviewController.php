<?php

namespace App\Http\Controllers;

use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function index()
    {
        return Review::query()->orderBy('id')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'user_id' => ['required', 'integer', 'exists:users,id'],
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
            'rating' => ['required', 'integer', 'between:1,10'],
            'comment' => ['nullable', 'string'],
        ]);

        $exists = Review::query()
            ->where('user_id', $data['user_id'])
            ->where('movie_id', $data['movie_id'])
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The user has already reviewed this movie.',
            ], 422);
        }

        $review = Review::create($data);

        return response()->json($review, 201);
    }

    public function show(Review $review)
    {
        return $review;
    }

    public function update(Request $request, Review $review)
    {
        $data = $request->validate([
            'user_id' => ['sometimes', 'required', 'integer', 'exists:users,id'],
            'movie_id' => ['sometimes', 'required', 'integer', 'exists:movies,id'],
            'rating' => ['sometimes', 'required', 'integer', 'between:1,10'],
            'comment' => ['nullable', 'string'],
        ]);

        $userId = $data['user_id'] ?? $review->user_id;
        $movieId = $data['movie_id'] ?? $review->movie_id;

        $exists = Review::query()
            ->where('user_id', $userId)
            ->where('movie_id', $movieId)
            ->where('id', '!=', $review->id)
            ->exists();
        if ($exists) {
            return response()->json([
                'message' => 'The user has already reviewed this movie.',
            ], 422);
        }

        $review->update($data);

        return $review;
    }

    public function destroy(Review $review)
    {
        $review->delete();

        return response()->noContent();
    }
}
