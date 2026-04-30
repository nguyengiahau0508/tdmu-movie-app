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
        Schema::create('watch_history', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('user_id');
            $table->unsignedInteger('movie_id');
            $table->unsignedInteger('episode_id')->nullable();
            $table->integer('watched_seconds')->default(0);
            $table->integer('duration_seconds')->default(0);
            $table->boolean('is_finished')->default(false);
            $table->timestamp('updated_at')->useCurrent()->useCurrentOnUpdate();

            $table->foreign('user_id', 'fk_watch_history_user')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
            $table->foreign('movie_id', 'fk_watch_history_movie')
                ->references('id')
                ->on('movies')
                ->cascadeOnDelete();
            $table->foreign('episode_id', 'fk_watch_history_episode')
                ->references('id')
                ->on('episodes')
                ->cascadeOnDelete();
            $table->unique(['user_id', 'movie_id', 'episode_id'], 'uk_watch_history_user_content');
            $table->index('user_id', 'idx_watch_history_user');
            $table->index('updated_at', 'idx_watch_history_updated');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('watch_history');
    }
};
