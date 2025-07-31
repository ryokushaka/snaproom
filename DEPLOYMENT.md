# Snaproom MSA Deployment Guide

Complete deployment guide for the improved MSA environment with Redis clustering and Kafka event streaming.

## 🚀 Quick Deployment

### Start MSA Environment
```bash
# Build and start complete MSA stack
make -f Makefile.msa msa-build
make -f Makefile.msa msa-up

# Verify all services are healthy
make -f Makefile.msa health-check

# Test health endpoints
./test-health-endpoints.sh
```

### Access Points
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Health Check**: http://localhost:8000/api/health/detailed
- **Kafka UI**: http://localhost:8080 (admin/admin_secret)
- **Redis Commander**: http://localhost:8081 (admin/admin_secret)

## 🔍 Health Monitoring

### Health Check Endpoints

**Basic Health Check**
```bash
curl http://localhost:8000/api/health
```
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "service": "snaproom-laravel",
  "version": "1.0.0"
}
```

**Detailed Health Check**
```bash
curl http://localhost:8000/api/health/detailed
```
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "service": "snaproom-laravel",
  "version": "1.0.0",
  "response_time_ms": 45.2,
  "checks": {
    "database": {
      "status": "healthy",
      "response_time_ms": 12.1,
      "connection": "pgsql",
      "host": "snaproom-db"
    },
    "redis": {
      "status": "healthy",
      "response_time_ms": 5.3,
      "host": "redis-master",
      "port": 6379,
      "stats": {
        "version": "7.0.0",
        "memory": "2.5M",
        "clients": 3
      }
    },
    "kafka": {
      "status": "healthy",
      "response_time_ms": 28.7,
      "brokers": "kafka-1:9092,kafka-2:9092,kafka-3:9092",
      "cluster_info": {
        "brokers": [
          {"id": 1, "host": "kafka-1", "port": 9092},
          {"id": 2, "host": "kafka-2", "port": 9092},
          {"id": 3, "host": "kafka-3", "port": 9092}
        ],
        "topics": [
          {"name": "user-events", "partitions": 6},
          {"name": "notification-events", "partitions": 3}
        ]
      }
    },
    "application": {
      "status": "healthy",
      "checks": {
        "storage_writable": true,
        "logs_writable": true,
        "cache_writable": true,
        "env_loaded": true,
        "debug_mode": false
      },
      "environment": "production",
      "php_version": "8.2.0",
      "laravel_version": "12.0.0"
    }
  }
}
```

**Kubernetes-Style Checks**
```bash
# Readiness check
curl http://localhost:8000/api/health/ready

# Liveness check  
curl http://localhost:8000/api/health/live
```

## 🛠️ Implementation Improvements

### 1. Enhanced Health Check System

**✅ Comprehensive Health Controller**
- Database connectivity validation
- Redis cluster health with statistics
- Kafka cluster connectivity and topology
- Application environment validation
- Performance metrics (response times)
- Kubernetes-compatible ready/live endpoints

**✅ Multi-Service Integration**  
- CacheService integration for Redis health
- KafkaService integration for broker health
- Database connection pooling validation
- Storage and filesystem checks

### 2. Docker Infrastructure Enhancements

**✅ Updated Dockerfile**
```dockerfile
# Added Kafka and Redis PHP extensions
RUN apk add --no-cache \
    librdkafka-dev \
    autoconf \
    g++ \
    make

# Install PECL extensions
RUN pecl install redis-6.0.2 rdkafka-6.0.3 \
    && docker-php-ext-enable redis rdkafka
```

**✅ Improved Service Dependencies**
```yaml
# Redis Sentinel with health checks
redis-sentinel:
  depends_on:
    redis-master:
      condition: service_healthy
    redis-replica:
      condition: service_healthy
  healthcheck:
    test: ["CMD", "redis-cli", "-p", "26379", "ping"]

# Kafka initialization with proper dependencies  
kafka-init:
  depends_on:
    kafka-1:
      condition: service_healthy
    kafka-2:
      condition: service_healthy
    kafka-3:
      condition: service_healthy
```

### 3. Application Lifecycle Management

**✅ Uptime Tracking**
```php
// AppServiceProvider automatically tracks application start time
public function boot(): void
{
    if (!Cache::has('app_start_time')) {
        Cache::forever('app_start_time', now());
    }
}
```

**✅ Service Registration**
- CacheService dependency injection
- KafkaService dependency injection  
- Automatic service health validation

## 🔄 Service Communication Flow

### Request Flow
```
1. Client → React Frontend (Port 3000)
2. React → Nginx Proxy → Laravel API (Port 8000)
3. Laravel → PostgreSQL (Port 5432)
4. Laravel → Redis Master (Port 6379) + Replica (Port 6380)
5. Laravel → Kafka Cluster (Ports 9092-9094)
6. Sentinel → Redis Monitoring (Port 26379)
```

### Health Check Flow
```
1. External → /api/health → HealthController
2. HealthController → Database Connection Test
3. HealthController → CacheService → Redis Health
4. HealthController → KafkaService → Broker Health
5. HealthController → Application Environment Check
6. Response → Aggregated Health Status
```

## 🚨 Troubleshooting

### Common Issues After Deployment

**Health Check Failures**
```bash
# Check container status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Check specific service logs
docker logs snaproom-laravel -f
docker logs redis-master -f
docker logs kafka-1 -f

# Test individual components
curl http://localhost:8000/api/health/detailed | jq '.checks'
```

**Service Connectivity Issues**
```bash
# Test network connectivity
docker exec snaproom-laravel ping redis-master
docker exec snaproom-laravel ping kafka-1

# Check environment variables
docker exec snaproom-laravel env | grep -E "(REDIS|KAFKA|DB)"

# Validate PHP extensions
docker exec snaproom-laravel php -m | grep -E "(redis|rdkafka)"
```

**Performance Issues**
```bash
# Monitor health check performance
time curl http://localhost:8000/api/health/detailed

# Check service resource usage
docker stats --no-stream

# Monitor Redis performance
docker exec redis-master redis-cli -a redis_secret INFO stats
```

## 📊 Performance Benchmarks

### Expected Response Times
- **Basic Health Check**: <10ms
- **Detailed Health Check**: <50ms
- **Database Check**: <20ms
- **Redis Check**: <5ms
- **Kafka Check**: <30ms
- **React → Laravel Proxy**: <50ms

### Resource Usage
- **Laravel Container**: ~200MB RAM, <20% CPU
- **Redis Master**: ~50MB RAM, <10% CPU
- **Kafka Broker**: ~400MB RAM, <30% CPU
- **PostgreSQL**: ~100MB RAM, <20% CPU

## 🔐 Security Enhancements

### Network Security
- All services isolated in private Docker network
- Only necessary ports exposed to host
- Service-to-service communication via internal hostnames

### Authentication
- Redis password protection enabled
- Kafka SASL ready for production (currently PLAINTEXT for development)
- Management UI authentication required

### Health Check Security
- Health endpoints provide detailed information in development
- Production should filter sensitive data from health responses
- Consider rate limiting for health endpoints

## 🚀 Production Deployment

### Environment Variables for Production
```bash
# Update these in production
APP_KEY=base64:GENERATE_REAL_APP_KEY_HERE
REDIS_PASSWORD=STRONG_REDIS_PASSWORD
KAFKA_BROKERS=kafka-1:9092,kafka-2:9092,kafka-3:9092

# Database
DB_CONNECTION=pgsql
DB_HOST=snaproom-db
DB_PASSWORD=STRONG_DB_PASSWORD

# Security
APP_DEBUG=false
APP_ENV=production
LOG_LEVEL=info
```

### Production Checklist
- [ ] Generate real APP_KEY with `php artisan key:generate`
- [ ] Use strong passwords for all services
- [ ] Enable Kafka SASL authentication
- [ ] Configure SSL/TLS certificates
- [ ] Set up log aggregation
- [ ] Configure monitoring and alerting
- [ ] Test all health endpoints
- [ ] Verify backup procedures
- [ ] Load test the system

This deployment setup provides a robust, monitorable, and scalable MSA environment ready for production use.