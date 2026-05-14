<?php

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

if (! extension_loaded('pdo_sqlite')) {
    test('auth api tests require pdo_sqlite extension', function () {
        $this->markTestSkipped('pdo_sqlite extension is required for RefreshDatabase tests.');
    });

    return;
}

uses(RefreshDatabase::class);

test('user can register and receive a jwt token', function () {
    $response = $this->postJson('/api/auth/register', [
        'username' => 'new_user',
        'email' => 'new_user@example.com',
        'password' => 'strong-password',
    ]);

    $response
        ->assertCreated()
        ->assertJsonStructure([
            'token',
            'token_type',
            'expires_in',
            'user' => ['id', 'username', 'email', 'role'],
        ]);

    expect(User::query()->where('email', 'new_user@example.com')->exists())->toBeTrue();
});

test('user can login and access profile with jwt token', function () {
    $user = User::query()->create([
        'username' => 'existing_user',
        'email' => 'existing_user@example.com',
        'password_hash' => Hash::make('strong-password'),
        'role' => 'user',
    ]);

    $loginResponse = $this->postJson('/api/auth/login', [
        'email' => $user->email,
        'password' => 'strong-password',
    ]);

    $loginResponse->assertOk()->assertJsonStructure(['token', 'user']);
    $token = $loginResponse->json('token');

    $meResponse = $this
        ->withHeader('Authorization', "Bearer {$token}")
        ->getJson('/api/auth/me');

    $meResponse
        ->assertOk()
        ->assertJsonPath('user.id', $user->id)
        ->assertJsonPath('user.email', $user->email);
});

test('auth me endpoint rejects missing or invalid token', function () {
    $this->getJson('/api/auth/me')->assertUnauthorized();

    $this
        ->withHeader('Authorization', 'Bearer invalid.token.value')
        ->getJson('/api/auth/me')
        ->assertUnauthorized();
});
