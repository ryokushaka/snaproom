package exporter

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// StartExporter starts the Prometheus metrics HTTP server
func StartExporter(port int) {
	// Create HTTP server with timeout configurations
	server := &http.Server{
		Addr:         ":" + strconv.Itoa(port),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Metrics endpoint
	http.Handle("/metrics", promhttp.Handler())
	
	// Health check endpoint
	http.HandleFunc("/health", healthHandler)
	
	// Ready check endpoint
	http.HandleFunc("/ready", readyHandler)

	fmt.Printf("Starting Prometheus exporter on port %d\n", port)
	fmt.Printf("Metrics available at: http://localhost:%d/metrics\n", port)
	fmt.Printf("Health check at: http://localhost:%d/health\n", port)

	// Start server
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		panic(fmt.Sprintf("Failed to start exporter server: %v", err))
	}
}

// healthHandler provides health check endpoint
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	
	response := `{
		"status": "healthy",
		"service": "snaproom-logging-collector",
		"timestamp": "` + time.Now().Format(time.RFC3339) + `",
		"version": "1.0.0"
	}`
	
	w.Write([]byte(response))
}

// readyHandler provides readiness check endpoint
func readyHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	
	response := `{
		"status": "ready",
		"service": "snaproom-logging-collector",
		"timestamp": "` + time.Now().Format(time.RFC3339) + `"
	}`
	
	w.Write([]byte(response))
}

// StartExporterWithGracefulShutdown starts the exporter with graceful shutdown support
func StartExporterWithGracefulShutdown(port int, ctx context.Context) error {
	server := &http.Server{
		Addr:         ":" + strconv.Itoa(port),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Setup handlers
	http.Handle("/metrics", promhttp.Handler())
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/ready", readyHandler)

	// Start server in goroutine
	go func() {
		fmt.Printf("Starting Prometheus exporter on port %d\n", port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			fmt.Printf("Server error: %v\n", err)
		}
	}()

	// Wait for context cancellation
	<-ctx.Done()

	// Graceful shutdown
	fmt.Println("Shutting down server...")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	return server.Shutdown(shutdownCtx)
}