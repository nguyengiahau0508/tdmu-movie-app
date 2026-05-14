<?php

namespace Tests\Feature;

use App\Models\Movie;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class EpisodeValidationTest extends TestCase
{
    use RefreshDatabase;

    public function test_store_episode_with_empty_url_and_no_file()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $movie = Movie::create([
            'title' => 'Test Movie',
            'slug' => 'test-movie',
        ]);

        $response = $this->actingAs($admin)
            ->postJson('/api/admin/episodes', [
                'movie_id' => $movie->id,
                'season_number' => 1,
                'episode_number' => 1,
                'title' => 'Test Episode',
                'video_url' => '', // Empty string
            ]);

        $response->assertStatus(422);
        // Let's see the error message
        $this->dump($response->json());
    }

    public function test_store_episode_without_url_field()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $movie = Movie::create([
            'title' => 'Test Movie',
            'slug' => 'test-movie',
        ]);

        $response = $this->actingAs($admin)
            ->postJson('/api/admin/episodes', [
                'movie_id' => $movie->id,
                'season_number' => 1,
                'episode_number' => 1,
                'title' => 'Test Episode',
                // video_url missing
            ]);

        $response->assertStatus(422);
        $this->dump($response->json());
    }
}
