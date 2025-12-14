// Package executor - configure.go handles single-stage configure pipeline
package executor

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/kairin/ghostty-installer/internal/registry"
)

// ConfigurePipeline handles tool configuration (single stage)
type ConfigurePipeline struct {
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

// NewConfigurePipeline creates a new configure pipeline for a tool
func NewConfigurePipeline(tool *registry.Tool, config PipelineConfig) *ConfigurePipeline {
	return &ConfigurePipeline{
		config:       config,
		tool:         tool,
		outputChan:   make(chan OutputLine, 100),
		progressChan: make(chan StageProgress, 2),
	}
}

// OutputChan returns the channel for real-time output
func (p *ConfigurePipeline) OutputChan() <-chan OutputLine {
	return p.outputChan
}

// ProgressChan returns the channel for stage progress updates
func (p *ConfigurePipeline) ProgressChan() <-chan StageProgress {
	return p.progressChan
}

// Execute runs the configure script
func (p *ConfigurePipeline) Execute(ctx context.Context) error {
	p.mu.Lock()
	if p.running {
		p.mu.Unlock()
		return fmt.Errorf("configure already running")
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

	// Check for configure script
	configureScript := p.tool.Scripts.Configure
	if configureScript == "" {
		return fmt.Errorf("no configure script available for %s", p.tool.DisplayName)
	}

	// Send starting progress
	p.progressChan <- StageProgress{
		Stage:    StageConfigure,
		Complete: false,
		Success:  false,
	}

	start := time.Now()

	// Run the configure script with streaming output
	outputChan, resultChan := RunScript(p.config.RepoRoot, configureScript, nil)

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
			Stage:    StageConfigure,
			Complete: true,
			Success:  result.ExitCode == 0,
			Duration: time.Since(start),
			ExitCode: result.ExitCode,
		}

		if result.ExitCode != 0 {
			progress.Error = fmt.Errorf("configure exited with code %d", result.ExitCode)
			p.progressChan <- progress
			return progress.Error
		}

		p.progressChan <- progress
		return nil

	case <-ctx.Done():
		progress := StageProgress{
			Stage:    StageConfigure,
			Complete: true,
			Success:  false,
			Duration: time.Since(start),
			Error:    ctx.Err(),
		}
		p.progressChan <- progress
		return ctx.Err()
	}
}

// Cancel stops the running configure
func (p *ConfigurePipeline) Cancel() error {
	p.mu.Lock()
	defer p.mu.Unlock()

	if !p.running || p.cancel == nil {
		return fmt.Errorf("configure not running")
	}

	p.cancel()
	return nil
}

// IsRunning returns whether the configure is currently executing
func (p *ConfigurePipeline) IsRunning() bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.running
}
