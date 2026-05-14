<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('movie_genres', function (Blueprint $table) {
            $table->unsignedInteger('movie_id');
            $table->unsignedInteger('genre_id');

            $table->primary(['movie_id', 'genre_id']);
            $table->foreign('movie_id', 'fk_movie_genres_movie')
                ->references('id')
                ->on('movies')
                ->cascadeOnDelete();
            $table->foreign('genre_id', 'fk_movie_genres_genre')
                ->references('id')
                ->on('genres')
                ->cascadeOnDelete();
            $table->index('genre_id', 'idx_movie_genres_genre');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('movie_genres');
    }
};
