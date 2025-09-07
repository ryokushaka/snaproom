package collect

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"time"

	"collector/internal/exporter"
	"collector/internal/log"
)

var (
	cycleInterval = 10
	startTime     = time.Now()
	logDirs       = []string{
		"./logs",
		"/logs",
	}
	serviceLogPaths = map[string]string{
		"snaproom-laravel": "/logs/laravel",
		"snaproom-react":   "/logs/react",
		"collector":        "./logs",
	}
)

func StartCollecting() {
	ctx := context.Background()
	StartCollectingWithContext(ctx, cycleInterval)
}

func StartCollectingWithContext(ctx context.Context, interval int) {
	log.InfoWithFields("Starting log collection service", map[string]interface{}{
		"cycle_interval_seconds": interval,
	})
	
	ticker := time.NewTicker(time.Second * time.Duration(interval))
	defer ticker.Stop()
	
	for {
		select {
		case <-ctx.Done():
			log.Info("Collection context cancelled, stopping log collection")
			return
		case <-ticker.C:
			log.Debug("Starting collect cycle")
			if err := cycle(); err != nil {
				log.Error("Collection cycle failed", err, map[string]interface{}{
					"cycle_interval": interval,
				})
				// Record error metric
				exporter.RecordLogError("collector", "cycle_error")
			}
		}
	}
}

func cycle() error {
	startCycle := time.Now()
	
	// Update uptime
	uptime := time.Since(startTime).Seconds()
	exporter.UpdateUptime(uptime)
	
	// Legacy metrics for backwards compatibility
	exporter.MyCounter.Add(1)
	log.Debug("Counter increased")

	random := rand.Float64()
	exporter.MyGauge.Set(random)
	log.Debug("Gauge updated", map[string]interface{}{
		"value": random,
	})

	// Collect log metrics from various services
	if err := collectLogMetrics(); err != nil {
		log.Error("Failed to collect log metrics", err)
		return fmt.Errorf("log metrics collection failed: %w", err)
	}
	
	// Record cycle processing time
	cycleTime := time.Since(startCycle).Seconds()
	exporter.RecordLogProcessingTime("collector", cycleTime)
	
	log.InfoWithFields("Cycle completed successfully", map[string]interface{}{
		"duration_seconds": fmt.Sprintf("%.3f", cycleTime),
		"uptime_seconds": fmt.Sprintf("%.0f", uptime),
	})
	
	return nil
}

func collectLogMetrics() error {
	var lastError error
	errorCount := 0
	
	for service, logPath := range serviceLogPaths {
		if err := collectServiceLogs(service, logPath); err != nil {
			log.ErrorWithFields("Error collecting logs for service", err, map[string]interface{}{
				"service": service,
				"log_path": logPath,
			})
			exporter.RecordLogError(service, "collection_error")
			lastError = err
			errorCount++
		}
	}
	
	// Collect from standard log directories
	for _, logDir := range logDirs {
		if err := collectDirectoryLogs(logDir); err != nil {
			log.ErrorWithFields("Error collecting logs from directory", err, map[string]interface{}{
				"log_directory": logDir,
			})
			exporter.RecordLogError("collector", "directory_error")
			lastError = err
			errorCount++
		}
	}
	
	if errorCount > 0 {
		log.Warn("Log collection completed with errors", map[string]interface{}{
			"error_count": errorCount,
			"total_sources": len(serviceLogPaths) + len(logDirs),
		})
		return fmt.Errorf("log collection had %d errors, last error: %w", errorCount, lastError)
	}
	
	log.Debug("Log metrics collection completed successfully", map[string]interface{}{
		"services_checked": len(serviceLogPaths),
		"directories_checked": len(logDirs),
	})
	
	return nil
}

func collectServiceLogs(service, logPath string) error {
	if _, err := os.Stat(logPath); os.IsNotExist(err) {
		return nil // Skip if directory doesn't exist
	}
	
	return filepath.Walk(logPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".log") {
			// Update file size metric
			exporter.UpdateLogFileSize(service, info.Name(), float64(info.Size()))
			
			// Simulate log level counting (in real implementation, parse log content)
			logCount := rand.Float64() * 10
			levels := []string{"info", "warn", "error", "debug"}
			level := levels[rand.Intn(len(levels))]
			
			exporter.RecordLogCollection(service, level, logCount)
			
			log.Log(fmt.Sprintf("Processed %s log file: %s (%.2f logs, level: %s)", 
				service, info.Name(), logCount, level))
		}
		
		return nil
	})
}

func collectDirectoryLogs(logDir string) error {
	if _, err := os.Stat(logDir); os.IsNotExist(err) {
		return nil // Skip if directory doesn't exist
	}
	
	return filepath.Walk(logDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".log") {
			// Determine service from filename or path
			service := determineServiceFromPath(path)
			
			// Update file size metric
			exporter.UpdateLogFileSize(service, info.Name(), float64(info.Size()))
			
			// Simulate log processing
			logCount := rand.Float64() * 5
			level := "info"
			
			exporter.RecordLogCollection(service, level, logCount)
		}
		
		return nil
	})
}

func determineServiceFromPath(path string) string {
	if strings.Contains(path, "laravel") {
		return "snaproom-laravel"
	} else if strings.Contains(path, "react") {
		return "snaproom-react"
	} else if strings.Contains(path, "collector") {
		return "collector"
	}
	return "unknown"
}