package log

import (
	"fmt"
	"io"
	"log"
	"os"
	"path"
	"strings"
	"time"

	"collector/internal/utility"
)

// LogLevel represents different log levels
type LogLevel int

const (
	DEBUG LogLevel = iota
	INFO
	WARN
	ERROR
	FATAL
)

var (
	logDir       = "logs"
	logFile      = "collector.log"
	currentLevel = INFO // Default log level
	logger       *log.Logger
	logWriter    io.Writer
)

// String returns the string representation of log level
func (level LogLevel) String() string {
	switch level {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	case FATAL:
		return "FATAL"
	default:
		return "UNKNOWN"
	}
}

// SetLogLevel sets the minimum log level
func SetLogLevel(level LogLevel) {
	currentLevel = level
}

// InitLogPath initializes the logging system with proper error handling
func InitLogPath() error {
	currentDir := utility.CurrentDir()
	logPath := path.Join(currentDir, logDir)

	// Create logs directory if it doesn't exist
	if err := os.MkdirAll(logPath, 0755); err != nil {
		return fmt.Errorf("failed to create log directory %s: %v", logPath, err)
	}

	// Open log file with proper permissions
	logFilePath := path.Join(logPath, logFile)
	file, err := os.OpenFile(logFilePath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open log file %s: %v", logFilePath, err)
	}

	// Create multi-writer to write to both file and stdout
	logWriter = io.MultiWriter(file, os.Stdout)
	
	// Initialize logger with custom format
	logger = log.New(logWriter, "", 0)

	// Log initialization success
	logMessage(INFO, "Logging system initialized successfully", nil)
	return nil
}

// logMessage is the internal logging function
func logMessage(level LogLevel, message string, fields map[string]interface{}) {
	// Skip if log level is below current threshold
	if level < currentLevel {
		return
	}

	// Format timestamp
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	
	// Build log entry
	var logEntry strings.Builder
	logEntry.WriteString(fmt.Sprintf("%s [%s] %s", timestamp, level.String(), message))
	
	// Add fields if provided
	if fields != nil && len(fields) > 0 {
		logEntry.WriteString(" |")
		for key, value := range fields {
			logEntry.WriteString(fmt.Sprintf(" %s=%v", key, value))
		}
	}

	// Write to logger (which writes to both file and stdout)
	if logger != nil {
		logger.Println(logEntry.String())
	} else {
		// Fallback if logger is not initialized
		fmt.Println(logEntry.String())
	}
}

// Log writes an info level log message (backwards compatibility)
func Log(text string) {
	Info(text)
}

// Debug logs a debug message
func Debug(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	logMessage(DEBUG, message, f)
}

// Info logs an info message
func Info(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	logMessage(INFO, message, f)
}

// Warn logs a warning message
func Warn(message string, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	}
	logMessage(WARN, message, f)
}

// Error logs an error message
func Error(message string, err error, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	} else {
		f = make(map[string]interface{})
	}
	
	if err != nil {
		f["error"] = err.Error()
	}
	
	logMessage(ERROR, message, f)
}

// Fatal logs a fatal message and exits the program
func Fatal(message string, err error, fields ...map[string]interface{}) {
	var f map[string]interface{}
	if len(fields) > 0 {
		f = fields[0]
	} else {
		f = make(map[string]interface{})
	}
	
	if err != nil {
		f["error"] = err.Error()
	}
	
	logMessage(FATAL, message, f)
	os.Exit(1)
}

// InfoWithFields logs an info message with structured fields
func InfoWithFields(message string, fields map[string]interface{}) {
	logMessage(INFO, message, fields)
}

// ErrorWithFields logs an error message with structured fields
func ErrorWithFields(message string, err error, fields map[string]interface{}) {
	if fields == nil {
		fields = make(map[string]interface{})
	}
	if err != nil {
		fields["error"] = err.Error()
	}
	logMessage(ERROR, message, fields)
}

// LogLevel helpers
func IsDebugEnabled() bool {
	return currentLevel <= DEBUG
}

func IsInfoEnabled() bool {
	return currentLevel <= INFO
}

// GetLogLevel returns the current log level
func GetLogLevel() LogLevel {
	return currentLevel
}

// SetLogLevelFromString sets log level from string
func SetLogLevelFromString(levelStr string) error {
	switch strings.ToUpper(levelStr) {
	case "DEBUG":
		SetLogLevel(DEBUG)
	case "INFO":
		SetLogLevel(INFO)
	case "WARN", "WARNING":
		SetLogLevel(WARN)
	case "ERROR":
		SetLogLevel(ERROR)
	case "FATAL":
		SetLogLevel(FATAL)
	default:
		return fmt.Errorf("invalid log level: %s", levelStr)
	}
	return nil
}