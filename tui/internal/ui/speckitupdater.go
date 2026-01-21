// Package ui - speckitupdater.go provides the SpecKit Project Updater main view
package ui

import (
	"fmt"
	"os"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/kairin/ghostty-installer/internal/speckit"
)

// SpecKitUpdaterState represents the current input state
type SpecKitUpdaterState int

const (
	StateList SpecKitUpdaterState = iota
	StateAddProject
)

// SpecKitUpdaterModel manages the SpecKit Project Updater view
type SpecKitUpdaterModel struct {
	// Data
	config   *speckit.ProjectConfig
	repoRoot string

	// Selection
	cursor int
	state  SpecKitUpdaterState

	// Components
	spinner   spinner.Model
	textInput textinput.Model

	// Flags
	loading   bool
	loadError error

	// Dimensions
	width  int
	height int
}

// NewSpecKitUpdaterModel creates a new SpecKit updater model
func NewSpecKitUpdaterModel(repoRoot string) SpecKitUpdaterModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	ti := textinput.New()
	ti.Placeholder = "Enter project path (e.g., ~/projects/myapp)"
	ti.CharLimit = 256
	ti.Width = 50

	return SpecKitUpdaterModel{
		repoRoot:  repoRoot,
		spinner:   s,
		textInput: ti,
		loading:   true,
		state:     StateList,
	}
}

// specKitConfigLoadedMsg signals config loading is complete
type specKitConfigLoadedMsg struct {
	config *speckit.ProjectConfig
	err    error
}

// specKitProjectAddedMsg signals a project was added
type specKitProjectAddedMsg struct {
	path string
	err  error
}

// Init initializes the model
func (m SpecKitUpdaterModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.loadConfig(),
	)
}

// loadConfig returns a command that loads the speckit config
func (m SpecKitUpdaterModel) loadConfig() tea.Cmd {
	return func() tea.Msg {
		config, err := speckit.LoadConfig()
		return specKitConfigLoadedMsg{config: config, err: err}
	}
}

// Update handles messages
func (m SpecKitUpdaterModel) Update(msg tea.Msg) (SpecKitUpdaterModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case specKitConfigLoadedMsg:
		m.loading = false
		if msg.err != nil {
			m.loadError = msg.err
		} else {
			m.config = msg.config
		}
		return m, nil

	case specKitProjectAddedMsg:
		if msg.err != nil {
			// Show error briefly then return to list
			m.loadError = msg.err
			m.state = StateList
			m.textInput.Reset()
		} else {
			// Save config and refresh
			if m.config != nil {
				speckit.SaveConfig(m.config)
			}
			m.state = StateList
			m.textInput.Reset()
			m.loadError = nil
		}
		return m, nil

	case tea.KeyMsg:
		if m.state == StateAddProject {
			return m.handleAddProjectInput(msg)
		}
		return m.handleListInput(msg)
	}

	// Update text input if in add project state
	if m.state == StateAddProject {
		var cmd tea.Cmd
		m.textInput, cmd = m.textInput.Update(msg)
		return m, cmd
	}

	return m, nil
}

// handleListInput handles key presses in list state
func (m SpecKitUpdaterModel) handleListInput(msg tea.KeyMsg) (SpecKitUpdaterModel, tea.Cmd) {
	maxItems := m.getMenuItemCount()

	switch msg.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		} else {
			m.cursor = maxItems - 1 // Wrap to bottom
		}

	case "down", "j":
		if m.cursor < maxItems-1 {
			m.cursor++
		} else {
			m.cursor = 0 // Wrap to top
		}

	case "enter":
		return m.handleEnter()
	}

	return m, nil
}

// handleAddProjectInput handles key presses in add project state
func (m SpecKitUpdaterModel) handleAddProjectInput(msg tea.KeyMsg) (SpecKitUpdaterModel, tea.Cmd) {
	switch msg.String() {
	case "enter":
		// Try to add the project
		path := strings.TrimSpace(m.textInput.Value())
		if path == "" {
			m.state = StateList
			m.textInput.Reset()
			return m, nil
		}

		// Expand ~ to home directory
		if strings.HasPrefix(path, "~/") {
			home, _ := userHomeDir()
			path = home + path[1:]
		}

		// Add project to config
		if m.config != nil {
			err := speckit.AddProject(m.config, path)
			return m, func() tea.Msg {
				return specKitProjectAddedMsg{path: path, err: err}
			}
		}
		return m, nil

	case "esc":
		m.state = StateList
		m.textInput.Reset()
		m.loadError = nil
		return m, nil
	}

	// Forward to text input
	var cmd tea.Cmd
	m.textInput, cmd = m.textInput.Update(msg)
	return m, cmd
}

// handleEnter handles enter key in list state
func (m SpecKitUpdaterModel) handleEnter() (SpecKitUpdaterModel, tea.Cmd) {
	projectCount := 0
	if m.config != nil {
		projectCount = len(m.config.Projects)
	}

	if m.cursor < projectCount {
		// Selected a project - will navigate to detail view
		return m, nil // Return to model.go for handling
	}

	menuIndex := m.cursor - projectCount
	switch menuIndex {
	case 0: // Add Project
		m.state = StateAddProject
		m.textInput.Focus()
		m.loadError = nil
		return m, textinput.Blink
	case 1: // Update All
		// Will be handled by model.go
		return m, nil
	case 2: // Refresh
		m.loading = true
		m.loadError = nil
		return m, tea.Batch(m.spinner.Tick, m.loadConfig())
	case 3: // Back
		return m, nil // Return to model.go for handling
	}

	return m, nil
}

// getMenuItemCount returns the total number of menu items
func (m SpecKitUpdaterModel) getMenuItemCount() int {
	projectCount := 0
	if m.config != nil {
		projectCount = len(m.config.Projects)
	}
	return projectCount + 4 // Projects + Add Project + Update All + Refresh + Back
}

// View renders the view
func (m SpecKitUpdaterModel) View() string {
	var b strings.Builder

	// Header
	header := SpecKitHeaderStyle.Render("SpecKit Project Updater • Track & Update .specify/ Installations")
	b.WriteString(header)
	b.WriteString("\n\n")

	// Show loading or content
	if m.loading {
		b.WriteString(m.spinner.View() + " Loading projects...")
		b.WriteString("\n")
	} else if m.state == StateAddProject {
		b.WriteString(m.renderAddProjectInput())
	} else {
		b.WriteString(m.renderProjectList())
	}

	// Error display
	if m.loadError != nil {
		b.WriteString("\n")
		b.WriteString(OutputErrorStyle.Render(fmt.Sprintf("Error: %v", m.loadError)))
		b.WriteString("\n")
	}

	// Help
	b.WriteString("\n")
	if m.state == StateAddProject {
		b.WriteString(HelpStyle.Render("enter confirm • esc cancel"))
	} else {
		b.WriteString(HelpStyle.Render("↑↓ navigate • enter select • esc back"))
	}

	return b.String()
}

// renderProjectList renders the project list and menu
func (m SpecKitUpdaterModel) renderProjectList() string {
	var b strings.Builder

	projectCount := 0
	if m.config != nil {
		projectCount = len(m.config.Projects)
	}

	if projectCount == 0 {
		b.WriteString(DetailStyle.Render("No projects tracked. Add a project to get started."))
		b.WriteString("\n\n")
	} else {
		// Render project list
		b.WriteString("Tracked Projects:\n")
		for i, project := range m.config.Projects {
			cursor := " "
			style := MenuItemStyle
			if m.cursor == i {
				cursor = ">"
				style = MenuSelectedStyle
			}

			// Status icon
			icon := m.getStatusIcon(project.Status)

			// Format: > /path/to/project [status]
			line := fmt.Sprintf("%s %s [%s]", icon, project.Path, project.Status)
			b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(line)))
		}
		b.WriteString("\n")
	}

	// Menu items
	menuItems := []string{"Add Project", "Update All", "Refresh", "Back"}

	b.WriteString("Actions:\n")
	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.cursor == projectCount+i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	return b.String()
}

// renderAddProjectInput renders the add project text input
func (m SpecKitUpdaterModel) renderAddProjectInput() string {
	var b strings.Builder

	b.WriteString("Add Project Directory\n\n")
	b.WriteString("Enter the path to a project with a .specify/ directory:\n\n")
	b.WriteString(m.textInput.View())
	b.WriteString("\n")

	return b.String()
}

// getStatusIcon returns an icon for the project status
func (m SpecKitUpdaterModel) getStatusIcon(status speckit.ProjectStatus) string {
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
func (m *SpecKitUpdaterModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	if m.state == StateAddProject {
		// Let Update handle it
		return nil, false
	}

	switch msg.String() {
	case "enter":
		projectCount := 0
		if m.config != nil {
			projectCount = len(m.config.Projects)
		}

		if m.cursor < projectCount {
			// Project selected - signal to model.go
			return nil, true
		}

		menuIndex := m.cursor - projectCount
		switch menuIndex {
		case 0: // Add Project - handled internally
			return nil, false
		case 1: // Update All
			return nil, true
		case 2: // Refresh - handled internally
			return nil, false
		case 3: // Back
			return nil, true
		}
	}

	return nil, false
}

// GetSelectedProject returns the currently selected project, or nil for menu items
func (m SpecKitUpdaterModel) GetSelectedProject() *speckit.TrackedProject {
	if m.config == nil {
		return nil
	}
	if m.cursor < len(m.config.Projects) {
		return &m.config.Projects[m.cursor]
	}
	return nil
}

// IsAddProjectSelected returns true if "Add Project" is selected
func (m SpecKitUpdaterModel) IsAddProjectSelected() bool {
	projectCount := 0
	if m.config != nil {
		projectCount = len(m.config.Projects)
	}
	return m.cursor == projectCount
}

// IsUpdateAllSelected returns true if "Update All" is selected
func (m SpecKitUpdaterModel) IsUpdateAllSelected() bool {
	projectCount := 0
	if m.config != nil {
		projectCount = len(m.config.Projects)
	}
	return m.cursor == projectCount+1
}

// IsRefreshSelected returns true if "Refresh" is selected
func (m SpecKitUpdaterModel) IsRefreshSelected() bool {
	projectCount := 0
	if m.config != nil {
		projectCount = len(m.config.Projects)
	}
	return m.cursor == projectCount+2
}

// IsBackSelected returns true if "Back" is selected
func (m SpecKitUpdaterModel) IsBackSelected() bool {
	projectCount := 0
	if m.config != nil {
		projectCount = len(m.config.Projects)
	}
	return m.cursor == projectCount+3
}

// GetConfig returns the current config
func (m SpecKitUpdaterModel) GetConfig() *speckit.ProjectConfig {
	return m.config
}

// GetRepoRoot returns the repo root path
func (m SpecKitUpdaterModel) GetRepoRoot() string {
	return m.repoRoot
}

// userHomeDir returns the user's home directory
func userHomeDir() (string, error) {
	return os.UserHomeDir()
}
