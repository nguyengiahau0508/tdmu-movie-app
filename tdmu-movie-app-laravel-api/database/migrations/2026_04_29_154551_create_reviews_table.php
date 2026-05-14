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
        Schema::create('reviews', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('user_id');
            $table->unsignedInteger('movie_id');
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->timestamps();

            $table->foreign('user_id', 'fk_reviews_user')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
            $table->foreign('movie_id', 'fk_reviews_movie')
                ->references('id')
                ->on('movies')
                ->cascadeOnDelete();
            $table->unique(['user_id', 'movie_id'], 'uk_reviews_user_movie');
            $table->index('movie_id', 'idx_reviews_movie');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('reviews');
    }
};
