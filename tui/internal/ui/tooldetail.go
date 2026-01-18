// Package ui - tooldetail.go provides the single tool detail view with status and actions
package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/cache"
	"github.com/kairin/ghostty-installer/internal/executor"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// ToolDetailModel manages the single tool detail view
type ToolDetailModel struct {
	// Tool being displayed
	tool *registry.Tool

	// Status data
	status *cache.ToolStatus

	// Navigation
	cursor int // Index in action menu

	// State
	loading bool

	// Return navigation
	returnTo View

	// Shared state (statuses from parent)
	state *sharedState

	// Components
	spinner spinner.Model

	// Dimensions
	width  int
	height int

	// Cache and repo root for status checks
	cache    *cache.StatusCache
	repoRoot string
}

// NewToolDetailModel creates a new tool detail model
func NewToolDetailModel(tool *registry.Tool, returnTo View, state *sharedState, c *cache.StatusCache, repoRoot string) ToolDetailModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	// Try to get cached status
	var status *cache.ToolStatus
	if tool != nil {
		if cached, ok := c.Get(tool.ID); ok {
			status = cached
		}
	}

	return ToolDetailModel{
		tool:     tool,
		status:   status,
		returnTo: returnTo,
		state:    state,
		spinner:  s,
		loading:  status == nil,
		cache:    c,
		repoRoot: repoRoot,
	}
}

// Init initializes the tool detail model
func (m ToolDetailModel) Init() tea.Cmd {
	if m.loading {
		return tea.Batch(
			m.spinner.Tick,
			m.refreshToolStatus(),
		)
	}
	return nil
}

// refreshToolStatus returns a command that checks the tool's status
func (m ToolDetailModel) refreshToolStatus() tea.Cmd {
	if m.tool == nil {
		return nil
	}

	// Check cache first
	if status, ok := m.cache.Get(m.tool.ID); ok {
		return func() tea.Msg {
			return toolDetailStatusLoadedMsg{status: status}
		}
	}

	// Run check script
	tool := m.tool
	repoRoot := m.repoRoot
	c := m.cache

	return func() tea.Msg {
		output, err := executor.RunCheck(repoRoot, tool.Scripts.Check)
		if err != nil {
			return toolDetailStatusLoadedMsg{
				status: &cache.ToolStatus{ID: tool.ID, Status: "Unknown"},
			}
		}

		status := cache.ParseCheckOutput(tool.ID, output)
		c.Set(status)

		return toolDetailStatusLoadedMsg{status: status}
	}
}

// Tool detail-specific messages
type toolDetailStatusLoadedMsg struct {
	status *cache.ToolStatus
}

// Update handles messages for the tool detail model
func (m ToolDetailModel) Update(msg tea.Msg) (ToolDetailModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case toolDetailStatusLoadedMsg:
		m.status = msg.status
		m.loading = false
		return m, nil
	}

	return m, nil
}

// View renders the tool detail view
func (m ToolDetailModel) View() string {
	if m.tool == nil {
		return "No tool selected - press ESC"
	}

	var b strings.Builder

	// Header with tool name and description
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("212")). // Pink/magenta for tool details
		Bold(true)
	header := headerStyle.Render(fmt.Sprintf("%s - Details", m.tool.DisplayName))
	b.WriteString(header)
	b.WriteString("\n")

	// Description if available
	if m.tool.Description != "" {
		descStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("245"))
		b.WriteString(descStyle.Render(m.tool.Description))
		b.WriteString("\n")
	}
	b.WriteString("\n")

	// Status table (5 rows)
	b.WriteString(m.renderStatusTable())
	b.WriteString("\n")

	// Action menu
	b.WriteString(m.renderActionMenu())
	b.WriteString("\n")

	// Help
	help := HelpStyle.Render("↑↓ navigate • enter select • r refresh • esc back")
	b.WriteString(help)

	return b.String()
}

// renderStatusTable renders the tool status as a vertical table
func (m ToolDetailModel) renderStatusTable() string {
	var b strings.Builder

	// Column widths for label and value
	colLabel := 12
	colValue := 50

	// Helper to render a row
	renderRow := func(label, value string, valueStyle lipgloss.Style) {
		labelStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("245")).
			Width(colLabel)
		row := fmt.Sprintf("%s %s",
			labelStyle.Render(label+":"),
			valueStyle.Render(value),
		)
		b.WriteString(row)
		b.WriteString("\n")
	}

	// Default value style
	valueStyle := lipgloss.NewStyle().Width(colValue)

	if m.loading {
		// Show loading state
		loadingStyle := StatusUnknownStyle
		renderRow("Status", m.spinner.View()+" Loading...", loadingStyle)
		renderRow("Version", "-", valueStyle)
		renderRow("Latest", "-", valueStyle)
		renderRow("Method", "-", valueStyle)
		renderRow("Location", "-", valueStyle)
	} else if m.status != nil {
		// Status row with icon and color
		statusStyle := GetStatusStyle(m.status.Status)
		icon := GetStatusIcon(m.status.Status, m.status.NeedsUpdate())
		statusText := icon + " " + m.status.Status
		if m.status.NeedsUpdate() {
			statusText = icon + " Update Available"
			statusStyle = StatusUpdateStyle
		}
		renderRow("Status", statusText, statusStyle)

		// Version
		version := m.status.Version
		if version == "" {
			version = "-"
		}
		renderRow("Version", version, valueStyle)

		// Latest version
		latest := m.status.LatestVer
		if latest == "" {
			latest = "-"
		}
		renderRow("Latest", latest, valueStyle)

		// Method
		method := m.status.Method
		if method == "" {
			method = "-"
		}
		renderRow("Method", method, valueStyle)

		// Location
		location := m.status.Location
		if location == "" {
			location = "-"
		}
		renderRow("Location", location, valueStyle)
	} else {
		// No status available
		renderRow("Status", "Unknown", StatusUnknownStyle)
		renderRow("Version", "-", valueStyle)
		renderRow("Latest", "-", valueStyle)
		renderRow("Method", "-", valueStyle)
		renderRow("Location", "-", valueStyle)
	}

	// Box with pink/magenta border for tool details
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("212")).
		Padding(1, 2)

	return boxStyle.Render(b.String())
}

// renderActionMenu renders the action menu for the tool
func (m ToolDetailModel) renderActionMenu() string {
	var b strings.Builder

	actions := m.getActions()

	b.WriteString("\nActions:\n")

	for i, action := range actions {
		cursor := " "
		style := MenuItemStyle
		if i == m.cursor {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(action)))
	}

	return b.String()
}

// getActions returns the available actions based on tool status
func (m ToolDetailModel) getActions() []string {
	actions := []string{}

	if m.status != nil && m.status.NeedsUpdate() {
		actions = append(actions, "Update")
	} else {
		actions = append(actions, "Install")
	}

	actions = append(actions, "Reinstall", "Uninstall")
	actions = append(actions, "Back")

	return actions
}

// HandleKey processes key presses in tool detail view
func (m *ToolDetailModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	actions := m.getActions()
	maxCursor := len(actions) - 1

	switch msg.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		} else {
			m.cursor = maxCursor // Wrap to bottom
		}
		return nil, false

	case "down", "j":
		if m.cursor < maxCursor {
			m.cursor++
		} else {
			m.cursor = 0 // Wrap to top
		}
		return nil, false

	case "r":
		// Refresh status
		m.loading = true
		if m.tool != nil {
			m.cache.Invalidate(m.tool.ID)
		}
		return tea.Batch(
			m.spinner.Tick,
			m.refreshToolStatus(),
		), false

	case "enter":
		// Signal action selection
		return nil, true

	case "esc":
		// Signal back navigation
		m.cursor = len(actions) - 1 // Select "Back"
		return nil, true
	}

	return nil, false
}

// IsBackSelected returns true if "Back" is selected
func (m ToolDetailModel) IsBackSelected() bool {
	actions := m.getActions()
	return m.cursor == len(actions)-1
}

// GetSelectedAction returns the currently selected action
func (m ToolDetailModel) GetSelectedAction() string {
	actions := m.getActions()
	if m.cursor < len(actions) {
		return actions[m.cursor]
	}
	return ""
}

// GetTool returns the tool being displayed
func (m ToolDetailModel) GetTool() *registry.Tool {
	return m.tool
}

// GetReturnTo returns the view to return to
func (m ToolDetailModel) GetReturnTo() View {
	return m.returnTo
}
