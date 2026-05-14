<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class MediaStorageService
{
    public function storeUploadedFile(UploadedFile $file, string $directory): string
    {
        $path = $file->store($directory, 'public');

        return url('/api/media/' . $path);
    }

    public function replaceUploadedFile(?string $currentUrl, UploadedFile $file, string $directory): string
    {
        $this->deleteByUrl($currentUrl);

        return $this->storeUploadedFile($file, $directory);
    }

    public function deleteByUrl(?string $url): void
    {
        if (! $url) {
            return;
        }

        $path = $this->storagePathFromUrl($url);
        if (! $path) {
            return;
        }

        \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
    }

    private function storagePathFromUrl(string $url): ?string
    {
        $path = parse_url($url, PHP_URL_PATH);
        if (! is_string($path)) {
            return null;
        }

        if (str_starts_with($path, '/api/media/')) {
            return ltrim(substr($path, strlen('/api/media/')), '/');
        }

        if (str_starts_with($path, '/storage/')) {
            return ltrim(substr($path, strlen('/storage/')), '/');
        }

        return null;
    }
}
