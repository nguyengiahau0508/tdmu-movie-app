<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Services\JwtService;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateJwt
{
    public function __construct(private readonly JwtService $jwtService) {}

    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        if (! $token) {
            return response()->json([
                'message' => 'Authorization token is required.',
            ], 401);
        }

        try {
            $userId = $this->jwtService->userIdFromToken($token);
        } catch (RuntimeException) {
            return response()->json([
                'message' => 'Authorization token is invalid or expired.',
            ], 401);
        }

        $user = User::query()->find($userId);
        if (! $user) {
            return response()->json([
                'message' => 'User not found for this token.',
            ], 401);
        }

        Auth::setUser($user);
        $request->setUserResolver(static fn () => $user);

        return $next($request);
    }
}
