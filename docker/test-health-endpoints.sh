#!/bin/bash

# MSA Health Check Test Script
# Tests all health endpoints after the improvements

echo "🔍 MSA Health Check Test Suite"
echo "=============================="

BASE_URL="http://localhost:8000/api"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    echo -n "Testing $name... "
    
    response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$url")
    status_code=${response: -3}
    
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $status_code)"
        if [ -s /tmp/response.json ]; then
            echo "  Response: $(cat /tmp/response.json | jq -c '.' 2>/dev/null || cat /tmp/response.json)"
        fi
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $status_code, expected $expected_status)"
        if [ -s /tmp/response.json ]; then
            echo "  Response: $(cat /tmp/response.json)"
        fi
    fi
    echo
}

# Function to check if service is running
check_service() {
    local service=$1
    local port=$2
    
    echo -n "Checking $service on port $port... "
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✓ Running${NC}"
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

echo "📡 Checking Service Availability"
echo "--------------------------------"

# Check if services are running
check_service "PostgreSQL" 5432
check_service "Redis Master" 6379
check_service "Redis Replica" 6380
check_service "Redis Sentinel" 26379
check_service "Kafka Broker 1" 29092
check_service "Kafka Broker 2" 29093  
check_service "Kafka Broker 3" 29094
check_service "Laravel API" 8000
check_service "React Frontend" 3000
check_service "Kafka UI" 8080
check_service "Redis Commander" 8081

echo
echo "🏥 Testing Health Endpoints"
echo "---------------------------"

# Test basic health endpoint
test_endpoint "Basic Health" "$BASE_URL/health" 200

# Test detailed health endpoint
test_endpoint "Detailed Health" "$BASE_URL/health/detailed" 200

# Test readiness endpoint
test_endpoint "Readiness Check" "$BASE_URL/health/ready" 200

# Test liveness endpoint  
test_endpoint "Liveness Check" "$BASE_URL/health/live" 200

echo "🔧 Testing Individual Service Health"
echo "------------------------------------"

# Test specific service components via detailed endpoint
echo "Fetching detailed health information..."
detailed_response=$(curl -s "$BASE_URL/health/detailed")

if [ $? -eq 0 ] && [ -n "$detailed_response" ]; then
    echo "Database Status: $(echo "$detailed_response" | jq -r '.checks.database.status' 2>/dev/null || echo 'N/A')"
    echo "Redis Status: $(echo "$detailed_response" | jq -r '.checks.redis.status' 2>/dev/null || echo 'N/A')"
    echo "Kafka Status: $(echo "$detailed_response" | jq -r '.checks.kafka.status' 2>/dev/null || echo 'N/A')"
    echo "Application Status: $(echo "$detailed_response" | jq -r '.checks.application.status' 2>/dev/null || echo 'N/A')"
else
    echo -e "${RED}Could not fetch detailed health information${NC}"
fi

echo
echo "📊 Performance Metrics"
echo "---------------------"

if [ -n "$detailed_response" ]; then
    response_time=$(echo "$detailed_response" | jq -r '.response_time_ms' 2>/dev/null)
    if [ "$response_time" != "null" ] && [ -n "$response_time" ]; then
        echo "Health Check Response Time: ${response_time}ms"
    fi
    
    overall_status=$(echo "$detailed_response" | jq -r '.status' 2>/dev/null)
    if [ "$overall_status" = "healthy" ]; then
        echo -e "Overall Status: ${GREEN}$overall_status${NC}"
    else
        echo -e "Overall Status: ${RED}$overall_status${NC}"
    fi
fi

echo
echo "🧪 Integration Tests"
echo "-------------------"

# Test React -> Laravel communication
echo -n "Testing React -> Laravel proxy... "
react_response=$(curl -s -w "%{http_code}" -o /tmp/react.json "http://localhost:3000/api/health")
react_status=${react_response: -3}

if [ "$react_status" -eq 200 ]; then
    echo -e "${GREEN}✓ PASS${NC} (Nginx proxy working)"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $react_status)"
fi

# Clean up
rm -f /tmp/response.json /tmp/react.json

echo
echo "✅ Health Check Test Complete"
echo "=============================="