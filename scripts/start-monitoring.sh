#!/bin/bash

# Snaproom Monitoring Stack Startup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker and Docker Compose are available
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Create necessary directories
create_directories() {
    print_info "Creating monitoring directories..."
    
    mkdir -p ../config/prometheus/rules
    mkdir -p ../config/grafana/provisioning/datasources
    mkdir -p ../config/grafana/provisioning/dashboards
    mkdir -p ../config/grafana/dashboards
    mkdir -p ../config/alertmanager
    mkdir -p ../config/postgres-exporter
    mkdir -p ../config/blackbox
    
    print_success "Directories created"
}

# Start monitoring services
start_services() {
    print_info "Starting Snaproom MSA with monitoring stack..."
    
    cd ../docker
    
    # Pull latest images
    print_info "Pulling latest monitoring images..."
    docker-compose pull prometheus grafana alertmanager node-exporter redis-exporter postgres-exporter kafka-exporter cadvisor blackbox-exporter
    
    # Start all services
    print_info "Starting all services..."
    docker-compose up -d
    
    print_success "All services started"
}

# Wait for services to be ready
wait_for_services() {
    print_info "Waiting for services to be ready..."
    
    # Wait for Prometheus
    print_info "Waiting for Prometheus..."
    timeout 60 bash -c 'until curl -s http://localhost:9090/-/ready; do sleep 2; done' || {
        print_error "Prometheus failed to start"
        return 1
    }
    
    # Wait for Grafana
    print_info "Waiting for Grafana..."
    timeout 60 bash -c 'until curl -s http://localhost:3001/api/health; do sleep 2; done' || {
        print_error "Grafana failed to start"
        return 1
    }
    
    # Wait for AlertManager
    print_info "Waiting for AlertManager..."
    timeout 60 bash -c 'until curl -s http://localhost:9093/-/ready; do sleep 2; done' || {
        print_error "AlertManager failed to start"
        return 1
    }
    
    print_success "All monitoring services are ready"
}

# Check service health
check_health() {
    print_info "Checking service health..."
    
    # Check Prometheus targets
    print_info "Checking Prometheus targets..."
    TARGETS=$(curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length')
    print_info "Prometheus is monitoring $TARGETS targets"
    
    # Check Grafana data sources
    print_info "Checking Grafana data sources..."
    DATASOURCES=$(curl -s -u admin:admin_secret http://localhost:3001/api/datasources | jq '. | length')
    print_info "Grafana has $DATASOURCES data sources configured"
    
    print_success "Health check completed"
}

# Display access information
show_access_info() {
    print_success "Snaproom Monitoring Stack is ready!"
    echo ""
    echo "=== Access Information ==="
    echo "🎯 Prometheus:     http://localhost:9090"
    echo "📊 Grafana:        http://localhost:3001 (admin/admin_secret)"
    echo "🚨 AlertManager:   http://localhost:9093"
    echo "📈 Node Exporter:  http://localhost:9100/metrics"
    echo "🔴 Redis Metrics:  http://localhost:9121/metrics"
    echo "🐘 Postgres Metrics: http://localhost:9187/metrics"
    echo "📨 Kafka Metrics:  http://localhost:9308/metrics"
    echo "🐳 Container Metrics: http://localhost:8080"
    echo ""
    echo "=== Main Application ==="
    echo "🎨 Frontend:       http://localhost:3000"
    echo "⚙️  Backend API:    http://localhost:8000"
    echo "🌊 Kafka UI:       http://localhost:8080 (admin/admin_secret)"
    echo "🔗 Redis Commander: http://localhost:8081 (admin/admin_secret)"
    echo ""
    echo "=== Health Checks ==="
    echo "curl http://localhost:8000/api/health"
    echo "curl http://localhost:9090/-/healthy"
    echo "curl http://localhost:3001/api/health"
    echo ""
}

# Cleanup function
cleanup() {
    print_warning "Cleaning up..."
    cd ../docker
    docker-compose down
    print_info "Cleanup completed"
}

# Main execution
main() {
    print_info "Starting Snaproom Monitoring Stack setup..."
    
    # Handle Ctrl+C
    trap cleanup SIGINT SIGTERM
    
    check_prerequisites
    create_directories
    start_services
    
    # Wait a bit for services to initialize
    sleep 10
    
    wait_for_services
    check_health
    show_access_info
    
    # Keep script running and show logs
    print_info "Monitoring stack is running. Press Ctrl+C to stop."
    print_info "You can view logs with: docker-compose -f ../docker/docker-compose.yaml logs -f"
    
    # Wait for interrupt
    while true; do
        sleep 30
        # Optional: periodic health check
        if ! curl -s http://localhost:9090/-/ready > /dev/null; then
            print_warning "Prometheus health check failed"
        fi
    done
}

# Show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     Start monitoring stack (default)"
    echo "  stop      Stop monitoring stack"
    echo "  restart   Restart monitoring stack"
    echo "  status    Show service status"
    echo "  logs      Show service logs"
    echo "  help      Show this help message"
}

# Command handling
case "${1:-start}" in
    start)
        main
        ;;
    stop)
        print_info "Stopping monitoring stack..."
        cd ../docker
        docker-compose down
        print_success "Monitoring stack stopped"
        ;;
    restart)
        print_info "Restarting monitoring stack..."
        cd ../docker
        docker-compose restart prometheus grafana alertmanager
        print_success "Monitoring stack restarted"
        ;;
    status)
        print_info "Checking service status..."
        cd ../docker
        docker-compose ps
        ;;
    logs)
        print_info "Showing service logs..."
        cd ../docker
        docker-compose logs -f prometheus grafana alertmanager
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac