// Package speckit provides core logic for the SpecKit Project Updater feature.
// It handles tracking speckit installations, comparing files against canonical versions,
// and applying patches to enforce constitutional branch naming.
package speckit

import "time"

// ProjectStatus represents the current state of a tracked project
type ProjectStatus string

const (
	// StatusPending indicates the project has not been scanned yet
	StatusPending ProjectStatus = "pending"
	// StatusUpToDate indicates the project matches canonical files
	StatusUpToDate ProjectStatus = "up-to-date"
	// StatusNeedsUpdate indicates the project has differing files
	StatusNeedsUpdate ProjectStatus = "needs-update"
	// StatusError indicates an error occurred during scanning
	StatusError ProjectStatus = "error"
)

// FileDifference represents a detected difference in a speckit file
type FileDifference struct {
	// File is the relative path within .specify/ (e.g., "scripts/bash/common.sh")
	File string `json:"file"`
	// LineStart is the first differing line number (1-indexed)
	LineStart int `json:"lineStart"`
	// LineEnd is the last differing line number (1-indexed)
	LineEnd int `json:"lineEnd"`
	// CanonicalContent is the content from the canonical repo
	CanonicalContent string `json:"canonicalContent"`
	// ProjectContent is the content from the target project
	ProjectContent string `json:"projectContent"`
}

// TrackedProject represents a project directory with speckit installation being monitored
type TrackedProject struct {
	// Path is the absolute path to the project root
	Path string `json:"path"`
	// LastScanned is the timestamp of the last scan (ISO 8601)
	LastScanned *time.Time `json:"lastScanned,omitempty"`
	// Status is the current state of the project
	Status ProjectStatus `json:"status"`
	// Differences contains the file differences found during the last scan
	Differences []FileDifference `json:"differences,omitempty"`
	// LastBackup is the path to the most recent backup, if exists
	LastBackup string `json:"lastBackup,omitempty"`
}

// ProjectConfig is the persisted configuration for tracked projects
type ProjectConfig struct {
	// Version is the config schema version (for future migrations)
	Version int `json:"version"`
	// Projects is the list of tracked projects
	Projects []TrackedProject `json:"projects"`
}

// NewProjectConfig creates a new empty project config with the current schema version
func NewProjectConfig() *ProjectConfig {
	return &ProjectConfig{
		Version:  1,
		Projects: []TrackedProject{},
	}
}

// FindProject finds a project by path, returns nil if not found
func (c *ProjectConfig) FindProject(path string) *TrackedProject {
	for i := range c.Projects {
		if c.Projects[i].Path == path {
			return &c.Projects[i]
		}
	}
	return nil
}

// HasProject checks if a project path is already tracked
func (c *ProjectConfig) HasProject(path string) bool {
	return c.FindProject(path) != nil
}
