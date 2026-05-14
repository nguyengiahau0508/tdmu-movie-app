<?php

namespace App\Services;

use App\Models\User;
use RuntimeException;

class JwtService
{
    public function issueToken(User $user): string
    {
        $issuedAt = now()->timestamp;
        $header = ['alg' => 'HS256', 'typ' => 'JWT'];
        $payload = [
            'iss' => config('jwt.issuer'),
            'sub' => $user->id,
            'iat' => $issuedAt,
            'exp' => $issuedAt + (int) config('jwt.ttl', 86400),
        ];

        $encodedHeader = $this->base64UrlEncode(json_encode($header, JSON_THROW_ON_ERROR));
        $encodedPayload = $this->base64UrlEncode(json_encode($payload, JSON_THROW_ON_ERROR));
        $signature = $this->sign("{$encodedHeader}.{$encodedPayload}");

        return "{$encodedHeader}.{$encodedPayload}.{$signature}";
    }

    /**
     * @return array<string, mixed>
     */
    public function decodeToken(string $token): array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            throw new RuntimeException('Token format is invalid.');
        }

        [$encodedHeader, $encodedPayload, $receivedSignature] = $parts;

        $expectedSignature = $this->sign("{$encodedHeader}.{$encodedPayload}");
        if (! hash_equals($expectedSignature, $receivedSignature)) {
            throw new RuntimeException('Token signature is invalid.');
        }

        /** @var array<string, mixed>|null $header */
        $header = json_decode($this->base64UrlDecode($encodedHeader), true);
        if (! is_array($header) || ($header['alg'] ?? null) !== 'HS256') {
            throw new RuntimeException('Token algorithm is invalid.');
        }

        /** @var array<string, mixed>|null $payload */
        $payload = json_decode($this->base64UrlDecode($encodedPayload), true);
        if (! is_array($payload)) {
            throw new RuntimeException('Token payload is invalid.');
        }

        $exp = $payload['exp'] ?? null;
        if (! is_int($exp) || $exp <= now()->timestamp) {
            throw new RuntimeException('Token is expired.');
        }

        return $payload;
    }

    public function userIdFromToken(string $token): int
    {
        $payload = $this->decodeToken($token);
        $subject = $payload['sub'] ?? null;

        if (! is_int($subject) || $subject <= 0) {
            throw new RuntimeException('Token subject is invalid.');
        }

        return $subject;
    }

    private function sign(string $data): string
    {
        $rawSignature = hash_hmac('sha256', $data, $this->secret(), true);

        return $this->base64UrlEncode($rawSignature);
    }

    private function secret(): string
    {
        $secret = (string) config('jwt.secret', '');
        if ($secret !== '') {
            return $secret;
        }

        $appKey = (string) config('app.key', '');
        if ($appKey === '') {
            return 'tdmu-default-jwt-secret-change-me';
        }

        if (str_starts_with($appKey, 'base64:')) {
            $decoded = base64_decode(substr($appKey, 7), true);
            if ($decoded !== false && $decoded !== '') {
                return $decoded;
            }
        }

        return $appKey;
    }

    private function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }

    private function base64UrlDecode(string $value): string
    {
        $remainder = strlen($value) % 4;
        if ($remainder > 0) {
            $value .= str_repeat('=', 4 - $remainder);
        }

        $decoded = base64_decode(strtr($value, '-_', '+/'), true);
        if ($decoded === false) {
            throw new RuntimeException('Token section decoding failed.');
        }

        return $decoded;
    }
}
