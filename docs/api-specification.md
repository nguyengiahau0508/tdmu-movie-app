# 🚀 API Specification – Movie Streaming Application

## Overview

This document defines the REST API specification for the TDMU Movie Streaming Application. The API is organized into logical resource groups and follows RESTful principles.

---

## 📋 Base URL & Authentication

**Base URL**: `https://api.tdmu-movies.com/v1`

**Authentication**: Bearer token (JWT)
```
Authorization: Bearer <jwt_token>
```

**Response Format**: JSON

---

## 🔑 Authentication Endpoints

### 1. User Registration
```
POST /auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "SecurePassword123!"
}

Response (201):
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "user",
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 2. User Login
```
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}

Response (200):
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "role": "user",
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 3. Refresh Token
```
POST /auth/refresh
Authorization: Bearer <jwt_token>

Response (200):
{
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 4. Logout
```
POST /auth/logout
Authorization: Bearer <jwt_token>

Response (200):
{
  "message": "Logged out successfully"
}
```

---

## 👤 User Endpoints

### 1. Get User Profile
```
GET /users/me
Authorization: Bearer <jwt_token>

Response (200):
{
  "id": 1,
  "username": "john_doe",
  "email": "john@example.com",
  "profile_avatar": "https://...",
  "bio": "Movie enthusiast",
  "role": "user",
  "is_active": true,
  "created_at": "2024-01-15T10:30:00Z"
}
```

### 2. Update User Profile
```
PUT /users/me
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "username": "john_doe",
  "bio": "Updated bio",
  "profile_avatar": "https://..."
}

Response (200):
{
  "id": 1,
  "username": "john_doe",
  "bio": "Updated bio",
  "profile_avatar": "https://...",
  "updated_at": "2024-01-15T11:00:00Z"
}
```

### 3. Get User Devices
```
GET /users/me/devices
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "device_id": "device-123",
      "device_name": "iPhone 14",
      "device_type": "mobile",
      "last_active": "2024-01-15T10:30:00Z"
    },
    {
      "id": 2,
      "device_id": "device-456",
      "device_name": "Samsung TV",
      "device_type": "tv",
      "last_active": "2024-01-14T20:00:00Z"
    }
  ]
}
```

---

## 🎬 Movies & Content Endpoints

### 1. List All Movies
```
GET /movies?page=1&limit=20&sort=-rating_avg&filter[genre]=action&filter[year]=2023
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "title": "The Matrix",
      "slug": "the-matrix",
      "description": "A computer programmer...",
      "poster_url": "https://...",
      "backdrop_url": "https://...",
      "release_year": 1999,
      "type": "single",
      "rating_avg": 8.7,
      "rating_count": 2543,
      "is_premium": false,
      "genres": ["action", "sci-fi"],
      "actors": [
        {
          "id": 1,
          "name": "Keanu Reeves",
          "character_name": "Neo"
        }
      ],
      "directors": [
        {
          "id": 1,
          "name": "Lana Wachowski"
        }
      ]
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100,
    "per_page": 20
  }
}
```

### 2. Get Movie Details
```
GET /movies/:movieId
Authorization: Bearer <jwt_token>

Response (200):
{
  "id": 1,
  "title": "The Matrix",
  "description": "...",
  "type": "single",
  "duration": 136,
  "content_rating": "R",
  "is_premium": false,
  "rating_avg": 8.7,
  "genres": ["action", "sci-fi"],
  "actors": [...],
  "directors": [...],
  "episodes": [
    {
      "id": 1,
      "season_number": 1,
      "episode_number": 1,
      "title": "Welcome to the Matrix",
      "duration": 45,
      "video_url": "https://..."
    }
  ],
  "my_review": {
    "rating": 9,
    "comment": "Amazing movie!"
  },
  "in_watchlist": true
}
```

### 3. Search Movies
```
GET /movies/search?q=matrix&type=single
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "title": "The Matrix",
      "poster_url": "https://...",
      "rating_avg": 8.7
    }
  ]
}
```

### 4. Get Popular Movies
```
GET /movies/popular?limit=10
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [...]
}
```

### 5. Get Movie Episodes (for series)
```
GET /movies/:movieId/episodes?season=1
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "season_number": 1,
      "episode_number": 1,
      "title": "Pilot",
      "description": "...",
      "duration": 45,
      "release_date": "2023-01-15",
      "video_url": "https://...",
      "thumbnail_url": "https://..."
    }
  ]
}
```

---

## ⭐ Watchlist & Favorites Endpoints

### 1. Get User Watchlist
```
GET /users/me/watchlist?page=1&limit=20
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "movie_id": 1,
      "movie": {
        "id": 1,
        "title": "The Matrix",
        "poster_url": "https://..."
      },
      "custom_rating": 9,
      "notes": "Want to rewatch",
      "added_at": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {...}
}
```

### 2. Add to Watchlist
```
POST /users/me/watchlist
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "movie_id": 1,
  "custom_rating": 9,
  "notes": "Want to rewatch"
}

Response (201):
{
  "id": 1,
  "movie_id": 1,
  "added_at": "2024-01-15T10:30:00Z"
}
```

### 3. Remove from Watchlist
```
DELETE /users/me/watchlist/:watchlistId
Authorization: Bearer <jwt_token>

Response (204):
```

### 4. Update Watchlist Item
```
PUT /users/me/watchlist/:watchlistId
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "custom_rating": 8,
  "notes": "Already watched"
}

Response (200):
{
  "id": 1,
  "custom_rating": 8,
  "notes": "Already watched",
  "updated_at": "2024-01-15T11:00:00Z"
}
```

---

## ⏯️ Watch History Endpoints

### 1. Get Continue Watching
```
GET /users/me/continue-watching?device_id=device-123
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "movie": {
        "id": 1,
        "title": "Breaking Bad",
        "slug": "breaking-bad"
      },
      "episode": {
        "id": 5,
        "season_number": 2,
        "episode_number": 3,
        "title": "Catalyst"
      },
      "watched_time": 2340,
      "total_duration": 2700,
      "progress_percent": 86.67,
      "last_watched": "2024-01-15T20:30:00Z"
    }
  ]
}
```

### 2. Update Watch History
```
POST /users/me/watch-history
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "episode_id": 5,
  "watched_time": 2340,
  "total_duration": 2700,
  "device_id": "device-123",
  "is_finished": false
}

Response (201):
{
  "id": 1,
  "episode_id": 5,
  "watched_time": 2340,
  "updated_at": "2024-01-15T20:30:00Z"
}
```

### 3. Mark as Watched
```
POST /users/me/watch-history/:historyId/finish
Authorization: Bearer <jwt_token>

Response (200):
{
  "id": 1,
  "is_finished": true,
  "updated_at": "2024-01-15T21:45:00Z"
}
```

---

## 💬 Reviews & Ratings Endpoints

### 1. Get Movie Reviews
```
GET /movies/:movieId/reviews?page=1&limit=10&sort=-created_at
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "user": {
        "id": 1,
        "username": "john_doe"
      },
      "rating": 9,
      "comment": "Best movie ever!",
      "is_helpful_count": 45,
      "created_at": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {...}
}
```

### 2. Add Review
```
POST /movies/:movieId/reviews
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "rating": 9,
  "comment": "Excellent movie!"
}

Response (201):
{
  "id": 1,
  "movie_id": 1,
  "rating": 9,
  "comment": "Excellent movie!",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### 3. Update Review
```
PUT /movies/:movieId/reviews/:reviewId
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "rating": 8,
  "comment": "Updated comment"
}

Response (200):
{
  "id": 1,
  "rating": 8,
  "comment": "Updated comment",
  "updated_at": "2024-01-15T11:00:00Z"
}
```

### 4. Delete Review
```
DELETE /movies/:movieId/reviews/:reviewId
Authorization: Bearer <jwt_token>

Response (204):
```

### 5. Mark Review as Helpful
```
POST /movies/:movieId/reviews/:reviewId/helpful
Authorization: Bearer <jwt_token>

Response (200):
{
  "id": 1,
  "is_helpful_count": 46
}
```

---

## 💳 Subscription Endpoints

### 1. Get Subscription Plans
```
GET /subscriptions
Authorization: Bearer <jwt_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "name": "Free",
      "description": "Free tier with ads",
      "price": 0,
      "max_devices": 1,
      "max_quality": "480p",
      "allows_download": false
    },
    {
      "id": 2,
      "name": "Premium",
      "description": "Ad-free with 4K",
      "price": 14.99,
      "max_devices": 4,
      "max_quality": "4k",
      "allows_download": true
    }
  ]
}
```

### 2. Get User's Active Subscription
```
GET /users/me/subscription
Authorization: Bearer <jwt_token>

Response (200):
{
  "id": 1,
  "subscription": {
    "id": 2,
    "name": "Premium"
  },
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": "2024-02-15T00:00:00Z",
  "is_active": true,
  "auto_renew": true
}
```

### 3. Subscribe to Plan
```
POST /users/me/subscribe
Authorization: Bearer <jwt_token>
Content-Type: application/json

{
  "subscription_id": 2
}

Response (201):
{
  "id": 1,
  "subscription_id": 2,
  "start_date": "2024-01-15T00:00:00Z",
  "end_date": "2024-02-15T00:00:00Z"
}
```

### 4. Cancel Subscription
```
DELETE /users/me/subscription
Authorization: Bearer <jwt_token>

Response (200):
{
  "message": "Subscription cancelled successfully"
}
```

---

## 👥 Admin Endpoints

### 1. Create Movie (Admin only)
```
POST /admin/movies
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "title": "New Movie",
  "description": "...",
  "type": "single",
  "release_year": 2024,
  "duration": 120,
  "poster_url": "https://...",
  "genre_ids": [1, 2],
  "actor_ids": [1, 2],
  "director_ids": [1],
  "is_premium": false,
  "content_rating": "PG-13"
}

Response (201):
{
  "id": 100,
  "title": "New Movie",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### 2. Update Movie (Admin only)
```
PUT /admin/movies/:movieId
Authorization: Bearer <admin_token>
Content-Type: application/json

{...movie data...}

Response (200):
{...updated movie...}
```

### 3. Delete Movie (Admin only)
```
DELETE /admin/movies/:movieId
Authorization: Bearer <admin_token>

Response (204):
```

### 4. Add Episode (Admin only)
```
POST /admin/movies/:movieId/episodes
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "title": "Episode 1",
  "season_number": 1,
  "episode_number": 1,
  "description": "...",
  "video_url": "https://...",
  "thumbnail_url": "https://...",
  "duration": 45,
  "release_date": "2024-01-15"
}

Response (201):
{...episode...}
```

### 5. Get Audit Logs (Admin only)
```
GET /admin/audit-logs?entity_type=movies&action=create&page=1&limit=20
Authorization: Bearer <admin_token>

Response (200):
{
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "entity_type": "movies",
      "entity_id": 100,
      "action": "create",
      "new_value": {...},
      "created_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

---

## 🔍 Search & Filter Parameters

### Common Query Parameters:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)
- `sort`: Sort field (prefix with `-` for desc, e.g., `-created_at`)
- `search`: Full-text search query

### Movie Filters:
- `filter[genre]`: Genre ID or slug
- `filter[year]`: Release year
- `filter[type]`: 'single' or 'series'
- `filter[rating_min]`: Minimum rating (1-10)
- `filter[is_premium]`: true/false
- `filter[content_rating]`: G, PG, PG-13, R, 16+, 18+

### Example:
```
GET /movies?page=1&limit=20&sort=-rating_avg&filter[genre]=action&filter[year]=2023&search=matrix
```

---

## ❌ Error Responses

### 400 Bad Request
```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "Validation failed",
  "errors": {
    "email": ["Invalid email format"],
    "password": ["Password must be at least 8 characters"]
  }
}
```

### 401 Unauthorized
```json
{
  "status": "error",
  "code": "UNAUTHORIZED",
  "message": "Invalid or expired token"
}
```

### 403 Forbidden
```json
{
  "status": "error",
  "code": "FORBIDDEN",
  "message": "You don't have permission to access this resource"
}
```

### 404 Not Found
```json
{
  "status": "error",
  "code": "NOT_FOUND",
  "message": "Resource not found"
}
```

### 409 Conflict
```json
{
  "status": "error",
  "code": "CONFLICT",
  "message": "Resource already exists"
}
```

### 500 Internal Server Error
```json
{
  "status": "error",
  "code": "INTERNAL_ERROR",
  "message": "An unexpected error occurred"
}
```

---

## 📝 Rate Limiting

All API endpoints are rate-limited:

- **Default**: 100 requests per minute per user
- **Premium Users**: 500 requests per minute
- **Admin**: Unlimited

Response headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642257600
```

---

## 🔐 Security Considerations

1. **HTTPS Only**: All API calls must use HTTPS
2. **JWT Tokens**: Expire after 24 hours
3. **CORS**: Enabled for authorized domains only
4. **Rate Limiting**: Prevent abuse and DDoS attacks
5. **Input Validation**: All inputs are validated and sanitized
6. **SQL Injection Prevention**: Parameterized queries used throughout

---

## 📌 Versioning

- Current Version: `v1`
- Backward Compatibility: Maintained for 2 major versions
- Deprecation Notice: 6 months advance notice before removal

---

## 🔗 Additional Resources

- Full API Documentation: https://docs.tdmu-movies.com
- OpenAPI/Swagger: https://api.tdmu-movies.com/swagger
- SDK Samples: https://github.com/tdmu/movie-app-sdk
