// Package cache provides status caching with TTL
package cache

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

const (
	CacheDir   = ".cache/ghostty-installer"
	StatusTTL  = 5 * time.Minute  // Dashboard refresh
	VersionTTL = 24 * time.Hour   // Latest version checks
)

// ToolStatus represents the cached status of a tool
type ToolStatus struct {
	ID        string    `json:"id"`
	Status    string    `json:"status"`    // "INSTALLED", "Not Installed", "Unknown"
	Version   string    `json:"version"`   // Installed version
	Method    string    `json:"method"`    // Installation method
	Location  string    `json:"location"`  // Path to binary
	LatestVer string    `json:"latest"`    // Latest available version
	Details   []string  `json:"details"`   // Sub-items (npm versions, globals, etc.)
	CachedAt  time.Time `json:"cached_at"` // When this was cached
}

// IsInstalled returns true if the tool is installed
func (s *ToolStatus) IsInstalled() bool {
	return s.Status == "INSTALLED"
}

// NeedsUpdate returns true if an update is available
func (s *ToolStatus) NeedsUpdate() bool {
	if !s.IsInstalled() || s.LatestVer == "" || s.LatestVer == "-" {
		return false
	}
	// Simple string comparison - in production, use semver
	return s.Version != s.LatestVer && s.LatestVer > s.Version
}

// StatusCache manages cached tool statuses
type StatusCache struct {
	mu      sync.RWMutex
	entries map[string]*ToolStatus
	path    string
}

// NewStatusCache creates a new cache
func NewStatusCache() *StatusCache {
	home, _ := os.UserHomeDir()
	cachePath := filepath.Join(home, CacheDir, "status.json")

	c := &StatusCache{
		entries: make(map[string]*ToolStatus),
		path:    cachePath,
	}

	// Load existing cache
	c.load()

	return c
}

// Get returns a cached status if valid
func (c *StatusCache) Get(toolID string) (*ToolStatus, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()

	entry, ok := c.entries[toolID]
	if !ok {
		return nil, false
	}

	// Check TTL
	if time.Since(entry.CachedAt) > StatusTTL {
		return nil, false
	}

	return entry, true
}

// Set stores a status in the cache and persists to disk
func (c *StatusCache) Set(status *ToolStatus) {
	c.mu.Lock()
	status.CachedAt = time.Now()
	c.entries[status.ID] = status
	c.mu.Unlock()

	// Persist to disk (non-blocking, errors logged but not returned)
	go func() {
		if err := c.Save(); err != nil {
			// Silently ignore save errors - cache is best-effort
			_ = err
		}
	}()
}

// Invalidate removes a tool from the cache
func (c *StatusCache) Invalidate(toolID string) {
	c.mu.Lock()
	defer c.mu.Unlock()

	delete(c.entries, toolID)
}

// InvalidateAll clears the entire cache
func (c *StatusCache) InvalidateAll() {
	c.mu.Lock()
	defer c.mu.Unlock()

	c.entries = make(map[string]*ToolStatus)
}

// Save persists the cache to disk
func (c *StatusCache) Save() error {
	c.mu.RLock()
	defer c.mu.RUnlock()

	// Ensure directory exists
	dir := filepath.Dir(c.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	data, err := json.MarshalIndent(c.entries, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(c.path, data, 0644)
}

// load reads the cache from disk
func (c *StatusCache) load() {
	data, err := os.ReadFile(c.path)
	if err != nil {
		return // No cache file yet
	}

	var entries map[string]*ToolStatus
	if err := json.Unmarshal(data, &entries); err != nil {
		return // Invalid cache file
	}

	// Lock before modifying entries to prevent race condition
	c.mu.Lock()
	c.entries = entries
	c.mu.Unlock()
}

// ParseCheckOutput parses the pipe-delimited output from check scripts
// Format: STATUS|VERSION|METHOD|LOCATION|LATEST
// Location can have sub-details separated by ^
func ParseCheckOutput(toolID string, output string) *ToolStatus {
	output = strings.TrimSpace(output)
	parts := strings.Split(output, "|")

	if len(parts) < 5 {
		return &ToolStatus{
			ID:     toolID,
			Status: "Unknown",
		}
	}

	status := &ToolStatus{
		ID:        toolID,
		Status:    parts[0],
		Version:   parts[1],
		Method:    parts[2],
		LatestVer: parts[4],
	}

	// Parse location with sub-details (^-delimited)
	locationParts := strings.Split(parts[3], "^")
	if len(locationParts) > 0 {
		status.Location = locationParts[0]
		if len(locationParts) > 1 {
			status.Details = locationParts[1:]
		}
	}

	return status
}
