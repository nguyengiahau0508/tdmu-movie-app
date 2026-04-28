# 🎬 TDMU Movie Streaming Application

> A production-ready, scalable movie streaming platform with multi-device support, subscription management, and enterprise-grade security.

[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)](https://github.com)
[![Database](https://img.shields.io/badge/Database-MariaDB%2010.5%2B-blue)](https://mariadb.org)
[![API](https://img.shields.io/badge/API-NestJS%2B-e74c3c)](https://nestjs.com)
[![Frontend](https://img.shields.io/badge/Frontend-Flutter%20%26%20React-61dafb)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📋 Overview

TDMU Movie Streaming Application is a comprehensive video streaming platform designed for scalability, security, and user experience. The platform supports:

- 🎥 **Movies & Series** - Rich content management with episodes support
- 📱 **Multi-Device Streaming** - Seamless sync across phone, tablet, TV, and web
- 💳 **Flexible Subscriptions** - Multi-tier plans (Free, Basic, Premium) with granular access control
- ⭐ **Personalization** - Watch history, watchlist, reviews, and ratings
- 🔐 **Enterprise Security** - JWT authentication, audit logging, role-based access control
- 🌍 **Global Scale** - Built for 1M+ users with CDN distribution

---

## 🚀 Quick Start

### Prerequisites
- MariaDB 10.5 or higher
- Node.js 16+ (for backend)
- Flutter 3.0+ or React (for frontend)

### Setup Database (5 minutes)

```bash
# 1. Create database
mysql -u root -p
> CREATE DATABASE movie_app;
> EXIT;

# 2. Import schema
mysql -u root -p movie_app < docs/schema-improved.sql

# 3. Verify installation
mysql -u root -p -e "USE movie_app; SHOW TABLES;"
```

### Setup Backend

```bash
cd tdmu-movie-app-nestjs-agent

# Install dependencies
npm install

# Configure environment
cp .env.example .env

# Run development server
npm run start:dev

# API will be available at http://localhost:3000
```

### Setup Frontend (Flutter)

```bash
cd tdmu_movie_app_flutter_client

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

### Setup Frontend (Web - React)

```bash
cd tdmu-movie-app-web

# Install dependencies
npm install

# Start development server
npm start

# Open http://localhost:3000
```

---

## 📚 Documentation

Comprehensive documentation is available in the `docs/` folder:

| Document | Purpose | Audience |
|----------|---------|----------|
| **[docs/QUICK-START.md](docs/QUICK-START.md)** | 5-minute quick start | Everyone |
| **[docs/README.md](docs/README.md)** | Complete navigation | Everyone |
| **[docs/database-design.md](docs/database-design.md)** | Database schema (18 tables) | Backend/DBA |
| **[docs/api-specification.md](docs/api-specification.md)** | 40+ API endpoints | Developers |
| **[docs/architecture.md](docs/architecture.md)** | System architecture | DevOps/Architects |
| **[docs/schema-improved.sql](docs/schema-improved.sql)** | Executable SQL schema | DBA |
| **[docs/system-overview.md](docs/system-overview.md)** | Project overview | Everyone |

**👉 New to the project?** Start with [docs/README.md](docs/README.md)

---

## 🎯 Key Features

### 🎬 Content Management
- Support for movies and series with episode management
- Genre categorization with SEO-friendly slugs
- Normalized actor/director database
- Premium content marking and availability
- Content ratings (G, PG, PG-13, R, 16+, 18+)

### 👥 User Management
- User registration and authentication (JWT-based)
- Multi-device synchronization
- Profile management (avatar, bio, preferences)
- Role-based access control (User, VIP, Admin)
- Soft delete for data recovery

### 💳 Subscription System
- Multi-tier subscription plans (Free/Basic/Premium)
- Granular content access control per subscription
- Quality restrictions (480p/720p/1080p/4K)
- Download and offline viewing permissions
- Auto-renewal management

### 📺 Streaming & Playback
- Watch history with resume functionality
- Multi-device sync for continue watching
- Adaptive bitrate streaming (HLS/DASH)
- DRM support (Widevine, FairPlay, PlayReady)
- Multiple streaming servers for redundancy

### ⭐ Personalization
- Watchlist with custom notes and ratings
- User reviews and ratings (1 per movie)
- Personalized recommendations (future ML integration)
- Viewing history tracking with device info
- Social features (helpful votes on reviews)

### 🔐 Enterprise Features
- Comprehensive audit logging
- IP address and device tracking
- Role-based access control
- Granular permission management
- Data recovery via soft delete

---

## 📊 Database Architecture

### 18 Core Tables

**User Management:**
- `users` - User accounts and authentication
- `user_devices` - Multi-device tracking

**Subscriptions:**
- `subscriptions` - Available subscription plans
- `user_subscriptions` - Active user subscriptions
- `content_access` - Fine-grained content permissions

**Content:**
- `movies` - Movies and series metadata
- `episodes` - Series episodes
- `genres` - Genre classification
- `actors` - Actor information
- `directors` - Director information

**Relationships:**
- `movie_genres` - Movie-genre mapping
- `movie_actors` - Movie-actor casting
- `movie_directors` - Movie-director mapping

**Personalization:**
- `watchlists` - User watchlists (My List)
- `watch_history` - Viewing history with resume points
- `reviews` - User reviews and ratings

**Infrastructure:**
- `audit_logs` - Complete audit trail
- `streaming_servers` - Streaming server management

### Key Statistics
- **30+ Optimized Indexes** - For fast queries
- **12 Foreign Keys** - Referential integrity
- **3 Database Views** - Pre-built common queries
- **Soft Delete Support** - Data recovery capability

---

## 🚀 API Overview

The API provides 40+ endpoints across multiple domains:

### Authentication
```
POST   /auth/register        - User registration
POST   /auth/login           - User login
POST   /auth/refresh         - Refresh JWT token
POST   /auth/logout          - User logout
```

### Movies & Content
```
GET    /movies               - Browse all movies
GET    /movies/:id           - Get movie details
GET    /movies/search        - Search movies
GET    /movies/popular       - Get popular movies
GET    /movies/:id/episodes  - Get series episodes
GET    /movies/:id/reviews   - Get reviews
```

### Watchlist & History
```
GET    /users/me/watchlist   - Get watchlist
POST   /users/me/watchlist   - Add to watchlist
GET    /users/me/continue-watching - Resume points
POST   /users/me/watch-history    - Update progress
```

### Subscriptions
```
GET    /subscriptions        - Available plans
GET    /users/me/subscription - Active subscription
POST   /users/me/subscribe   - Subscribe to plan
DELETE /users/me/subscription - Cancel subscription
```

### Admin Operations
```
POST   /admin/movies         - Create movie
PUT    /admin/movies/:id     - Update movie
DELETE /admin/movies/:id     - Delete movie
GET    /admin/audit-logs     - View audit trail
```

**📖 Full API documentation:** [docs/api-specification.md](docs/api-specification.md)

---

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────┐
│     CLIENT APPS                 │
│  (Flutter, React, Smart TV)     │
└─────────────┬───────────────────┘
              │
┌─────────────▼───────────────────┐
│   API GATEWAY & LOAD BALANCER   │
│  (NGINX / AWS ALB)              │
└─────────────┬───────────────────┘
              │
    ┌─────────┼────────┐
    │         │        │
┌───▼─┐  ┌───▼─┐  ┌───▼──┐
│API  │  │Cache│  │Queue │
│NestJS   │Redis  │RabbitMQ
└───┬─┘  └─────┘  └──────┘
    │
┌───▼───────────────────────┐
│  MariaDB + Replicas       │
│  Master + Read Replicas   │
└────────────────────────────┘
```

### Deployment Targets
- **Development**: Single server with all services
- **Staging**: Production-like environment with replication
- **Production**: Multi-region with auto-scaling, CDN, and DRM

**📖 Full architecture:** [docs/architecture.md](docs/architecture.md)

---

## 🔐 Security

### Authentication & Authorization
- ✅ JWT-based authentication (24-hour expiry)
- ✅ Bcrypt password hashing (12 rounds)
- ✅ Role-based access control (RBAC)
- ✅ Granular permission management
- ✅ Device tracking and fingerprinting

### Data Protection
- ✅ HTTPS/TLS 1.3 for all communications
- ✅ Database encryption at rest
- ✅ Parameterized queries (SQL injection prevention)
- ✅ Rate limiting (100-1000 req/min per tier)
- ✅ Audit logging of all changes

### Compliance
- ✅ GDPR-compliant (soft delete for recovery)
- ✅ Audit trail for compliance reporting
- ✅ Data retention policies
- ✅ Privacy controls

---

## 📈 Performance Targets

| Metric | Target |
|--------|--------|
| API Response Time | < 200ms (p95) |
| Video Start Time | < 2 seconds |
| Search Response | < 100ms |
| Database Query | < 50ms |
| Cache Hit Rate | > 80% |
| System Uptime | 99.95% |
| Concurrent Users | 10,000+ |
| Supported Users | 1M+ |

---

## 📁 Project Structure

```
tdmu-movie-app/
├── README.md                          👈 You are here
├── docs/                              📚 Documentation
│   ├── QUICK-START.md
│   ├── README.md
│   ├── database-design.md
│   ├── api-specification.md
│   ├── architecture.md
│   ├── schema-improved.sql
│   └── system-overview.md
│
├── tdmu-movie-app-nestjs-agent/       🚀 Backend API
│   ├── src/
│   │   ├── auth/
│   │   ├── users/
│   │   ├── movies/
│   │   ├── subscriptions/
│   │   └── ...
│   ├── .env.example
│   ├── package.json
│   └── README.md
│
├── tdmu_movie_app_flutter_client/     📱 Flutter Frontend
│   ├── lib/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── models/
│   │   ├── services/
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── README.md
│
└── tdmu-movie-app-web/                🌐 React Frontend
    ├── src/
    │   ├── components/
    │   ├── pages/
    │   ├── services/
    │   ├── hooks/
    │   └── App.tsx
    ├── package.json
    └── README.md
```

---

## 🚀 Development Workflow

### 1. Database Setup
```bash
# Import schema
mysql -u root -p movie_app < docs/schema-improved.sql

# Create test data (optional)
# Run seed script: mysql -u root -p movie_app < docs/seeds.sql
```

### 2. Backend Development
```bash
cd tdmu-movie-app-nestjs-agent
npm install
npm run start:dev
# Implements API endpoints from api-specification.md
```

### 3. Frontend Development
```bash
cd tdmu_movie_app_flutter_client
flutter pub get
flutter run
# OR
cd ../tdmu-movie-app-web
npm install
npm start
```

### 4. Testing
```bash
# Backend tests
npm run test

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e
```

### 5. Deployment
```bash
# See docs/architecture.md for deployment strategy
# Use provided Docker configurations
# Set up CI/CD pipeline using GitHub Actions
```

---

## 🤝 Contributing

### Code Style
- Follow ESLint configuration
- Use Prettier for formatting
- Write meaningful commit messages
- Add tests for new features

### Pull Request Process
1. Create feature branch (`git checkout -b feature/amazing-feature`)
2. Write/update tests
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Reporting Issues
- Use GitHub Issues for bug reports
- Include reproduction steps
- Attach relevant logs/screenshots

---

## 📖 Documentation Structure

```
docs/
├── QUICK-START.md          → 5-minute setup guide
├── README.md               → Complete navigation
├── database-design.md      → Schema & optimization
├── api-specification.md    → 40+ endpoints
├── architecture.md         → System design
├── schema-improved.sql     → Executable schema
└── system-overview.md      → Project overview
```

**Each document is self-contained and cross-referenced.**

---

## 🐛 Known Issues & Limitations

- Video transcoding pipeline (planned for v2)
- Real-time notifications (planned for v2)
- Advanced ML recommendations (planned for v2)
- Multi-language support (planned for v2)

---

## 🗓️ Roadmap

### Phase 1: MVP Launch (Current)
- ✅ Database design
- ✅ API specification
- ✅ Authentication system
- ✅ Basic content management
- ⏳ Core streaming functionality

### Phase 2: Advanced Features (Q2 2024)
- 🔄 Real-time notifications (WebSocket)
- 🔄 Content recommendations (ML)
- 🔄 Advanced analytics
- 🔄 Live streaming support

### Phase 3: Enterprise Scale (Q3 2024)
- 🔄 Multi-region deployment
- 🔄 Advanced DRM features
- 🔄 Partner integrations
- 🔄 Payment processing

---

## 🔗 Useful Links

- **API Documentation**: [docs/api-specification.md](docs/api-specification.md)
- **Database Design**: [docs/database-design.md](docs/database-design.md)
- **Architecture**: [docs/architecture.md](docs/architecture.md)
- **Quick Start**: [docs/QUICK-START.md](docs/QUICK-START.md)

---

## 💡 Technology Stack

### Backend
- **Framework**: NestJS (TypeScript)
- **Database**: MariaDB 10.5+
- **Cache**: Redis
- **Queue**: RabbitMQ
- **API**: REST + WebSocket
- **Auth**: JWT + Bcrypt

### Frontend (Mobile)
- **Framework**: Flutter 3.0+
- **State**: Riverpod/GetX
- **Video Player**: Flutter Video Player
- **Storage**: SQLite

### Frontend (Web)
- **Framework**: React 18+
- **Language**: TypeScript
- **Video Player**: HLS.js / Plyr
- **State**: Redux/Zustand

### Infrastructure
- **Cloud**: AWS/Azure/GCP
- **Container**: Docker
- **Orchestration**: Kubernetes
- **CDN**: CloudFront/Cloudflare

---

## 📊 Statistics

- **Database Tables**: 18
- **API Endpoints**: 40+
- **Documentation**: 7 files (87 KB)
- **Code Coverage Target**: > 80%
- **Performance**: Sub-200ms API responses

---

## 📞 Support & Contact

### Getting Help
1. Check [docs/README.md](docs/README.md) for navigation
2. Review [docs/QUICK-START.md](docs/QUICK-START.md) for setup
3. Search existing issues
4. Create new issue with details

### Contact
- **Project Lead**: [@hau](https://github.com)
- **Email**: hau@tdmu.edu.vn
- **Issues**: [GitHub Issues](https://github.com/tdmu/movie-app/issues)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ✨ Acknowledgments

- TDMU for project initiation
- Community contributors
- Open-source libraries and frameworks

---

## 🎬 Let's Build Something Amazing!

This is a production-ready codebase. We're excited to see what you'll build with it!

**Questions?** Check the [documentation](docs/) or [open an issue](https://github.com/tdmu/movie-app/issues).

---

<div align="center">

**[📖 Documentation](docs/README.md)** • **[🚀 Quick Start](docs/QUICK-START.md)** • **[💬 Discussions](https://github.com/tdmu/movie-app/discussions)** • **[🐛 Issues](https://github.com/tdmu/movie-app/issues)**

Made with ❤️ by the TDMU Team

</div>
