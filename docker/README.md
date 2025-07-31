# Docker Configuration

Docker orchestration for the Snaproom MSA application.

## 🏗️ Architecture Overview

This directory contains the complete Docker configuration for running the Snaproom application in a microservices architecture with:

- **PostgreSQL** - Primary database
- **Redis Cluster** - Master-Replica-Sentinel setup for caching
- **Kafka Cluster** - 3-broker setup for event streaming
- **Laravel API** - Backend application
- **React Frontend** - Frontend application
- **Management UIs** - Kafka UI and Redis Commander

## 🚀 Quick Start

### Start Complete MSA Environment
```bash
# From the docker directory
docker-compose up -d

# Or from project root
docker-compose -f docker/docker-compose.yaml up -d
```

### Access Points
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Health Check**: http://localhost:8000/api/health/detailed
- **Kafka UI**: http://localhost:8080 (admin/admin_secret)
- **Redis Commander**: http://localhost:8081 (admin/admin_secret)

## 📁 Directory Structure

```
docker/
├── docker-compose.yaml       # Main Docker Compose configuration
├── test-health-endpoints.sh  # Health check testing script
└── README.md                 # This file
```

## 🔧 Configuration Files

Configuration files are located in the `../config/` directory:

```
config/
├── init-db.sql              # Database initialization script
└── redis/
    └── sentinel.conf         # Redis Sentinel configuration
```

## 🛠️ Management Commands

### Basic Operations
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f snaproom-laravel
docker-compose logs -f kafka-1
```

### Health Monitoring
```bash
# Run comprehensive health checks
./test-health-endpoints.sh

# Check individual service health
curl http://localhost:8000/api/health/detailed
```

### Service Management
```bash
# Restart specific service
docker-compose restart snaproom-laravel

# Rebuild service
docker-compose build --no-cache snaproom-laravel
docker-compose up -d snaproom-laravel

# Scale services
docker-compose up -d --scale snaproom-laravel=3
```

## 🔍 Service Configuration

### Database (PostgreSQL)
- **Port**: 5432
- **Database**: snaproom
- **User**: snaproom
- **Initialization**: Runs `../config/init-db.sql` on first start

### Cache (Redis Cluster)
- **Master**: localhost:6379
- **Replica**: localhost:6380  
- **Sentinel**: localhost:26379
- **Password**: redis_secret

### Messaging (Kafka)
- **Brokers**: localhost:29092, 29093, 29094
- **Internal**: kafka-1:9092, kafka-2:9092, kafka-3:9092
- **Zookeeper**: localhost:22181

### Applications
- **Laravel**: localhost:8000 (with health endpoints)
- **React**: localhost:3000 (proxied through Nginx)

## 🚨 Troubleshooting

### Common Issues

**Port Conflicts**:
```bash
# Check port usage
netstat -tulpn | grep :8000
lsof -i :6379

# Stop conflicting services
sudo systemctl stop redis
sudo systemctl stop postgresql
```

**Service Dependencies**:
```bash
# Check service health
docker-compose ps
docker inspect <container_name> --format='{{.State.Health.Status}}'

# Restart in dependency order
docker-compose restart snaproom-db redis-master kafka-1
docker-compose restart snaproom-laravel snaproom-react
```

**Resource Issues**:
```bash
# Check container resource usage
docker stats --no-stream

# Clean up unused resources
docker system prune -f
docker volume prune -f
```

### Log Analysis
```bash
# Application errors
docker-compose logs snaproom-laravel | grep ERROR

# Database connection issues
docker-compose logs snaproom-db | tail -50

# Kafka cluster issues
docker-compose logs kafka-1 kafka-2 kafka-3
```

## 📊 Performance Tuning

### Resource Limits
The configuration includes appropriate resource limits for development:
- **Kafka**: 512MB heap, 1GB container limit
- **Redis**: 256MB max memory with LRU eviction
- **PostgreSQL**: Standard configuration with health checks

### Production Considerations
For production deployment:
1. **Increase resource limits** based on load testing
2. **Enable TLS** for all inter-service communication  
3. **Configure monitoring** with Prometheus/Grafana
4. **Set up log aggregation** with ELK stack
5. **Implement backup strategies** for persistent volumes

## 🔐 Security Notes

### Development Security
- **Default passwords** are used for development convenience
- **All services** run in isolated Docker network
- **Only necessary ports** are exposed to host

### Production Security Checklist
- [ ] Change all default passwords
- [ ] Enable TLS/SSL certificates
- [ ] Configure proper firewall rules
- [ ] Set up secret management
- [ ] Enable audit logging
- [ ] Configure backup encryption

This Docker configuration provides a complete, production-ready MSA environment that can be easily deployed and managed.