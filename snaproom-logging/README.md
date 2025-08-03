# Snaproom Logging System

Production-ready logging and monitoring system for the Snaproom MSA environment, featuring Prometheus metrics collection, Loki log aggregation, and comprehensive observability.

## 🏗 Architecture Overview

This logging system implements a comprehensive observability stack following Snaproom MSA conventions:

- **Custom Go Collector**: Metrics collection and log processing
- **Prometheus**: Time-series metrics storage and alerting
- **Loki**: Log aggregation and querying
- **Promtail**: Log shipping and parsing
- **Grafana**: Visualization and dashboards

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Access to main Snaproom MSA network
- Go 1.24.2+ (for development)

### Launch the Stack

```bash
# Start the complete logging stack
docker-compose up -d

# View logs
docker-compose logs -f

# Check service health
docker-compose ps
```

### Access Points

- **Grafana Dashboard**: http://localhost:3001 (admin/snaproom_logging_secret)
- **Prometheus UI**: http://localhost:9090
- **Loki API**: http://localhost:3100
- **Collector Metrics**: http://localhost:8080/metrics
- **Collector Health**: http://localhost:8080/health

## 📊 Metrics and Monitoring

### Available Metrics

The collector exposes comprehensive metrics following Snaproom naming conventions:

#### Log Collection Metrics
- `snaproom_logs_collected_total` - Total logs collected by service and level
- `snaproom_log_processing_duration_seconds` - Processing time histogram
- `snaproom_log_file_size_bytes` - Current log file sizes
- `snaproom_log_errors_total` - Processing errors by type

#### System Metrics
- `snaproom_collector_uptime_seconds` - Collector uptime
- `snaproom_collector_cycles_total` - Collection cycles completed

### Log Aggregation

Promtail automatically discovers and ships logs from:

- **Application Logs**: `/logs/**/*.log`
- **Collector Logs**: `./logs/collector.log`
- **Docker Logs**: `/var/lib/docker/containers/*/*-json.log`
- **System Logs**: `/var/log/*.log`

## 🔧 Configuration

### Environment Variables

The collector supports configuration via environment variables:

```bash
# Logging configuration
LOG_LEVEL=info          # DEBUG, INFO, WARN, ERROR, FATAL
METRICS_PORT=8080       # Metrics server port
CYCLE_INTERVAL=10       # Collection cycle interval (seconds)

# Container hostname for labeling
HOSTNAME=snaproom-logging
```

### Integration with Main MSA

The logging system connects to the main Snaproom network:

```yaml
networks:
  snaproom-network:
    external: true
    name: snaproom-network
```

## 🏭 Production Considerations

### Security

- **Network Isolation**: Services communicate via internal Docker networks
- **Access Control**: Grafana authentication configured
- **Port Management**: Minimal external port exposure

### Performance

- **Retention Policies**: 30-day data retention for both metrics and logs
- **Resource Limits**: Configured memory and processing limits
- **Compression**: WAL compression and chunk optimization enabled

### Reliability

- **Health Checks**: All services include comprehensive health monitoring
- **Graceful Shutdown**: Signal handling for clean service stops
- **Error Recovery**: Automatic retry mechanisms with exponential backoff

## 🔗 Integration Points

### Main MSA Services

Add this to your main Prometheus configuration to scrape the logging collector:

```yaml
scrape_configs:
  - job_name: 'snaproom-logging-collector'
    static_configs:
      - targets: ['snaproom-logging-collector:8080']
    scrape_interval: 30s
    metrics_path: '/metrics'
```

### Application Integration

Applications can write logs to mounted volumes for automatic collection:

```yaml
# In your application's docker-compose.yaml
volumes:
  - ./logs:/app/logs
  - logging_volume:/shared/logs
```

## 🛠 Development

### Local Development

```bash
# Navigate to collector directory
cd collector

# Install dependencies
go mod tidy

# Run locally
go run cmd/collector/main.go

# Build binary
go build -o bin/collector cmd/collector/main.go
```

### Testing

```bash
# Run tests
go test ./...

# Check metrics endpoint
curl http://localhost:8080/metrics

# Verify health
curl http://localhost:8080/health
```

## 📈 Monitoring and Alerting

### Key Metrics to Monitor

1. **Collection Health**: `snaproom_collector_uptime_seconds`
2. **Error Rates**: `snaproom_log_errors_total`
3. **Processing Performance**: `snaproom_log_processing_duration_seconds`
4. **Data Volume**: `snaproom_logs_collected_total`

### Alert Recommendations

```yaml
# Example alert rules
groups:
  - name: snaproom-logging
    rules:
      - alert: LogCollectorDown
        expr: up{job="snaproom-logging-collector"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Snaproom log collector is down"
```

## 🔍 Troubleshooting

### Common Issues

1. **Port Conflicts**: Check for conflicts with main MSA services (especially Grafana port 3000 vs 3001)
2. **Network Issues**: Ensure `snaproom-network` exists and is accessible
3. **Volume Permissions**: Verify log directory permissions for container access
4. **Configuration Errors**: Check YAML syntax in config files

### Debug Commands

```bash
# Check container logs
docker-compose logs collector

# Verify network connectivity
docker-compose exec collector wget -qO- http://prometheus:9090/-/healthy

# Test log collection
docker-compose exec collector ls -la /logs/

# Check metrics
curl -s http://localhost:8080/metrics | grep snaproom
```

## 📚 Documentation

For detailed architecture and implementation guides, see:

- [Monitoring System Overview](../snaproom.wiki/Monitoring-Snaproom-Monitoring-01-모니터링-시스템-개요.md)
- [Architecture Design](../snaproom.wiki/Monitoring-Snaproom-Monitoring-02-아키텍처-설계-및-근거.md)

## 🎯 Roadmap

### Upcoming Features

- [ ] Distributed tracing integration
- [ ] Advanced alerting rules
- [ ] Multi-environment support
- [ ] Automated dashboard provisioning
- [ ] Enhanced security features

## 📄 License

Part of the Snaproom MSA project. See main project documentation for license details.

---

**Snaproom Logging System v1.0.0**  
Built with ❤️ for production observability