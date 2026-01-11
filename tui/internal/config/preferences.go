// Package config provides user preference management for the installer
package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/kairin/ghostty-installer/internal/registry"
)

// Preferences stores user installation method preferences
type Preferences struct {
	GhosttyMethod registry.InstallMethod `json:"ghostty_method"`
	LastModified  time.Time              `json:"last_modified"`
}

// PreferenceStore manages the preference file on disk
type PreferenceStore struct {
	path string
}

// NewPreferenceStore creates a preference store with default path
// Default: ~/.config/ghostty-installer/preferences.json
func NewPreferenceStore() *PreferenceStore {
	home, err := os.UserHomeDir()
	if err != nil {
		home = os.Getenv("HOME")
	}

	configDir := filepath.Join(home, ".config", "ghostty-installer")
	return &PreferenceStore{
		path: filepath.Join(configDir, "preferences.json"),
	}
}

// NewPreferenceStoreWithPath creates a preference store with custom path
func NewPreferenceStoreWithPath(path string) *PreferenceStore {
	return &PreferenceStore{
		path: path,
	}
}

// Load reads preferences from disk
func (s *PreferenceStore) Load() (*Preferences, error) {
	data, err := os.ReadFile(s.path)
	if err != nil {
		if os.IsNotExist(err) {
			// File doesn't exist yet, return empty preferences
			return &Preferences{}, nil
		}
		return nil, fmt.Errorf("failed to read preferences: %w", err)
	}

	var prefs Preferences
	if err := json.Unmarshal(data, &prefs); err != nil {
		return nil, fmt.Errorf("failed to parse preferences: %w", err)
	}

	return &prefs, nil
}

// Save writes preferences to disk
func (s *PreferenceStore) Save(prefs *Preferences) error {
	// Update last modified time
	prefs.LastModified = time.Now()

	// Ensure directory exists
	dir := filepath.Dir(s.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	// Marshal to JSON with indentation
	data, err := json.MarshalIndent(prefs, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal preferences: %w", err)
	}

	// Write to file with user-only read/write permissions
	if err := os.WriteFile(s.path, data, 0644); err != nil {
		return fmt.Errorf("failed to write preferences: %w", err)
	}

	return nil
}

// GetGhosttyMethod returns the saved Ghostty installation method
// Returns empty string if no preference is saved
func (s *PreferenceStore) GetGhosttyMethod() (registry.InstallMethod, error) {
	prefs, err := s.Load()
	if err != nil {
		return "", err
	}

	return prefs.GhosttyMethod, nil
}

// SetGhosttyMethod saves the user's preferred Ghostty installation method
func (s *PreferenceStore) SetGhosttyMethod(method registry.InstallMethod) error {
	prefs, err := s.Load()
	if err != nil {
		// If load fails, create new preferences
		prefs = &Preferences{}
	}

	prefs.GhosttyMethod = method
	return s.Save(prefs)
}

// Clear removes the preference file
func (s *PreferenceStore) Clear() error {
	if err := os.Remove(s.path); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to clear preferences: %w", err)
	}
	return nil
}

// Exists checks if the preference file exists
func (s *PreferenceStore) Exists() bool {
	_, err := os.Stat(s.path)
	return err == nil
}

// GetPath returns the path to the preference file
func (s *PreferenceStore) GetPath() string {
	return s.path
}
