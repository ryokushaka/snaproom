package utility

import (
	"os"
	"path"
	"path/filepath"
	"sync"
)

var currentDir string
var currentDirOnce sync.Once

func CurrentDir() string {
	currentDirOnce.Do(func() {
		// For containerized environments, use working directory instead of executable path
		// This ensures logs are created in /app (working directory) rather than /usr/local/bin
		if workDir := os.Getenv("PWD"); workDir != "" {
			currentDir = workDir
		} else {
			// Fallback to current working directory
			if wd, err := os.Getwd(); err == nil {
				currentDir = wd
			} else {
				// Last resort: relative to executable (original behavior)
				exec, _ := os.Executable()
				execDir := filepath.Dir(exec)
				currentDir = path.Join(execDir, "..")
			}
		}
	})
	
	return currentDir
}