// Package speckit - patcher.go provides backup and patch application logic
package speckit

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// backupDirPrefix is the prefix for backup directories
const backupDirPrefix = ".backup-"

// createBackupDir creates a timestamped backup directory within the project's .specify/
// Returns the full path to the created backup directory
func createBackupDir(projectPath string) (string, error) {
	timestamp := time.Now().Format("20060102-150405")
	backupDir := filepath.Join(projectPath, ".specify", backupDirPrefix+timestamp)

	if err := os.MkdirAll(backupDir, 0755); err != nil {
		return "", fmt.Errorf("creating backup directory: %w", err)
	}

	return backupDir, nil
}

// copyFile copies a file from src to dst, preserving permissions
func copyFile(src, dst string) error {
	// Get source file info for permissions
	srcInfo, err := os.Stat(src)
	if err != nil {
		return fmt.Errorf("stat source: %w", err)
	}

	// Ensure destination directory exists
	if err := os.MkdirAll(filepath.Dir(dst), 0755); err != nil {
		return fmt.Errorf("create dest dir: %w", err)
	}

	// Open source file
	srcFile, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("open source: %w", err)
	}
	defer srcFile.Close()

	// Create destination file with same permissions
	dstFile, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, srcInfo.Mode())
	if err != nil {
		return fmt.Errorf("create dest: %w", err)
	}
	defer dstFile.Close()

	// Copy content
	if _, err := io.Copy(dstFile, srcFile); err != nil {
		return fmt.Errorf("copy content: %w", err)
	}

	return nil
}

// CreateBackup creates a backup of the specified files before patching
// files is a list of relative paths within .specify/ to backup
// Returns the backup directory path
func CreateBackup(projectPath string, files []string) (string, error) {
	backupDir, err := createBackupDir(projectPath)
	if err != nil {
		return "", err
	}

	specifyDir := filepath.Join(projectPath, ".specify")

	for _, relPath := range files {
		srcPath := filepath.Join(specifyDir, relPath)
		dstPath := filepath.Join(backupDir, relPath)

		// Skip if source doesn't exist
		if _, err := os.Stat(srcPath); os.IsNotExist(err) {
			continue
		}

		if err := copyFile(srcPath, dstPath); err != nil {
			// Cleanup on failure
			os.RemoveAll(backupDir)
			return "", fmt.Errorf("backing up %s: %w", relPath, err)
		}
	}

	return backupDir, nil
}

// ApplyPatch copies canonical files to the project to replace differing content
// This is a full-file replacement strategy - simpler and more reliable than line-by-line patching
func ApplyPatch(projectPath, repoRoot string, diffs []FileDifference) error {
	if len(diffs) == 0 {
		return nil // Nothing to patch
	}

	canonicalBase := filepath.Join(repoRoot, ".specify")
	projectBase := filepath.Join(projectPath, ".specify")

	// Get unique files to patch
	filesToPatch := make(map[string]bool)
	for _, diff := range diffs {
		filesToPatch[diff.File] = true
	}

	// Copy each canonical file to the project
	for relPath := range filesToPatch {
		srcPath := filepath.Join(canonicalBase, relPath)
		dstPath := filepath.Join(projectBase, relPath)

		if err := copyFile(srcPath, dstPath); err != nil {
			return fmt.Errorf("patching %s: %w", relPath, err)
		}
	}

	return nil
}

// RestoreFromBackup restores files from a backup directory
func RestoreFromBackup(projectPath, backupPath string) error {
	if backupPath == "" {
		return fmt.Errorf("no backup path provided")
	}

	// Check if backup exists
	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		return fmt.Errorf("backup directory not found: %s", backupPath)
	}

	projectBase := filepath.Join(projectPath, ".specify")

	// Walk the backup directory and restore each file
	err := filepath.Walk(backupPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories
		if info.IsDir() {
			return nil
		}

		// Calculate relative path from backup
		relPath, err := filepath.Rel(backupPath, path)
		if err != nil {
			return err
		}

		// Restore to project
		dstPath := filepath.Join(projectBase, relPath)
		if err := copyFile(path, dstPath); err != nil {
			return fmt.Errorf("restoring %s: %w", relPath, err)
		}

		return nil
	})

	return err
}

// GetLatestBackup finds the most recent backup directory for a project
func GetLatestBackup(projectPath string) (string, error) {
	specifyDir := filepath.Join(projectPath, ".specify")

	entries, err := os.ReadDir(specifyDir)
	if err != nil {
		return "", fmt.Errorf("reading .specify directory: %w", err)
	}

	var latestBackup string
	var latestTime time.Time

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		name := entry.Name()
		if len(name) < len(backupDirPrefix) || name[:len(backupDirPrefix)] != backupDirPrefix {
			continue
		}

		// Parse timestamp from directory name
		timestampStr := name[len(backupDirPrefix):]
		t, err := time.Parse("20060102-150405", timestampStr)
		if err != nil {
			continue // Invalid timestamp format, skip
		}

		if latestBackup == "" || t.After(latestTime) {
			latestBackup = filepath.Join(specifyDir, name)
			latestTime = t
		}
	}

	if latestBackup == "" {
		return "", nil // No backup found (not an error)
	}

	return latestBackup, nil
}

// GetFilesToPatch returns the unique list of files that need to be patched
func GetFilesToPatch(diffs []FileDifference) []string {
	fileMap := make(map[string]bool)
	for _, diff := range diffs {
		fileMap[diff.File] = true
	}

	files := make([]string, 0, len(fileMap))
	for f := range fileMap {
		files = append(files, f)
	}

	return files
}
