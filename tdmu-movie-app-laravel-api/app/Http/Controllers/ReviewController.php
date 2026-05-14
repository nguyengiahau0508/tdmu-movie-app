<?php

namespace App\Http\Controllers;

use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function index(Request $request)
    {
        $query = Review::query();

        if ($request->filled('movie_id')) {
            $query->where('movie_id', $request->input('movie_id'));
        }

        return $query->with('user')->orderBy('created_at', 'desc')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'movie_id' => ['required', 'integer', 'exists:movies,id'],
            'rating' => ['required', 'integer', 'between:1,10'],
            'comment' => ['nullable', 'string'],
        ]);

        $review = Review::updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'movie_id' => $data['movie_id'],
            ],
            [
                'rating' => $data['rating'],
                'comment' => $data['comment'],
            ]
        );

        return response()->json($review, 201);
    }

    public function show(Review $review)
    {
        return $review->load('user');
    }

    public function update(Request $request, Review $review)
    {
        if ($review->user_id !== $request->user()->id) {
            abort(403);
        }

        $data = $request->validate([
            'rating' => ['sometimes', 'required', 'integer', 'between:1,10'],
            'comment' => ['nullable', 'string'],
        ]);

        $review->update($data);

        return $review;
    }

    public function destroy(Review $review, Request $request)
    {
        if ($review->user_id !== $request->user()->id) {
            abort(403);
        }
        $review->delete();

        return response()->noContent();
    }
}
