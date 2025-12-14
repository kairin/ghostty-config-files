// Package diagnostics - detector.go handles running detector scripts and parsing output
package diagnostics

import (
	"context"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

// DetectorScript paths relative to repo root
var detectorScripts = []string{
	"scripts/007-diagnostics/detect_failed_services.sh",
	"scripts/007-diagnostics/detect_orphaned_services.sh",
	"scripts/007-diagnostics/detect_network_wait_issues.sh",
	"scripts/007-diagnostics/detect_unsupported_snaps.sh",
	"scripts/007-diagnostics/detect_cosmetic_warnings.sh",
}

// DetectorTimeout is the timeout for each detector script
const DetectorTimeout = 30 * time.Second

// DetectorResult holds the result from a single detector
type DetectorResult struct {
	Script string
	Issues []*Issue
	Error  error
}

// RunDetectors executes all detector scripts concurrently and aggregates results
func RunDetectors(ctx context.Context, repoRoot string) ([]*Issue, []error) {
	var wg sync.WaitGroup
	results := make(chan DetectorResult, len(detectorScripts))

	// Run each detector concurrently
	for _, script := range detectorScripts {
		wg.Add(1)
		go func(scriptPath string) {
			defer wg.Done()
			result := runSingleDetector(ctx, repoRoot, scriptPath)
			results <- result
		}(script)
	}

	// Close results channel when all detectors complete
	go func() {
		wg.Wait()
		close(results)
	}()

	// Collect results
	allIssues := make([]*Issue, 0)
	errors := make([]error, 0)

	for result := range results {
		if result.Error != nil {
			errors = append(errors, result.Error)
			continue
		}
		allIssues = append(allIssues, result.Issues...)
	}

	return allIssues, errors
}

// runSingleDetector executes a single detector script
func runSingleDetector(ctx context.Context, repoRoot, scriptPath string) DetectorResult {
	result := DetectorResult{Script: scriptPath}

	// Build absolute path
	fullPath := filepath.Join(repoRoot, scriptPath)

	// Create context with timeout
	ctx, cancel := context.WithTimeout(ctx, DetectorTimeout)
	defer cancel()

	// Execute script
	cmd := exec.CommandContext(ctx, "bash", fullPath)
	cmd.Dir = repoRoot

	output, err := cmd.Output()
	if err != nil {
		// Check if it's a context error (timeout/cancellation)
		if ctx.Err() != nil {
			result.Error = ctx.Err()
			return result
		}
		// Non-zero exit is okay - might just mean no issues found
		// Only record error if we got no output
		if len(output) == 0 {
			result.Error = err
			return result
		}
	}

	// Parse output into issues
	result.Issues = ParseIssues(string(output))
	return result
}

// RunSingleDetector runs one detector script (for testing or targeted scanning)
func RunSingleDetector(ctx context.Context, repoRoot, scriptPath string) ([]*Issue, error) {
	result := runSingleDetector(ctx, repoRoot, scriptPath)
	return result.Issues, result.Error
}

// GetDetectorScripts returns the list of detector script paths
func GetDetectorScripts() []string {
	return detectorScripts
}

// DetectorExists checks if a detector script exists
func DetectorExists(repoRoot, scriptPath string) bool {
	fullPath := filepath.Join(repoRoot, scriptPath)
	_, err := exec.LookPath("bash")
	if err != nil {
		return false
	}

	cmd := exec.Command("test", "-f", fullPath)
	return cmd.Run() == nil
}

// GetMissingDetectors returns a list of missing detector scripts
func GetMissingDetectors(repoRoot string) []string {
	missing := make([]string, 0)
	for _, script := range detectorScripts {
		if !DetectorExists(repoRoot, script) {
			missing = append(missing, script)
		}
	}
	return missing
}

// ScanResult holds the complete scan result
type ScanResult struct {
	Issues        []*Issue
	Errors        []error
	ScanTime      time.Time
	Duration      time.Duration
	ScriptsRan    int
	ScriptsFailed int
}

// RunFullScan executes all detectors and returns a complete scan result
func RunFullScan(ctx context.Context, repoRoot string) *ScanResult {
	start := time.Now()

	issues, errors := RunDetectors(ctx, repoRoot)

	return &ScanResult{
		Issues:        issues,
		Errors:        errors,
		ScanTime:      start,
		Duration:      time.Since(start),
		ScriptsRan:    len(detectorScripts),
		ScriptsFailed: len(errors),
	}
}

// Summary returns a human-readable summary of the scan
func (r *ScanResult) Summary() string {
	var b strings.Builder

	b.WriteString("Scan completed in ")
	b.WriteString(r.Duration.Round(time.Millisecond).String())
	b.WriteString("\n")

	total := len(r.Issues)
	groups := GroupBySeverity(r.Issues)

	b.WriteString("Found ")
	b.WriteString(string(rune('0' + total)))
	b.WriteString(" issues: ")

	parts := make([]string, 0, 3)
	if len(groups[SeverityCritical]) > 0 {
		parts = append(parts, string(rune('0'+len(groups[SeverityCritical])))+" critical")
	}
	if len(groups[SeverityModerate]) > 0 {
		parts = append(parts, string(rune('0'+len(groups[SeverityModerate])))+" moderate")
	}
	if len(groups[SeverityLow]) > 0 {
		parts = append(parts, string(rune('0'+len(groups[SeverityLow])))+" low")
	}

	if len(parts) > 0 {
		b.WriteString(strings.Join(parts, ", "))
	} else {
		b.WriteString("no issues found")
	}

	if r.ScriptsFailed > 0 {
		b.WriteString(" (")
		b.WriteString(string(rune('0' + r.ScriptsFailed)))
		b.WriteString(" scripts failed)")
	}

	return b.String()
}
