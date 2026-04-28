# 📚 TDMU Movie Streaming Application – Complete Documentation

Welcome! This folder contains all the documentation for the TDMU Movie Streaming Application – a production-ready movie streaming platform supporting movies, series, multi-device sync, and subscription management.

---

## 📖 Documentation Overview

### 🔧 Quick Navigation

| Document | Purpose | Audience |
|----------|---------|----------|
| [System Overview](./system-overview.md) | Project introduction & features | Everyone |
| [Database Design](./database-design.md) | Complete database schema | Backend/DBAs |
| [API Specification](./api-specification.md) | REST API endpoints & examples | Frontend/Backend developers |
| [System Architecture](./architecture.md) | Infrastructure & deployment | DevOps/Architects |
| [schema-improved.sql](./schema-improved.sql) | Executable SQL schema | DBAs/Backend |

---

## 🎯 What is This Project?

**TDMU Movie Streaming Application** is a scalable, multi-platform streaming service that supports:

✅ **Movies & Series** - Comprehensive content management  
✅ **Multi-Device Streaming** - Watch on phone, tablet, TV, browser  
✅ **Subscriptions** - Free, Basic, Premium tiers with different features  
✅ **Personalization** - Watch history, watchlist, recommendations, reviews  
✅ **Enterprise Grade** - Audit logging, access control, security  

---

## 📚 Detailed Documentation

### 1. 🏢 System Overview (`system-overview.md`)

**What's Inside:**
- Project introduction & goals
- Key features (client-side, admin dashboard, advanced features)
- Technology stack
- Tech stack recommendations

**Best For:** Understanding project scope, what features exist

**Read This First** if you're new to the project!

---

### 2. 🗄️ Database Design (`database-design.md`)

**What's Inside:**
- Complete database schema (18 tables)
- User management with multi-device support
- Subscription & access control system
- Content management (movies, actors, directors, episodes)
- Personalization features (watchlist, reviews, history)
- Audit logging & soft delete

**Key Features:**
```
✅ Normalized actor/director management
✅ Multi-tier subscription system
✅ Soft delete for audit trail
✅ Multi-device sync support
✅ Comprehensive audit logging
✅ Optimized indexing
✅ Database views for common queries
```

**Tables Included:**
- users, user_devices
- subscriptions, user_subscriptions, content_access
- movies, genres, actors, directors, episodes
- movie_genres, movie_actors, movie_directors
- watchlists, watch_history, reviews
- audit_logs
- streaming_servers

**Best For:** Backend developers, database architects, DBAs

**SQL Schema File:** [schema-improved.sql](./schema-improved.sql) - Ready to import!

---

### 3. 🚀 API Specification (`api-specification.md`)

**What's Inside:**
- Complete REST API documentation
- 40+ endpoints across all features
- Request/response examples with JSON
- Error handling & status codes
- Rate limiting strategy
- Security best practices

**API Sections:**
- 🔑 Authentication (register, login, refresh, logout)
- 👤 User Management (profile, devices)
- 🎬 Movies & Content (list, search, popular, episodes)
- ⭐ Watchlist & Favorites
- ⏯️ Watch History (continue watching)
- 💬 Reviews & Ratings
- 💳 Subscriptions (plans, active subscription, subscribe)
- 👥 Admin Operations (CRUD movies, audit logs)

**Example Endpoint:**
```json
GET /movies?page=1&limit=20&sort=-rating_avg&filter[genre]=action
Response: 
{
  "data": [{movie_details}],
  "pagination": {page: 1, total_pages: 5, total_count: 100}
}
```

**Best For:** Frontend developers, API integrators, mobile developers

**Features Documented:**
- ✅ Pagination, sorting, filtering
- ✅ Request/response examples
- ✅ Error codes and messages
- ✅ Rate limiting
- ✅ Search parameters

---

### 4. 🏗️ System Architecture (`architecture.md`)

**What's Inside:**
- High-level system architecture diagram
- Component breakdown:
  - Frontend (Flutter, React, Smart TV)
  - API Gateway & Load Balancer
  - Backend (NestJS)
  - Database (MariaDB + replicas)
  - Cache (Redis)
  - Message Queue (RabbitMQ)
  - Video Streaming (HLS/CDN)
  - Search & Analytics

**Data Flows Documented:**
- User registration & login
- Video streaming & playback
- Multi-device watch history sync
- Review & recommendation pipeline
- Subscription management

**Security Architecture:**
- Authentication & JWT
- Authorization & RBAC
- DDoS protection & rate limiting
- Data encryption in transit & at rest

**Scalability Strategy:**
- Horizontal scaling of API servers
- Database replication strategy
- Caching layers
- CDN distribution

**Deployment Architecture:**
- AWS deployment example
- CI/CD pipeline
- Monitoring & observability
- Production vs MVP comparison

**Best For:** DevOps engineers, system architects, infrastructure teams

---

### 5. 🔧 SQL Schema File (`schema-improved.sql`)

**What's Inside:**
- Complete MariaDB schema (ready to execute)
- 18 tables with full definitions
- Foreign keys & constraints
- Comprehensive indexes
- Database views (3 pre-built views)
- Comments explaining each table

**How to Use:**
```bash
# Import into MariaDB
mysql -u root -p your_database < schema-improved.sql

# Or copy-paste into any SQL IDE
```

**Best For:** Database setup, development, testing

---

## 🚀 Getting Started

### Step 1: Understand the Project
👉 Read [System Overview](./system-overview.md) (5 min)

### Step 2: Check the Database Design
👉 Read [Database Design](./database-design.md) (15 min)
   - Understand tables and relationships
   - Review data model summary

### Step 3: Review API Specifications
👉 Read [API Specification](./api-specification.md) (15 min)
   - Understand endpoints
   - Check request/response formats
   - Review error handling

### Step 4: Study Architecture
👉 Read [System Architecture](./architecture.md) (10 min)
   - Understand system components
   - Review deployment strategy
   - Check scalability approach

### Step 5: Set Up Database
```bash
# Create database
mysql -u root -p
> CREATE DATABASE movie_app;

# Import schema
mysql -u root -p movie_app < docs/schema-improved.sql

# Verify
mysql -u root -p -e "USE movie_app; SHOW TABLES;"
```

---

## 🎓 Learning Paths

### For Backend Developers
1. Read: System Overview → API Specification → Database Design
2. Activities:
   - Study the database schema
   - Plan API implementation
   - Review error handling patterns
   - Check authentication flow

### For Frontend Developers
1. Read: System Overview → API Specification
2. Activities:
   - Review API endpoints
   - Check request/response formats
   - Study authentication flow
   - Plan UI components

### For DevOps / Infrastructure
1. Read: System Architecture → Database Design
2. Activities:
   - Plan deployment strategy
   - Set up monitoring
   - Configure load balancer
   - Plan backup strategy

### For Database Administrators
1. Read: Database Design → schema-improved.sql
2. Activities:
   - Import schema
   - Review indexing strategy
   - Plan backup/recovery
   - Test replication setup

### For Project Managers
1. Read: System Overview → Architecture (high-level only)
2. Focus on:
   - Feature completeness
   - Scalability design
   - Security considerations

---

## 💡 Key Design Decisions

### 1. Database Normalization
**Why?** Separate tables for actors/directors eliminates redundancy and enables efficient queries.

### 2. Soft Delete Pattern
**Why?** Allows data recovery, enables audit trails, and complies with data retention policies.

### 3. Multi-Device Sync
**Why?** Users can start watching on phone and continue on TV without losing progress.

### 4. Subscription System
**Why?** Supports multiple monetization tiers and granular content access control.

### 5. Comprehensive Indexing
**Why?** Ensures fast queries even with millions of records.

### 6. Audit Logging
**Why?** Tracks all changes for compliance, security, and troubleshooting.

---

## 📊 Database Schema Statistics

```
Total Tables: 18
Total Relationships: 12 foreign keys
Total Indexes: 30+
Key Features:
  • Soft delete on 8 core tables
  • 3 optimized database views
  • Composite indexes for common queries
  • Support for 1M+ users
  • Multi-regional ready
```

---

## 🔒 Security Features

✅ JWT-based authentication (24-hour expiry)
✅ Bcrypt password hashing (salt rounds: 12)
✅ Role-based access control (User, VIP, Admin)
✅ Granular content access permissions
✅ IP address & device tracking
✅ Comprehensive audit logging
✅ Soft delete for data recovery
✅ SQL injection prevention (parameterized queries)
✅ HTTPS/TLS 1.3 for all communications
✅ Rate limiting (100-1000 req/min per tier)

---

## 📈 Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| API Response | < 200ms (p95) | Including DB queries |
| Video Start | < 2s | After click to play |
| Search | < 100ms | Full-text search |
| DB Query | < 50ms | Typical queries |
| Cache Hit Rate | > 80% | Redis cache |
| System Uptime | 99.95% | ~4.38 hrs/year downtime |
| Concurrent Users | 10,000+ | Simultaneous streams |

---

## 🔄 Update Log

### Version 1.0 - Initial Release
- ✅ Complete database schema
- ✅ API specification (40+ endpoints)
- ✅ System architecture documentation
- ✅ Production-ready design
- ✅ Subscription system
- ✅ Multi-device sync
- ✅ Audit logging

---

## ❓ FAQ

### Q: Is this ready for production?
**A:** Yes! The schema is production-ready with enterprise features like audit logging, soft delete, and comprehensive indexing.

### Q: How many concurrent users can the system support?
**A:** Design targets 10,000+ concurrent streams with proper horizontal scaling and database replication.

### Q: What database should we use?
**A:** MariaDB 10.5+ recommended. MySQL 8.0+ is also compatible (minor tweaks needed).

### Q: Can we scale this system?
**A:** Yes! Architecture includes horizontal scaling of API servers, database replication, caching layers, and CDN for media.

### Q: How do we handle multi-device streaming?
**A:** The `user_devices` table tracks devices, and `watch_history` includes device_id for seamless sync across platforms.

### Q: What's the subscription model?
**A:** Multi-tier system (Free, Basic, Premium) with subscription plans having different limits:
- Max devices (1-4 concurrent streams)
- Quality (480p - 4K)
- Download permissions
- Offline viewing

---

## 🤝 Contributing

To update documentation:
1. Review the existing structure
2. Keep formatting consistent
3. Use examples where helpful
4. Update related documents

---

## 📞 Questions?

If you have questions about the design:
1. Check the relevant documentation file
2. Review the data model diagrams
3. Check the FAQ section above

---

## 📜 License

This documentation is part of the TDMU Movie Streaming Application project.

---

## 🎬 Next Steps

→ **For Developers**: Start with [API Specification](./api-specification.md)  
→ **For DBAs**: Start with [Database Design](./database-design.md)  
→ **For DevOps**: Start with [System Architecture](./architecture.md)  
→ **For Everyone**: Start with [System Overview](./system-overview.md)  

Happy building! 🚀
