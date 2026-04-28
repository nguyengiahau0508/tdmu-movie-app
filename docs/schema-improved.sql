-- ============================================================================
-- MOVIE STREAMING APPLICATION - IMPROVED DATABASE SCHEMA (MariaDB)
-- ============================================================================
-- This is a production-ready schema with:
-- - Normalized actor/director management
-- - Subscription & content access control
-- - Multi-device synchronization
-- - Audit logging & soft delete
-- - Optimized indexes
-- ============================================================================

-- ============================================================================
-- 1. USER MANAGEMENT
-- ============================================================================

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('user', 'vip', 'admin') DEFAULT 'user',
    profile_avatar VARCHAR(255),
    bio TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User devices for multi-device sync
CREATE TABLE user_devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    device_name VARCHAR(100),
    device_type ENUM('web', 'mobile', 'tablet', 'tv') DEFAULT 'web',
    ip_address VARCHAR(45),
    user_agent TEXT,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_device_id (device_id),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. SUBSCRIPTION MANAGEMENT
-- ============================================================================

CREATE TABLE subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    duration_days INT DEFAULT 30,
    max_devices INT DEFAULT 1,
    max_quality ENUM('480p', '720p', '1080p', '4k') DEFAULT '1080p',
    allows_download BOOLEAN DEFAULT FALSE,
    allows_offline BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User subscriptions - tracks active subscriptions
CREATE TABLE user_subscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subscription_id INT NOT NULL,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE RESTRICT,
    INDEX idx_user_id (user_id),
    INDEX idx_is_active (is_active),
    INDEX idx_end_date (end_date),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. CONTENT MANAGEMENT
-- ============================================================================

CREATE TABLE genres (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    slug VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_slug (slug),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Actors table
CREATE TABLE actors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    profile_image VARCHAR(255),
    birth_date DATE,
    nationality VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_name (name),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Directors table
CREATE TABLE directors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    profile_image VARCHAR(255),
    birth_date DATE,
    nationality VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_name (name),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Streaming servers
CREATE TABLE streaming_servers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    url VARCHAR(255) NOT NULL,
    priority INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    region VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_is_active (is_active),
    INDEX idx_region (region)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movies/Series table
CREATE TABLE movies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE,
    description TEXT,
    poster_url VARCHAR(255),
    backdrop_url VARCHAR(255),
    release_year INT,
    duration INT,
    type ENUM('single', 'series') DEFAULT 'single',
    country VARCHAR(100),
    studio VARCHAR(100),
    budget DECIMAL(15, 2),
    revenue DECIMAL(15, 2),
    rating_avg DECIMAL(3, 1) DEFAULT 0,
    rating_count INT DEFAULT 0,
    content_rating ENUM('G', 'PG', 'PG-13', 'R', '16+', '18+') DEFAULT 'PG',
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    INDEX idx_title (title),
    INDEX idx_slug (slug),
    INDEX idx_type (type),
    INDEX idx_is_premium (is_premium),
    INDEX idx_rating_avg (rating_avg),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movie-Genre relationship
CREATE TABLE movie_genres (
    movie_id INT,
    genre_id INT,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE,
    INDEX idx_genre_id (genre_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movie-Actor relationship
CREATE TABLE movie_actors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id INT NOT NULL,
    actor_id INT NOT NULL,
    character_name VARCHAR(255),
    role_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (actor_id) REFERENCES actors(id) ON DELETE CASCADE,
    UNIQUE KEY unique_movie_actor (movie_id, actor_id),
    INDEX idx_actor_id (actor_id),
    INDEX idx_role_order (role_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movie-Director relationship
CREATE TABLE movie_directors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id INT NOT NULL,
    director_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (director_id) REFERENCES directors(id) ON DELETE CASCADE,
    UNIQUE KEY unique_movie_director (movie_id, director_id),
    INDEX idx_director_id (director_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes (for series)
CREATE TABLE episodes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    season_number INT NOT NULL DEFAULT 1,
    episode_number INT NOT NULL,
    description TEXT,
    video_url VARCHAR(255) NOT NULL,
    thumbnail_url VARCHAR(255),
    duration INT,
    release_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    INDEX idx_movie_id (movie_id),
    INDEX idx_season_episode (season_number, episode_number),
    INDEX idx_release_date (release_date),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. USER INTERACTION & PERSONALIZATION
-- ============================================================================

-- Watchlist (My List)
CREATE TABLE watchlists (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    movie_id INT NOT NULL,
    custom_rating INT CHECK (custom_rating BETWEEN 1 AND 10),
    notes TEXT,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_movie (user_id, movie_id),
    INDEX idx_user_id (user_id),
    INDEX idx_added_at (added_at),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Watch history (Continue Watching)
CREATE TABLE watch_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    episode_id INT NOT NULL,
    device_id VARCHAR(255),
    watched_time INT DEFAULT 0,
    total_duration INT,
    is_finished BOOLEAN DEFAULT FALSE,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (episode_id) REFERENCES episodes(id) ON DELETE CASCADE,
    INDEX idx_user_id_episode_id (user_id, episode_id),
    INDEX idx_user_id (user_id),
    INDEX idx_is_finished (is_finished),
    INDEX idx_updated_at (updated_at),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reviews and Ratings
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    movie_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 10) NOT NULL,
    comment TEXT,
    is_helpful_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_movie_review (user_id, movie_id),
    INDEX idx_movie_id (movie_id),
    INDEX idx_rating (rating),
    INDEX idx_is_helpful_count (is_helpful_count),
    INDEX idx_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. ACCESS CONTROL
-- ============================================================================

-- Content access control (granular permissions)
CREATE TABLE content_access (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subscription_id INT,
    role VARCHAR(50),
    movie_id INT,
    can_view BOOLEAN DEFAULT FALSE,
    can_download BOOLEAN DEFAULT FALSE,
    max_quality ENUM('480p', '720p', '1080p', '4k') DEFAULT '1080p',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    INDEX idx_subscription_id (subscription_id),
    INDEX idx_movie_id (movie_id),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. AUDIT & LOGGING
-- ============================================================================

CREATE TABLE audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    entity_type VARCHAR(100) NOT NULL,
    entity_id INT,
    action VARCHAR(50) NOT NULL,
    old_value JSON,
    new_value JSON,
    description TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_entity_type (entity_type),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 7. VIEWS FOR COMMON QUERIES
-- ============================================================================

-- Active subscriptions view
CREATE OR REPLACE VIEW active_user_subscriptions AS
SELECT 
    us.id,
    us.user_id,
    s.name as subscription_name,
    s.max_quality,
    s.allows_download,
    us.start_date,
    us.end_date,
    us.is_active
FROM user_subscriptions us
JOIN subscriptions s ON us.subscription_id = s.id
WHERE us.deleted_at IS NULL 
  AND us.is_active = TRUE 
  AND us.end_date > NOW();

-- Popular movies view
CREATE OR REPLACE VIEW popular_movies AS
SELECT 
    m.id,
    m.title,
    m.slug,
    m.poster_url,
    m.rating_avg,
    m.rating_count,
    m.type,
    COUNT(DISTINCT wh.user_id) as total_views
FROM movies m
LEFT JOIN episodes e ON m.id = e.movie_id
LEFT JOIN watch_history wh ON e.id = wh.episode_id AND wh.deleted_at IS NULL
WHERE m.deleted_at IS NULL
GROUP BY m.id
ORDER BY total_views DESC;

-- User watch progress view
CREATE OR REPLACE VIEW user_continue_watching AS
SELECT 
    wh.id,
    u.username,
    m.title as movie_title,
    e.episode_number,
    e.season_number,
    wh.watched_time,
    e.duration,
    ROUND((wh.watched_time / e.duration) * 100, 2) as progress_percent,
    wh.updated_at
FROM watch_history wh
JOIN users u ON wh.user_id = u.id
JOIN episodes e ON wh.episode_id = e.id
JOIN movies m ON e.movie_id = m.id
WHERE wh.deleted_at IS NULL 
  AND wh.is_finished = FALSE
ORDER BY wh.updated_at DESC;
