
# 🗄️ Database Design – Movie Streaming Application (MariaDB)

## 📌 Overview

This database design is built for a movie streaming system that supports:

* Single movies and TV series
* User personalization (watch history, favorites)
* Scalable querying for high-traffic features

The schema is optimized for **MariaDB** and structured into logical modules.

---

## 🧩 1. User Management

Handles authentication, user data, and role-based access.

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('user', 'vip', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

---

## 🎬 2. Content Management

Supports both movies and series with flexible relationships.

### 📂 Genres

```sql
CREATE TABLE genres (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) UNIQUE NOT NULL
);
```

### 🎥 Movies

```sql
CREATE TABLE movies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    poster_url VARCHAR(255),
    backdrop_url VARCHAR(255),
    release_year INT,
    duration INT,
    type ENUM('single', 'series') DEFAULT 'single',
    rating_avg DECIMAL(3,1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 🔗 Movie - Genre (Many-to-Many)

```sql
CREATE TABLE movie_genres (
    movie_id INT,
    genre_id INT,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);
```

### 📺 Episodes

```sql
CREATE TABLE episodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id INT,
    title VARCHAR(255),
    episode_number INT,
    video_url VARCHAR(255) NOT NULL,
    thumbnail_url VARCHAR(255),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE
);
```

---

## ❤️ 3. User Interaction & Personalization

Core for engagement and retention features.

### 📌 Watchlist

```sql
CREATE TABLE watchlists (
    user_id INT,
    movie_id INT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, movie_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (movie_id) REFERENCES movies(id)
);
```

### ⏯️ Watch History (Continue Watching)

```sql
CREATE TABLE watch_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    episode_id INT,
    watched_time INT,
    is_finished BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (episode_id) REFERENCES episodes(id)
);
```

### ⭐ Reviews

```sql
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    movie_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 10),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (movie_id) REFERENCES movies(id)
);
```

---

## ⚙️ Optimization Strategies (MariaDB)

### 📈 Indexing

* Add indexes for:

  * `watch_history(user_id, episode_id)`
  * `movies(title)`
* Improves performance for:

  * Continue Watching
  * Search queries

---

### 🧾 JSON Usage

* Use `JSON` column (e.g., `metadata`) in `movies`:

```sql
ALTER TABLE movies ADD metadata JSON;
```

* Store flexible data:

  * cast
  * directors
  * awards

---

### ⚡ Efficient Watch History Updates

Use:

```sql
INSERT INTO watch_history (...)
ON DUPLICATE KEY UPDATE watched_time = VALUES(watched_time);
```

* Prevent duplicate records
* Optimize write performance

---

### 📡 Streaming Strategy

* Store HLS (`.m3u8`) or DASH URLs in `video_url`
* Enables adaptive streaming on frontend (Flutter/Web)

---

## 🧱 Design Considerations

### ✅ Strengths

* Clean separation of concerns
* Scalable for MVP → production
* Optimized for personalization features

### ⚠️ Limitations (Future Improvements)

* No actor/director tables (can normalize later)
* No tagging system
* No multi-language support

---

## 🚀 Future Enhancements

* Add `actors`, `directors` tables (normalize metadata)
* Full-text search (ElasticSearch integration)
* Recommendation system (ML-based)
* Sharding for large-scale systems

---

## 📌 Conclusion

This schema is production-ready for MVP and provides a strong foundation for scaling into a full-featured streaming platform.
