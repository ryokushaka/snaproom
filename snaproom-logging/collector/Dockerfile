# Multi-stage Dockerfile for Snaproom Logging Collector
# Stage 1: Build stage with Go compiler and dependencies
FROM golang:1.24.2-alpine AS builder

# Install git and ca-certificates for module downloads
RUN apk add --no-cache git ca-certificates tzdata

# Create non-root user for build process
RUN adduser -D -g '' collector

# Set working directory
WORKDIR /build

# Copy go.mod and go.sum first for better layer caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build the binary with optimizations
# CGO_ENABLED=0: Static binary for scratch/distroless images
# -ldflags: Strip debug info and reduce binary size
# -trimpath: Remove file system paths from binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags='-w -s -extldflags "-static"' \
    -trimpath \
    -o collector \
    ./cmd/collector

# Create directory structure for runtime stage
RUN mkdir -p /tmp/app/logs && chown 65532:65532 /tmp/app/logs

# Stage 2: Runtime stage with minimal distroless image
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

# Copy timezone data from builder
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy CA certificates for HTTPS connections
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the compiled binary from builder stage
COPY --from=builder /build/collector /usr/local/bin/collector

# Copy the logs directory structure with proper ownership
COPY --from=builder --chown=65532:65532 /tmp/app /app

# Switch to non-root user
USER 65532:65532

# Set working directory
WORKDIR /app

# Expose metrics port
EXPOSE 8080

# Health check - Note: Docker Compose will handle health checks via HTTP endpoints
# HEALTHCHECK disabled in favor of Docker Compose HTTP health checks
# This avoids dependency on specific CLI flags in the Go application

# Set environment variables with defaults
ENV LOG_LEVEL=info \
    CYCLE_INTERVAL=10 \
    METRICS_PORT=8080

# Run the binary
ENTRYPOINT ["/usr/local/bin/collector"]