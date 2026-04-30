<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Watchlist extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'movie_id',
    ];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'movie_id' => 'integer',
            'created_at' => 'datetime',
        ];
    }
}
