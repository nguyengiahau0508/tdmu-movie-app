<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Episode extends Model
{
    protected $fillable = [
        'movie_id',
        'season_number',
        'episode_number',
        'title',
        'description',
        'duration',
        'video_url',
        'thumbnail_url',
    ];

    protected function casts(): array
    {
        return [
            'movie_id' => 'integer',
            'season_number' => 'integer',
            'episode_number' => 'integer',
            'duration' => 'integer',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }
}
