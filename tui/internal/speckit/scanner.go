// Package speckit - scanner.go provides file comparison logic for speckit projects
package speckit

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// canonicalFiles is the list of bash scripts to compare against canonical versions
// These are the files that enforce constitutional branch naming
var canonicalFiles = []string{
	"scripts/bash/common.sh",
	"scripts/bash/create-new-feature.sh",
}

// getCanonicalFilePaths returns the list of canonical bash script paths relative to .specify/
func getCanonicalFilePaths() []string {
	return canonicalFiles
}

// readFileLines reads a file and returns its lines as a slice
func readFileLines(path string) ([]string, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return lines, nil
}

// compareFiles compares two files and returns the differences found
// Returns nil if files are identical or if either file doesn't exist
func compareFiles(canonicalPath, projectPath string) ([]FileDifference, error) {
	// Read both files
	canonicalLines, err := readFileLines(canonicalPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil // Canonical file missing - skip
		}
		return nil, fmt.Errorf("reading canonical file: %w", err)
	}

	projectLines, err := readFileLines(projectPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil // Project file missing - skip
		}
		return nil, fmt.Errorf("reading project file: %w", err)
	}

	var diffs []FileDifference

	// Find differing regions
	// We'll use a simple approach: find contiguous blocks of differences
	i := 0
	maxLen := len(canonicalLines)
	if len(projectLines) > maxLen {
		maxLen = len(projectLines)
	}

	for i < maxLen {
		// Skip identical lines
		if i < len(canonicalLines) && i < len(projectLines) && canonicalLines[i] == projectLines[i] {
			i++
			continue
		}

		// Found a difference - find the extent
		startLine := i + 1 // 1-indexed
		var canonicalContent, projectContent strings.Builder

		// Collect differing lines
		for i < maxLen {
			if i < len(canonicalLines) && i < len(projectLines) && canonicalLines[i] == projectLines[i] {
				break // Back to identical
			}

			if i < len(canonicalLines) {
				if canonicalContent.Len() > 0 {
					canonicalContent.WriteString("\n")
				}
				canonicalContent.WriteString(canonicalLines[i])
			}

			if i < len(projectLines) {
				if projectContent.Len() > 0 {
					projectContent.WriteString("\n")
				}
				projectContent.WriteString(projectLines[i])
			}

			i++
		}

		endLine := i // 1-indexed (exclusive becomes inclusive)

		diffs = append(diffs, FileDifference{
			LineStart:        startLine,
			LineEnd:          endLine,
			CanonicalContent: canonicalContent.String(),
			ProjectContent:   projectContent.String(),
		})
	}

	return diffs, nil
}

// ScanProject scans a project directory and compares speckit files against canonical versions
// repoRoot is the path to the ghostty-config-files repo (canonical source)
// projectPath is the path to the target project being scanned
func ScanProject(projectPath, repoRoot string) ([]FileDifference, error) {
	var allDiffs []FileDifference

	canonicalBase := filepath.Join(repoRoot, ".specify")
	projectBase := filepath.Join(projectPath, ".specify")

	// Check if project has .specify/
	if _, err := os.Stat(projectBase); os.IsNotExist(err) {
		return nil, ErrNoSpecKit
	}

	// Compare each canonical file
	for _, relPath := range getCanonicalFilePaths() {
		canonicalPath := filepath.Join(canonicalBase, relPath)
		projectFilePath := filepath.Join(projectBase, relPath)

		diffs, err := compareFiles(canonicalPath, projectFilePath)
		if err != nil {
			return nil, fmt.Errorf("comparing %s: %w", relPath, err)
		}

		// Add file path to each diff
		for i := range diffs {
			diffs[i].File = relPath
		}

		allDiffs = append(allDiffs, diffs...)
	}

	return allDiffs, nil
}

// generateUnifiedDiff generates a unified diff format string for display
func generateUnifiedDiff(canonicalLines, projectLines []string, filename string) string {
	var result strings.Builder

	result.WriteString(fmt.Sprintf("--- a/.specify/%s (canonical)\n", filename))
	result.WriteString(fmt.Sprintf("+++ b/.specify/%s (project)\n", filename))

	// Simple unified diff generation
	// Find differing regions and output with context
	const contextLines = 3

	i := 0
	maxLen := len(canonicalLines)
	if len(projectLines) > maxLen {
		maxLen = len(projectLines)
	}

	for i < maxLen {
		// Skip identical lines
		if i < len(canonicalLines) && i < len(projectLines) && canonicalLines[i] == projectLines[i] {
			i++
			continue
		}

		// Found a difference - find extent and add context
		diffStart := i
		diffEnd := i

		// Find extent of difference
		for diffEnd < maxLen {
			if diffEnd < len(canonicalLines) && diffEnd < len(projectLines) && canonicalLines[diffEnd] == projectLines[diffEnd] {
				break
			}
			diffEnd++
		}

		// Calculate context boundaries
		ctxStart := diffStart - contextLines
		if ctxStart < 0 {
			ctxStart = 0
		}
		ctxEnd := diffEnd + contextLines
		if ctxEnd > maxLen {
			ctxEnd = maxLen
		}

		// Output hunk header
		canonStart := ctxStart + 1
		canonCount := 0
		if diffEnd <= len(canonicalLines) {
			canonCount = min(ctxEnd, len(canonicalLines)) - ctxStart
		}
		projStart := ctxStart + 1
		projCount := 0
		if diffEnd <= len(projectLines) {
			projCount = min(ctxEnd, len(projectLines)) - ctxStart
		}

		result.WriteString(fmt.Sprintf("@@ -%d,%d +%d,%d @@\n", canonStart, canonCount, projStart, projCount))

		// Output context and diff lines
		for j := ctxStart; j < ctxEnd; j++ {
			inCanonical := j < len(canonicalLines)
			inProject := j < len(projectLines)

			if j >= diffStart && j < diffEnd {
				// In the diff region
				if inCanonical {
					result.WriteString(fmt.Sprintf("-%s\n", canonicalLines[j]))
				}
				if inProject && (!inCanonical || canonicalLines[j] != projectLines[j]) {
					result.WriteString(fmt.Sprintf("+%s\n", projectLines[j]))
				}
			} else {
				// Context line
				if inCanonical {
					result.WriteString(fmt.Sprintf(" %s\n", canonicalLines[j]))
				} else if inProject {
					result.WriteString(fmt.Sprintf(" %s\n", projectLines[j]))
				}
			}
		}

		i = diffEnd
	}

	return result.String()
}

// GenerateDiffOutput generates a full diff output for all differences in a project
func GenerateDiffOutput(projectPath, repoRoot string, diffs []FileDifference) (string, error) {
	if len(diffs) == 0 {
		return "No differences found - project is up to date.", nil
	}

	var result strings.Builder

	canonicalBase := filepath.Join(repoRoot, ".specify")
	projectBase := filepath.Join(projectPath, ".specify")

	// Group diffs by file
	fileMap := make(map[string][]FileDifference)
	for _, diff := range diffs {
		fileMap[diff.File] = append(fileMap[diff.File], diff)
	}

	// Generate diff for each file
	for _, relPath := range getCanonicalFilePaths() {
		if _, ok := fileMap[relPath]; !ok {
			continue // No diffs for this file
		}

		canonicalPath := filepath.Join(canonicalBase, relPath)
		projectFilePath := filepath.Join(projectBase, relPath)

		canonicalLines, _ := readFileLines(canonicalPath)
		projectLines, _ := readFileLines(projectFilePath)

		diff := generateUnifiedDiff(canonicalLines, projectLines, relPath)
		if diff != "" {
			result.WriteString(diff)
			result.WriteString("\n")
		}
	}

	return result.String(), nil
}

// min returns the minimum of two integers
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
