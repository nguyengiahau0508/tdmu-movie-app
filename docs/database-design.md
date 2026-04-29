# 🗄️ Database Design – Movie App MVP

Thiết kế DB được rút gọn để phục vụ app xem phim cơ bản.

## 1. Danh sách bảng

1. `users`: tài khoản người dùng.
2. `genres`: thể loại phim.
3. `movies`: thông tin phim/series.
4. `movie_genres`: quan hệ N-N giữa phim và thể loại.
5. `episodes`: tập phim cho series.
6. `watchlists`: danh sách yêu thích.
7. `watch_history`: tiến độ xem để continue watching.
8. `reviews`: đánh giá phim.

## 2. Thiết kế chi tiết

### users
- `id`, `username`, `email`, `password_hash`, `role`, `created_at`, `updated_at`
- `role`: `user` hoặc `admin`

### genres
- `id`, `name`, `slug`

### movies
- `id`, `title`, `slug`, `description`
- `poster_url`, `backdrop_url`
- `release_year`, `country`
- `duration` (phim lẻ, phút)
- `type` (`single` | `series`)
- `rating_avg`, `rating_count`
- `is_published`, `created_at`, `updated_at`

### movie_genres
- `movie_id`, `genre_id`
- Primary key kép để tránh trùng quan hệ.

### episodes
- `id`, `movie_id`, `season_number`, `episode_number`
- `title`, `description`
- `duration`, `video_url`, `thumbnail_url`
- Unique `(movie_id, season_number, episode_number)`

### watchlists
- `id`, `user_id`, `movie_id`, `created_at`
- Unique `(user_id, movie_id)` để không thêm trùng.

### watch_history
- `id`, `user_id`, `movie_id`, `episode_id`
- `watched_seconds`, `duration_seconds`, `is_finished`, `updated_at`
- Unique `(user_id, movie_id, episode_id)` để update tiến độ đúng bản ghi.

### reviews
- `id`, `user_id`, `movie_id`
- `rating` (1-10), `comment`, `created_at`, `updated_at`
- Unique `(user_id, movie_id)` mỗi user chỉ review 1 lần/phim.

## 3. Quan hệ chính

- `movies` N-N `genres` qua `movie_genres`.
- `movies` 1-N `episodes`.
- `users` N-N `movies` qua `watchlists`.
- `users` N-N `movies` qua `watch_history`.
- `users` N-N `movies` qua `reviews`.

## 4. Ghi chú triển khai

- Không dùng soft-delete trong MVP để đơn giản hoá truy vấn.
- Không có bảng subscription/content_access.
- Không có bảng audit logs/user_devices ở bản này.
- Có thể bổ sung sau khi sản phẩm có nhu cầu thực tế.
