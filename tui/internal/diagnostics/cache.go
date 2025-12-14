// Package diagnostics - cache.go handles caching of diagnostic results with boot ID validation
package diagnostics

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

const (
	// CacheDir is the base directory for diagnostics cache
	CacheDir = ".cache/ghostty-boot-diagnostics"
	// CacheFile is the filename for the cached results
	CacheFile = "scan_results.json"
	// CacheTTL is how long cache is valid (24 hours)
	CacheTTL = 24 * time.Hour
)

// DiagnosticsCache holds cached scan results
type DiagnosticsCache struct {
	Version      int           `json:"version"`
	Timestamp    time.Time     `json:"timestamp"`
	BootID       string        `json:"boot_id"`
	Issues       []*Issue      `json:"issues"`
	ScanDuration time.Duration `json:"scan_duration"`
}

// CacheStore manages the diagnostics cache
type CacheStore struct {
	mu      sync.RWMutex
	baseDir string
	cached  *DiagnosticsCache
	bootID  string
}

// NewCacheStore creates a new cache store
func NewCacheStore() *CacheStore {
	home, _ := os.UserHomeDir()
	baseDir := filepath.Join(home, CacheDir)

	store := &CacheStore{
		baseDir: baseDir,
	}

	// Read boot ID once at creation
	store.bootID = readBootID()

	return store
}

// readBootID reads the current boot ID from /proc/sys/kernel/random/boot_id
func readBootID() string {
	data, err := os.ReadFile("/proc/sys/kernel/random/boot_id")
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

// getCachePath returns the full path to the cache file
func (s *CacheStore) getCachePath() string {
	return filepath.Join(s.baseDir, CacheFile)
}

// ensureDir creates the cache directory if it doesn't exist
func (s *CacheStore) ensureDir() error {
	return os.MkdirAll(s.baseDir, 0755)
}

// IsValid checks if the cache is still valid
// Cache is invalid if:
// - It doesn't exist
// - It's older than TTL
// - The boot ID has changed (system rebooted)
func (s *CacheStore) IsValid() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	// Load from disk if not in memory
	if s.cached == nil {
		s.mu.RUnlock()
		s.load()
		s.mu.RLock()
	}

	if s.cached == nil {
		return false
	}

	// Check TTL
	if time.Since(s.cached.Timestamp) > CacheTTL {
		return false
	}

	// Check boot ID (invalidate on reboot)
	if s.cached.BootID != s.bootID && s.bootID != "" {
		return false
	}

	return true
}

// load reads the cache from disk
func (s *CacheStore) load() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	path := s.getCachePath()
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // No cache exists
		}
		return fmt.Errorf("failed to read cache: %w", err)
	}

	var cached DiagnosticsCache
	if err := json.Unmarshal(data, &cached); err != nil {
		return fmt.Errorf("failed to parse cache: %w", err)
	}

	s.cached = &cached
	return nil
}

// Save stores scan results to the cache
func (s *CacheStore) Save(result *ScanResult) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Ensure directory exists
	if err := s.ensureDir(); err != nil {
		return fmt.Errorf("failed to create cache directory: %w", err)
	}

	cache := &DiagnosticsCache{
		Version:      1,
		Timestamp:    result.ScanTime,
		BootID:       s.bootID,
		Issues:       result.Issues,
		ScanDuration: result.Duration,
	}

	// Marshal to JSON
	data, err := json.MarshalIndent(cache, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal cache: %w", err)
	}

	// Write atomically (temp file + rename)
	path := s.getCachePath()
	tempPath := path + ".tmp"

	file, err := os.Create(tempPath)
	if err != nil {
		return fmt.Errorf("failed to create temp file: %w", err)
	}

	if _, err := file.Write(data); err != nil {
		file.Close()
		os.Remove(tempPath)
		return fmt.Errorf("failed to write cache: %w", err)
	}

	if err := file.Sync(); err != nil {
		file.Close()
		os.Remove(tempPath)
		return fmt.Errorf("failed to sync cache: %w", err)
	}

	if err := file.Close(); err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("failed to close cache: %w", err)
	}

	// Atomic rename
	if err := os.Rename(tempPath, path); err != nil {
		os.Remove(tempPath)
		return fmt.Errorf("failed to finalize cache: %w", err)
	}

	s.cached = cache
	return nil
}

// Get returns cached results if valid, nil otherwise
func (s *CacheStore) Get() *DiagnosticsCache {
	if !s.IsValid() {
		return nil
	}

	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.cached
}

// GetIssues returns cached issues if valid
func (s *CacheStore) GetIssues() []*Issue {
	cache := s.Get()
	if cache == nil {
		return nil
	}
	return cache.Issues
}

// Clear removes the cache file
func (s *CacheStore) Clear() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.cached = nil
	path := s.getCachePath()
	err := os.Remove(path)
	if os.IsNotExist(err) {
		return nil
	}
	return err
}

// Age returns how old the cache is
func (s *CacheStore) Age() time.Duration {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if s.cached == nil {
		return 0
	}
	return time.Since(s.cached.Timestamp)
}

// AgeString returns a human-readable cache age
func (s *CacheStore) AgeString() string {
	age := s.Age()
	if age == 0 {
		return "never"
	}

	if age < time.Minute {
		return "just now"
	} else if age < time.Hour {
		mins := int(age.Minutes())
		if mins == 1 {
			return "1m ago"
		}
		return fmt.Sprintf("%dm ago", mins)
	} else if age < 24*time.Hour {
		hours := int(age.Hours())
		if hours == 1 {
			return "1h ago"
		}
		return fmt.Sprintf("%dh ago", hours)
	}

	days := int(age.Hours() / 24)
	if days == 1 {
		return "1 day ago"
	}
	return fmt.Sprintf("%d days ago", days)
}

// GetBootID returns the current boot ID
func (s *CacheStore) GetBootID() string {
	return s.bootID
}

// WasRebootDetected returns true if a reboot was detected since last scan
func (s *CacheStore) WasRebootDetected() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if s.cached == nil || s.bootID == "" {
		return false
	}
	return s.cached.BootID != s.bootID
}
