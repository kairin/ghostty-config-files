package ui

import (
	"fmt"
	"os/exec"
	"strings"
	"sync"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/cache"
	"github.com/kairin/ghostty-installer/internal/config"
	"github.com/kairin/ghostty-installer/internal/detector"
	"github.com/kairin/ghostty-installer/internal/diagnostics"
	"github.com/kairin/ghostty-installer/internal/executor"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// View represents the current screen
type View int

const (
	ViewDashboard View = iota
	ViewExtras
	ViewAppMenu
	ViewMethodSelect
	ViewInstaller
	ViewDiagnostics
	ViewConfirm
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
	spinner       spinner.Model
	installer     *InstallerModel
	extras        *ExtrasModel
	diagnostics   *DiagnosticsModel
	confirmDialog *ConfirmModel
	methodSelector *MethodSelectorModel

	// Pending uninstall (set when confirmation shown)
	uninstallTool *registry.Tool

	// Flags
	demoMode   bool
	sudoCached bool
	loading    bool

	// Dimensions
	width  int
	height int

	// Boot diagnostics (cached issue count for banner)
	diagCache *diagnostics.CacheStore

	// Batch installation state (for "Install All" feature)
	batchQueue []*registry.Tool // Queue of tools to install
	batchIndex int              // Current position in queue
	batchMode  bool             // Whether in batch install mode

	// Status refresh tracking (prevents race conditions)
	refreshPending bool // True when async refresh is in flight

	// Clean install state (uninstall before install)
	pendingCleanInstall *registry.Tool // Tool to install after uninstall completes

	// Sudo authentication state
	pendingInstall *pendingInstall // Install waiting for sudo auth
	sudoAuthDone   bool            // Whether sudo auth was attempted this session
}

// pendingInstall stores installation to execute after sudo auth
type pendingInstall struct {
	tool      *registry.Tool
	resume    bool
	uninstall bool
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
		spinner:   s,
		demoMode:  demoMode,
		loading:   true,
		diagCache: diagnostics.NewCacheStore(),
	}
}

// Init initializes the model
func (m Model) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.refreshAllStatuses(),
		tea.WindowSize(), // Query initial terminal size for proper layout
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
	// Handle installation messages globally (before view-specific handling)
	// This ensures startInstallMsg/startUninstallMsg are processed regardless of currentView
	switch msg := msg.(type) {
	case startInstallMsg:
		// Check if sudo auth is needed before starting installation
		if !m.sudoAuthDone && !checkSudoCached() {
			// Store pending install and request sudo auth
			m.pendingInstall = &pendingInstall{
				tool:   msg.tool,
				resume: msg.resume,
			}
			return m, requestSudoAuth()
		}
		m.sudoAuthDone = true
		return m.startInstaller(msg.tool, msg.resume)

	case startUninstallMsg:
		// Check if sudo auth is needed before starting uninstallation
		if !m.sudoAuthDone && !checkSudoCached() {
			m.pendingInstall = &pendingInstall{
				tool:      msg.tool,
				uninstall: true,
			}
			return m, requestSudoAuth()
		}
		m.sudoAuthDone = true
		return m.startUninstaller(msg.tool)

	case sudoAuthMsg:
		m.sudoAuthDone = true
		if msg.success && m.pendingInstall != nil {
			// Resume pending installation
			pending := m.pendingInstall
			m.pendingInstall = nil
			if pending.uninstall {
				return m.startUninstaller(pending.tool)
			}
			return m.startInstaller(pending.tool, pending.resume)
		}
		// Auth failed or cancelled - clear pending and return to previous view
		m.pendingInstall = nil
		return m, nil

	case ConfirmResult:
		// Handle confirmation dialog result globally (before view-specific handling)
		return m.handleConfirmResult(msg)

	case methodSelectedMsg:
		// User selected installation method - save preference and proceed
		if m.selectedTool != nil {
			m.selectedTool.MethodOverride = msg.method

			// Save preference if requested
			if msg.savePreference && m.selectedTool.ID == "ghostty" {
				prefStore := config.NewPreferenceStore()
				_ = prefStore.SetGhosttyMethod(msg.method)
			}

			// Clear method selector
			m.methodSelector = nil

			// Proceed with installation using selected method
			return m.proceedWithInstall(m.selectedTool, msg.resume)
		}
		return m, nil

	case InstallerExitMsg:
		// User requested to exit installer view via recovery button
		m.batchMode = false
		m.batchQueue = nil
		m.batchIndex = 0
		m.pendingCleanInstall = nil

		// Return to extras view if we came from there
		if m.extras != nil {
			m.currentView = ViewExtras
			m.installer = nil
			m.refreshPending = false
			return m, m.extras.Init()
		}

		m.currentView = ViewDashboard
		m.installer = nil
		m.loading = true
		if !m.refreshPending {
			m.refreshPending = true
			return m, tea.Batch(m.spinner.Tick, m.refreshAllStatuses())
		}
		return m, m.spinner.Tick
	}

	// If installer is active, delegate messages to it
	if m.currentView == ViewInstaller && m.installer != nil {
		var cmd tea.Cmd
		newInstaller, cmd := m.installer.Update(msg)
		m.installer = &newInstaller

		// Auto-continue batch installation when current tool completes successfully
		if m.batchMode && !m.installer.IsRunning() && m.installer.IsSuccess() {
			m.batchIndex++
			if m.batchIndex < len(m.batchQueue) {
				// Start next tool in batch (auto-continue, no ESC needed)
				nextTool := m.batchQueue[m.batchIndex]
				m.selectedTool = nextTool
				m.installer = nil
				return m, func() tea.Msg {
					return startInstallMsg{tool: nextTool, resume: false}
				}
			}
			// Batch complete - return to extras
			m.batchMode = false
			m.batchQueue = nil
			m.batchIndex = 0
			if m.extras != nil {
				m.currentView = ViewExtras
				m.installer = nil
				return m, m.extras.Init()
			}
			m.currentView = ViewDashboard
			m.installer = nil
			return m, m.refreshAllStatuses()
		}

		// Check if uninstall completed and we have pending clean install
		if !m.batchMode && !m.installer.IsRunning() && m.installer.IsSuccess() && m.installer.IsUninstall() {
			if m.pendingCleanInstall != nil {
				tool := m.pendingCleanInstall
				m.pendingCleanInstall = nil
				// Chain to install after successful uninstall
				installer := NewInstallerModel(tool, m.repoRoot)
				m.installer = &installer
				initCmd := m.installer.Init()
				startCmd := func() tea.Msg {
					return InstallerStartMsg{Resume: false}
				}
				return m, tea.Batch(initCmd, startCmd)
			}
		}

		// Clear pendingCleanInstall if uninstall failed (prevent stale state)
		if !m.batchMode && !m.installer.IsRunning() && !m.installer.IsSuccess() && m.installer.IsUninstall() {
			m.pendingCleanInstall = nil
		}

		// Single-tool installation complete (not batch mode) - refresh in background
		// Only trigger once (check refreshPending to avoid double refresh)
		if !m.batchMode && !m.installer.IsRunning() && m.installer.IsSuccess() && !m.refreshPending {
			m.refreshPending = true
			m.loading = true // Show loading indicator on dashboard
			// Invalidate cache for this tool so fresh check runs
			if m.selectedTool != nil {
				m.cache.Invalidate(m.selectedTool.ID)
			}
			// Trigger background status refresh (user stays on success screen)
			return m, tea.Batch(m.spinner.Tick, m.refreshAllStatuses())
		}

		// Check for ESC to cancel/exit
		if keyMsg, ok := msg.(tea.KeyMsg); ok && keyMsg.String() == "esc" {
			if !m.installer.IsRunning() {
				// Reset batch state and return to appropriate view
				m.batchMode = false
				m.batchQueue = nil
				m.batchIndex = 0
				m.pendingCleanInstall = nil // Clear pending install on cancel

				// Return to extras view if we came from there
				if m.extras != nil {
					m.currentView = ViewExtras
					m.installer = nil
					m.refreshPending = false
					return m, m.extras.Init()
				}

				m.currentView = ViewDashboard
				m.installer = nil
				// Show loading indicator while refresh completes
				m.loading = true
				// Ensure status refresh happens before returning to dashboard
				if !m.refreshPending {
					m.refreshPending = true
					return m, tea.Batch(m.spinner.Tick, m.refreshAllStatuses())
				}
				// Refresh already in flight, just keep spinner going
				return m, m.spinner.Tick
			}
		}
		return m, cmd
	}

	// If method selector is active, delegate messages to it
	if m.currentView == ViewMethodSelect && m.methodSelector != nil {
		newSelector, cmd := m.methodSelector.Update(msg)
		m.methodSelector = &newSelector

		// Handle ESC to go back
		if _, ok := msg.(backMsg); ok {
			m.methodSelector = nil
			m.currentView = ViewDashboard
			return m, nil
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
					// Install All reinstalls all extras tools regardless of status
					toInstall := registry.GetExtrasTools()

					if len(toInstall) == 0 {
						return m, nil
					}

					// Start batch installation
					m.batchQueue = toInstall
					m.batchIndex = 0
					m.batchMode = true

					// Start first tool installation
					firstTool := m.batchQueue[0]
					m.selectedTool = firstTool
					return m, func() tea.Msg {
						return startInstallMsg{tool: firstTool, resume: false}
					}
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

	// If confirm dialog is active, delegate messages to it
	if m.currentView == ViewConfirm && m.confirmDialog != nil {
		newConfirm, cmd := m.confirmDialog.Update(msg)
		m.confirmDialog = &newConfirm
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
		m.refreshPending = false // Reset flag so future refreshes can trigger
		return m, nil
	}

	return m, nil
}

// startInstallMsg triggers installation of a tool
type startInstallMsg struct {
	tool   *registry.Tool
	resume bool
}

// startUninstallMsg triggers uninstallation of a tool
type startUninstallMsg struct {
	tool *registry.Tool
}

// sudoAuthMsg signals sudo authentication is complete
type sudoAuthMsg struct {
	success bool
	err     error
}

// checkSudoCached returns true if sudo credentials are currently cached
func checkSudoCached() bool {
	cmd := exec.Command("sudo", "-n", "true")
	return cmd.Run() == nil
}

// requestSudoAuth returns a command that prompts for sudo password
// This suspends the TUI and gives the user full terminal access
func requestSudoAuth() tea.Cmd {
	c := exec.Command("sudo", "-v")
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return sudoAuthMsg{success: err == nil, err: err}
	})
}

// startInstaller creates and starts the installer view
// For multi-method tools (like ghostty), shows method selector first if no preference saved
func (m Model) startInstaller(tool *registry.Tool, resume bool) (tea.Model, tea.Cmd) {
	// Check if tool is already installed - need to uninstall first (clean install)
	// This ensures old versions are removed before installing new ones
	m.state.mu.RLock()
	status, hasStatus := m.state.statuses[tool.ID]
	m.state.mu.RUnlock()

	if hasStatus && status != nil && status.IsInstalled() {
		m.pendingCleanInstall = tool // Remember to install after uninstall
		return m.startUninstaller(tool)
	}

	// Check for multi-method support (e.g., ghostty supports snap and source)
	if tool.SupportsMultipleMethods() {
		// Check for saved preference
		prefStore := config.NewPreferenceStore()
		var savedMethod registry.InstallMethod

		if tool.ID == "ghostty" {
			savedMethod, _ = prefStore.GetGhosttyMethod()
		}

		if savedMethod != "" {
			// Use saved preference, skip method selection
			tool.MethodOverride = savedMethod
			return m.proceedWithInstall(tool, resume)
		}

		// No preference - show method selector
		sysInfo, err := detector.DetectSystem()
		if err != nil {
			// Fallback: detector failed, use default method
			return m.proceedWithInstall(tool, resume)
		}

		recommendation := detector.RecommendGhosttyMethod(sysInfo)

		selector := NewMethodSelector(tool, recommendation, sysInfo)
		m.methodSelector = &selector
		m.selectedTool = tool // Remember tool for later
		m.currentView = ViewMethodSelect
		return m, selector.Init()
	}

	// Single method tool - proceed directly
	return m.proceedWithInstall(tool, resume)
}

// proceedWithInstall proceeds with installation after method selection (or directly for single-method tools)
func (m Model) proceedWithInstall(tool *registry.Tool, resume bool) (tea.Model, tea.Cmd) {
	// Normal fresh install
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

// showUninstallConfirm shows the confirmation dialog for uninstalling
func (m Model) showUninstallConfirm(tool *registry.Tool) (tea.Model, tea.Cmd) {
	confirm := ConfirmUninstall(tool.DisplayName, tool)
	confirm.SetSize(m.width, m.height)
	m.confirmDialog = &confirm
	m.uninstallTool = tool
	m.previousView = m.currentView
	m.currentView = ViewConfirm
	return m, nil
}

// handleConfirmResult handles the result from the confirmation dialog
func (m Model) handleConfirmResult(result ConfirmResult) (tea.Model, tea.Cmd) {
	// Clear the confirmation dialog
	m.confirmDialog = nil
	m.currentView = m.previousView

	if result.Confirmed && m.uninstallTool != nil {
		// User confirmed - start uninstall
		tool := m.uninstallTool
		m.uninstallTool = nil
		return m, func() tea.Msg {
			return startUninstallMsg{tool: tool}
		}
	}

	// User cancelled - go back
	m.uninstallTool = nil
	return m, nil
}

// startUninstaller creates and starts the uninstaller view
func (m Model) startUninstaller(tool *registry.Tool) (tea.Model, tea.Cmd) {
	// Create installer model in uninstall mode
	installer := NewInstallerModelForUninstall(tool, m.repoRoot)
	m.installer = &installer
	m.currentView = ViewInstaller

	// Initialize and start uninstall
	initCmd := m.installer.Init()
	startCmd := func() tea.Msg {
		return InstallerStartMsg{Resume: false, Uninstall: true}
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

// getToolStatus retrieves the cached status for a tool by ID
func (m Model) getToolStatus(toolID string) *cache.ToolStatus {
	m.state.mu.RLock()
	defer m.state.mu.RUnlock()

	if status, ok := m.state.statuses[toolID]; ok {
		return status
	}
	return nil
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
	case ViewMethodSelect:
		if m.methodSelector != nil {
			return m.methodSelector.View()
		}
		return m.viewDashboard()
	case ViewInstaller:
		if m.installer != nil {
			return m.installer.View()
		}
		return m.viewDashboard()
	case ViewDiagnostics:
		return m.viewDiagnostics()
	case ViewConfirm:
		if m.confirmDialog != nil {
			return m.confirmDialog.View()
		}
		return m.viewDashboard()
	default:
		return m.viewDashboard()
	}
}

func (m Model) viewDashboard() string {
	var b strings.Builder

	// Header (compact single line)
	header := HeaderStyle.Render("System Installer • Ghostty, Feh, Local AI Tools")
	b.WriteString(header)
	b.WriteString("\n\n")

	// Diagnostics banner (if issues found in cache)
	if issues := m.diagCache.GetIssues(); len(issues) > 0 {
		critCount := 0
		for _, issue := range issues {
			if issue.Severity == diagnostics.SeverityCritical {
				critCount++
			}
		}

		bannerStyle := lipgloss.NewStyle().
			Foreground(ColorWarning).
			Bold(true)

		var bannerText string
		if critCount > 0 {
			bannerText = fmt.Sprintf("%s %d boot issues found (%d critical) - see Boot Diagnostics",
				IconWarning, len(issues), critCount)
		} else {
			bannerText = fmt.Sprintf("%s %d boot issues found - see Boot Diagnostics",
				IconWarning, len(issues))
		}
		b.WriteString(bannerStyle.Render(bannerText))
		b.WriteString("\n\n")
	}

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

	// Build menu items dynamically based on status and tool capabilities
	var menuItems []string
	if hasStatus && status.NeedsUpdate() {
		menuItems = append(menuItems, "Update")
	} else {
		menuItems = append(menuItems, "Install")
	}
	menuItems = append(menuItems, "Reinstall", "Uninstall")

	// Add Configure option if available and conditions met
	if m.selectedTool.Scripts.Configure != "" {
		// Only show Configure for ZSH when both Ghostty and ZSH are installed
		if m.selectedTool.ID == "zsh" {
			ghosttyStatus := m.getToolStatus("ghostty")
			zshStatus := m.getToolStatus("zsh")

			if ghosttyStatus != nil && zshStatus != nil &&
				ghosttyStatus.IsInstalled() && zshStatus.IsInstalled() {
				menuItems = append(menuItems, "Configure")
			}
		}
	}

	menuItems = append(menuItems, "Back")

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

	// Build menu items dynamically (same logic as viewAppMenu)
	m.state.mu.RLock()
	status, hasStatus := m.state.statuses[m.selectedTool.ID]
	m.state.mu.RUnlock()

	var menuItems []string
	if hasStatus && status.NeedsUpdate() {
		menuItems = append(menuItems, "Update")
	} else {
		menuItems = append(menuItems, "Install")
	}
	menuItems = append(menuItems, "Reinstall", "Uninstall")

	// Add Configure option if available and conditions met
	if m.selectedTool.Scripts.Configure != "" {
		if m.selectedTool.ID == "zsh" {
			ghosttyStatus := m.getToolStatus("ghostty")
			zshStatus := m.getToolStatus("zsh")

			if ghosttyStatus != nil && zshStatus != nil &&
				ghosttyStatus.IsInstalled() && zshStatus.IsInstalled() {
				menuItems = append(menuItems, "Configure")
			}
		}
	}

	menuItems = append(menuItems, "Back")

	// Get selected action by name (not index)
	if m.menuCursor >= len(menuItems) {
		return m, nil
	}
	selectedAction := menuItems[m.menuCursor]

	// Handle action by name
	switch selectedAction {
	case "Install", "Update", "Reinstall":
		return m, func() tea.Msg {
			return startInstallMsg{tool: m.selectedTool, resume: false}
		}
	case "Uninstall":
		return m.showUninstallConfirm(m.selectedTool)
	case "Configure":
		return m.startConfigure(m.selectedTool)
	case "Back":
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

// startConfigure initiates the configuration process for a tool
func (m Model) startConfigure(tool *registry.Tool) (tea.Model, tea.Cmd) {
	if tool.Scripts.Configure == "" {
		return m, nil
	}

	// Create installer model for configure operation
	installer := NewInstallerModelForConfigure(tool, m.repoRoot)
	m.installer = &installer
	m.currentView = ViewInstaller

	// Initialize and start
	initCmd := m.installer.Init()
	startCmd := func() tea.Msg {
		return InstallerStartMsg{Resume: false, Uninstall: false}
	}

	return m, tea.Batch(initCmd, startCmd)
}
