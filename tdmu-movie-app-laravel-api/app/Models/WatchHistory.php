<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WatchHistory extends Model
{
    public const CREATED_AT = null;

    protected $table = 'watch_history';

    protected $fillable = [
        'user_id',
        'movie_id',
        'episode_id',
        'watched_seconds',
        'duration_seconds',
        'is_finished',
    ];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'movie_id' => 'integer',
            'episode_id' => 'integer',
            'watched_seconds' => 'integer',
            'duration_seconds' => 'integer',
            'is_finished' => 'boolean',
            'updated_at' => 'datetime',
        ];
    }
}
