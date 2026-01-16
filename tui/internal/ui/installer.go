// Package ui - installer.go provides the installation progress view
package ui

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/key"
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

// recoveryButton represents a selectable recovery action button
type recoveryButton struct {
	label    string
	action   func() tea.Msg
	shortcut string // "R", "C", or "ESC"
}

// Recovery key bindings for navigation
type recoveryKeyMap struct {
	Left   key.Binding
	Right  key.Binding
	Tab    key.Binding
	Enter  key.Binding
	Escape key.Binding
	Retry  key.Binding
	Resume key.Binding
}

var recoveryKeys = recoveryKeyMap{
	Left: key.NewBinding(
		key.WithKeys("left", "h"),
		key.WithHelp("←/h", "previous"),
	),
	Right: key.NewBinding(
		key.WithKeys("right", "l"),
		key.WithHelp("→/l", "next"),
	),
	Tab: key.NewBinding(
		key.WithKeys("tab"),
		key.WithHelp("tab", "switch"),
	),
	Enter: key.NewBinding(
		key.WithKeys("enter"),
		key.WithHelp("enter", "select"),
	),
	Escape: key.NewBinding(
		key.WithKeys("esc"),
		key.WithHelp("esc", "back"),
	),
	Retry: key.NewBinding(
		key.WithKeys("r", "R"),
		key.WithHelp("r", "retry"),
	),
	Resume: key.NewBinding(
		key.WithKeys("c", "C"),
		key.WithHelp("c", "resume"),
	),
}

// InstallerModel manages the installation view
type InstallerModel struct {
	// Tool being installed/uninstalled
	tool *registry.Tool

	// Pipeline (for installation)
	pipeline *executor.Pipeline
	cancel   context.CancelFunc

	// Uninstall pipeline
	uninstallPipeline *executor.UninstallPipeline
	isUninstall       bool

	// Configure pipeline
	configurePipeline *executor.ConfigurePipeline
	isConfigure       bool

	// Update mode (non-destructive in-place update)
	isUpdate bool

	// State
	state        InstallerState
	currentStage executor.PipelineStage
	stages       []stageStatus

	// Components
	tailSpinner TailSpinner

	// Error handling
	lastError     error
	hasCheckpoint bool

	// Dimensions
	width  int
	height int

	// Repo root for script execution
	repoRoot string

	// Timing for elapsed display
	startTime time.Time

	// Recovery button selection (for failed/paused states)
	recoveryFocused int
	recoveryButtons []recoveryButton
}

// stageStatus tracks the status of each pipeline stage
type stageStatus struct {
	stage    executor.PipelineStage
	complete bool
	success  bool
	duration string
}

// NewInstallerModel creates a new installer model
// Returns nil-safe model if tool is nil (defensive programming)
func NewInstallerModel(tool *registry.Tool, repoRoot string) InstallerModel {
	stages := []stageStatus{
		{stage: executor.StageCheck},
		{stage: executor.StageInstallDeps},
		{stage: executor.StageVerifyDeps},
		{stage: executor.StageInstall},
		{stage: executor.StageConfirm},
	}

	ts := NewTailSpinner()

	// Nil check: prevent panic when accessing tool.DisplayName
	displayName := "Unknown Tool"
	if tool != nil {
		displayName = tool.DisplayName
	}
	ts.SetTitle(fmt.Sprintf("Installing %s", displayName))
	ts.SetDisplayLines(20) // Show more lines during installation

	return InstallerModel{
		tool:        tool,
		state:       InstallerIdle,
		stages:      stages,
		tailSpinner: ts,
		repoRoot:    repoRoot,
	}
}

// NewInstallerModelForUninstall creates an installer model configured for uninstallation
// Returns nil-safe model if tool is nil (defensive programming)
func NewInstallerModelForUninstall(tool *registry.Tool, repoRoot string) InstallerModel {
	// Single stage for uninstall
	stages := []stageStatus{
		{stage: executor.StageUninstall},
	}

	ts := NewTailSpinner()

	// Nil check: prevent panic when accessing tool.DisplayName
	displayName := "Unknown Tool"
	if tool != nil {
		displayName = tool.DisplayName
	}
	ts.SetTitle(fmt.Sprintf("Uninstalling %s", displayName))
	ts.SetDisplayLines(20)

	return InstallerModel{
		tool:        tool,
		state:       InstallerIdle,
		stages:      stages,
		tailSpinner: ts,
		repoRoot:    repoRoot,
		isUninstall: true,
	}
}

// NewInstallerModelForConfigure creates an installer model configured for configuration
// Returns nil-safe model if tool is nil (defensive programming)
func NewInstallerModelForConfigure(tool *registry.Tool, repoRoot string) InstallerModel {
	// Single stage for configure
	stages := []stageStatus{
		{stage: executor.StageConfigure},
	}

	ts := NewTailSpinner()

	// Nil check: prevent panic when accessing tool.DisplayName
	displayName := "Unknown Tool"
	if tool != nil {
		displayName = tool.DisplayName
	}
	ts.SetTitle(fmt.Sprintf("Configuring %s", displayName))
	ts.SetDisplayLines(20)

	return InstallerModel{
		tool:        tool,
		state:       InstallerIdle,
		stages:      stages,
		tailSpinner: ts,
		repoRoot:    repoRoot,
		isConfigure: true,
	}
}

// NewInstallerModelForUpdate creates an installer model configured for in-place updates
// This is non-destructive - preserves user data like npm global packages
// Returns nil-safe model if tool is nil (defensive programming)
func NewInstallerModelForUpdate(tool *registry.Tool, repoRoot string) InstallerModel {
	// Update pipeline stages: Check → Update → Confirm
	stages := []stageStatus{
		{stage: executor.StageCheck},
		{stage: executor.StageUpdate},
		{stage: executor.StageConfirm},
	}

	ts := NewTailSpinner()

	// Nil check: prevent panic when accessing tool.DisplayName
	displayName := "Unknown Tool"
	if tool != nil {
		displayName = tool.DisplayName
	}
	ts.SetTitle(fmt.Sprintf("Updating %s", displayName))
	ts.SetDisplayLines(20)

	return InstallerModel{
		tool:        tool,
		state:       InstallerIdle,
		stages:      stages,
		tailSpinner: ts,
		repoRoot:    repoRoot,
		isUpdate:    true,
	}
}

// Installer message types
type (
	// InstallerStartMsg initiates installation or uninstallation
	InstallerStartMsg struct {
		Resume    bool
		Uninstall bool
		Update    bool // In-place update (non-destructive)
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

	// InstallerExitMsg signals the user wants to exit the installer view
	InstallerExitMsg struct{}
)

// Init initializes the installer model
func (m InstallerModel) Init() tea.Cmd {
	return tea.Batch(
		m.tailSpinner.Init(),
		tea.WindowSize(), // Query terminal size for proper viewport layout
	)
}

// buildRecoveryButtons constructs the appropriate recovery buttons based on current state
func (m *InstallerModel) buildRecoveryButtons() {
	m.recoveryButtons = nil
	isUninstall := m.isUninstall

	// Back (first - default focus for safety)
	m.recoveryButtons = append(m.recoveryButtons, recoveryButton{
		label:    "Back",
		shortcut: "ESC",
		action:   func() tea.Msg { return InstallerExitMsg{} },
	})

	// Retry (always available)
	m.recoveryButtons = append(m.recoveryButtons, recoveryButton{
		label:    "Retry",
		shortcut: "R",
		action: func() tea.Msg {
			return InstallerStartMsg{Resume: false, Uninstall: isUninstall}
		},
	})

	// Resume (only if checkpoint exists and not uninstall/configure)
	if m.state == InstallerFailed && m.hasCheckpoint && !m.isUninstall && !m.isConfigure {
		m.recoveryButtons = append(m.recoveryButtons, recoveryButton{
			label:    "Resume",
			shortcut: "C",
			action:   func() tea.Msg { return InstallerStartMsg{Resume: true} },
		})
	}

	// Default to Back (index 0) for safety
	m.recoveryFocused = 0
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
		if msg.Uninstall {
			return m.startUninstallPipeline()
		}
		if m.isConfigure {
			return m.startConfigurePipeline()
		}
		if m.isUpdate {
			return m.startUpdatePipeline()
		}
		return m.startPipeline(msg.Resume)

	case StageProgressMsg:
		m.updateStageProgress(msg.Progress)
		// RE-SUBSCRIBE to continue receiving progress updates (critical fix)
		// Without this, only the first progress message is received and stage stays at 2/5
		if m.state == InstallerRunning {
			if m.isConfigure && m.configurePipeline != nil {
				return m, m.readConfigureProgress()
			} else if m.isUninstall && m.uninstallPipeline != nil {
				return m, m.readUninstallProgress()
			} else if m.isUpdate && m.pipeline != nil {
				return m, m.readPipelineProgress()
			} else if m.pipeline != nil {
				return m, m.readPipelineProgress()
			}
		}
		return m, nil

	case PipelineCompleteMsg:
		m.handlePipelineComplete(msg)
		return m, nil

	case OutputBatchMsg:
		var cmd tea.Cmd
		m.tailSpinner, cmd = m.tailSpinner.Update(msg)
		cmds = append(cmds, cmd)

		// RE-SUBSCRIBE to continue reading output (critical fix)
		// Without this, only the first batch of output is displayed
		if m.state == InstallerRunning {
			if m.isConfigure && m.configurePipeline != nil {
				cmds = append(cmds, BatchOutputCmd(m.configurePipeline.OutputChan()))
			} else if m.isUninstall && m.uninstallPipeline != nil {
				cmds = append(cmds, BatchOutputCmd(m.uninstallPipeline.OutputChan()))
			} else if m.pipeline != nil {
				cmds = append(cmds, BatchOutputCmd(m.pipeline.OutputChan()))
			}
		}
		return m, tea.Batch(cmds...)

	case InstallerCancelMsg:
		if m.pipeline != nil {
			m.pipeline.Cancel()
		}
		if m.uninstallPipeline != nil {
			m.uninstallPipeline.Cancel()
		}
		if m.configurePipeline != nil {
			m.configurePipeline.Cancel()
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
	// Running state: only ESC to cancel
	if m.state == InstallerRunning {
		if msg.String() == "esc" {
			if m.pipeline != nil {
				m.pipeline.Cancel()
			}
			if m.uninstallPipeline != nil {
				m.uninstallPipeline.Cancel()
			}
			if m.configurePipeline != nil {
				m.configurePipeline.Cancel()
			}
			m.state = InstallerPaused
			m.buildRecoveryButtons()
		}
		return nil
	}

	// Success state: only ESC to go back
	if m.state == InstallerSuccess {
		if msg.String() == "esc" {
			return func() tea.Msg { return InstallerExitMsg{} }
		}
		return nil
	}

	// Failed or Paused states: handle recovery button navigation
	if m.state == InstallerFailed || m.state == InstallerPaused {
		switch {
		case key.Matches(msg, recoveryKeys.Left):
			if m.recoveryFocused > 0 {
				m.recoveryFocused--
			}
			return nil

		case key.Matches(msg, recoveryKeys.Right):
			if m.recoveryFocused < len(m.recoveryButtons)-1 {
				m.recoveryFocused++
			}
			return nil

		case key.Matches(msg, recoveryKeys.Tab):
			if len(m.recoveryButtons) > 0 {
				m.recoveryFocused = (m.recoveryFocused + 1) % len(m.recoveryButtons)
			}
			return nil

		case key.Matches(msg, recoveryKeys.Enter):
			if m.recoveryFocused >= 0 && m.recoveryFocused < len(m.recoveryButtons) {
				return m.recoveryButtons[m.recoveryFocused].action
			}
			return nil

		case key.Matches(msg, recoveryKeys.Escape):
			return func() tea.Msg { return InstallerExitMsg{} }

		case key.Matches(msg, recoveryKeys.Retry):
			// Find and execute Retry button
			for i, btn := range m.recoveryButtons {
				if btn.shortcut == "R" {
					m.recoveryFocused = i
					return btn.action
				}
			}
			return nil

		case key.Matches(msg, recoveryKeys.Resume):
			// Find and execute Resume button (if exists)
			for i, btn := range m.recoveryButtons {
				if btn.shortcut == "C" {
					m.recoveryFocused = i
					return btn.action
				}
			}
			return nil
		}
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
	m.startTime = time.Now()
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

// startUninstallPipeline begins the uninstallation pipeline
func (m InstallerModel) startUninstallPipeline() (InstallerModel, tea.Cmd) {
	// Reset stages
	for i := range m.stages {
		m.stages[i].complete = false
		m.stages[i].success = false
		m.stages[i].duration = ""
	}

	// Create uninstall pipeline
	config := executor.DefaultPipelineConfig(m.repoRoot)
	m.uninstallPipeline = executor.NewUninstallPipeline(m.tool, config)

	// Create cancellable context
	ctx, cancel := context.WithCancel(context.Background())
	m.cancel = cancel
	m.state = InstallerRunning
	m.startTime = time.Now()
	m.tailSpinner.Clear()
	m.tailSpinner.SetStage("Uninstalling...")

	// Start commands
	cmds := []tea.Cmd{
		m.tailSpinner.Start(),
		m.runUninstallPipeline(ctx),
		m.readUninstallOutput(),
		m.readUninstallProgress(),
	}

	return m, tea.Batch(cmds...)
}

// startConfigurePipeline begins the configuration pipeline
func (m InstallerModel) startConfigurePipeline() (InstallerModel, tea.Cmd) {
	// Reset stages
	for i := range m.stages {
		m.stages[i].complete = false
		m.stages[i].success = false
		m.stages[i].duration = ""
	}

	// Create configure pipeline
	config := executor.DefaultPipelineConfig(m.repoRoot)
	m.configurePipeline = executor.NewConfigurePipeline(m.tool, config)

	// Create cancellable context
	ctx, cancel := context.WithCancel(context.Background())
	m.cancel = cancel
	m.state = InstallerRunning
	m.startTime = time.Now()
	m.tailSpinner.Clear()
	m.tailSpinner.SetStage("Configuring...")

	// Start commands
	cmds := []tea.Cmd{
		m.tailSpinner.Start(),
		m.runConfigurePipeline(ctx),
		m.readConfigureOutput(),
		m.readConfigureProgress(),
	}

	return m, tea.Batch(cmds...)
}

// startUpdatePipeline begins the update pipeline (non-destructive in-place update)
func (m InstallerModel) startUpdatePipeline() (InstallerModel, tea.Cmd) {
	// Reset stages
	for i := range m.stages {
		m.stages[i].complete = false
		m.stages[i].success = false
		m.stages[i].duration = ""
	}

	// Create pipeline (reuses standard Pipeline with ExecuteUpdate method)
	config := executor.DefaultPipelineConfig(m.repoRoot)
	m.pipeline = executor.NewPipeline(m.tool, config)

	// Create cancellable context
	ctx, cancel := context.WithCancel(context.Background())
	m.cancel = cancel
	m.state = InstallerRunning
	m.startTime = time.Now()
	m.tailSpinner.Clear()
	m.tailSpinner.SetStage("Checking...")

	// Set initial stage
	m.currentStage = executor.StageCheck

	// Start commands - use runUpdatePipeline which calls ExecuteUpdate
	cmds := []tea.Cmd{
		m.tailSpinner.Start(),
		m.runUpdatePipeline(ctx),
		m.readPipelineOutput(),
		m.readPipelineProgress(),
	}

	return m, tea.Batch(cmds...)
}

// runUpdatePipeline executes the update pipeline in a goroutine
func (m InstallerModel) runUpdatePipeline(ctx context.Context) tea.Cmd {
	pipeline := m.pipeline
	return func() tea.Msg {
		err := pipeline.ExecuteUpdate(ctx)
		return PipelineCompleteMsg{
			Success: err == nil,
			Error:   err,
		}
	}
}

// runUninstallPipeline executes the uninstall pipeline in a goroutine
func (m InstallerModel) runUninstallPipeline(ctx context.Context) tea.Cmd {
	pipeline := m.uninstallPipeline
	return func() tea.Msg {
		err := pipeline.Execute(ctx)
		return PipelineCompleteMsg{
			Success: err == nil,
			Error:   err,
		}
	}
}

// readUninstallOutput reads output from uninstall pipeline
func (m InstallerModel) readUninstallOutput() tea.Cmd {
	if m.uninstallPipeline == nil {
		return nil
	}
	return BatchOutputCmd(m.uninstallPipeline.OutputChan())
}

// readUninstallProgress reads progress updates from uninstall pipeline
func (m InstallerModel) readUninstallProgress() tea.Cmd {
	if m.uninstallPipeline == nil {
		return nil
	}
	return readProgressFromChannel(m.uninstallPipeline.ProgressChan())
}

// runConfigurePipeline executes the configure pipeline in a goroutine
func (m InstallerModel) runConfigurePipeline(ctx context.Context) tea.Cmd {
	pipeline := m.configurePipeline
	return func() tea.Msg {
		err := pipeline.Execute(ctx)
		return PipelineCompleteMsg{
			Success: err == nil,
			Error:   err,
		}
	}
}

// readConfigureOutput reads output from configure pipeline
func (m InstallerModel) readConfigureOutput() tea.Cmd {
	if m.configurePipeline == nil {
		return nil
	}
	return BatchOutputCmd(m.configurePipeline.OutputChan())
}

// readConfigureProgress reads progress updates from configure pipeline
func (m InstallerModel) readConfigureProgress() tea.Cmd {
	if m.configurePipeline == nil {
		return nil
	}
	return readProgressFromChannel(m.configurePipeline.ProgressChan())
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
	return readProgressFromChannel(m.pipeline.ProgressChan())
}

// readProgressFromChannel creates a command to read from any progress channel
// This is a generic helper to reduce code duplication between install/uninstall progress readers
func readProgressFromChannel(ch <-chan executor.StageProgress) tea.Cmd {
	if ch == nil {
		return nil
	}
	return func() tea.Msg {
		progress, ok := <-ch
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

	// Determine action label
	action := "Installation"
	if m.isUninstall {
		action = "Uninstallation"
	} else if m.isConfigure {
		action = "Configuration"
	} else if m.isUpdate {
		action = "Update"
	}

	if msg.Success {
		m.state = InstallerSuccess
		m.tailSpinner.SetTitle(fmt.Sprintf("✓ %s complete", action))
		// Mark all stages as complete on success (avoids race with progress channel)
		for i := range m.stages {
			m.stages[i].complete = true
			m.stages[i].success = true
		}
	} else {
		m.state = InstallerFailed
		m.tailSpinner.SetTitle(fmt.Sprintf("✗ %s failed", action))
		m.lastError = msg.Error
		// Check if there's a checkpoint for resume
		checkpoint := executor.NewCheckpointStore()
		m.hasCheckpoint = checkpoint.HasResumableCheckpoint(m.tool.ID)
		// Build recovery buttons for the failed state
		m.buildRecoveryButtons()
	}
}

// View renders the installer view
func (m InstallerModel) View() string {
	var b strings.Builder

	// 1. Spinner + Header at TOP (skip spinner animation when complete)
	if m.state == InstallerRunning {
		b.WriteString(m.tailSpinner.ViewSpinnerLine())
	} else {
		// Show title without spinner when complete/failed
		b.WriteString(m.tailSpinner.Title())
	}
	b.WriteString("\n\n")

	// 2. Stage info (skip for uninstall/configure - only one stage)
	if !m.isUninstall && !m.isConfigure {
		b.WriteString(m.renderStageInfo())
		b.WriteString("\n")
	}

	// 3. Output viewport (large - 20 lines)
	b.WriteString(m.tailSpinner.View())
	b.WriteString("\n")

	// 4. Progress bar at BOTTOM (skip for uninstall/configure and when complete)
	if !m.isUninstall && !m.isConfigure && m.state == InstallerRunning {
		b.WriteString(m.renderProgressBar())
		b.WriteString("\n")
	}

	// 5. Status/error message
	b.WriteString(m.renderStatus())
	b.WriteString("\n")

	// 6. Help
	b.WriteString(m.renderHelp())

	return b.String()
}

// renderStageInfo renders just the stage info line (for top of screen)
func (m InstallerModel) renderStageInfo() string {
	// Elapsed time
	elapsed := time.Since(m.startTime).Round(time.Second)
	elapsedStr := elapsed.String()
	if elapsed < time.Minute {
		elapsedStr = fmt.Sprintf("%ds", int(elapsed.Seconds()))
	}

	return fmt.Sprintf("  Stage %d/%d: %s  (elapsed: %s)",
		m.currentStage+1,
		len(m.stages),
		m.currentStage.String(),
		elapsedStr,
	)
}

// renderProgressBar renders the animated progress bar and stage list (for bottom of screen)
func (m InstallerModel) renderProgressBar() string {
	var b strings.Builder

	// Animated activity bar - shows movement to indicate work is happening
	barWidth := 40
	highlightWidth := 5
	elapsedMs := time.Since(m.startTime).Milliseconds()
	pos := int(elapsedMs/100) % (barWidth - highlightWidth + 1)

	// Build animated bar
	runes := make([]rune, barWidth)
	for i := 0; i < barWidth; i++ {
		if i >= pos && i < pos+highlightWidth {
			runes[i] = '▓'
		} else {
			runes[i] = '░'
		}
	}
	bar := string(runes)

	// Also show stage progress as fraction
	stageProgress := fmt.Sprintf("(%d/%d)", m.currentStage+1, len(m.stages))

	barStyle := lipgloss.NewStyle().Foreground(ColorPrimary)
	b.WriteString(fmt.Sprintf("  %s %s\n", barStyle.Render(bar), stageProgress))

	// Stage list with checkmarks
	b.WriteString("  ")
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
	action := "Installation"
	if m.isUninstall {
		action = "Uninstallation"
	} else if m.isConfigure {
		action = "Configuration"
	} else if m.isUpdate {
		action = "Update"
	}

	switch m.state {
	case InstallerSuccess:
		return StatusInstalledStyle.Render(fmt.Sprintf("\n%s %s complete!", IconCheckmark, action))

	case InstallerFailed:
		msg := StatusMissingStyle.Render(fmt.Sprintf("\n%s %s failed", IconCross, action))
		if m.lastError != nil {
			msg += StatusMissingStyle.Render(fmt.Sprintf(": %v", m.lastError))
		}
		return msg

	case InstallerPaused:
		return StatusUpdateStyle.Render(fmt.Sprintf("\n%s %s paused", IconWarning, action))

	default:
		return ""
	}
}

// renderHelp renders context-sensitive help
func (m InstallerModel) renderHelp() string {
	switch m.state {
	case InstallerRunning:
		return HelpStyle.Render("[ESC] Cancel")

	case InstallerFailed, InstallerPaused:
		return m.renderRecoveryButtons()

	case InstallerSuccess:
		return HelpStyle.Render("[ESC] Back to dashboard")

	default:
		return HelpStyle.Render("[ESC] Cancel")
	}
}

// renderRecoveryButtons renders visual selectable buttons for failed/paused states
func (m InstallerModel) renderRecoveryButtons() string {
	if len(m.recoveryButtons) == 0 {
		return HelpStyle.Render("[ESC] Back")
	}

	// Button styles (matching confirm.go pattern)
	buttonStyle := lipgloss.NewStyle().
		Padding(0, 2).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(ColorMuted)

	selectedStyle := lipgloss.NewStyle().
		Padding(0, 2).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(ColorPrimary).
		Foreground(ColorPrimary).
		Bold(true)

	var buttons []string
	for i, btn := range m.recoveryButtons {
		label := fmt.Sprintf("%s [%s]", btn.label, btn.shortcut)
		if i == m.recoveryFocused {
			buttons = append(buttons, selectedStyle.Render(label))
		} else {
			buttons = append(buttons, buttonStyle.Render(label))
		}
	}

	// Join buttons horizontally with spacing
	buttonRow := lipgloss.JoinHorizontal(lipgloss.Center, buttons...)

	// Help text for navigation
	helpText := HelpStyle.Render("[←/→] Select  [Enter] Confirm  [R/C/ESC] Quick select")

	return lipgloss.JoinVertical(lipgloss.Left, buttonRow, "", helpText)
}

// GetState returns the current installer state
func (m InstallerModel) GetState() InstallerState {
	return m.state
}

// IsRunning returns whether installation is in progress
func (m InstallerModel) IsRunning() bool {
	return m.state == InstallerRunning
}

// IsSuccess returns whether installation completed successfully
func (m InstallerModel) IsSuccess() bool {
	return m.state == InstallerSuccess
}

// IsUninstall returns whether this is an uninstall operation
func (m InstallerModel) IsUninstall() bool {
	return m.isUninstall
}

// IsUpdate returns whether this is an update operation
func (m InstallerModel) IsUpdate() bool {
	return m.isUpdate
}
