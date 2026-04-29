# 🚀 API Specification – Movie App MVP

## Base URL

`/api/v1`

## Authentication

Bearer JWT:

`Authorization: Bearer <token>`

---

## 1. Auth

### POST `/auth/register`
- Input: `username`, `email`, `password`
- Output: thông tin user + token

### POST `/auth/login`
- Input: `email`, `password`
- Output: thông tin user + token

---

## 2. Movies

### GET `/movies`
- Query: `page`, `limit`, `q`, `genre`, `type`
- Trả danh sách phim đã publish.

### GET `/movies/:movieId`
- Trả chi tiết phim + thể loại + điểm trung bình.

### GET `/movies/:movieId/episodes`
- Trả danh sách tập (nếu `type=series`).

### GET `/movies/:movieId/stream`
- Trả `video_url` của phim lẻ hoặc tập cụ thể.
- Query tùy chọn: `episode_id`

---

## 3. Watchlist (Yêu thích)

### GET `/users/me/watchlist`
- Danh sách phim yêu thích của user.

### POST `/users/me/watchlist`
- Input: `movie_id`
- Thêm phim vào yêu thích.

### DELETE `/users/me/watchlist/:movieId`
- Xoá phim khỏi yêu thích.

---

## 4. Watch History (Xem tiếp)

### GET `/users/me/continue-watching`
- Trả danh sách đang xem dở, sắp theo `updated_at` mới nhất.

### POST `/users/me/watch-history`
- Input:
  - `movie_id`
  - `episode_id` (nullable)
  - `watched_seconds`
  - `duration_seconds`
  - `is_finished`
- Tạo/cập nhật tiến độ xem.

---

## 5. Reviews

### GET `/movies/:movieId/reviews`
- Danh sách đánh giá của phim.

### POST `/movies/:movieId/reviews`
- Input: `rating` (1-10), `comment`
- Mỗi user chỉ có 1 review cho 1 phim.

### PUT `/movies/:movieId/reviews/:reviewId`
- Cập nhật review của chính user.

### DELETE `/movies/:movieId/reviews/:reviewId`
- Xoá review của chính user hoặc admin.

---

## 6. Admin (cơ bản)

### Movies
- `POST /admin/movies`
- `PUT /admin/movies/:movieId`
- `DELETE /admin/movies/:movieId`

### Episodes
- `POST /admin/movies/:movieId/episodes`
- `PUT /admin/episodes/:episodeId`
- `DELETE /admin/episodes/:episodeId`

### Genres
- `POST /admin/genres`
- `PUT /admin/genres/:genreId`
- `DELETE /admin/genres/:genreId`

---

## 7. Error format

```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "Dữ liệu không hợp lệ"
}
```
