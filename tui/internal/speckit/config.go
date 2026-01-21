// Package speckit - config.go handles config persistence for tracked projects
package speckit

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"time"
)

// configFileName is the name of the config file
const configFileName = "speckit-projects.json"

// ErrNoSpecKit is returned when a directory doesn't have a .specify/ folder
var ErrNoSpecKit = errors.New("no speckit installation found (.specify/ directory missing)")

// ErrDirNotExist is returned when the directory doesn't exist
var ErrDirNotExist = errors.New("directory does not exist")

// ErrAlreadyTracked is returned when trying to add a project that's already tracked
var ErrAlreadyTracked = errors.New("project is already being tracked")

// getConfigDir returns the config directory path (~/.config/ghostty-installer/)
func getConfigDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(homeDir, ".config", "ghostty-installer"), nil
}

// getConfigPath returns the full path to the config file
func getConfigPath() (string, error) {
	configDir, err := getConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(configDir, configFileName), nil
}

// LoadConfig loads the project config from disk, creating an empty one if missing
func LoadConfig() (*ProjectConfig, error) {
	configPath, err := getConfigPath()
	if err != nil {
		return nil, err
	}

	// Check if file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// Return empty config if file doesn't exist
		return NewProjectConfig(), nil
	}

	// Read and parse file
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var config ProjectConfig
	if err := json.Unmarshal(data, &config); err != nil {
		// Config file is corrupted - return empty config and let caller decide
		return NewProjectConfig(), nil
	}

	return &config, nil
}

// SaveConfig saves the project config to disk with pretty-printed JSON
func SaveConfig(config *ProjectConfig) error {
	configDir, err := getConfigDir()
	if err != nil {
		return err
	}

	// Ensure config directory exists
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return err
	}

	configPath, err := getConfigPath()
	if err != nil {
		return err
	}

	// Marshal with indentation for human readability
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(configPath, data, 0644)
}

// AddProject adds a new project to tracking after validating it has .specify/
func AddProject(config *ProjectConfig, projectPath string) error {
	// Convert to absolute path
	absPath, err := filepath.Abs(projectPath)
	if err != nil {
		return err
	}

	// Check if directory exists
	info, err := os.Stat(absPath)
	if os.IsNotExist(err) {
		return ErrDirNotExist
	}
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return ErrDirNotExist
	}

	// Check if .specify/ exists
	specifyPath := filepath.Join(absPath, ".specify")
	if _, err := os.Stat(specifyPath); os.IsNotExist(err) {
		return ErrNoSpecKit
	}

	// Check if already tracked
	if config.HasProject(absPath) {
		return ErrAlreadyTracked
	}

	// Add project with pending status
	config.Projects = append(config.Projects, TrackedProject{
		Path:   absPath,
		Status: StatusPending,
	})

	return nil
}

// RemoveProject removes a project from tracking (does not delete files)
func RemoveProject(config *ProjectConfig, projectPath string) error {
	// Convert to absolute path for matching
	absPath, err := filepath.Abs(projectPath)
	if err != nil {
		return err
	}

	// Find and remove the project
	for i, p := range config.Projects {
		if p.Path == absPath {
			// Remove by replacing with last element and truncating
			config.Projects[i] = config.Projects[len(config.Projects)-1]
			config.Projects = config.Projects[:len(config.Projects)-1]
			return nil
		}
	}

	return nil // Not an error if project wasn't found
}

// UpdateProjectStatus updates an existing project's status, differences, and backup info
func UpdateProjectStatus(config *ProjectConfig, path string, status ProjectStatus, diffs []FileDifference, backupPath string) error {
	project := config.FindProject(path)
	if project == nil {
		return errors.New("project not found")
	}

	now := time.Now()
	project.Status = status
	project.LastScanned = &now
	project.Differences = diffs

	if backupPath != "" {
		project.LastBackup = backupPath
	}

	return nil
}

// ClearProjectBackup clears the backup path for a project (after rollback)
func ClearProjectBackup(config *ProjectConfig, path string) error {
	project := config.FindProject(path)
	if project == nil {
		return errors.New("project not found")
	}

	project.LastBackup = ""
	return nil
}
