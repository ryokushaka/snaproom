#!/bin/bash

# Snaproom Monitoring Validation Script
# This script validates the monitoring stack configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration validation
validate_config_files() {
    print_info "Validating configuration files..."
    
    local config_files=(
        "../config/prometheus/prometheus.yml"
        "../config/prometheus/rules/snaproom-alerts.yml"
        "../config/grafana/provisioning/datasources/prometheus.yml"
        "../config/grafana/provisioning/dashboards/dashboard.yml"
        "../config/grafana/dashboards/snaproom-overview.json"
        "../config/alertmanager/alertmanager.yml"
        "../config/postgres-exporter/queries.yaml"
        "../config/blackbox/config.yml"
    )
    
    local missing_files=0
    for file in "${config_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Missing config file: $file"
            missing_files=$((missing_files + 1))
        else
            print_success "Found: $file"
        fi
    done
    
    if [[ $missing_files -eq 0 ]]; then
        print_success "All configuration files present"
    else
        print_error "$missing_files configuration files missing"
        return 1
    fi
}

# YAML syntax validation
validate_yaml_syntax() {
    print_info "Validating YAML syntax..."
    
    # Check if yq is available
    if command -v yq &> /dev/null; then
        local yaml_files=(
            "../config/prometheus/prometheus.yml"
            "../config/prometheus/rules/snaproom-alerts.yml"
            "../config/grafana/provisioning/datasources/prometheus.yml"
            "../config/grafana/provisioning/dashboards/dashboard.yml"
            "../config/alertmanager/alertmanager.yml"
            "../config/postgres-exporter/queries.yaml"
            "../config/blackbox/config.yml"
        )
        
        for file in "${yaml_files[@]}"; do
            if yq eval '.' "$file" > /dev/null 2>&1; then
                print_success "Valid YAML: $file"
            else
                print_error "Invalid YAML syntax: $file"
                return 1
            fi
        done
    else
        print_warning "yq not installed, skipping YAML syntax validation"
    fi
}

# JSON validation
validate_json_syntax() {
    print_info "Validating JSON syntax..."
    
    local json_files=(
        "../config/grafana/dashboards/snaproom-overview.json"
    )
    
    for file in "${json_files[@]}"; do
        if jq empty "$file" 2>/dev/null; then
            print_success "Valid JSON: $file"
        else
            print_error "Invalid JSON syntax: $file"
            return 1
        fi
    done
}

# Docker Compose validation
validate_docker_compose() {
    print_info "Validating Docker Compose configuration..."
    
    cd ../docker
    if docker-compose config --quiet; then
        print_success "Docker Compose configuration is valid"
    else
        print_error "Docker Compose configuration has errors"
        return 1
    fi
    
    # Check if monitoring services are defined
    local monitoring_services=$(docker-compose config --services | grep -E "(prometheus|grafana|alertmanager)" | wc -l)
    if [[ $monitoring_services -ge 3 ]]; then
        print_success "Monitoring services found in Docker Compose: $monitoring_services"
    else
        print_error "Not all monitoring services found in Docker Compose"
        return 1
    fi
}

# Port conflicts check
check_port_conflicts() {
    print_info "Checking for port conflicts..."
    
    local ports=(3000 3001 8000 8080 8081 9090 9093 9100 9121 9187 9308)
    local conflicts=0
    
    for port in "${ports[@]}"; do
        if lsof -i ":$port" &> /dev/null; then
            print_warning "Port $port is already in use"
            conflicts=$((conflicts + 1))
        fi
    done
    
    if [[ $conflicts -eq 0 ]]; then
        print_success "No port conflicts detected"
    else
        print_warning "$conflicts ports already in use - services may fail to start"
    fi
}

# Prerequisites check
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing=0
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        missing=$((missing + 1))
    else
        print_success "Docker is installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        missing=$((missing + 1))
    else
        print_success "Docker Compose is installed"
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed"
        missing=$((missing + 1))
    else
        print_success "curl is installed"
    fi
    
    if [[ $missing -eq 0 ]]; then
        print_success "All prerequisites met"
    else
        print_error "$missing prerequisites missing"
        return 1
    fi
}

# Main validation function
main() {
    print_info "Starting Snaproom Monitoring Stack validation..."
    echo ""
    
    local validation_errors=0
    
    # Run all validations
    check_prerequisites || validation_errors=$((validation_errors + 1))
    echo ""
    
    validate_config_files || validation_errors=$((validation_errors + 1))
    echo ""
    
    validate_yaml_syntax || validation_errors=$((validation_errors + 1))
    echo ""
    
    validate_json_syntax || validation_errors=$((validation_errors + 1))
    echo ""
    
    validate_docker_compose || validation_errors=$((validation_errors + 1))
    echo ""
    
    check_port_conflicts
    echo ""
    
    # Summary
    if [[ $validation_errors -eq 0 ]]; then
        print_success "✅ All validations passed! Monitoring stack is ready to deploy."
        echo ""
        echo "Next steps:"
        echo "1. Run: ./start-monitoring.sh"
        echo "2. Access Grafana: http://localhost:3001 (admin/admin_secret)"
        echo "3. Access Prometheus: http://localhost:9090"
        echo "4. Access AlertManager: http://localhost:9093"
    else
        print_error "❌ $validation_errors validation(s) failed. Please fix the issues before deploying."
        return 1
    fi
}

# Run validation
main "$@"