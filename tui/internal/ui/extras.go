// Package ui - extras.go provides the extras dashboard view with 7 additional tools
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

// ExtrasModel manages the extras dashboard view
type ExtrasModel struct {
	// Tool selection
	cursor int
	tools  []*registry.Tool

	// State
	loading bool

	// Shared state (statuses and loading flags from parent)
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

// NewExtrasModel creates a new extras model
func NewExtrasModel(state *sharedState, c *cache.StatusCache, repoRoot string) ExtrasModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	return ExtrasModel{
		tools:    registry.GetExtrasTools(),
		state:    state,
		spinner:  s,
		loading:  true,
		cache:    c,
		repoRoot: repoRoot,
	}
}

// Init initializes the extras model
func (m ExtrasModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.refreshExtrasStatuses(),
	)
}

// refreshExtrasStatuses returns a batch of commands that check all extras tools
func (m ExtrasModel) refreshExtrasStatuses() tea.Cmd {
	tools := registry.GetExtrasTools()
	cmds := make([]tea.Cmd, 0, len(tools))

	for _, tool := range tools {
		// Check cache first
		if status, ok := m.cache.Get(tool.ID); ok {
			toolID := tool.ID
			cachedStatus := status
			cmds = append(cmds, func() tea.Msg {
				return extrasStatusLoadedMsg{toolID: toolID, status: cachedStatus}
			})
			continue
		}

		// Create a command for each tool
		t := tool
		cmds = append(cmds, m.checkExtrasToolStatus(t))
	}

	// Add completion marker
	cmds = append(cmds, func() tea.Msg {
		return extrasAllLoadedMsg{}
	})

	return tea.Batch(cmds...)
}

// checkExtrasToolStatus returns a command that checks a single extras tool's status
func (m ExtrasModel) checkExtrasToolStatus(tool *registry.Tool) tea.Cmd {
	repoRoot := m.repoRoot
	c := m.cache

	return func() tea.Msg {
		output, err := executor.RunCheck(repoRoot, tool.Scripts.Check)
		if err != nil {
			return extrasStatusLoadedMsg{
				toolID: tool.ID,
				status: &cache.ToolStatus{ID: tool.ID, Status: "Unknown"},
			}
		}

		status := cache.ParseCheckOutput(tool.ID, output)
		c.Set(status)

		return extrasStatusLoadedMsg{toolID: tool.ID, status: status}
	}
}

// Extras-specific messages
type (
	extrasStatusLoadedMsg struct {
		toolID string
		status *cache.ToolStatus
	}
	extrasAllLoadedMsg struct{}
)

// Update handles messages for the extras model
func (m ExtrasModel) Update(msg tea.Msg) (ExtrasModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case extrasStatusLoadedMsg:
		m.state.mu.Lock()
		m.state.statuses[msg.toolID] = msg.status
		delete(m.state.loadingTools, msg.toolID)
		m.state.mu.Unlock()
		return m, nil

	case extrasAllLoadedMsg:
		m.loading = false
		return m, nil
	}

	return m, nil
}

// View renders the extras dashboard
func (m ExtrasModel) View() string {
	var b strings.Builder

	// Header (compact single line with cyan styling)
	header := ExtrasHeaderStyle.Render("Extras Tools • 7 Additional Tools")
	b.WriteString(header)
	b.WriteString("\n\n")

	// Status table
	b.WriteString(m.renderExtrasTable())
	b.WriteString("\n")

	// Menu
	b.WriteString(m.renderExtrasMenu())
	b.WriteString("\n")

	// Help
	help := HelpStyle.Render("↑↓ navigate • enter select • r refresh • esc back")
	b.WriteString(help)

	return b.String()
}

// renderExtrasTable renders the extras status table with cyan border
func (m ExtrasModel) renderExtrasTable() string {
	var b strings.Builder

	// Column widths
	colApp := 20
	colStatus := 14
	colVersion := 26
	colLatest := 24
	colMethod := 10

	// Header
	headerLine := fmt.Sprintf("%-*s %-*s %-*s %-*s %-*s",
		colApp, "APP",
		colStatus, "STATUS",
		colVersion, "VERSION",
		colLatest, "LATEST",
		colMethod, "METHOD",
	)
	b.WriteString(TableHeaderStyle.Render(headerLine))
	b.WriteString("\n")

	// Separator
	sep := strings.Repeat("─", colApp+colStatus+colVersion+colLatest+colMethod+4)
	b.WriteString(lipgloss.NewStyle().Foreground(ColorMuted).Render(sep))
	b.WriteString("\n")

	// Tools
	for i, tool := range m.tools {
		m.state.mu.RLock()
		status, hasStatus := m.state.statuses[tool.ID]
		m.state.mu.RUnlock()

		// Determine status display
		var statusStr, versionStr, latestStr, methodStr string
		var statusStyle lipgloss.Style

		if m.loading && !hasStatus {
			statusStr = m.spinner.View() + " Loading"
			statusStyle = StatusUnknownStyle
			versionStr = "-"
			latestStr = "-"
			methodStr = "-"
		} else if hasStatus {
			statusStyle = GetStatusStyle(status.Status)
			icon := GetStatusIcon(status.Status, status.NeedsUpdate())
			if status.NeedsUpdate() {
				statusStr = icon + " Update"
				statusStyle = StatusUpdateStyle
			} else if status.IsInstalled() {
				statusStr = icon + " " + status.Status
			} else {
				statusStr = icon + " " + status.Status
			}
			versionStr = status.Version
			latestStr = status.LatestVer
			methodStr = status.Method
		} else {
			statusStr = "Unknown"
			statusStyle = StatusUnknownStyle
			versionStr = "-"
			latestStr = "-"
			methodStr = "-"
		}

		// Format row
		rowStyle := TableRowStyle
		if i == m.cursor {
			rowStyle = TableSelectedStyle
		}

		row := fmt.Sprintf("%-*s %s%-*s %-*s %-*s %-*s",
			colApp, tool.DisplayName,
			"",
			colStatus-1, statusStyle.Render(statusStr),
			colVersion, versionStr,
			colLatest, latestStr,
			colMethod, methodStr,
		)
		b.WriteString(rowStyle.Render(row))
		b.WriteString("\n")

		// Show details
		if hasStatus && status.Location != "" && status.Location != "-" {
			locLine := fmt.Sprintf("    %s %s", IconFolder, status.Location)
			b.WriteString(DetailStyle.Render(locLine))
			b.WriteString("\n")
		}

		if hasStatus && len(status.Details) > 0 {
			for _, detail := range status.Details {
				if detail != "" {
					b.WriteString(DetailStyle.Render("    " + detail))
					b.WriteString("\n")
				}
			}
		}
	}

	return ExtrasBoxStyle.Render(b.String())
}

// renderExtrasMenu renders the extras menu options
func (m ExtrasModel) renderExtrasMenu() string {
	var b strings.Builder

	toolCount := len(m.tools)

	// Menu items: Individual tools + Install All + Back
	menuItems := make([]string, 0, toolCount+2)
	for _, tool := range m.tools {
		menuItems = append(menuItems, tool.DisplayName)
	}
	menuItems = append(menuItems, "Install All", "Back")

	b.WriteString("\nChoose:\n")

	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.cursor == i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	return b.String()
}

// HandleKey processes key presses in extras view
func (m *ExtrasModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	switch msg.String() {
	case "up", "k":
		maxCursor := len(m.tools) + 2 // Tools + "Install All" + "Back"
		if m.cursor > 0 {
			m.cursor--
		} else {
			m.cursor = maxCursor - 1 // Wrap to bottom
		}
		return nil, false

	case "down", "j":
		maxCursor := len(m.tools) + 2
		if m.cursor < maxCursor-1 {
			m.cursor++
		} else {
			m.cursor = 0 // Wrap to top
		}
		return nil, false

	case "r":
		// Refresh all statuses
		m.loading = true
		m.cache.InvalidateAll()
		return tea.Batch(
			m.spinner.Tick,
			m.refreshExtrasStatuses(),
		), false

	case "enter":
		toolCount := len(m.tools)
		if m.cursor < toolCount {
			// Selected a tool - return it for handling
			return nil, true // Signal tool selection
		} else if m.cursor == toolCount {
			// "Install All" selected
			return nil, true
		} else {
			// "Back" selected
			return nil, true
		}
	}

	return nil, false
}

// GetSelectedTool returns the currently selected tool, or nil for menu items
func (m ExtrasModel) GetSelectedTool() *registry.Tool {
	if m.cursor < len(m.tools) {
		return m.tools[m.cursor]
	}
	return nil
}

// IsInstallAllSelected returns true if "Install All" is selected
func (m ExtrasModel) IsInstallAllSelected() bool {
	return m.cursor == len(m.tools)
}

// IsBackSelected returns true if "Back" is selected
func (m ExtrasModel) IsBackSelected() bool {
	return m.cursor == len(m.tools)+1
}

// GetCursor returns the current cursor position
func (m ExtrasModel) GetCursor() int {
	return m.cursor
}

// SetCursor sets the cursor position
func (m *ExtrasModel) SetCursor(pos int) {
	m.cursor = pos
}
