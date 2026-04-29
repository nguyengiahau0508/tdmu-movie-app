# ⚡ Quick Start – Movie App MVP

## 1. Tạo database

```sql
CREATE DATABASE movie_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

## 2. Import schema

```bash
mysql -u root -p movie_app < docs/schema-improved.sql
```

## 3. Kiểm tra bảng

```sql
USE movie_app;
SHOW TABLES;
```

Bạn sẽ có 8 bảng:
- users
- genres
- movies
- movie_genres
- episodes
- watchlists
- watch_history
- reviews

## 4. Bước tiếp theo

1. Đọc `docs/api-specification.md` để làm backend API.
2. Đọc `docs/system-overview.md` để nắm phạm vi MVP.
3. Đọc `docs/database-design.md` để hiểu quan hệ dữ liệu.
