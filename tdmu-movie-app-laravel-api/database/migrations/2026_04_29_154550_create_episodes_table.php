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
        Schema::create('episodes', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('movie_id');
            $table->integer('season_number')->default(1);
            $table->integer('episode_number');
            $table->string('title', 255);
            $table->text('description')->nullable();
            $table->integer('duration')->nullable();
            $table->string('video_url', 500);
            $table->string('thumbnail_url', 500)->nullable();
            $table->timestamps();

            $table->foreign('movie_id', 'fk_episodes_movie')
                ->references('id')
                ->on('movies')
                ->cascadeOnDelete();
            $table->unique(['movie_id', 'season_number', 'episode_number'], 'uk_episode_order');
            $table->index('movie_id', 'idx_episodes_movie');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('episodes');
    }
};
