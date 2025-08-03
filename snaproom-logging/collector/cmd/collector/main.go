package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"collector/internal/collect"
	"collector/internal/exporter"
	"collector/internal/log"
)

var (
	defaultPort         = 8080
	defaultCycleInterval = 10
)

func main() {
	// Initialize configuration from environment variables
	config := loadConfig()
	
	// Initialize logging system
	if err := log.InitLogPath(); err != nil {
		fmt.Printf("Failed to initialize logging: %v\n", err)
		os.Exit(1)
	}

	// Set log level from environment
	if logLevel := os.Getenv("LOG_LEVEL"); logLevel != "" {
		if err := log.SetLogLevelFromString(logLevel); err != nil {
			log.Warn("Invalid log level, using default INFO", map[string]interface{}{
				"provided_level": logLevel,
				"error": err.Error(),
			})
		}
	}

	log.InfoWithFields("Starting Snaproom Logging Collector", map[string]interface{}{
		"version": "1.0.0",
		"port": config.Port,
		"cycle_interval": config.CycleInterval,
		"log_level": log.GetLogLevel().String(),
	})

	// Initialize metrics
	exporter.InitMetrics()
	log.Info("Metrics system initialized")

	// Create context for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Setup signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Start metrics exporter in goroutine
	go func() {
		log.InfoWithFields("Starting metrics exporter", map[string]interface{}{
			"port": config.Port,
		})
		
		if err := exporter.StartExporterWithGracefulShutdown(config.Port, ctx); err != nil {
			log.Error("Exporter error", err)
		}
	}()

	// Start collection in goroutine
	go func() {
		log.Info("Starting log collection")
		collect.StartCollectingWithContext(ctx, config.CycleInterval)
	}()

	// Wait for shutdown signal
	<-sigChan
	log.Info("Received shutdown signal, starting graceful shutdown...")

	// Cancel context to signal all goroutines to stop
	cancel()

	// Give services time to shut down gracefully
	shutdownTimeout := 30 * time.Second
	log.InfoWithFields("Waiting for graceful shutdown", map[string]interface{}{
		"timeout_seconds": int(shutdownTimeout.Seconds()),
	})

	time.Sleep(shutdownTimeout)
	log.Info("Snaproom Logging Collector shutdown complete")
}

// Config holds the application configuration
type Config struct {
	Port          int
	CycleInterval int
}

// loadConfig loads configuration from environment variables with defaults
func loadConfig() Config {
	config := Config{
		Port:          defaultPort,
		CycleInterval: defaultCycleInterval,
	}

	// Load port from environment
	if portStr := os.Getenv("METRICS_PORT"); portStr != "" {
		if port, err := strconv.Atoi(portStr); err != nil {
			log.Warn("Invalid METRICS_PORT, using default", map[string]interface{}{
				"provided_port": portStr,
				"default_port": defaultPort,
				"error": err.Error(),
			})
		} else {
			config.Port = port
		}
	}

	// Load cycle interval from environment
	if intervalStr := os.Getenv("CYCLE_INTERVAL"); intervalStr != "" {
		if interval, err := strconv.Atoi(intervalStr); err != nil {
			log.Warn("Invalid CYCLE_INTERVAL, using default", map[string]interface{}{
				"provided_interval": intervalStr,
				"default_interval": defaultCycleInterval,
				"error": err.Error(),
			})
		} else {
			config.CycleInterval = interval
		}
	}

	return config
}