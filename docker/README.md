# Docker Configuration

Docker orchestration for the Snaproom MSA application with separate repository architecture.

## 🏗️ Architecture Overview

This directory contains the complete Docker configuration for running the Snaproom application in a microservices architecture with:

- **PostgreSQL** - Primary database
- **Redis Cluster** - Master-Replica-Sentinel setup for caching
- **Kafka Cluster** - 3-broker setup for event streaming
- **Laravel API** - Backend application (separate repository)
- **React Frontend** - Frontend application (separate repository)
- **Management UIs** - Kafka UI and Redis Commander

## 📋 Prerequisites

### Repository Setup
Since services are managed as separate repositories, you need to clone them alongside this main repository:

```bash
# Clone main repository
git clone https://github.com/ryokushaka/snaproom.git
cd snaproom

# Clone service repositories (alongside main repo)
cd ..
git clone https://github.com/ryokushaka/snaproom-react.git
git clone https://github.com/ryokushaka/snaproom-laravel.git
git clone https://github.com/ryokushaka/snaproom-infrastructure.git

# Directory structure should look like:
# workspace/
# ├── snaproom/                    # Main orchestration repository
# ├── snaproom-react/              # Frontend repository
# ├── snaproom-laravel/            # Backend repository
# └── snaproom-infrastructure/     # Infrastructure repository
```

## 🚀 Quick Start

### Start Complete MSA Environment
```bash
# From the snaproom/docker directory
cd snaproom/docker
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

## 📁 Repository Structure

```
workspace/
├── snaproom/                    # 🎯 Main orchestration repository
│   ├── docker/                 # Docker configurations
│   ├── config/                 # Shared configurations
│   ├── scripts/                # Management scripts
│   └── *.md                   # Documentation
├── snaproom-react/             # 🎯 Frontend repository
├── snaproom-laravel/           # 🎯 Backend repository
└── snaproom-infrastructure/    # 🎯 Infrastructure repository
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

### Repository Setup Issues

**Missing Service Repositories**:
```bash
# Check if service repositories exist
ls -la ../snaproom-react
ls -la ../snaproom-laravel

# If missing, clone them:
cd ..
git clone https://github.com/ryokushaka/snaproom-react.git
git clone https://github.com/ryokushaka/snaproom-laravel.git
```

**Build Context Errors**:
```bash
# Ensure repositories are at the correct relative paths
# Docker build contexts expect:
# ../snaproom-react/     (for frontend)
# ../snaproom-laravel/   (for backend)
```

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

## 📊 Multi-Repository Workflow

### Development Workflow
```bash
# 1. Update service repositories
cd ../snaproom-react && git pull
cd ../snaproom-laravel && git pull
cd ../snaproom-infrastructure && git pull

# 2. Rebuild and restart services
cd ../snaproom/docker
docker-compose build --no-cache
docker-compose up -d
```

### Release Management
Each repository maintains its own versioning:
- **snaproom**: Orchestration and configuration versions
- **snaproom-react**: Frontend application versions
- **snaproom-laravel**: Backend API versions
- **snaproom-infrastructure**: Infrastructure versions

### CI/CD Integration
```yaml
# Example workflow for coordinated deployment
name: Deploy MSA
on:
  workflow_run:
    workflows: ["snaproom-react CI", "snaproom-laravel CI"]
    types: [completed]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout orchestration
        uses: actions/checkout@v3
      - name: Deploy with Docker
        run: make -f Makefile.docker up
```

## 🔐 Security Notes

### Development Security
- **Default passwords** are used for development convenience
- **All services** run in isolated Docker network
- **Only necessary ports** are exposed to host

### Repository Security
- **Separate repositories** allow granular access control
- **Service isolation** prevents cross-contamination
- **Independent security policies** per service

This Docker configuration provides a complete, production-ready MSA environment with clean separation between orchestration and service repositories.