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
        Schema::create('movies', function (Blueprint $table) {
            $table->increments('id');
            $table->string('title', 255);
            $table->string('slug', 255)->unique();
            $table->text('description')->nullable();
            $table->string('poster_url', 255)->nullable();
            $table->string('backdrop_url', 255)->nullable();
            $table->integer('release_year')->nullable();
            $table->string('country', 100)->nullable();
            $table->integer('duration')->nullable();
            $table->enum('type', ['single', 'series'])->default('single');
            $table->decimal('rating_avg', 3, 1)->default(0.0);
            $table->integer('rating_count')->default(0);
            $table->boolean('is_published')->default(true);
            $table->timestamps();

            $table->index('title', 'idx_movies_title');
            $table->index('release_year', 'idx_movies_release_year');
            $table->index('type', 'idx_movies_type');
            $table->index('is_published', 'idx_movies_published');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('movies');
    }
};
