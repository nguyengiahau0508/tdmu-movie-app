<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Movie extends Model
{
    protected $fillable = [
        'title',
        'slug',
        'description',
        'poster_url',
        'backdrop_url',
        'release_year',
        'country',
        'duration',
        'type',
        'rating_avg',
        'rating_count',
        'is_published',
    ];

    protected function casts(): array
    {
        return [
            'release_year' => 'integer',
            'duration' => 'integer',
            'rating_avg' => 'decimal:1',
            'rating_count' => 'integer',
            'is_published' => 'boolean',
            'created_at' => 'datetime',
            'updated_at' => 'datetime',
        ];
    }

    public function genres()
    {
        return $this->belongsToMany(Genre::class, 'movie_genres');
    }

    public function episodes()
    {
        return $this->hasMany(Episode::class);
    }
}
