// Package ui - mcpservers.go provides the MCP Servers management view
package ui

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// MCPServerStatus represents the connection status of an MCP server
type MCPServerStatus struct {
	Connected bool
	Error     string
}

// MCPServersModel manages the MCP Servers management view
type MCPServersModel struct {
	// Server selection
	cursor  int
	servers []*registry.MCPServer

	// Status tracking
	statuses map[string]MCPServerStatus

	// State
	loading bool

	// Action menu state (for individual server selection)
	menuMode     bool
	actionItems  []string
	actionCursor int
	selectedServer *registry.MCPServer

	// Components
	spinner spinner.Model

	// Dimensions
	width  int
	height int
}

// NewMCPServersModel creates a new MCP Servers model
func NewMCPServersModel() MCPServersModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	return MCPServersModel{
		cursor:   0,
		servers:  registry.GetAllMCPServers(),
		statuses: make(map[string]MCPServerStatus),
		spinner:  s,
		loading:  true,
	}
}

// Init initializes the MCP Servers model
func (m MCPServersModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.refreshMCPStatuses(),
	)
}

// refreshMCPStatuses returns a command that checks MCP server statuses
func (m MCPServersModel) refreshMCPStatuses() tea.Cmd {
	return func() tea.Msg {
		// Run claude mcp list to get current server status
		cmd := exec.Command("claude", "mcp", "list")
		output, err := cmd.Output()
		if err != nil {
			return mcpAllLoadedMsg{err: err}
		}

		statuses := parseMCPListOutput(string(output))
		return mcpAllLoadedMsg{statuses: statuses}
	}
}

// parseMCPListOutput parses the output of `claude mcp list` command
func parseMCPListOutput(output string) map[string]MCPServerStatus {
	statuses := make(map[string]MCPServerStatus)

	lines := strings.Split(output, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}

		// Parse format: "server_name: connected" or "server_name: disconnected"
		// Or format with status indicators
		for _, server := range registry.GetAllMCPServers() {
			if strings.Contains(line, server.ID) {
				connected := strings.Contains(strings.ToLower(line), "connected") ||
					strings.Contains(line, "✓") ||
					!strings.Contains(strings.ToLower(line), "error")

				statuses[server.ID] = MCPServerStatus{
					Connected: connected,
				}
			}
		}
	}

	return statuses
}

// MCP-specific messages
type (
	mcpAllLoadedMsg struct {
		statuses map[string]MCPServerStatus
		err      error
	}

	mcpInstallResultMsg struct {
		serverID string
		success  bool
		err      error
	}

	mcpRemoveResultMsg struct {
		serverID string
		success  bool
		err      error
	}

	// MCPShowPrereqMsg signals that prerequisites view should be shown
	MCPShowPrereqMsg struct {
		Server *registry.MCPServer
	}

	// MCPInstallServerMsg signals that a server should be installed (prerequisites passed)
	MCPInstallServerMsg struct {
		Server *registry.MCPServer
	}

	// MCPShowSecretsWizardMsg signals that secrets wizard should be shown
	MCPShowSecretsWizardMsg struct{}
)

// Update handles messages for the MCP Servers model
func (m MCPServersModel) Update(msg tea.Msg) (MCPServersModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case mcpAllLoadedMsg:
		if msg.err == nil && msg.statuses != nil {
			m.statuses = msg.statuses
		}
		m.loading = false
		return m, nil

	case mcpInstallResultMsg:
		// Refresh status after install
		m.loading = true
		return m, m.refreshMCPStatuses()

	case mcpRemoveResultMsg:
		// Refresh status after remove
		m.loading = true
		return m, m.refreshMCPStatuses()
	}

	return m, nil
}

// View renders the MCP Servers management dashboard
func (m MCPServersModel) View() string {
	var b strings.Builder

	// Header (magenta styling for MCP)
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("135")). // Magenta for MCP
		Bold(true)
	header := headerStyle.Render(fmt.Sprintf("MCP Servers • %d Servers", registry.MCPServerCount()))
	b.WriteString(header)
	b.WriteString("\n\n")

	// Status table
	b.WriteString(m.renderServersTable())
	b.WriteString("\n")

	// Show action menu if in menu mode, otherwise show main menu
	if m.menuMode && m.selectedServer != nil {
		b.WriteString(m.renderActionMenu())
	} else {
		b.WriteString(m.renderMCPMenu())
	}
	b.WriteString("\n")

	// Help
	var helpText string
	if m.menuMode {
		helpText = "↑↓ navigate • enter select • esc cancel"
	} else {
		helpText = "↑↓ navigate • enter select • r refresh • esc back"
	}
	help := HelpStyle.Render(helpText)
	b.WriteString(help)

	return b.String()
}

// renderServersTable renders the MCP servers status table
func (m MCPServersModel) renderServersTable() string {
	var b strings.Builder

	// Column widths
	colServer := 16
	colTransport := 10
	colStatus := 14
	colDescription := 40

	// Header
	headerLine := fmt.Sprintf("%-*s %-*s %-*s %-*s",
		colServer, "SERVER",
		colTransport, "TRANSPORT",
		colStatus, "STATUS",
		colDescription, "DESCRIPTION",
	)
	b.WriteString(TableHeaderStyle.Render(headerLine))
	b.WriteString("\n")

	// Separator
	sep := strings.Repeat("─", colServer+colTransport+colStatus+colDescription+3)
	b.WriteString(lipgloss.NewStyle().Foreground(ColorMuted).Render(sep))
	b.WriteString("\n")

	// Servers
	for i, server := range m.servers {
		// Determine status display
		var statusStr, transportStr string
		var statusStyle lipgloss.Style

		if m.loading {
			statusStr = m.spinner.View() + " Loading"
			statusStyle = StatusUnknownStyle
		} else {
			status, hasStatus := m.statuses[server.ID]
			if hasStatus && status.Connected {
				statusStr = IconCheckmark + " Connected"
				statusStyle = StatusInstalledStyle
			} else {
				statusStr = IconCross + " Not Added"
				statusStyle = StatusMissingStyle
			}
		}

		// Transport type
		if server.Transport == registry.TransportHTTP {
			transportStr = "HTTP"
		} else {
			transportStr = "stdio"
		}

		// Format row
		rowStyle := TableRowStyle
		if i == m.cursor && m.cursor < len(m.servers) {
			rowStyle = TableSelectedStyle
		}

		row := fmt.Sprintf("%-*s %-*s %s%-*s %-*s",
			colServer, server.DisplayName,
			colTransport, transportStr,
			"",
			colStatus-1, statusStyle.Render(statusStr),
			colDescription, server.Description,
		)
		b.WriteString(rowStyle.Render(row))
		b.WriteString("\n")
	}

	// Box with magenta border for MCP
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("135")). // Magenta
		Padding(1, 2)

	return boxStyle.Render(b.String())
}

// renderMCPMenu renders the MCP menu options
func (m MCPServersModel) renderMCPMenu() string {
	var b strings.Builder

	serverCount := len(m.servers)

	// Menu items: Individual servers (0-6) + "Setup Secrets" (7) + "Back" (8)
	menuItems := []string{"Setup Secrets", "Back"}

	b.WriteString("\nChoose:\n")

	// Render menu items
	menuStartIndex := serverCount
	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.cursor == menuStartIndex+i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	return b.String()
}

// renderActionMenu renders the action menu for a selected server
func (m MCPServersModel) renderActionMenu() string {
	var b strings.Builder

	// Show which server is selected
	serverStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("135")). // Magenta
		Bold(true)
	b.WriteString(fmt.Sprintf("\nActions for %s:\n", serverStyle.Render(m.selectedServer.DisplayName)))

	// Render action items
	for i, item := range m.actionItems {
		cursor := " "
		style := MenuItemStyle
		if i == m.actionCursor {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	return b.String()
}

// HandleKey processes key presses in MCP Servers view
func (m *MCPServersModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	// Handle action menu mode separately
	if m.menuMode {
		return m.handleActionMenuKey(msg)
	}

	// Calculate menu boundaries
	serverCount := len(m.servers)
	menuItemCount := 2 // Setup Secrets + Back
	maxCursor := serverCount + menuItemCount - 1

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
		return m.refreshMCPStatuses(), false

	case "enter":
		// Handle selection
		if m.cursor < serverCount {
			// Selected a server - show action menu
			m.showActionMenu(m.servers[m.cursor])
			return nil, false
		} else if m.cursor == serverCount {
			// "Setup Secrets" selected
			return func() tea.Msg {
				return MCPShowSecretsWizardMsg{}
			}, false
		} else {
			// "Back" selected
			return nil, true
		}
	}

	return nil, false
}

// showActionMenu prepares and displays the action menu for a server
func (m *MCPServersModel) showActionMenu(server *registry.MCPServer) {
	m.selectedServer = server
	m.menuMode = true
	m.actionCursor = 0

	// Build action items based on server status
	status, hasStatus := m.statuses[server.ID]
	if hasStatus && status.Connected {
		m.actionItems = []string{"Remove", "Back"}
	} else {
		m.actionItems = []string{"Install", "Back"}
	}
}

// handleActionMenuKey processes key presses when in action menu mode
func (m *MCPServersModel) handleActionMenuKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	switch msg.String() {
	case "up", "k":
		if m.actionCursor > 0 {
			m.actionCursor--
		} else {
			m.actionCursor = len(m.actionItems) - 1 // Wrap to bottom
		}
		return nil, false

	case "down", "j":
		if m.actionCursor < len(m.actionItems)-1 {
			m.actionCursor++
		} else {
			m.actionCursor = 0 // Wrap to top
		}
		return nil, false

	case "esc":
		// Cancel action menu
		m.menuMode = false
		m.selectedServer = nil
		m.actionItems = nil
		m.actionCursor = 0
		return nil, false

	case "enter":
		// Execute selected action
		if m.actionCursor < len(m.actionItems) {
			action := m.actionItems[m.actionCursor]
			switch action {
			case "Install":
				server := m.selectedServer
				m.menuMode = false
				m.selectedServer = nil
				m.actionItems = nil
				m.actionCursor = 0

				// Check prerequisites first
				if !server.AllPrerequisitesPassed() || !server.AllSecretsPresent() {
					// Show prerequisites view
					return func() tea.Msg {
						return MCPShowPrereqMsg{Server: server}
					}, false
				}

				// Prerequisites passed - install directly
				m.loading = true
				return m.installMCPServer(server), false
			case "Remove":
				cmd := m.removeMCPServer(m.selectedServer)
				m.menuMode = false
				m.selectedServer = nil
				m.actionItems = nil
				m.actionCursor = 0
				m.loading = true
				return cmd, false
			case "Back":
				m.menuMode = false
				m.selectedServer = nil
				m.actionItems = nil
				m.actionCursor = 0
				return nil, false
			}
		}
	}

	return nil, false
}

// installMCPServer returns a command to install an MCP server
func (m *MCPServersModel) installMCPServer(server *registry.MCPServer) tea.Cmd {
	return func() tea.Msg {
		args := server.GetAddCommand()
		cmd := exec.Command("claude", args...)
		err := cmd.Run()

		return mcpInstallResultMsg{
			serverID: server.ID,
			success:  err == nil,
			err:      err,
		}
	}
}

// removeMCPServer returns a command to remove an MCP server
func (m *MCPServersModel) removeMCPServer(server *registry.MCPServer) tea.Cmd {
	return func() tea.Msg {
		args := server.GetRemoveCommand()
		cmd := exec.Command("claude", args...)
		err := cmd.Run()

		return mcpRemoveResultMsg{
			serverID: server.ID,
			success:  err == nil,
			err:      err,
		}
	}
}

// GetSelectedServer returns the currently selected server, or nil for menu items
func (m MCPServersModel) GetSelectedServer() *registry.MCPServer {
	if m.cursor < len(m.servers) {
		return m.servers[m.cursor]
	}
	return nil
}

// IsSetupSecretsSelected returns true if "Setup Secrets" is selected
func (m MCPServersModel) IsSetupSecretsSelected() bool {
	return m.cursor == len(m.servers)
}

// IsBackSelected returns true if "Back" is selected
func (m MCPServersModel) IsBackSelected() bool {
	return m.cursor == len(m.servers)+1
}
