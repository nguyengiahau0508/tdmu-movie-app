<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{
    protected $fillable = [
        'user_id',
        'movie_id',
        'rating',
        'comment',
    ];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'movie_id' => 'integer',
            'rating' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
