// Package executor handles running bash scripts with real-time output
package executor

import (
	"bufio"
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
)

// ansiRegex matches ANSI escape sequences (colors, cursor movement, etc.)
var ansiRegex = regexp.MustCompile(`\x1b\[[0-9;]*[a-zA-Z]`)

// sanitizeOutput removes control characters that break TUI display
// Handles: carriage returns (progress bars), ANSI escape sequences, control chars
func sanitizeOutput(text string) string {
	// Handle carriage returns - keep only the last segment after \r
	// This simulates what a real terminal does (overwrites line)
	if idx := strings.LastIndex(text, "\r"); idx != -1 {
		text = text[idx+1:]
	}

	// Strip ANSI escape sequences (colors, cursor movement)
	text = ansiRegex.ReplaceAllString(text, "")

	// Remove other control characters except tab and newline
	var result strings.Builder
	result.Grow(len(text))
	for _, r := range text {
		if r >= 32 || r == '\t' || r == '\n' {
			result.WriteRune(r)
		}
	}

	return result.String()
}

// OutputLine represents a single line of script output
type OutputLine struct {
	Text      string
	Timestamp time.Time
	IsError   bool // true if from stderr
}

// ScriptResult represents the outcome of a script execution
type ScriptResult struct {
	ExitCode int
	Duration time.Duration
	LastLine string // Last line of stdout (useful for check scripts)
}

// RunCheck executes a check script and returns parsed output
func RunCheck(repoRoot, scriptPath string) (string, error) {
	fullPath := filepath.Join(repoRoot, scriptPath)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "bash", fullPath)
	cmd.Dir = repoRoot

	// Set up environment
	cmd.Env = os.Environ()

	output, err := cmd.Output()
	if err != nil {
		// Check scripts may exit non-zero for "not installed"
		// Still return the output if available
		if len(output) > 0 {
			return strings.TrimSpace(string(output)), nil
		}
		return "", err
	}

	return strings.TrimSpace(string(output)), nil
}

// RunScript executes a bash script with real-time output streaming
// Returns channels for output lines and the final result
// Timeout: 5 minutes for installation scripts
func RunScript(repoRoot, scriptPath string, env map[string]string, args ...string) (<-chan OutputLine, <-chan ScriptResult) {
	output := make(chan OutputLine, 100)
	result := make(chan ScriptResult, 1)

	go func() {
		defer close(output)
		defer close(result)

		// 5 minute timeout for installation scripts
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
		defer cancel()

		fullPath := filepath.Join(repoRoot, scriptPath)

		// Build command with script path and arguments
		cmdArgs := append([]string{fullPath}, args...)
		cmd := exec.CommandContext(ctx, "bash", cmdArgs...)
		cmd.Dir = repoRoot

		// Set environment
		cmd.Env = os.Environ()
		for k, v := range env {
			cmd.Env = append(cmd.Env, k+"="+v)
		}

		// Create pipes for stdout/stderr
		stdout, err := cmd.StdoutPipe()
		if err != nil {
			result <- ScriptResult{ExitCode: -1}
			return
		}

		stderr, err := cmd.StderrPipe()
		if err != nil {
			result <- ScriptResult{ExitCode: -1}
			return
		}

		start := time.Now()
		if err := cmd.Start(); err != nil {
			result <- ScriptResult{ExitCode: -1}
			return
		}

		// Stream output from both pipes
		var wg sync.WaitGroup
		wg.Add(2)

		// Protected lastLine with mutex to prevent race condition
		var lastLine string
		var lastLineMu sync.Mutex

		go func() {
			defer wg.Done()
			scanner := bufio.NewScanner(stdout)
			for scanner.Scan() {
				line := scanner.Text()
				lastLineMu.Lock()
				lastLine = line
				lastLineMu.Unlock()
				output <- OutputLine{
					Text:      sanitizeOutput(line),
					Timestamp: time.Now(),
					IsError:   false,
				}
			}
		}()

		go func() {
			defer wg.Done()
			scanner := bufio.NewScanner(stderr)
			for scanner.Scan() {
				output <- OutputLine{
					Text:      sanitizeOutput(scanner.Text()),
					Timestamp: time.Now(),
					IsError:   true,
				}
			}
		}()

		wg.Wait()

		err = cmd.Wait()
		exitCode := 0
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				exitCode = exitErr.ExitCode()
			} else {
				exitCode = -1
			}
		}

		// Safe read of lastLine
		lastLineMu.Lock()
		finalLastLine := lastLine
		lastLineMu.Unlock()

		result <- ScriptResult{
			ExitCode: exitCode,
			Duration: time.Since(start),
			LastLine: finalLastLine,
		}
	}()

	return output, result
}

// PipelineStage represents a stage in the 5-stage installation pipeline
type PipelineStage int

const (
	StageCheck PipelineStage = iota
	StageInstallDeps
	StageVerifyDeps
	StageInstall
	StageConfirm
	StageUninstall
	StageConfigure
	StageUpdate // In-place update (non-destructive, preserves data)
)

// String returns the human-readable stage name
func (s PipelineStage) String() string {
	return [...]string{
		"Checking installation",
		"Installing dependencies",
		"Verifying dependencies",
		"Building and installing",
		"Confirming installation",
		"Uninstalling",
		"Configuring",
		"Updating",
	}[s]
}

// ActiveForm returns the present continuous form for display
func (s PipelineStage) ActiveForm() string {
	return [...]string{
		"Checking...",
		"Installing dependencies...",
		"Verifying dependencies...",
		"Building and installing...",
		"Confirming installation...",
		"Uninstalling...",
		"Configuring...",
		"Updating...",
	}[s]
}
