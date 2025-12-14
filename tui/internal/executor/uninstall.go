// Package executor - uninstall.go handles single-stage uninstall pipeline
package executor

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/kairin/ghostty-installer/internal/registry"
)

// UninstallPipeline handles tool uninstallation (single stage)
type UninstallPipeline struct {
	config PipelineConfig
	tool   *registry.Tool

	// Cancellation
	mu      sync.Mutex
	cancel  context.CancelFunc
	running bool

	// Output channels
	outputChan   chan OutputLine
	progressChan chan StageProgress
}

// NewUninstallPipeline creates a new uninstall pipeline for a tool
func NewUninstallPipeline(tool *registry.Tool, config PipelineConfig) *UninstallPipeline {
	return &UninstallPipeline{
		config:       config,
		tool:         tool,
		outputChan:   make(chan OutputLine, 100),
		progressChan: make(chan StageProgress, 2),
	}
}

// OutputChan returns the channel for real-time output
func (p *UninstallPipeline) OutputChan() <-chan OutputLine {
	return p.outputChan
}

// ProgressChan returns the channel for stage progress updates
func (p *UninstallPipeline) ProgressChan() <-chan StageProgress {
	return p.progressChan
}

// Execute runs the uninstall script
func (p *UninstallPipeline) Execute(ctx context.Context) error {
	p.mu.Lock()
	if p.running {
		p.mu.Unlock()
		return fmt.Errorf("uninstall already running")
	}
	p.running = true

	// Create cancellable context with timeout
	ctx, cancel := context.WithTimeout(ctx, p.config.StageTimeout)
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

	// Check for uninstall script
	uninstallScript := p.tool.Scripts.Uninstall
	if uninstallScript == "" {
		return fmt.Errorf("no uninstall script available for %s", p.tool.DisplayName)
	}

	// Send starting progress
	p.progressChan <- StageProgress{
		Stage:    StageUninstall,
		Complete: false,
		Success:  false,
	}

	start := time.Now()

	// Run the uninstall script with streaming output
	outputChan, resultChan := RunScript(p.config.RepoRoot, uninstallScript, nil)

	// Forward output to pipeline's output channel
	go func() {
		for line := range outputChan {
			select {
			case p.outputChan <- line:
			case <-ctx.Done():
				return
			}
		}
	}()

	// Wait for result or timeout
	select {
	case result := <-resultChan:
		progress := StageProgress{
			Stage:    StageUninstall,
			Complete: true,
			Success:  result.ExitCode == 0,
			Duration: time.Since(start),
			ExitCode: result.ExitCode,
		}

		if result.ExitCode != 0 {
			progress.Error = fmt.Errorf("uninstall exited with code %d", result.ExitCode)
			p.progressChan <- progress
			return progress.Error
		}

		p.progressChan <- progress
		return nil

	case <-ctx.Done():
		progress := StageProgress{
			Stage:    StageUninstall,
			Complete: true,
			Success:  false,
			Duration: time.Since(start),
			Error:    ctx.Err(),
		}
		p.progressChan <- progress
		return ctx.Err()
	}
}

// Cancel stops the running uninstall
func (p *UninstallPipeline) Cancel() error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if !p.running || p.cancel == nil {
		return fmt.Errorf("uninstall not running")
	}

	p.cancel()
	return nil
}

// IsRunning returns whether the uninstall is currently executing
func (p *UninstallPipeline) IsRunning() bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.running
}

// StageUninstall is a pseudo-stage for uninstall operations
const StageUninstall PipelineStage = 99
