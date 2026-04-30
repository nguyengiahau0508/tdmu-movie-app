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
        Schema::create('watchlists', function (Blueprint $table) {
            $table->increments('id');
            $table->unsignedInteger('user_id');
            $table->unsignedInteger('movie_id');
            $table->timestamp('created_at')->useCurrent();

            $table->foreign('user_id', 'fk_watchlists_user')
                ->references('id')
                ->on('users')
                ->cascadeOnDelete();
            $table->foreign('movie_id', 'fk_watchlists_movie')
                ->references('id')
                ->on('movies')
                ->cascadeOnDelete();
            $table->unique(['user_id', 'movie_id'], 'uk_watchlists_user_movie');
            $table->index('user_id', 'idx_watchlists_user');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('watchlists');
    }
};
