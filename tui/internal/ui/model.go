package ui

import (
	"fmt"
	"strings"
	"sync"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/cache"
	"github.com/kairin/ghostty-installer/internal/executor"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// View represents the current screen
type View int

const (
	ViewDashboard View = iota
	ViewExtras
	ViewAppMenu
	ViewInstaller
	ViewDiagnostics
)

// sharedState holds mutex-protected data that needs to survive model copies
// In Bubbletea's Elm architecture, the Model is copied on each Update
// A mutex must not be copied, so we use a pointer to shared state
type sharedState struct {
	mu           sync.RWMutex
	statuses     map[string]*cache.ToolStatus
	loadingTools map[string]bool
}

// Model is the root Bubbletea model
type Model struct {
	// View state
	currentView  View
	previousView View

	// Data
	cache    *cache.StatusCache
	repoRoot string

	// Tool selection
	selectedTool *registry.Tool
	mainCursor   int
	extrasCursor int
	menuCursor   int

	// Status data (shared across model copies via pointer)
	state *sharedState

	// Components
	spinner     spinner.Model
	installer   *InstallerModel
	extras      *ExtrasModel
	diagnostics *DiagnosticsModel

	// Flags
	demoMode   bool
	sudoCached bool
	loading    bool

	// Dimensions
	width  int
	height int

	// Boot diagnostics
	bootIssueCount int
}

// NewModel creates a new Model
func NewModel(repoRoot string, demoMode bool) Model {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	return Model{
		currentView: ViewDashboard,
		cache:       cache.NewStatusCache(),
		repoRoot:    repoRoot,
		state: &sharedState{
			statuses:     make(map[string]*cache.ToolStatus),
			loadingTools: make(map[string]bool),
		},
		spinner:  s,
		demoMode: demoMode,
		loading:  true,
	}
}

// Init initializes the model
func (m Model) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.refreshAllStatuses(),
	)
}

// Messages
type statusLoadedMsg struct {
	toolID string
	status *cache.ToolStatus
}

type allStatusesLoadedMsg struct{}

// refreshAllStatuses returns a batch of commands that check all main tools in parallel
// Each tool check is a separate tea.Cmd, allowing Bubbletea to handle concurrency properly
func (m Model) refreshAllStatuses() tea.Cmd {
	tools := registry.GetMainTools()
	cmds := make([]tea.Cmd, 0, len(tools))

	for _, tool := range tools {
		// Check cache first
		if status, ok := m.cache.Get(tool.ID); ok {
			// Return cached status as immediate message
			toolID := tool.ID
			cachedStatus := status
			cmds = append(cmds, func() tea.Msg {
				return statusLoadedMsg{toolID: toolID, status: cachedStatus}
			})
			continue
		}

		// Create a command for each tool (captures tool in closure)
		t := tool
		cmds = append(cmds, m.checkToolStatusAsync(t))
	}

	// Add a completion marker at the end
	cmds = append(cmds, func() tea.Msg {
		return allStatusesLoadedMsg{}
	})

	return tea.Batch(cmds...)
}

// checkToolStatusAsync returns a command that checks a single tool's status asynchronously
func (m Model) checkToolStatusAsync(tool *registry.Tool) tea.Cmd {
	repoRoot := m.repoRoot
	c := m.cache

	return func() tea.Msg {
		output, err := executor.RunCheck(repoRoot, tool.Scripts.Check)
		if err != nil {
			return statusLoadedMsg{
				toolID: tool.ID,
				status: &cache.ToolStatus{ID: tool.ID, Status: "Unknown"},
			}
		}

		status := cache.ParseCheckOutput(tool.ID, output)
		c.Set(status)

		return statusLoadedMsg{toolID: tool.ID, status: status}
	}
}

// checkToolStatus returns a command that checks a single tool's status
func (m Model) checkToolStatus(tool *registry.Tool) tea.Cmd {
	return func() tea.Msg {
		output, err := executor.RunCheck(m.repoRoot, tool.Scripts.Check)
		if err != nil {
			return statusLoadedMsg{
				toolID: tool.ID,
				status: &cache.ToolStatus{ID: tool.ID, Status: "Unknown"},
			}
		}

		status := cache.ParseCheckOutput(tool.ID, output)
		m.cache.Set(status)

		return statusLoadedMsg{toolID: tool.ID, status: status}
	}
}

// Update handles messages
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	// If installer is active, delegate messages to it
	if m.currentView == ViewInstaller && m.installer != nil {
		var cmd tea.Cmd
		newInstaller, cmd := m.installer.Update(msg)
		m.installer = &newInstaller

		// Check for ESC to return to dashboard
		if keyMsg, ok := msg.(tea.KeyMsg); ok && keyMsg.String() == "esc" {
			if !m.installer.IsRunning() {
				m.currentView = ViewDashboard
				m.installer = nil
				// Refresh status after installation
				return m, m.refreshAllStatuses()
			}
		}
		return m, cmd
	}

	// If extras view is active, delegate messages to it
	if m.currentView == ViewExtras && m.extras != nil {
		newExtras, cmd := m.extras.Update(msg)
		m.extras = &newExtras

		// Handle key presses for extras
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			if keyMsg.String() == "esc" {
				m.currentView = ViewDashboard
				m.extras = nil
				return m, nil
			}

			extrasCmd, handled := m.extras.HandleKey(keyMsg)
			if handled {
				// Handle tool selection or menu actions
				if m.extras.IsBackSelected() {
					m.currentView = ViewDashboard
					m.extras = nil
					return m, nil
				} else if m.extras.IsInstallAllSelected() {
					// TODO: Implement install all
					return m, nil
				} else if tool := m.extras.GetSelectedTool(); tool != nil {
					m.selectedTool = tool
					m.currentView = ViewAppMenu
					m.menuCursor = 0
					return m, nil
				}
			}
			if extrasCmd != nil {
				return m, extrasCmd
			}
		}

		return m, cmd
	}

	// If diagnostics view is active, delegate messages to it
	if m.currentView == ViewDiagnostics && m.diagnostics != nil {
		newDiag, cmd := m.diagnostics.Update(msg)
		m.diagnostics = &newDiag

		// Handle key presses for diagnostics
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			if keyMsg.String() == "esc" {
				m.currentView = ViewDashboard
				m.diagnostics = nil
				return m, nil
			}

			diagCmd := m.diagnostics.HandleKey(keyMsg)
			if diagCmd != nil {
				return m, diagCmd
			}
		}

		return m, cmd
	}

	switch msg := msg.(type) {
	case tea.KeyMsg:
		return m.handleKeyPress(msg)

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case statusLoadedMsg:
		m.state.mu.Lock()
		m.state.statuses[msg.toolID] = msg.status
		delete(m.state.loadingTools, msg.toolID)
		m.state.mu.Unlock()
		return m, nil

	case allStatusesLoadedMsg:
		m.loading = false
		return m, nil

	case startInstallMsg:
		return m.startInstaller(msg.tool, msg.resume)
	}

	return m, nil
}

// startInstallMsg triggers installation of a tool
type startInstallMsg struct {
	tool   *registry.Tool
	resume bool
}

// startInstaller creates and starts the installer view
func (m Model) startInstaller(tool *registry.Tool, resume bool) (tea.Model, tea.Cmd) {
	installer := NewInstallerModel(tool, m.repoRoot)
	m.installer = &installer
	m.currentView = ViewInstaller

	// Initialize and start
	initCmd := m.installer.Init()
	startCmd := func() tea.Msg {
		return InstallerStartMsg{Resume: resume}
	}

	return m, tea.Batch(initCmd, startCmd)
}

// handleKeyPress handles key presses
func (m Model) handleKeyPress(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		return m, tea.Quit

	case "up", "k":
		switch m.currentView {
		case ViewDashboard:
			if m.mainCursor > 0 {
				m.mainCursor--
			}
		case ViewAppMenu:
			if m.menuCursor > 0 {
				m.menuCursor--
			}
		}
		return m, nil

	case "down", "j":
		switch m.currentView {
		case ViewDashboard:
			maxCursor := registry.MainToolCount() + 3 // Tools + menu items
			if m.mainCursor < maxCursor-1 {
				m.mainCursor++
			}
		case ViewAppMenu:
			maxCursor := 4 // Install, Reinstall, Uninstall, Back
			if m.menuCursor < maxCursor-1 {
				m.menuCursor++
			}
		}
		return m, nil

	case "enter":
		return m.handleEnter()

	case "r":
		// Refresh all statuses
		m.loading = true
		m.cache.InvalidateAll()
		return m, tea.Batch(
			m.spinner.Tick,
			m.refreshAllStatuses(),
		)

	case "esc":
		if m.currentView != ViewDashboard {
			m.currentView = ViewDashboard
			m.menuCursor = 0
		}
		return m, nil
	}

	return m, nil
}

func (m Model) handleEnter() (tea.Model, tea.Cmd) {
	switch m.currentView {
	case ViewDashboard:
		tools := registry.GetMainTools()
		toolCount := len(tools)

		if m.mainCursor < toolCount {
			// Selected a tool
			m.selectedTool = tools[m.mainCursor]
			m.currentView = ViewAppMenu
			m.menuCursor = 0
		} else {
			// Menu item
			menuIndex := m.mainCursor - toolCount
			switch menuIndex {
			case 0: // Extras
				extras := NewExtrasModel(m.state, m.cache, m.repoRoot)
				m.extras = &extras
				m.currentView = ViewExtras
				return m, m.extras.Init()
			case 1: // Boot Diagnostics
				diag := NewDiagnosticsModel(m.repoRoot, m.demoMode, m.sudoCached)
				m.diagnostics = &diag
				m.currentView = ViewDiagnostics
				return m, m.diagnostics.Init()
			case 2: // Exit
				return m, tea.Quit
			}
		}

	case ViewAppMenu:
		return m.handleAppMenuEnter()
	}

	return m, nil
}

// View renders the UI
func (m Model) View() string {
	switch m.currentView {
	case ViewDashboard:
		return m.viewDashboard()
	case ViewExtras:
		return m.viewExtras()
	case ViewAppMenu:
		return m.viewAppMenu()
	case ViewInstaller:
		if m.installer != nil {
			return m.installer.View()
		}
		return m.viewDashboard()
	case ViewDiagnostics:
		return m.viewDiagnostics()
	default:
		return m.viewDashboard()
	}
}

func (m Model) viewDashboard() string {
	var b strings.Builder

	// Header
	header := HeaderStyle.Render(
		"System Installer\nGhostty, Feh, Local AI Tools",
	)
	b.WriteString(header)
	b.WriteString("\n\n")

	// Dashboard table
	b.WriteString(m.renderStatusTable())
	b.WriteString("\n")

	// Menu
	b.WriteString(m.renderMainMenu())
	b.WriteString("\n")

	// Help
	help := HelpStyle.Render("↑↓ navigate • enter select • r refresh • q quit")
	b.WriteString(help)

	return b.String()
}

func (m Model) renderStatusTable() string {
	var b strings.Builder

	// Calculate column widths
	colApp := 24
	colStatus := 14
	colVersion := 30
	colLatest := 28
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
	tools := registry.GetMainTools()
	for i, tool := range tools {
		m.state.mu.RLock()
		status, hasStatus := m.state.statuses[tool.ID]
		m.state.mu.RUnlock()

		// Determine status display
		var statusStr, versionStr, latestStr, methodStr string
		var statusStyle lipgloss.Style
		var icon string

		if m.loading && !hasStatus {
			statusStr = m.spinner.View() + " Loading"
			statusStyle = StatusUnknownStyle
			icon = ""
			versionStr = "-"
			latestStr = "-"
			methodStr = "-"
		} else if hasStatus {
			statusStyle = GetStatusStyle(status.Status)
			icon = GetStatusIcon(status.Status, status.NeedsUpdate())
			if status.NeedsUpdate() {
				statusStr = icon + " Update"
				statusStyle = StatusUpdateStyle
			} else if status.IsInstalled() {
				statusStr = icon + " OK"
			} else {
				statusStr = icon + " Missing"
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
		if i == m.mainCursor {
			rowStyle = TableSelectedStyle
		}

		row := fmt.Sprintf("%-*s %s%-*s %-*s %-*s %-*s",
			colApp, tool.DisplayName,
			"", // Status gets styled separately
			colStatus-1, statusStyle.Render(statusStr),
			colVersion, versionStr,
			colLatest, latestStr,
			colMethod, methodStr,
		)
		b.WriteString(rowStyle.Render(row))
		b.WriteString("\n")

		// Show details (location, sub-items)
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

	return BoxStyle.Render(b.String())
}

func (m Model) renderMainMenu() string {
	var b strings.Builder

	tools := registry.GetMainTools()
	toolCount := len(tools)

	menuItems := []string{"Extras", "Boot Diagnostics", "Exit"}

	b.WriteString("\nChoose:\n")

	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.mainCursor == toolCount+i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	return b.String()
}

func (m Model) viewExtras() string {
	if m.extras != nil {
		return m.extras.View()
	}
	return "Loading extras..."
}

func (m Model) viewAppMenu() string {
	if m.selectedTool == nil {
		return "No tool selected - press ESC"
	}

	var b strings.Builder

	// Header
	header := HeaderStyle.Render(fmt.Sprintf("%s - Actions", m.selectedTool.DisplayName))
	b.WriteString(header)
	b.WriteString("\n\n")

	// Get status
	m.state.mu.RLock()
	status, hasStatus := m.state.statuses[m.selectedTool.ID]
	m.state.mu.RUnlock()

	// Show current status
	if hasStatus {
		statusLine := fmt.Sprintf("Status: %s", status.Status)
		if status.Version != "" && status.Version != "-" {
			statusLine += fmt.Sprintf(" (v%s)", status.Version)
		}
		b.WriteString(DetailStyle.Render(statusLine))
		b.WriteString("\n\n")
	}

	// Menu options based on status
	menuItems := []string{"Install", "Reinstall", "Uninstall", "Back"}
	if hasStatus && status.NeedsUpdate() {
		menuItems = []string{"Update", "Reinstall", "Uninstall", "Back"}
	}

	b.WriteString("Choose action:\n")
	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.menuCursor == i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	b.WriteString("\n")
	b.WriteString(HelpStyle.Render("↑↓ navigate • enter select • esc back"))

	return b.String()
}

// handleAppMenuEnter processes enter key in app menu
func (m Model) handleAppMenuEnter() (tea.Model, tea.Cmd) {
	if m.selectedTool == nil {
		return m, nil
	}

	// Get status to determine menu options
	m.state.mu.RLock()
	status, hasStatus := m.state.statuses[m.selectedTool.ID]
	m.state.mu.RUnlock()

	// Menu items: Install/Update, Reinstall, Uninstall, Back
	hasUpdate := hasStatus && status.NeedsUpdate()

	switch m.menuCursor {
	case 0: // Install or Update
		return m, func() tea.Msg {
			return startInstallMsg{tool: m.selectedTool, resume: false}
		}
	case 1: // Reinstall
		return m, func() tea.Msg {
			return startInstallMsg{tool: m.selectedTool, resume: false}
		}
	case 2: // Uninstall
		// TODO: Implement uninstall
		_ = hasUpdate // Silence unused warning
		return m, nil
	case 3: // Back
		m.currentView = ViewDashboard
		m.menuCursor = 0
		return m, nil
	}

	return m, nil
}

func (m Model) viewDiagnostics() string {
	if m.diagnostics != nil {
		return m.diagnostics.View()
	}
	return "Loading diagnostics..."
}

// SetSudoCached sets the sudo cached flag for demo mode
func (m *Model) SetSudoCached(cached bool) {
	m.sudoCached = cached
}
