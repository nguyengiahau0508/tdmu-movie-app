<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MovieGenre extends Model
{
    public $timestamps = false;

    protected $table = 'movie_genres';

    public $incrementing = false;

    protected $primaryKey = 'movie_id';

    protected $fillable = [
        'movie_id',
        'genre_id',
    ];
}
