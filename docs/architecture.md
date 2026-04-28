# 🏗️ System Architecture – Movie Streaming Application

## Overview

This document describes the overall architecture of the TDMU Movie Streaming Application, including system components, data flow, and deployment strategy.

---

## 📊 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  • Flutter Mobile App    • Web Browser (React/Next.js)      │
│  • iOS (via Flutter)     • Smart TV Apps (WebView)          │
│  • Android (via Flutter) • Tablet Support                    │
└──────────────────┬──────────────────────────────────────────┘
                   │ HTTPS/WSS
┌──────────────────▼──────────────────────────────────────────┐
│              API GATEWAY & LOAD BALANCER                     │
│  • SSL/TLS Termination  • Rate Limiting  • CORS              │
└──────────────────┬──────────────────────────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼────────┐ ┌──▼──────┐ ┌────▼───────┐
│ NestJS API │ │  Queue  │ │   Cache    │
│  (Backend) │ │(RabbitMQ)│ │   (Redis)  │
└───┬────────┘ └────┬─────┘ └────┬───────┘
    │                │            │
    │                ▼            │
    │          ┌─────────────┐    │
    │          │ Background  │    │
    │          │ Workers     │    │
    │          └─────────────┘    │
    │                │            │
    └────────┬───────┴────────────┘
             │
    ┌────────▼─────────────────┐
    │   DATABASE LAYER         │
    ├──────────────────────────┤
    │ • MariaDB (Primary Data) │
    │ • Read Replicas          │
    │ • Backup Strategy        │
    └──────────────────────────┘
```

---

## 🧩 System Components

### 1. Frontend/Client Applications

**Mobile (Flutter)**
- Single codebase for iOS & Android
- Offline download support
- Native video player integration
- Push notifications
- Device sync

**Web Application (React/Next.js)**
- Responsive design
- Progressive Web App (PWA)
- Browser video player
- Subtitle support

**Smart TV / Set-top Box**
- WebView-based client
- Remote control support
- Voice commands (Alexa, Google Home)

### 2. API Gateway & Load Balancer
```
Function: Single entry point for all client requests
Technology: NGINX or AWS ALB
Features:
- SSL/TLS termination
- Request routing
- Rate limiting
- CORS handling
- Compression (gzip)
```

### 3. Backend API Server

**Framework**: NestJS
- Scalable backend framework
- TypeScript support
- Modular architecture
- Built-in testing framework

**Core Modules**:
```
auth/          → Authentication & authorization
users/         → User management & profiles
movies/        → Content management
episodes/      → Series management
subscriptions/ → Subscription & billing
watchlist/     → User's saved items
reviews/       → Reviews & ratings
streaming/     → Video streaming URLs & DRM
admin/         → Admin dashboard APIs
```

### 4. Caching Layer (Redis)

**Use Cases**:
- Session management
- User authentication tokens
- Popular movies cache
- Search suggestions
- Rate limiting counters
- Real-time notifications

**Configuration**:
```
- Single instance for development
- Cluster for production HA
- TTL-based expiration
- Memory management (LRU eviction)
```

### 5. Message Queue (RabbitMQ / Bull)

**Asynchronous Tasks**:
- Email notifications
- Video transcoding jobs
- Audit log processing
- Analytics data pipeline
- Content recommendations

**Benefits**:
- Decoupled components
- Fault tolerance
- Job retry mechanism
- Rate throttling

### 6. Database Layer

**Primary Database**: MariaDB
- User data
- Content metadata
- Watch history
- Reviews & ratings
- Subscriptions

**Database Strategy**:
```
Master (Write) → Read Replicas (1+)
             ↓
         Backup Server
         (Nightly snapshots)
```

**Optimization**:
- Connection pooling (ProxySQL)
- Query caching
- Slow query logging
- Regular EXPLAIN analysis

### 7. Video Streaming

**Streaming Protocol**: HLS (HTTP Live Streaming)
- Adaptive bitrate streaming
- Multi-quality support (480p, 720p, 1080p, 4K)
- CDN distribution

**Video Storage**: S3-compatible storage
- Original uploads (master copy)
- Transcoded versions (multiple bitrates)
- Thumbnails & previews

**DRM (Digital Rights Management)**:
- Widevine (Chrome, Android)
- FairPlay (iOS, Safari)
- PlayReady (Windows, Xbox)

### 8. Content Delivery Network (CDN)

**Purpose**: Distribute media globally
- CloudFront / Cloudflare / Akamai
- Origin: S3 bucket + HLS manifest
- Cache control headers
- Geo-blocking support

### 9. Search & Analytics

**Search Engine** (Future enhancement):
- ElasticSearch for full-text search
- Faceted search (genres, actors, directors)
- Auto-complete suggestions
- Search analytics

**Analytics Platform** (Future enhancement):
- BigQuery / Snowflake
- User behavior tracking
- Content performance metrics
- Subscription analysis

---

## 🔄 Data Flow Diagrams

### User Registration & Login Flow
```
Client
  │
  ├─→ POST /auth/register {email, password, username}
  │        ↓
  │    Validate input
  │        ↓
  │    Hash password (bcrypt)
  │        ↓
  │    Check email uniqueness
  │        ↓
  │    Create user in DB
  │        ↓
  │    Generate JWT token
  │        ↓
  │    Cache token in Redis
  │        ↓
  │    Return token + user data
  │
  └←─ 201 Created
```

### Content Streaming Flow
```
Client (Play Movie)
  │
  ├─→ GET /movies/{id}/stream
  │        ↓
  │    Verify user subscription
  │        ↓
  │    Check content access
  │        ↓
  │    Get streaming URL (HLS manifest)
  │        ↓
  │    Record device/IP for DRM
  │        ↓
  │    Return signed CDN URL
  │        ↓
  │    Client fetches from CDN
  │        ↓
  │    Video player starts playback
  │
  │ (Every 30 seconds)
  │ POST /watch-history
  │   └─→ Update watched_time
  │
  └─ When finished
    POST /watch-history/finish
      └─→ Mark as_finished = true
```

### Watch History Sync (Multi-device)
```
Device A watches episode
  │
  ├─→ POST /watch-history
  │   {episode_id, watched_time, device_id}
  │        ↓
  │    Update in DB
  │        ↓
  │    Cache in Redis
  │        ↓
  │    Publish to WebSocket channel
  │        ↓
Device B receives update via WebSocket
  └─→ User sync "Continue Watching" across devices
```

### Review & Recommendation Flow
```
User submits review
  │
  ├─→ POST /movies/{id}/reviews
  │   {rating, comment}
  │        ↓
  │    Save to DB
  │        ↓
  │    Invalidate movie cache
  │        ↓
  │    Enqueue analytics job
  │        ↓
Background Worker
  │
  ├─→ Process analytics
  │        ↓
  │    Update aggregated rating
  │        ↓
  │    Trigger recommendation algo
  │        ↓
  │    Cache recommendations
  │
  └─→ User sees recommendations on next login
```

---

## 🔐 Security Architecture

### Authentication & Authorization
```
┌─────────────────────────────┐
│ User Login                  │
├─────────────────────────────┤
│ 1. Verify credentials       │
│ 2. Generate JWT token       │
│ 3. Set exp: 24 hours        │
│ 4. Store in Redis           │
│ 5. Send to client           │
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ Protected Requests          │
├─────────────────────────────┤
│ Bearer: Authorization header│
│ Middleware verifies JWT     │
│ Extract user from token     │
│ Apply role-based rules      │
└─────────────────────────────┘
```

### Data Protection
- **In Transit**: HTTPS/TLS 1.3
- **At Rest**: Database encryption
- **Passwords**: Bcrypt (salt rounds: 12)
- **Sensitive Data**: Hashed in audit logs
- **API Keys**: Rotate quarterly

### DDoS & Rate Limiting
```
┌─────────────────────────────┐
│ Request arrives             │
├─────────────────────────────┤
│ Check rate limit in Redis   │
│ IP-based: 100 req/min       │
│ User-based: 500 req/min     │
│ Premium: 1000 req/min       │
└─────────────────────────────┘
         │
    ┌────┴────┐
    │          │
  ✓ Pass   ✗ Reject
    │       (429 Too Many)
    ▼
  Process
```

---

## 📈 Scalability Strategy

### Horizontal Scaling
```
Load Balancer (NGINX)
    │
    ├→ API Server 1
    ├→ API Server 2
    ├→ API Server 3
    └→ API Server N
```

### Database Scaling
```
Write Master
    │
    ├→ Read Replica 1
    ├→ Read Replica 2
    └→ Read Replica N
```

### Caching Strategy
```
Cache-Aside Pattern:
┌─────────────┐
│ Get Request │
└──────┬──────┘
       │
   ┌───▼────┐
   │ Redis? │
   └───┬────┘
       │
   ┌───▼───────────┐
   │ Yes │ No      │
   │     └─→ DB    │
   │         ↓     │
   │    Cache+Return
   └─────────────┘
```

### Content Distribution
```
Global CDN Network
  ├→ North America PoP
  ├→ Europe PoP
  ├→ Asia Pacific PoP
  └→ South America PoP
  
Origin Server (S3 + CloudFront)
```

---

## 🚀 Deployment Architecture

### Environment Strategy
```
Development
    ↓
Testing/QA
    ↓
Staging (Production-like)
    ↓
Production
```

### Production Deployment (AWS Example)
```
┌─────────────────────────────────┐
│  CloudFront (CDN)               │
├─────────────────────────────────┤
│  ALB (Application Load Balancer)│
├─────────────────────────────────┤
│  ECS Cluster (NestJS)           │
│  • 3+ instances for HA          │
│  • Auto-scaling group           │
│  • Health checks                │
├─────────────────────────────────┤
│  RDS Aurora MySQL               │
│  • Primary + 2 read replicas    │
│  • Automated backups            │
│  • Point-in-time recovery       │
├─────────────────────────────────┤
│  ElastiCache (Redis)            │
│  • Multi-AZ cluster             │
│  • Automatic failover           │
├─────────────────────────────────┤
│  S3 (Video Storage)             │
│  • Versioning enabled           │
│  • Cross-region replication     │
├─────────────────────────────────┤
│  Monitoring & Logging           │
│  • CloudWatch                   │
│  • DataDog / New Relic          │
│  • ELK Stack (logs)             │
└─────────────────────────────────┘
```

---

## 🔍 Monitoring & Observability

### Key Metrics
```
Application:
  - API response time (p50, p95, p99)
  - Request rate (req/sec)
  - Error rate (5xx errors)
  - Auth failure rate

Infrastructure:
  - CPU utilization
  - Memory usage
  - Disk I/O
  - Network bandwidth

Database:
  - Query execution time
  - Slow queries
  - Connections used
  - Replication lag

Streaming:
  - Video buffer ratio
  - Start-up time
  - Quality switches
  - Playback failures
```

### Alerting Rules
```
- API response time > 1s (alert)
- Error rate > 1% (critical)
- DB replication lag > 10s (alert)
- Cache hit rate < 70% (warning)
- Disk usage > 85% (alert)
```

---

## 🧹 Maintenance Strategy

### Daily
- Monitor error rates
- Check database performance
- Verify backup completion
- Review security logs

### Weekly
- Update content recommendations
- Analyze user behavior
- Performance tuning
- Cache optimization

### Monthly
- Database optimization (ANALYZE, OPTIMIZE)
- Security patches
- Dependency updates
- Capacity planning

### Quarterly
- Full security audit
- Load testing
- Disaster recovery drill
- Database migration testing

---

## 🔄 CI/CD Pipeline

```
Developer Push
    ↓
GitHub Actions Trigger
    ├─→ Lint & Format Check
    ├─→ Unit Tests
    ├─→ Integration Tests
    ├─→ Security Scan (SonarQube)
    ├─→ Build Docker Image
    ├─→ Push to Registry
    ├─→ Deploy to Staging
    ├─→ Smoke Tests
    └─→ Manual Approval
         ↓
    Deploy to Production
```

---

## 📊 Architecture Comparison: MVP vs Production

| Feature | MVP | Production |
|---------|-----|-----------|
| API Servers | 1 | 3-5 (Auto-scaling) |
| Database | Single instance | Master + Read replicas |
| Cache | Optional | Redis cluster |
| CDN | Optional | Required |
| Monitoring | Basic logs | Comprehensive (DataDog) |
| DRM | No | Yes (Widevine + FairPlay) |
| Regions | 1 | 3+ (Global) |
| Backup | Manual | Automated + DR tests |
| Load Balancer | None | NGINX/ALB |

---

## 🎯 Performance Targets

- **API Response Time**: < 200ms (p95)
- **Video Start Time**: < 2 seconds
- **Search Response**: < 100ms
- **Database Query**: < 50ms
- **Cache Hit Rate**: > 80%
- **System Uptime**: 99.95% (4.38 hours/year downtime)
- **Concurrent Users**: 10,000+ simultaneous streams

---

## 📌 Future Enhancements

1. **AI/ML Features**
   - Content recommendations
   - Anomaly detection
   - Fraud detection

2. **Real-time Features**
   - WebSocket for notifications
   - Live streaming support
   - Real-time chat

3. **Advanced Analytics**
   - User segmentation
   - Cohort analysis
   - Churn prediction

4. **Global Expansion**
   - Multi-region deployment
   - Multi-currency support
   - Local content partnerships

---

## 📚 Related Documentation

- [Database Design](./database-design.md)
- [API Specification](./api-specification.md)
- [System Overview](./system-overview.md)
- [Deployment Guide](./deployment-guide.md) (to be created)
- [Security Guide](./security-guide.md) (to be created)
