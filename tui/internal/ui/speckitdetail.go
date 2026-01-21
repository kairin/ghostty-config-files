// Package ui - speckitdetail.go provides the SpecKit single project detail view
package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/kairin/ghostty-installer/internal/speckit"
)

// SpecKitDetailState represents the current view state
type SpecKitDetailState int

const (
	DetailStateMain SpecKitDetailState = iota
	DetailStatePreview
)

// SpecKitDetailModel manages a single project's detail view
type SpecKitDetailModel struct {
	// Data
	project  *speckit.TrackedProject
	config   *speckit.ProjectConfig
	repoRoot string

	// State
	state    SpecKitDetailState
	scanning bool
	cursor   int

	// Diff data
	diffs      []speckit.FileDifference
	diffOutput string

	// Components
	spinner  spinner.Model
	viewport viewport.Model

	// Error handling
	lastError error

	// Dimensions
	width  int
	height int
}

// NewSpecKitDetailModel creates a new SpecKit detail model
func NewSpecKitDetailModel(project *speckit.TrackedProject, config *speckit.ProjectConfig, repoRoot string) SpecKitDetailModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	vp := viewport.New(80, 20)
	vp.Style = DiffContextStyle

	return SpecKitDetailModel{
		project:  project,
		config:   config,
		repoRoot: repoRoot,
		spinner:  s,
		viewport: vp,
		diffs:    project.Differences,
		state:    DetailStateMain,
	}
}

// specKitScanCompleteMsg signals scanning is complete
type specKitScanCompleteMsg struct {
	projectPath string
	diffs       []speckit.FileDifference
	err         error
}

// specKitPatchCompleteMsg signals patching is complete
type specKitPatchCompleteMsg struct {
	projectPath string
	backupPath  string
	err         error
}

// specKitRollbackCompleteMsg signals rollback is complete
type specKitRollbackCompleteMsg struct {
	projectPath string
	err         error
}

// Init initializes the model
func (m SpecKitDetailModel) Init() tea.Cmd {
	return m.spinner.Tick
}

// Update handles messages
func (m SpecKitDetailModel) Update(msg tea.Msg) (SpecKitDetailModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.viewport.Width = msg.Width - 4
		m.viewport.Height = msg.Height - 10
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case specKitScanCompleteMsg:
		m.scanning = false
		if msg.err != nil {
			m.lastError = msg.err
			return m, nil
		}

		m.diffs = msg.diffs
		m.lastError = nil

		// Update project status in config
		if m.config != nil && m.project != nil {
			status := speckit.StatusUpToDate
			if len(msg.diffs) > 0 {
				status = speckit.StatusNeedsUpdate
			}
			speckit.UpdateProjectStatus(m.config, m.project.Path, status, msg.diffs, "")
			speckit.SaveConfig(m.config)

			// Update local project reference
			m.project.Status = status
			m.project.Differences = msg.diffs
		}

		return m, nil

	case specKitPatchCompleteMsg:
		if msg.err != nil {
			m.lastError = msg.err
			return m, nil
		}

		m.lastError = nil

		// Update project status
		if m.config != nil && m.project != nil {
			speckit.UpdateProjectStatus(m.config, m.project.Path, speckit.StatusUpToDate, nil, msg.backupPath)
			speckit.SaveConfig(m.config)

			m.project.Status = speckit.StatusUpToDate
			m.project.Differences = nil
			m.project.LastBackup = msg.backupPath
			m.diffs = nil
		}

		return m, nil

	case specKitRollbackCompleteMsg:
		if msg.err != nil {
			m.lastError = msg.err
			return m, nil
		}

		m.lastError = nil

		// Clear backup and set pending status (needs re-scan)
		if m.config != nil && m.project != nil {
			speckit.ClearProjectBackup(m.config, m.project.Path)
			speckit.UpdateProjectStatus(m.config, m.project.Path, speckit.StatusPending, nil, "")
			speckit.SaveConfig(m.config)

			m.project.Status = speckit.StatusPending
			m.project.LastBackup = ""
			m.diffs = nil
		}

		return m, nil

	case tea.KeyMsg:
		if m.state == DetailStatePreview {
			return m.handlePreviewInput(msg)
		}
		return m.handleMainInput(msg)
	}

	// Update viewport if in preview state
	if m.state == DetailStatePreview {
		var cmd tea.Cmd
		m.viewport, cmd = m.viewport.Update(msg)
		return m, cmd
	}

	return m, nil
}

// handleMainInput handles key presses in main state
func (m SpecKitDetailModel) handleMainInput(msg tea.KeyMsg) (SpecKitDetailModel, tea.Cmd) {
	menuItems := m.getMenuItems()
	maxItems := len(menuItems)

	switch msg.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		} else {
			m.cursor = maxItems - 1
		}

	case "down", "j":
		if m.cursor < maxItems-1 {
			m.cursor++
		} else {
			m.cursor = 0
		}

	case "enter":
		return m.handleEnter()
	}

	return m, nil
}

// handlePreviewInput handles key presses in preview state
func (m SpecKitDetailModel) handlePreviewInput(msg tea.KeyMsg) (SpecKitDetailModel, tea.Cmd) {
	switch msg.String() {
	case "esc", "q":
		m.state = DetailStateMain
		return m, nil
	}

	// Forward to viewport for scrolling
	var cmd tea.Cmd
	m.viewport, cmd = m.viewport.Update(msg)
	return m, cmd
}

// handleEnter handles enter key
func (m SpecKitDetailModel) handleEnter() (SpecKitDetailModel, tea.Cmd) {
	menuItems := m.getMenuItems()
	if m.cursor >= len(menuItems) {
		return m, nil
	}

	action := menuItems[m.cursor]
	switch action {
	case "Scan":
		return m.startScan()
	case "Preview":
		return m.showPreview()
	case "Apply":
		// Will be handled by model.go (needs confirmation)
		return m, nil
	case "Rollback":
		// Will be handled by model.go (needs confirmation)
		return m, nil
	case "Remove":
		// Will be handled by model.go (needs confirmation)
		return m, nil
	case "Back":
		return m, nil
	}

	return m, nil
}

// startScan initiates an async scan
func (m SpecKitDetailModel) startScan() (SpecKitDetailModel, tea.Cmd) {
	m.scanning = true
	m.lastError = nil

	projectPath := m.project.Path
	repoRoot := m.repoRoot

	return m, tea.Batch(
		m.spinner.Tick,
		func() tea.Msg {
			diffs, err := speckit.ScanProject(projectPath, repoRoot)
			return specKitScanCompleteMsg{
				projectPath: projectPath,
				diffs:       diffs,
				err:         err,
			}
		},
	)
}

// showPreview switches to preview mode
func (m SpecKitDetailModel) showPreview() (SpecKitDetailModel, tea.Cmd) {
	if len(m.diffs) == 0 {
		return m, nil
	}

	// Generate diff output
	diffOutput, err := speckit.GenerateDiffOutput(m.project.Path, m.repoRoot, m.diffs)
	if err != nil {
		m.lastError = err
		return m, nil
	}

	m.diffOutput = diffOutput
	m.viewport.SetContent(m.renderDiffContent())
	m.viewport.GotoTop()
	m.state = DetailStatePreview

	return m, nil
}

// getMenuItems returns the available menu items based on current state
func (m SpecKitDetailModel) getMenuItems() []string {
	items := []string{"Scan"}

	if len(m.diffs) > 0 {
		items = append(items, "Preview", "Apply")
	}

	if m.project != nil && m.project.LastBackup != "" {
		items = append(items, "Rollback")
	}

	items = append(items, "Remove", "Back")

	return items
}

// View renders the view
func (m SpecKitDetailModel) View() string {
	if m.state == DetailStatePreview {
		return m.renderPreviewView()
	}
	return m.renderMainView()
}

// renderMainView renders the main detail view
func (m SpecKitDetailModel) renderMainView() string {
	var b strings.Builder

	// Header
	header := SpecKitHeaderStyle.Render("SpecKit Project Detail")
	b.WriteString(header)
	b.WriteString("\n\n")

	// Project info
	if m.project != nil {
		b.WriteString(fmt.Sprintf("Path: %s\n", m.project.Path))
		b.WriteString(fmt.Sprintf("Status: %s %s\n", m.getStatusIcon(m.project.Status), m.project.Status))

		if m.project.LastScanned != nil {
			b.WriteString(fmt.Sprintf("Last Scanned: %s\n", m.project.LastScanned.Format("2006-01-02 15:04:05")))
		}

		if m.project.LastBackup != "" {
			b.WriteString(fmt.Sprintf("Backup: %s\n", m.project.LastBackup))
		}
	}
	b.WriteString("\n")

	// Scanning indicator
	if m.scanning {
		b.WriteString(m.spinner.View() + " Scanning for differences...")
		b.WriteString("\n\n")
	}

	// Diff summary
	if len(m.diffs) > 0 {
		b.WriteString(fmt.Sprintf("Found %d difference(s):\n", len(m.diffs)))
		// Group by file
		fileMap := make(map[string]int)
		for _, diff := range m.diffs {
			fileMap[diff.File]++
		}
		for file, count := range fileMap {
			b.WriteString(DetailStyle.Render(fmt.Sprintf("  %s: %d region(s)", file, count)))
			b.WriteString("\n")
		}
		b.WriteString("\n")
	} else if m.project != nil && m.project.Status == speckit.StatusUpToDate {
		b.WriteString(StatusInstalledStyle.Render("✓ Project is up to date"))
		b.WriteString("\n\n")
	}

	// Error display
	if m.lastError != nil {
		b.WriteString(OutputErrorStyle.Render(fmt.Sprintf("Error: %v", m.lastError)))
		b.WriteString("\n\n")
	}

	// Menu
	menuItems := m.getMenuItems()
	b.WriteString("Actions:\n")
	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.cursor == i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	// Help
	b.WriteString("\n")
	b.WriteString(HelpStyle.Render("↑↓ navigate • enter select • esc back"))

	return b.String()
}

// renderPreviewView renders the diff preview view
func (m SpecKitDetailModel) renderPreviewView() string {
	var b strings.Builder

	// Header
	header := SpecKitHeaderStyle.Render("Diff Preview")
	b.WriteString(header)
	b.WriteString("\n\n")

	// Viewport with diff content
	b.WriteString(m.viewport.View())
	b.WriteString("\n\n")

	// Help
	b.WriteString(HelpStyle.Render("↑↓/pgup/pgdn scroll • esc/q back"))

	return b.String()
}

// renderDiffContent renders the diff content with syntax highlighting
func (m SpecKitDetailModel) renderDiffContent() string {
	var b strings.Builder

	lines := strings.Split(m.diffOutput, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "---") || strings.HasPrefix(line, "+++") {
			b.WriteString(DiffHeaderStyle.Render(line))
		} else if strings.HasPrefix(line, "@@") {
			b.WriteString(DiffHeaderStyle.Render(line))
		} else if strings.HasPrefix(line, "-") {
			b.WriteString(DiffRemovedStyle.Render(line))
		} else if strings.HasPrefix(line, "+") {
			b.WriteString(DiffAddedStyle.Render(line))
		} else {
			b.WriteString(DiffContextStyle.Render(line))
		}
		b.WriteString("\n")
	}

	return b.String()
}

// getStatusIcon returns an icon for the project status
func (m SpecKitDetailModel) getStatusIcon(status speckit.ProjectStatus) string {
	switch status {
	case speckit.StatusUpToDate:
		return IconCheckmark
	case speckit.StatusNeedsUpdate:
		return IconArrowUp
	case speckit.StatusError:
		return IconCross
	default:
		return IconCircle
	}
}

// HandleKey processes key presses (called from model.go for navigation)
func (m *SpecKitDetailModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	if m.state == DetailStatePreview {
		// Preview handles its own input
		return nil, false
	}

	switch msg.String() {
	case "enter":
		menuItems := m.getMenuItems()
		if m.cursor >= len(menuItems) {
			return nil, false
		}

		action := menuItems[m.cursor]
		switch action {
		case "Scan", "Preview":
			// Handled internally
			return nil, false
		case "Apply", "Rollback", "Remove", "Back":
			// Signal to model.go
			return nil, true
		}
	}

	return nil, false
}

// GetSelectedAction returns the currently selected action
func (m SpecKitDetailModel) GetSelectedAction() string {
	menuItems := m.getMenuItems()
	if m.cursor < len(menuItems) {
		return menuItems[m.cursor]
	}
	return ""
}

// IsBackSelected returns true if "Back" is selected
func (m SpecKitDetailModel) IsBackSelected() bool {
	return m.GetSelectedAction() == "Back"
}

// GetProject returns the current project
func (m SpecKitDetailModel) GetProject() *speckit.TrackedProject {
	return m.project
}

// GetDiffs returns the current differences
func (m SpecKitDetailModel) GetDiffs() []speckit.FileDifference {
	return m.diffs
}

// GetConfig returns the config
func (m SpecKitDetailModel) GetConfig() *speckit.ProjectConfig {
	return m.config
}

// StartPatch initiates the patch operation (called after confirmation)
func (m SpecKitDetailModel) StartPatch(repoRoot string) tea.Cmd {
	if m.project == nil || len(m.diffs) == 0 {
		return nil
	}

	projectPath := m.project.Path
	diffs := m.diffs

	return func() tea.Msg {
		// Create backup first
		files := speckit.GetFilesToPatch(diffs)
		backupPath, err := speckit.CreateBackup(projectPath, files)
		if err != nil {
			return specKitPatchCompleteMsg{
				projectPath: projectPath,
				err:         fmt.Errorf("backup failed: %w", err),
			}
		}

		// Apply patch
		err = speckit.ApplyPatch(projectPath, repoRoot, diffs)
		if err != nil {
			// Restore from backup on failure
			speckit.RestoreFromBackup(projectPath, backupPath)
			return specKitPatchCompleteMsg{
				projectPath: projectPath,
				err:         fmt.Errorf("patch failed (restored from backup): %w", err),
			}
		}

		return specKitPatchCompleteMsg{
			projectPath: projectPath,
			backupPath:  backupPath,
		}
	}
}

// StartRollback initiates the rollback operation (called after confirmation)
func (m SpecKitDetailModel) StartRollback() tea.Cmd {
	if m.project == nil || m.project.LastBackup == "" {
		return nil
	}

	projectPath := m.project.Path
	backupPath := m.project.LastBackup

	return func() tea.Msg {
		err := speckit.RestoreFromBackup(projectPath, backupPath)
		return specKitRollbackCompleteMsg{
			projectPath: projectPath,
			err:         err,
		}
	}
}
