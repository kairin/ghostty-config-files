// Package diagnostics - fixer.go handles two-phase fix execution (user-level, then sudo)
package diagnostics

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"
)

// FixTimeout is the timeout for each fix command
const FixTimeout = 60 * time.Second

// FixResult represents the result of a single fix attempt
type FixResult struct {
	Issue    *Issue
	Success  bool
	Output   string
	Error    error
	Duration time.Duration
}

// BatchFixResult represents the results of a batch fix operation
type BatchFixResult struct {
	UserLevel   []FixResult
	SudoLevel   []FixResult
	TotalFixed  int
	TotalFailed int
	Duration    time.Duration
	NeedsReboot bool
}

// Fixer handles issue fix execution
type Fixer struct {
	repoRoot   string
	demoMode   bool
	sudoCached bool
}

// NewFixer creates a new fixer
func NewFixer(repoRoot string, demoMode, sudoCached bool) *Fixer {
	return &Fixer{
		repoRoot:   repoRoot,
		demoMode:   demoMode,
		sudoCached: sudoCached,
	}
}

// ExecuteFix executes a single fix command
func (f *Fixer) ExecuteFix(ctx context.Context, issue *Issue) FixResult {
	result := FixResult{Issue: issue}
	start := time.Now()

	if !issue.IsFixable() || issue.FixCommand == "" {
		result.Error = fmt.Errorf("issue is not fixable")
		return result
	}

	// In demo mode, skip sudo commands unless cached
	if f.demoMode && issue.RequiresSudo() && !f.sudoCached {
		result.Error = fmt.Errorf("skipped in demo mode (requires sudo)")
		result.Output = "[DEMO] Would execute: " + issue.FixCommand
		return result
	}

	// Create context with timeout
	ctx, cancel := context.WithTimeout(ctx, FixTimeout)
	defer cancel()

	// Execute the fix command
	cmd := exec.CommandContext(ctx, "bash", "-c", issue.FixCommand)
	cmd.Dir = f.repoRoot

	output, err := cmd.CombinedOutput()
	result.Duration = time.Since(start)
	result.Output = string(output)

	if err != nil {
		if ctx.Err() != nil {
			result.Error = fmt.Errorf("timeout after %v", FixTimeout)
		} else {
			result.Error = fmt.Errorf("command failed: %w", err)
		}
		return result
	}

	result.Success = true
	return result
}

// ExecuteBatch executes fixes for multiple issues in two phases
// Phase 1: User-level fixes (no sudo required)
// Phase 2: Sudo-level fixes (batched with single auth prompt)
func (f *Fixer) ExecuteBatch(ctx context.Context, issues []*Issue) *BatchFixResult {
	start := time.Now()
	result := &BatchFixResult{
		UserLevel: make([]FixResult, 0),
		SudoLevel: make([]FixResult, 0),
	}

	// Separate by sudo requirement
	userLevel, sudoLevel := SeparateBySudo(issues)

	// Phase 1: Execute user-level fixes
	for _, issue := range userLevel {
		fixResult := f.ExecuteFix(ctx, issue)
		result.UserLevel = append(result.UserLevel, fixResult)
		if fixResult.Success {
			result.TotalFixed++
		} else {
			result.TotalFailed++
		}

		// Check for cancellation
		select {
		case <-ctx.Done():
			result.Duration = time.Since(start)
			return result
		default:
		}
	}

	// Phase 2: Execute sudo-level fixes
	if len(sudoLevel) > 0 {
		// In demo mode without cached sudo, skip all sudo fixes
		if f.demoMode && !f.sudoCached {
			for _, issue := range sudoLevel {
				result.SudoLevel = append(result.SudoLevel, FixResult{
					Issue:  issue,
					Error:  fmt.Errorf("skipped in demo mode (requires sudo)"),
					Output: "[DEMO] Would execute: " + issue.FixCommand,
				})
				result.TotalFailed++
			}
		} else {
			// Execute each sudo fix
			for _, issue := range sudoLevel {
				fixResult := f.ExecuteFix(ctx, issue)
				result.SudoLevel = append(result.SudoLevel, fixResult)
				if fixResult.Success {
					result.TotalFixed++
				} else {
					result.TotalFailed++
				}

				// Check for cancellation
				select {
				case <-ctx.Done():
					result.Duration = time.Since(start)
					return result
				default:
				}
			}
		}
	}

	// Check if any fix suggests a reboot
	result.NeedsReboot = f.shouldRecommendReboot(issues)
	result.Duration = time.Since(start)
	return result
}

// shouldRecommendReboot determines if fixes warrant a reboot recommendation
func (f *Fixer) shouldRecommendReboot(issues []*Issue) bool {
	for _, issue := range issues {
		// Certain issue types typically need a reboot to fully take effect
		switch issue.Type {
		case "ORPHANED_SERVICE", "FAILED_SERVICE", "NETWORK_WAIT":
			return true
		}

		// Any fix involving systemctl daemon-reload or kernel-related
		if strings.Contains(issue.FixCommand, "daemon-reload") {
			return true
		}
	}
	return false
}

// Summary generates a human-readable summary of fix results
func (r *BatchFixResult) Summary() string {
	var b strings.Builder

	b.WriteString(fmt.Sprintf("Fix complete in %v\n", r.Duration.Round(time.Millisecond)))
	b.WriteString(fmt.Sprintf("Fixed: %d, Failed: %d\n", r.TotalFixed, r.TotalFailed))

	if len(r.UserLevel) > 0 {
		b.WriteString(fmt.Sprintf("User-level: %d commands\n", len(r.UserLevel)))
	}
	if len(r.SudoLevel) > 0 {
		b.WriteString(fmt.Sprintf("System-level: %d commands\n", len(r.SudoLevel)))
	}

	if r.NeedsReboot {
		b.WriteString("\nReboot recommended to apply changes")
	}

	return b.String()
}

// SuccessCount returns the number of successful fixes
func (r *BatchFixResult) SuccessCount() int {
	return r.TotalFixed
}

// FailureCount returns the number of failed fixes
func (r *BatchFixResult) FailureCount() int {
	return r.TotalFailed
}

// AllSuccessful returns true if all fixes succeeded
func (r *BatchFixResult) AllSuccessful() bool {
	return r.TotalFailed == 0 && r.TotalFixed > 0
}

// GetFailedIssues returns all issues that failed to fix
func (r *BatchFixResult) GetFailedIssues() []*Issue {
	failed := make([]*Issue, 0)

	for _, res := range r.UserLevel {
		if !res.Success {
			failed = append(failed, res.Issue)
		}
	}
	for _, res := range r.SudoLevel {
		if !res.Success {
			failed = append(failed, res.Issue)
		}
	}

	return failed
}
