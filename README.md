# Snaproom - Full-Stack MSA Application

A modern full-stack application implementing Microservices Architecture (MSA) with Redis clustering, Kafka event streaming, and Feature-Sliced Design.

## 🏗️ Architecture Overview

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

## 🚀 Quick Start

### Repository Setup
```bash
# Clone main repository
git clone https://github.com/ryokushaka/snaproom.git
cd snaproom

# Clone service repositories (nested within main repo)
git clone https://github.com/ryokushaka/snaproom-react.git
git clone https://github.com/ryokushaka/snaproom-laravel.git
git clone https://github.com/ryokushaka/snaproom-infrastructure.git

# The nested repositories are ignored by main repo's .gitignore
# Each service repository maintains its own Git history
```

### Start MSA Environment
```bash
# Build and start complete MSA stack
cd snaproom
make -f Makefile.docker up

# Verify all services are healthy
make -f Makefile.docker health-check

# Test health endpoints
cd docker && ./test-health-endpoints.sh
```

### Access Points
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000/api/health
- **Kafka UI**: http://localhost:8080 (admin/admin_secret)
- **Redis Commander**: http://localhost:8081 (admin/admin_secret)

## 📁 Project Structure

```
snaproom/ (Main Repository)
├── docker/                   # Docker configurations and scripts
├── config/                   # Application and service configurations
├── scripts/                  # Management and deployment scripts
├── snaproom-react/          # 🎯 Frontend repository (nested)
├── snaproom-laravel/        # 🎯 Backend repository (nested)
├── snaproom-infrastructure/ # 🎯 Infrastructure repository (nested)
└── *.md                     # Documentation files
```

## 🛠️ Technology Stack

- **Frontend**: React 18 + TypeScript + FSD Architecture
- **Backend**: Laravel 12 + PHP 8.2 + ADR Pattern
- **Database**: PostgreSQL 15
- **Cache**: Redis 7 Cluster (Master-Replica-Sentinel)
- **Message Queue**: Kafka 3-Broker Cluster
- **Container**: Docker + Docker Compose

## 📚 Documentation

### Core Documentation
- **[MSA Architecture](README-MSA.md)** - Complete MSA guide with deployment instructions
- **[MSA Improvement Roadmap](MSA-IMPROVEMENT-ROADMAP.md)** - 3-phase enhancement plan (85% → 95% MSA)
- **[Docker Configuration](docker/README.md)** - Container orchestration setup
- **[Development Guide](CLAUDE.md)** - Development workflow and architecture patterns

### Service Repositories
- **[React Frontend](snaproom-react/README.md)** - Frontend repository (FSD architecture)
- **[Laravel Backend](snaproom-laravel/README.md)** - Backend repository (ADR pattern)
- **[Infrastructure Management](snaproom-infrastructure/README.md)** - Terraform AWS infrastructure

## 🔧 Development Commands

```bash
# Docker Environment
make -f Makefile.docker up      # Start MSA environment
make -f Makefile.docker health-check # Check service health
make -f Makefile.docker kafka-ui # Open Kafka management

# Infrastructure Management
cd snaproom-infrastructure
./scripts/deploy.sh -e dev -a plan    # Plan infrastructure
./scripts/deploy.sh -e dev -a apply   # Deploy infrastructure
./scripts/deploy.sh -e prod -a plan   # Plan production infrastructure

# Repository Management (Nested Repositories)
cd snaproom-react && git pull && cd ..      # Update frontend
cd snaproom-laravel && git pull && cd ..    # Update backend
cd snaproom-infrastructure && git pull && cd .. # Update infrastructure

# Development Shortcuts
make -f Makefile.docker logs    # View container logs
make -f Makefile.docker clean   # Clean up containers
```

## 🎯 Key Features

- **Microservices Architecture** with event-driven communication
- **Infrastructure as Code** with Terraform automation
- **Redis Clustering** for high-availability caching
- **Kafka Event Streaming** for async service communication
- **Feature-Sliced Design** for scalable React architecture
- **ADR Pattern** for clean Laravel API structure
- **Comprehensive Health Checks** for monitoring
- **Docker Containerization** for consistent deployment
- **Multi-Environment Support** (dev, staging, prod)