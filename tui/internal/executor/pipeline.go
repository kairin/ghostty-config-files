// Package executor - pipeline.go handles 5-stage installation pipeline orchestration
package executor

import (
	"context"
	"fmt"
	"os/exec"
	"sync"
	"time"

	"github.com/kairin/ghostty-installer/internal/registry"
)

// PipelineStage represents a stage in the 5-stage installation pipeline
// Already defined in executor.go: StageCheck, StageInstallDeps, StageVerifyDeps, StageInstall, StageConfirm

// StageProgress represents progress through a pipeline stage
type StageProgress struct {
	Stage    PipelineStage
	Complete bool
	Success  bool
	Duration time.Duration
	Error    error
	ExitCode int
}

// PipelineConfig holds configuration for pipeline execution
type PipelineConfig struct {
	StageTimeout   time.Duration // Timeout per stage (default: 5 min)
	OverallTimeout time.Duration // Overall timeout (default: 30 min)
	RepoRoot       string        // Repository root path
}

// DefaultPipelineConfig returns sensible defaults
func DefaultPipelineConfig(repoRoot string) PipelineConfig {
	return PipelineConfig{
		StageTimeout:   5 * time.Minute,
		OverallTimeout: 30 * time.Minute,
		RepoRoot:       repoRoot,
	}
}

// Pipeline orchestrates the 5-stage installation process
type Pipeline struct {
	config     PipelineConfig
	checkpoint *CheckpointStore
	tool       *registry.Tool

	// Cancellation
	mu      sync.Mutex
	cancel  context.CancelFunc
	running bool

	// Output channels
	outputChan   chan OutputLine
	progressChan chan StageProgress
}

// NewPipeline creates a new pipeline for a tool
func NewPipeline(tool *registry.Tool, config PipelineConfig) *Pipeline {
	return &Pipeline{
		config:       config,
		checkpoint:   NewCheckpointStore(),
		tool:         tool,
		outputChan:   make(chan OutputLine, 100),
		progressChan: make(chan StageProgress, 10),
	}
}

// OutputChan returns the channel for real-time output
func (p *Pipeline) OutputChan() <-chan OutputLine {
	return p.outputChan
}

// ProgressChan returns the channel for stage progress updates
func (p *Pipeline) ProgressChan() <-chan StageProgress {
	return p.progressChan
}

// Execute runs the full pipeline from the beginning
// CRITICAL: Pre-caches sudo credentials BEFORE any stage output to ensure
// password prompt appears first (immediately after clicking Install)
func (p *Pipeline) Execute(ctx context.Context) error {
	// PRE-CACHE SUDO FIRST (before any stage output)
	// This ensures the password prompt appears at the TOP, not bottom
	if err := p.preCacheSudo(ctx); err != nil {
		return fmt.Errorf("sudo authentication required: %w", err)
	}

	return p.executeFrom(ctx, StageCheck)
}

// preCacheSudo verifies sudo credentials are cached (non-interactive only)
// This is defense-in-depth: UI layer should already request auth via tea.ExecProcess
// which suspends the TUI to allow password entry. This check ensures auth happened.
// CRITICAL: Do NOT use interactive sudo -v here - the TUI has control of terminal
// and interactive prompts will hang indefinitely.
func (p *Pipeline) preCacheSudo(ctx context.Context) error {
	// Non-interactive check only - verify credentials are cached
	cmd := exec.CommandContext(ctx, "sudo", "-n", "true")
	if err := cmd.Run(); err != nil {
		// Credentials not cached - UI layer should have handled auth first
		return fmt.Errorf("sudo credentials not cached - authentication required before pipeline execution")
	}
	return nil
}

// ResumeFrom resumes pipeline execution from a specific stage
// Also pre-caches sudo credentials to ensure prompt appears first
func (p *Pipeline) ResumeFrom(ctx context.Context, stage PipelineStage) error {
	// PRE-CACHE SUDO (same as Execute)
	if err := p.preCacheSudo(ctx); err != nil {
		return fmt.Errorf("sudo authentication required: %w", err)
	}

	return p.executeFrom(ctx, stage)
}

// executeFrom runs the pipeline starting from a specific stage
func (p *Pipeline) executeFrom(ctx context.Context, startStage PipelineStage) error {
	p.mu.Lock()
	if p.running {
		p.mu.Unlock()
		return fmt.Errorf("pipeline already running")
	}
	p.running = true

	// Create cancellable context with overall timeout
	ctx, cancel := context.WithTimeout(ctx, p.config.OverallTimeout)
	p.cancel = cancel
	p.mu.Unlock()

	defer func() {
		p.mu.Lock()
		p.running = false
		p.cancel = nil
		p.mu.Unlock()
		close(p.outputChan)
		close(p.progressChan)
	}()

	// Execute each stage sequentially
	for stage := startStage; stage <= StageConfirm; stage++ {
		// Check for cancellation
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		// Save checkpoint before execution
		p.checkpoint.Save(p.tool.ID, StateCheckpoint{
			Version:      1,
			ToolID:       p.tool.ID,
			Timestamp:    time.Now(),
			CurrentStage: stage,
			IsResumable:  true,
		})

		// Execute stage with timeout
		progress, err := p.executeStage(ctx, stage)
		p.progressChan <- progress

		if err != nil {
			// Classify error severity
			severity := classifyError(stage, progress.ExitCode)

			if severity == ErrorFatal {
				// Save failure checkpoint for resume
				p.checkpoint.SaveFailure(p.tool.ID, stage, err, progress.ExitCode)
				return fmt.Errorf("stage %s failed: %w", stage.String(), err)
			}
			// Non-fatal: log warning and continue
			p.outputChan <- OutputLine{
				Text:      fmt.Sprintf("[WARN] Stage %s had non-fatal error: %v", stage.String(), err),
				Timestamp: time.Now(),
				IsError:   true,
			}
		}
	}

	// Clear checkpoint on success
	p.checkpoint.Clear(p.tool.ID)

	return nil
}

// executeStage runs a single pipeline stage
func (p *Pipeline) executeStage(ctx context.Context, stage PipelineStage) (StageProgress, error) {
	progress := StageProgress{
		Stage: stage,
	}

	// Get script path for this stage
	scriptPath := p.getScriptPath(stage)
	if scriptPath == "" {
		// No script for this stage - skip gracefully
		progress.Complete = true
		progress.Success = true
		return progress, nil
	}

	// Create stage-specific timeout
	stageCtx, cancel := context.WithTimeout(ctx, p.config.StageTimeout)
	defer cancel()

	start := time.Now()

	// Build script arguments - pass method if override is set
	var args []string
	if p.tool.MethodOverride != "" {
		args = []string{string(p.tool.MethodOverride)}
	}

	// Run the script with streaming output (args... spreads the slice)
	outputChan, resultChan := RunScript(p.config.RepoRoot, scriptPath, nil, args...)

	// Forward output to pipeline's output channel
	go func() {
		for line := range outputChan {
			select {
			case p.outputChan <- line:
			case <-stageCtx.Done():
				return
			}
		}
	}()

	// Wait for result or timeout
	select {
	case result := <-resultChan:
		progress.Duration = time.Since(start)
		progress.ExitCode = result.ExitCode
		progress.Complete = true
		progress.Success = result.ExitCode == 0

		if result.ExitCode != 0 {
			progress.Error = fmt.Errorf("script exited with code %d", result.ExitCode)
			return progress, progress.Error
		}
		return progress, nil

	case <-stageCtx.Done():
		progress.Duration = time.Since(start)
		progress.Error = stageCtx.Err()
		return progress, stageCtx.Err()
	}
}

// getScriptPath maps pipeline stage to script path
func (p *Pipeline) getScriptPath(stage PipelineStage) string {
	switch stage {
	case StageCheck:
		return p.tool.Scripts.Check
	case StageInstallDeps:
		return p.tool.Scripts.InstallDeps
	case StageVerifyDeps:
		return p.tool.Scripts.VerifyDeps
	case StageInstall:
		return p.tool.Scripts.Install
	case StageConfirm:
		return p.tool.Scripts.Confirm
	default:
		return ""
	}
}

// Cancel stops the running pipeline
func (p *Pipeline) Cancel() error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if !p.running || p.cancel == nil {
		return fmt.Errorf("pipeline not running")
	}

	p.cancel()
	return nil
}

// IsRunning returns whether the pipeline is currently executing
func (p *Pipeline) IsRunning() bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.running
}

// GetCheckpoint returns the current checkpoint for the tool
func (p *Pipeline) GetCheckpoint() (*StateCheckpoint, error) {
	return p.checkpoint.Load(p.tool.ID)
}

// ErrorSeverity classifies the severity of a pipeline error
type ErrorSeverity int

const (
	ErrorInfo  ErrorSeverity = iota // Continue without warning
	ErrorWarn                       // Log warning, continue
	ErrorFatal                      // Stop pipeline, save checkpoint
)

// classifyError determines error severity based on stage and exit code
func classifyError(stage PipelineStage, exitCode int) ErrorSeverity {
	// Exit code 0 is success
	if exitCode == 0 {
		return ErrorInfo
	}

	// Stage-specific severity mapping (from start.sh analysis)
	switch stage {
	case StageCheck:
		// Check failures are informational (tool not installed)
		return ErrorInfo
	case StageInstallDeps:
		// Dependency failures are FATAL - cannot build without deps
		return ErrorFatal
	case StageVerifyDeps:
		// Verification failures are FATAL - deps must be satisfied
		return ErrorFatal
	case StageInstall:
		// Installation failures are fatal
		return ErrorFatal
	case StageConfirm:
		// Confirmation failures are warnings (consider success)
		return ErrorWarn
	default:
		return ErrorFatal
	}
}
