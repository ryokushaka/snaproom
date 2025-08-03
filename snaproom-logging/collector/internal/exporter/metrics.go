package exporter

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// Application-level metrics following Snaproom naming conventions
var (
	// Log collection metrics
	LogsCollectedTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "snaproom_logs_collected_total",
			Help: "Total number of logs collected by service and level",
		},
		[]string{"service", "level"},
	)

	// Log processing duration
	LogProcessingDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "snaproom_log_processing_duration_seconds",
			Help:    "Time spent processing logs by service",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"service"},
	)

	// Log file size gauge
	LogFileSizeBytes = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "snaproom_log_file_size_bytes",
			Help: "Current size of log files in bytes",
		},
		[]string{"service", "filename"},
	)

	// Log errors counter
	LogErrorsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "snaproom_log_errors_total",
			Help: "Total number of log processing errors",
		},
		[]string{"service", "error_type"},
	)

	// Collector health metrics
	CollectorUptime = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "snaproom_collector_uptime_seconds",
			Help: "Time the collector has been running",
		},
	)

	// Legacy metrics for backwards compatibility
	MyCounter = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "snaproom_collector_cycles_total",
			Help: "Total number of collection cycles",
		},
	)

	MyGauge = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "snaproom_collector_random_value",
			Help: "Random gauge value for testing",
		},
	)
)

// InitMetrics initializes all metrics
func InitMetrics() {
	// Register all metrics with Prometheus
	// promauto handles registration automatically
	
	// Initialize collector uptime
	CollectorUptime.Set(0)
}

// RecordLogCollection records log collection events
func RecordLogCollection(service, level string, count float64) {
	LogsCollectedTotal.WithLabelValues(service, level).Add(count)
}

// RecordLogProcessingTime records time spent processing logs
func RecordLogProcessingTime(service string, duration float64) {
	LogProcessingDuration.WithLabelValues(service).Observe(duration)
}

// UpdateLogFileSize updates the current log file size
func UpdateLogFileSize(service, filename string, size float64) {
	LogFileSizeBytes.WithLabelValues(service, filename).Set(size)
}

// RecordLogError records log processing errors
func RecordLogError(service, errorType string) {
	LogErrorsTotal.WithLabelValues(service, errorType).Inc()
}

// UpdateUptime updates the collector uptime
func UpdateUptime(seconds float64) {
	CollectorUptime.Set(seconds)
}