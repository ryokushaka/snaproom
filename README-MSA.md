# Snaproom MSA Architecture Guide

Microservices Architecture (MSA) implementation with Redis clustering and Kafka event streaming for the Snaproom application.

## 🏗️ MSA Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   React App     │    │   Laravel API    │    │   PostgreSQL    │
│   (Port 3000)   │───▶│   (Port 8000)    │───▶│   (Port 5432)   │
│   Frontend       │    │   Gateway/BFF    │    │   Primary DB    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                    ┌───────────┼───────────┐
                    │           │           │
            ┌───────▼───────┐   │   ┌───────▼───────┐
            │ Redis Cluster │   │   │ Kafka Cluster │
            │ Master/Replica│   │   │ 3 Brokers +  │
            │ + Sentinel    │   │   │ Zookeeper    │
            │ Port 6379-81  │   │   │ Port 9092-94 │
            └───────────────┘   │   └───────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Management UIs      │
                    │ Kafka UI + Redis CMD  │
                    │   Port 8080-8081     │
                    └───────────────────────┘
```

## 🎯 MSA Design Patterns

### Event-Driven Architecture
- **Kafka Topics**: `user-events`, `notification-events`, `audit-events`, `system-events`
- **Event Sourcing**: All domain events captured and streamed
- **CQRS**: Command/Query separation with event replay capability
- **Saga Pattern**: Distributed transaction management across services

### Caching Strategy
- **Redis Master-Replica**: High availability with automatic failover
- **Cache Layers**: API responses, user sessions, frequently accessed data
- **Cache Invalidation**: Event-driven cache updates via Kafka

### Service Communication
- **Synchronous**: REST API for immediate responses
- **Asynchronous**: Kafka events for eventual consistency
- **Circuit Breaker**: Resilience patterns for service failures

## 🚀 Quick Start

### MSA Environment
```bash
# Start complete MSA stack
cd snaproom
make -f Makefile.docker up

# Check all services health
make -f Makefile.docker health-check

# Test specific health endpoints
cd docker && ./test-health-endpoints.sh

# Access management interfaces
# Kafka UI: http://localhost:8080 (admin/admin_secret)
# Redis Commander: http://localhost:8081 (admin/admin_secret)
```

### Access Points
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000/api/
- **Health Check**: http://localhost:8000/api/health
- **Detailed Health**: http://localhost:8000/api/health/detailed
- **Kafka UI**: http://localhost:8080 (admin/admin_secret)
- **Redis Commander**: http://localhost:8081 (admin/admin_secret)

### Service Health Monitoring
```bash
# Check all service health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Individual health checks
curl http://localhost:8000/api/health         # Laravel API Basic
curl http://localhost:8000/api/health/detailed # Laravel API Detailed
curl http://localhost:3000/health             # React App

# Advanced health monitoring
curl http://localhost:8000/api/health/kafka   # Kafka connectivity
curl http://localhost:8000/api/health/redis   # Redis cluster status
curl http://localhost:8000/api/health/database # PostgreSQL status
```

#### Health Check Response Examples

**Basic Health Check**
```json
{
  "status": "healthy",
  "timestamp": "2025-07-31T10:30:00Z",
  "service": "snaproom-laravel",
  "version": "1.0.0"
}
```

**Detailed Health Check**
```json
{
  "status": "healthy",
  "timestamp": "2025-07-31T10:30:00Z",
  "service": "snaproom-laravel",
  "version": "1.0.0",
  "dependencies": {
    "database": { "status": "healthy", "response_time": "12ms" },
    "redis": { "status": "healthy", "cluster_status": "ok" },
    "kafka": { "status": "healthy", "brokers": 3 }
  },
  "metrics": {
    "uptime": 86400,
    "memory_usage": "245MB",
    "cpu_usage": "15%"
  }
}
```

## 🔧 Redis Cluster Configuration

### High Availability Setup
- **Master**: Primary Redis instance (6379)
- **Replica**: Read replica with automatic sync (6380)  
- **Sentinel**: Monitoring and failover management (26379)

### Cache Implementation
```php
// Laravel CacheService usage
$cacheService = app(CacheService::class);

// Cache user data with tags
$cacheService->cacheUser($userId, $userData, 1800);

// Cache API responses
$cacheService->cacheApiResponse('/users', $params, $response, 300);

// Invalidate by tags
$cacheService->invalidateTags(['users']);
```

### Redis Performance Features
- **Connection Pooling**: Optimized connection management
- **Memory Management**: LRU eviction policy with 256MB limit
- **Persistence**: AOF + RDB snapshots for durability
- **Monitoring**: Real-time performance metrics

## ⚡ Kafka Event Streaming

### Topic Architecture
```yaml
Topics:
  user-events:
    partitions: 6
    replication: 3
    use_case: "User lifecycle events"
    
  notification-events:
    partitions: 3
    replication: 3
    use_case: "Real-time notifications"
    
  audit-events:
    partitions: 3
    replication: 3
    use_case: "Compliance and security"
    
  system-events:
    partitions: 3
    replication: 3
    use_case: "System monitoring"
```

### Event Publishing
```php
// Laravel KafkaService usage
$kafkaService = app(KafkaService::class);

// Publish user event
$kafkaService->publishUserEvent('user.created', $userId, $userData);

// Publish notification
$kafkaService->publishNotificationEvent('email', $userId, $emailData);

// Publish audit event
$kafkaService->publishAuditEvent('user.login', $userId, $contextData);
```

### Event Consumption
```bash
# Start Kafka consumer
php artisan kafka:consume user-events notification-events --timeout=120000

# Consumer with custom group
php artisan kafka:consume audit-events --group=audit-processor
```

### Event Schema
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "event": "user.created",
    "user_id": 123,
    "data": { "email": "user@example.com" }
  },
  "service": "snaproom-laravel",
  "version": "1.0.0"
}
```

## 🛠️ Development Workflow

### Local Development
```bash
# Start development environment
docker-compose -f docker-compose.msa.yaml up -d

# Monitor logs
docker-compose -f docker-compose.msa.yaml logs -f snaproom-laravel

# Access service shells
docker exec -it snaproom-laravel /bin/sh
docker exec -it kafka-1 /bin/bash
docker exec -it redis-master redis-cli -a redis_secret
```

### Event-Driven Development
1. **Define Events**: Create event schemas for domain changes
2. **Implement Publishers**: Add event publishing to domain actions
3. **Create Consumers**: Build event handlers for cross-service communication
4. **Test Integration**: Verify event flow and data consistency

### Caching Strategy
1. **Identify Hotspots**: Profile application for caching opportunities
2. **Design Cache Keys**: Consistent naming with proper namespacing
3. **Implement Invalidation**: Event-driven cache updates
4. **Monitor Performance**: Track cache hit rates and response times

## 📊 Monitoring & Observability

### Kafka Monitoring
```bash
# Access Kafka UI
http://localhost:8080

# Cluster information
php artisan tinker
>>> app(KafkaService::class)->getClusterInfo()

# Topic management
docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092
```

### Redis Monitoring
```bash
# Access Redis Commander
http://localhost:8081

# Redis CLI monitoring
docker exec -it redis-master redis-cli -a redis_secret
> INFO stats
> MONITOR

# Cache statistics
php artisan tinker
>>> app(CacheService::class)->getStats()
```

### Health Monitoring
```php
// Health check endpoints
GET /api/health/kafka    // Kafka connectivity
GET /api/health/redis    // Redis connectivity
GET /api/health/full     // Complete system health
```

## 🔒 Security Considerations

### Network Security
- **Container Isolation**: Services communicate via private Docker network
- **Authentication**: Redis password protection, Kafka SASL (production)
- **Encryption**: TLS for inter-service communication (production)

### Event Security
- **Event Validation**: Schema validation for all events
- **Access Control**: Service-based topic access restrictions
- **Audit Trail**: Complete event audit with user attribution

### Cache Security
- **Data Encryption**: Sensitive data encryption at rest
- **Access Control**: Redis AUTH and network isolation
- **TTL Management**: Automatic expiration of sensitive cached data

## 🔄 Scaling Strategies

### Horizontal Scaling
```yaml
# Scale Kafka brokers
kafka-4:
  image: confluentinc/cp-kafka:7.4.0
  environment:
    KAFKA_BROKER_ID: 4
    # ... additional broker configuration

# Scale Redis replicas
redis-replica-2:
  image: redis:7-alpine
  command: redis-server --replicaof redis-master 6379
```

### Vertical Scaling
```yaml
# Resource limits in docker-compose
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
    reservations:
      memory: 1G
      cpus: '0.5'
```

## 🚨 Troubleshooting

### Common Issues

**Kafka Connection Issues**:
```bash
# Check broker status
docker exec kafka-1 kafka-broker-api-versions --bootstrap-server localhost:9092

# Verify topic creation
docker exec kafka-1 kafka-topics --describe --topic user-events --bootstrap-server localhost:9092
```

**Redis Failover Issues**:
```bash
# Check sentinel status
docker exec redis-sentinel redis-cli -p 26379 sentinel masters

# Manual failover
docker exec redis-sentinel redis-cli -p 26379 sentinel failover snaproom-master
```

**Event Processing Issues**:
```bash
# Consumer lag monitoring
docker exec kafka-1 kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group snaproom-laravel

# Reset consumer offset
docker exec kafka-1 kafka-consumer-groups --bootstrap-server localhost:9092 --group snaproom-laravel --reset-offsets --to-earliest --topic user-events --execute
```

### Performance Tuning

**Kafka Optimization**:
- Adjust `batch.size` and `linger.ms` for throughput
- Configure `compression.type=snappy` for efficiency  
- Tune `replica.fetch.max.bytes` for replication

**Redis Optimization**:
- Monitor memory usage with `INFO memory`
- Adjust `maxmemory-policy` based on use case
- Enable `lazy-free` for non-blocking deletes

## 📚 Best Practices

### Event Design
- **Immutable Events**: Never modify published events
- **Schema Evolution**: Backward-compatible event schema changes
- **Idempotency**: Design consumers to handle duplicate events
- **Ordering**: Use partition keys for ordered processing

### Cache Management
- **Cache Hierarchy**: Layer caches by access patterns and TTL
- **Invalidation Strategy**: Event-driven invalidation over TTL expiration
- **Monitoring**: Track cache hit rates and performance impact
- **Fallback Strategy**: Always handle cache misses gracefully

### Operational Excellence
- **Monitoring**: Comprehensive metrics and alerting
- **Documentation**: Keep architecture diagrams and runbooks updated
- **Testing**: Include integration tests for event flows
- **Backup Strategy**: Regular backups of Kafka and Redis data

## 🔧 Configuration Management

### Environment Variables
```bash
# Kafka Configuration
KAFKA_BROKERS=kafka-1:9092,kafka-2:9092,kafka-3:9092
KAFKA_CONSUMER_GROUP_ID=snaproom-laravel

# Redis Configuration  
REDIS_HOST=redis-master
REDIS_PASSWORD=redis_secret
CACHE_DRIVER=redis

# Application Settings
APP_ENV=production
LOG_LEVEL=info
```

### Production Deployment
```yaml
# Production overrides
version: '3.8'
services:
  kafka-1:
    environment:
      KAFKA_LOG_RETENTION_HOURS: 168    # 7 days
      KAFKA_LOG_SEGMENT_BYTES: 1073741824  # 1GB
      
  redis-master:
    command: >
      redis-server 
      --maxmemory 1gb
      --maxmemory-policy allkeys-lru
      --save 900 1 300 10 60 10000
```

This MSA implementation provides a robust foundation for building scalable, event-driven microservices with Redis caching and Kafka messaging.