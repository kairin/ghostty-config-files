// Package ui - installer.go provides the installation progress view
package ui

import (
	"context"
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/executor"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// InstallerState represents the current state of the installer
type InstallerState int

const (
	InstallerIdle InstallerState = iota
	InstallerRunning
	InstallerPaused
	InstallerSuccess
	InstallerFailed
)

// InstallerModel manages the installation view
type InstallerModel struct {
	// Tool being installed
	tool *registry.Tool

	// Pipeline
	pipeline *executor.Pipeline
	cancel   context.CancelFunc

	// State
	state        InstallerState
	currentStage executor.PipelineStage
	stages       []stageStatus

	// Components
	tailSpinner TailSpinner

	// Error handling
	lastError    error
	hasCheckpoint bool

	// Dimensions
	width  int
	height int

	// Repo root for script execution
	repoRoot string
}

// stageStatus tracks the status of each pipeline stage
type stageStatus struct {
	stage    executor.PipelineStage
	complete bool
	success  bool
	duration string
}

// NewInstallerModel creates a new installer model
func NewInstallerModel(tool *registry.Tool, repoRoot string) InstallerModel {
	stages := []stageStatus{
		{stage: executor.StageCheck},
		{stage: executor.StageInstallDeps},
		{stage: executor.StageVerifyDeps},
		{stage: executor.StageInstall},
		{stage: executor.StageConfirm},
	}

	ts := NewTailSpinner()
	ts.SetTitle(fmt.Sprintf("Installing %s", tool.DisplayName))
	ts.SetDisplayLines(8) // Show more lines during installation

	return InstallerModel{
		tool:        tool,
		state:       InstallerIdle,
		stages:      stages,
		tailSpinner: ts,
		repoRoot:    repoRoot,
	}
}

// Installer message types
type (
	// InstallerStartMsg initiates installation
	InstallerStartMsg struct {
		Resume bool
	}

	// StageProgressMsg updates stage progress
	StageProgressMsg struct {
		Progress executor.StageProgress
	}

	// PipelineCompleteMsg signals pipeline completion
	PipelineCompleteMsg struct {
		Success bool
		Error   error
	}

	// InstallerCancelMsg cancels the installation
	InstallerCancelMsg struct{}
)

// Init initializes the installer model
func (m InstallerModel) Init() tea.Cmd {
	return m.tailSpinner.Init()
}

// Update handles messages for the installer
func (m InstallerModel) Update(msg tea.Msg) (InstallerModel, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.tailSpinner.SetDimensions(msg.Width-4, msg.Height-15)
		return m, nil

	case tea.KeyMsg:
		cmd := m.handleKey(msg)
		if cmd != nil {
			cmds = append(cmds, cmd)
		}
		return m, tea.Batch(cmds...)

	case InstallerStartMsg:
		return m.startPipeline(msg.Resume)

	case StageProgressMsg:
		m.updateStageProgress(msg.Progress)
		return m, nil

	case PipelineCompleteMsg:
		m.handlePipelineComplete(msg)
		return m, nil

	case OutputBatchMsg:
		var cmd tea.Cmd
		m.tailSpinner, cmd = m.tailSpinner.Update(msg)
		cmds = append(cmds, cmd)
		return m, tea.Batch(cmds...)

	case InstallerCancelMsg:
		if m.pipeline != nil {
			m.pipeline.Cancel()
		}
		m.state = InstallerIdle
		return m, nil
	}

	// Update tailspinner
	var cmd tea.Cmd
	m.tailSpinner, cmd = m.tailSpinner.Update(msg)
	if cmd != nil {
		cmds = append(cmds, cmd)
	}

	return m, tea.Batch(cmds...)
}

// handleKey processes key presses
func (m *InstallerModel) handleKey(msg tea.KeyMsg) tea.Cmd {
	switch msg.String() {
	case "esc":
		if m.state == InstallerRunning {
			// Cancel running pipeline
			if m.pipeline != nil {
				m.pipeline.Cancel()
			}
			m.state = InstallerPaused
		}
		return nil

	case "r":
		if m.state == InstallerFailed || m.state == InstallerPaused {
			// Restart from beginning
			return func() tea.Msg {
				return InstallerStartMsg{Resume: false}
			}
		}
		return nil

	case "c":
		if m.state == InstallerFailed && m.hasCheckpoint {
			// Resume from checkpoint
			return func() tea.Msg {
				return InstallerStartMsg{Resume: true}
			}
		}
		return nil
	}

	return nil
}

// startPipeline begins the installation pipeline
func (m InstallerModel) startPipeline(resume bool) (InstallerModel, tea.Cmd) {
	// Reset stages
	for i := range m.stages {
		m.stages[i].complete = false
		m.stages[i].success = false
		m.stages[i].duration = ""
	}

	// Create pipeline
	config := executor.DefaultPipelineConfig(m.repoRoot)
	m.pipeline = executor.NewPipeline(m.tool, config)

	// Create cancellable context
	ctx, cancel := context.WithCancel(context.Background())
	m.cancel = cancel
	m.state = InstallerRunning
	m.tailSpinner.Clear()

	// Start pipeline
	var startStage executor.PipelineStage
	if resume {
		checkpoint := executor.NewCheckpointStore()
		stage, ok := checkpoint.GetResumeStage(m.tool.ID)
		if ok {
			startStage = stage
		}
	}

	// Set initial stage
	m.currentStage = startStage
	m.tailSpinner.SetStage(startStage.ActiveForm())

	// Start commands
	cmds := []tea.Cmd{
		m.tailSpinner.Start(),
		m.runPipeline(ctx, startStage),
		m.readPipelineOutput(),
		m.readPipelineProgress(),
	}

	return m, tea.Batch(cmds...)
}

// runPipeline executes the pipeline in a goroutine
func (m InstallerModel) runPipeline(ctx context.Context, startStage executor.PipelineStage) tea.Cmd {
	pipeline := m.pipeline
	return func() tea.Msg {
		var err error
		if startStage > executor.StageCheck {
			err = pipeline.ResumeFrom(ctx, startStage)
		} else {
			err = pipeline.Execute(ctx)
		}
		return PipelineCompleteMsg{
			Success: err == nil,
			Error:   err,
		}
	}
}

// readPipelineOutput reads output from pipeline and sends batched messages
func (m InstallerModel) readPipelineOutput() tea.Cmd {
	if m.pipeline == nil {
		return nil
	}
	return BatchOutputCmd(m.pipeline.OutputChan())
}

// readPipelineProgress reads progress updates from pipeline
func (m InstallerModel) readPipelineProgress() tea.Cmd {
	if m.pipeline == nil {
		return nil
	}
	progressChan := m.pipeline.ProgressChan()
	return func() tea.Msg {
		progress, ok := <-progressChan
		if !ok {
			return nil
		}
		return StageProgressMsg{Progress: progress}
	}
}

// updateStageProgress updates the stage status from progress message
func (m *InstallerModel) updateStageProgress(progress executor.StageProgress) {
	stageIndex := int(progress.Stage)
	if stageIndex >= 0 && stageIndex < len(m.stages) {
		m.stages[stageIndex].complete = progress.Complete
		m.stages[stageIndex].success = progress.Success
		if progress.Duration > 0 {
			m.stages[stageIndex].duration = progress.Duration.Round(100).String()
		}
	}

	// Update current stage
	if progress.Complete && progress.Stage < executor.StageConfirm {
		m.currentStage = progress.Stage + 1
		m.tailSpinner.SetStage(m.currentStage.ActiveForm())
	}
}

// handlePipelineComplete processes pipeline completion
func (m *InstallerModel) handlePipelineComplete(msg PipelineCompleteMsg) {
	m.tailSpinner.Stop()

	if msg.Success {
		m.state = InstallerSuccess
	} else {
		m.state = InstallerFailed
		m.lastError = msg.Error
		// Check if there's a checkpoint for resume
		checkpoint := executor.NewCheckpointStore()
		m.hasCheckpoint = checkpoint.HasResumableCheckpoint(m.tool.ID)
	}
}

// View renders the installer view
func (m InstallerModel) View() string {
	var b strings.Builder

	// Header
	header := HeaderStyle.Render(fmt.Sprintf("Installing %s", m.tool.DisplayName))
	b.WriteString(header)
	b.WriteString("\n\n")

	// Stage progress
	b.WriteString(m.renderStageProgress())
	b.WriteString("\n\n")

	// Output spinner
	b.WriteString(m.tailSpinner.View())
	b.WriteString("\n")

	// Status/error message
	b.WriteString(m.renderStatus())
	b.WriteString("\n")

	// Help
	b.WriteString(m.renderHelp())

	return b.String()
}

// renderStageProgress renders the 5-stage progress bar
func (m InstallerModel) renderStageProgress() string {
	var b strings.Builder

	b.WriteString(fmt.Sprintf("  Stage %d/5: %s\n",
		m.currentStage+1,
		m.currentStage.String(),
	))

	// Progress bar
	progress := float64(m.currentStage) / float64(executor.StageConfirm+1)
	barWidth := 40
	filled := int(progress * float64(barWidth))

	bar := strings.Repeat("█", filled) + strings.Repeat("░", barWidth-filled)
	percent := int(progress * 100)

	barStyle := lipgloss.NewStyle().Foreground(ColorPrimary)
	b.WriteString(fmt.Sprintf("  %s %d%%\n\n", barStyle.Render(bar), percent))

	// Stage list with checkmarks
	b.WriteString("  Completed: ")
	for i, stage := range m.stages {
		if stage.complete {
			icon := IconCheckmark
			style := StatusInstalledStyle
			if !stage.success {
				icon = IconCross
				style = StatusMissingStyle
			}
			b.WriteString(style.Render(fmt.Sprintf("%s %s", icon, stage.stage.String())))
		} else if int(m.currentStage) == i {
			b.WriteString(StatusUpdateStyle.Render(fmt.Sprintf("→ %s", stage.stage.String())))
		} else {
			b.WriteString(StatusUnknownStyle.Render(stage.stage.String()))
		}
		if i < len(m.stages)-1 {
			b.WriteString(" ")
		}
	}

	return b.String()
}

// renderStatus renders the current status or error message
func (m InstallerModel) renderStatus() string {
	switch m.state {
	case InstallerSuccess:
		return StatusInstalledStyle.Render(fmt.Sprintf("\n%s Installation complete!", IconCheckmark))

	case InstallerFailed:
		msg := StatusMissingStyle.Render(fmt.Sprintf("\n%s Installation failed", IconCross))
		if m.lastError != nil {
			msg += StatusMissingStyle.Render(fmt.Sprintf(": %v", m.lastError))
		}
		return msg

	case InstallerPaused:
		return StatusUpdateStyle.Render(fmt.Sprintf("\n%s Installation paused", IconWarning))

	default:
		return ""
	}
}

// renderHelp renders context-sensitive help
func (m InstallerModel) renderHelp() string {
	switch m.state {
	case InstallerRunning:
		return HelpStyle.Render("[ESC] Cancel")

	case InstallerFailed:
		help := "[R] Restart"
		if m.hasCheckpoint {
			help += "  [C] Resume from checkpoint"
		}
		help += "  [ESC] Back"
		return HelpStyle.Render(help)

	case InstallerPaused:
		return HelpStyle.Render("[R] Restart  [ESC] Back")

	case InstallerSuccess:
		return HelpStyle.Render("[ESC] Back to dashboard")

	default:
		return HelpStyle.Render("[ESC] Cancel")
	}
}

// GetState returns the current installer state
func (m InstallerModel) GetState() InstallerState {
	return m.state
}

// IsRunning returns whether installation is in progress
func (m InstallerModel) IsRunning() bool {
	return m.state == InstallerRunning
}
