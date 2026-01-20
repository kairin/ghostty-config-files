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
	ViewNerdFonts
	ViewMCPServers
	ViewMCPPrereq
	ViewSecretsWizard
	ViewAppMenu
	ViewMethodSelect
	ViewInstaller
	ViewDiagnostics
	ViewConfirm
	ViewToolDetail
	ViewBatchPreview // NEW: Batch operation preview screen
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
	spinner        spinner.Model
	installer      *InstallerModel
	extras         *ExtrasModel
	nerdFonts      *NerdFontsModel
	mcpServers     *MCPServersModel
	mcpPrereq      *MCPPrereqModel
	secretsWizard  *SecretsWizardModel
	diagnostics    *DiagnosticsModel
	confirmDialog  *ConfirmModel
	methodSelector *MethodSelectorModel
	toolDetail     *ToolDetailModel
	toolDetailFrom View // View to return to when exiting tool detail

	// Batch preview component (for Install All / Update All previews)
	batchPreview *BatchPreviewModel

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
	tool           *registry.Tool
	resume         bool
	uninstall      bool
	forceReinstall bool // Skip update routing, force uninstall→reinstall
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
				tool:           msg.tool,
				resume:         msg.resume,
				forceReinstall: msg.forceReinstall,
			}
			return m, requestSudoAuth()
		}
		m.sudoAuthDone = true
		return m.startInstaller(msg.tool, msg.resume, msg.forceReinstall)

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
			return m.startInstaller(pending.tool, pending.resume, pending.forceReinstall)
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
					// Install All - show preview first
					toInstall := registry.GetExtrasTools()

					if len(toInstall) == 0 {
						return m, nil
					}

					// Copy status map for preview display
					m.state.mu.RLock()
					statuses := make(map[string]*cache.ToolStatus)
					for k, v := range m.state.statuses {
						statuses[k] = v
					}
					m.state.mu.RUnlock()
					preview := NewBatchPreviewModel(toInstall, statuses, "Install", ViewExtras)
					m.batchPreview = &preview
					m.currentView = ViewBatchPreview
					return m, nil
				} else if m.extras.IsClaudeConfigSelected() {
					// Install Claude Config (skills + agents) - use InstallerModel for in-TUI progress
					claudeConfigTool := &registry.Tool{
						ID:          "claude_config",
						DisplayName: "Claude Config",
						Scripts: registry.ToolScripts{
							Install: "scripts/install-claude-config.sh",
						},
					}
					m.selectedTool = claudeConfigTool
					installer := NewInstallerModel(claudeConfigTool, m.repoRoot)
					m.installer = &installer
					m.currentView = ViewInstaller

					initCmd := m.installer.Init()
					startCmd := func() tea.Msg {
						return InstallerStartMsg{Resume: false}
					}
					return m, tea.Batch(initCmd, startCmd)
				} else if m.extras.IsMCPServersSelected() {
					// Navigate to MCP Servers view
					mcpModel := NewMCPServersModel()
					m.mcpServers = &mcpModel
					m.currentView = ViewMCPServers
					return m, m.mcpServers.Init()
				} else if tool := m.extras.GetSelectedTool(); tool != nil {
					// Navigate to tool detail view for extras tools
					toolDetail := NewToolDetailModel(tool, ViewExtras, m.state, m.cache, m.repoRoot)
					m.toolDetail = &toolDetail
					m.toolDetailFrom = ViewExtras
					m.currentView = ViewToolDetail
					return m, m.toolDetail.Init()
				}
			}
			if extrasCmd != nil {
				return m, extrasCmd
			}
		}

		return m, cmd
	}

	// If Nerd Fonts view is active, delegate messages to it
	if m.currentView == ViewNerdFonts && m.nerdFonts != nil {
		newNerdFonts, cmd := m.nerdFonts.Update(msg)
		m.nerdFonts = &newNerdFonts

		// Handle NerdFontInstallMsg - single font installation/uninstallation
		if fontMsg, ok := msg.(NerdFontInstallMsg); ok {
			return m.handleNerdFontInstall(fontMsg)
		}

		// Handle key presses for Nerd Fonts
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			if keyMsg.String() == "esc" {
				m.currentView = ViewDashboard
				m.nerdFonts = nil
				return m, nil
			}

			nerdFontsCmd, handled := m.nerdFonts.HandleKey(keyMsg)
			if handled {
				// Handle menu actions
				if m.nerdFonts.IsBackSelected() {
					m.currentView = ViewDashboard
					m.nerdFonts = nil
					return m, nil
				} else if m.nerdFonts.IsInstallAllSelected() {
					// Install All - show preview of fonts to be installed
					// Get missing fonts for preview
					var missingFonts []FontFamily
					for _, font := range m.nerdFonts.fonts {
						if font.Status != "Installed" {
							missingFonts = append(missingFonts, font)
						}
					}
					if len(missingFonts) == 0 {
						return m, nil
					}
					preview := NewBatchPreviewModelForFonts(missingFonts, "Install", ViewNerdFonts)
					m.batchPreview = &preview
					m.currentView = ViewBatchPreview
					return m, nil
				}
				// Individual font selection is now handled via action menu (NerdFontInstallMsg)
			}
			if nerdFontsCmd != nil {
				return m, nerdFontsCmd
			}
		}

		return m, cmd
	}

	// If MCP Servers view is active, delegate messages to it
	if m.currentView == ViewMCPServers && m.mcpServers != nil {
		newMCPServers, cmd := m.mcpServers.Update(msg)
		m.mcpServers = &newMCPServers

		// Handle key presses for MCP Servers
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			if keyMsg.String() == "esc" {
				m.currentView = ViewExtras
				m.mcpServers = nil
				return m, nil
			}

			mcpCmd, handled := m.mcpServers.HandleKey(keyMsg)
			if handled {
				// Handle menu actions
				if m.mcpServers.IsBackSelected() {
					m.currentView = ViewExtras
					m.mcpServers = nil
					return m, nil
				}
			}
			if mcpCmd != nil {
				return m, mcpCmd
			}
		}

		return m, cmd
	}

	// If MCP Prerequisites view is active, delegate messages to it
	if m.currentView == ViewMCPPrereq && m.mcpPrereq != nil {
		newMCPPrereq, cmd := m.mcpPrereq.Update(msg)
		m.mcpPrereq = &newMCPPrereq

		// Handle key presses for MCP Prerequisites
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			_, handled := m.mcpPrereq.HandleKey(keyMsg)
			if handled {
				// Go back to MCP Servers view
				m.currentView = ViewMCPServers
				m.mcpPrereq = nil
				return m, nil
			}
		}

		return m, cmd
	}

	// If Secrets Wizard view is active, delegate messages to it
	if m.currentView == ViewSecretsWizard && m.secretsWizard != nil {
		newWizard, cmd := m.secretsWizard.Update(msg)
		m.secretsWizard = &newWizard

		// Handle key presses for Secrets Wizard
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			_, handled := m.secretsWizard.HandleKey(keyMsg)
			if handled {
				// Go back to MCP Servers view
				m.currentView = ViewMCPServers
				m.secretsWizard = nil
				return m, nil
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

	// If tool detail view is active, delegate messages to it
	if m.currentView == ViewToolDetail && m.toolDetail != nil {
		newToolDetail, cmd := m.toolDetail.Update(msg)
		m.toolDetail = &newToolDetail

		// Handle key presses for tool detail
		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			toolDetailCmd, handled := m.toolDetail.HandleKey(keyMsg)
			if handled {
				// Handle action selection or back
				if m.toolDetail.IsBackSelected() {
					// Return to previous view
					m.currentView = m.toolDetailFrom
					m.toolDetail = nil
					return m, nil
				}
				// Handle other actions
				action := m.toolDetail.GetSelectedAction()
				tool := m.toolDetail.GetTool()
				if tool != nil {
					switch action {
					case "Install", "Update":
						return m, func() tea.Msg {
							return startInstallMsg{tool: tool, resume: false, forceReinstall: false}
						}
					case "Reinstall":
						return m, func() tea.Msg {
							return startInstallMsg{tool: tool, resume: false, forceReinstall: true}
						}
					case "Uninstall":
						return m.showUninstallConfirm(tool)
					}
				}
			}
			if toolDetailCmd != nil {
				return m, toolDetailCmd
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

	// If batch preview is active, delegate messages to it
	if m.currentView == ViewBatchPreview && m.batchPreview != nil {
		newPreview, cmd := m.batchPreview.Update(msg)
		m.batchPreview = &newPreview

		if keyMsg, ok := msg.(tea.KeyMsg); ok {
			switch keyMsg.String() {
			case "enter":
				if m.batchPreview.IsConfirmed() {
					// Start batch operation
					if m.batchPreview.IsFont() {
						// Font batch - use nerdfonts tool
						tool, _ := registry.GetTool("nerdfonts")
						m.selectedTool = tool
						returnView := m.batchPreview.GetReturnView()
						m.batchPreview = nil
						m.currentView = returnView
						return m, func() tea.Msg {
							return startInstallMsg{tool: tool, resume: false}
						}
					} else {
						m.batchQueue = m.batchPreview.GetTools()
						m.batchIndex = 0
						m.batchMode = true
						m.batchPreview = nil
						if len(m.batchQueue) > 0 {
							firstTool := m.batchQueue[0]
							m.selectedTool = firstTool
							return m, func() tea.Msg {
								return startInstallMsg{tool: firstTool, resume: false}
							}
						}
					}
				}
				if m.batchPreview.IsCancelled() {
					returnView := m.batchPreview.GetReturnView()
					m.batchPreview = nil
					m.currentView = returnView
					return m, nil
				}
			case "esc":
				returnView := m.batchPreview.GetReturnView()
				m.batchPreview = nil
				m.currentView = returnView
				return m, nil
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
		m.refreshPending = false // Reset flag so future refreshes can trigger
		return m, nil

	case MCPShowPrereqMsg:
		// Show prerequisites view for MCP server
		prereqModel := NewMCPPrereqModel(msg.Server)
		m.mcpPrereq = &prereqModel
		m.currentView = ViewMCPPrereq
		return m, nil

	case MCPInstallServerMsg:
		// Install MCP server (prerequisites already passed)
		if m.mcpServers != nil {
			return m, m.mcpServers.installMCPServer(msg.Server)
		}
		return m, nil

	case MCPShowSecretsWizardMsg:
		// Show secrets wizard
		wizardModel := NewSecretsWizardModel()
		m.secretsWizard = &wizardModel
		m.currentView = ViewSecretsWizard
		return m, m.secretsWizard.Init()

	case claudeConfigResultMsg:
		// Claude config installation complete - return to extras view
		// The script output was shown directly via tea.ExecProcess
		if m.extras != nil {
			return m, m.extras.Init()
		}
		return m, nil
	}

	return m, nil
}

// startInstallMsg triggers installation of a tool
type startInstallMsg struct {
	tool           *registry.Tool
	resume         bool
	forceReinstall bool // Skip update routing, force uninstall→reinstall
}

// startUninstallMsg triggers uninstallation of a tool
type startUninstallMsg struct {
	tool *registry.Tool
}

// claudeConfigResultMsg reports result of installing Claude config
type claudeConfigResultMsg struct {
	success bool
	output  string
	err     error
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
// SMART ROUTING: If tool is installed and has update script, routes to UPDATE (non-destructive)
// instead of UNINSTALL→REINSTALL (destructive) to preserve user data
// Set forceReinstall=true to skip update routing and force clean reinstall
func (m Model) startInstaller(tool *registry.Tool, resume bool, forceReinstall bool) (tea.Model, tea.Cmd) {
	// Nil check: prevent panic when tool is nil
	if tool == nil {
		// Return to dashboard with no action if tool is nil
		return m, nil
	}

	// Check if tool is already installed
	m.state.mu.RLock()
	status, hasStatus := m.state.statuses[tool.ID]
	m.state.mu.RUnlock()

	if hasStatus && status != nil && status.IsInstalled() {
		// Tool is installed - check if we should UPDATE (non-destructive) or REINSTALL (destructive)
		// Route to UPDATE if: tool has update script AND needs update AND not forcing reinstall
		// This preserves npm globals, auth tokens, and configs
		if !forceReinstall && tool.HasUpdateScript() && status.NeedsUpdate() {
			return m.startUpdater(tool)
		}
		// No update script, already latest, or forcing reinstall - do clean reinstall (uninstall → install)
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
	// Nil check: prevent panic when tool is nil
	if tool == nil {
		return m, nil
	}

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

// startUpdater creates and starts the updater view (non-destructive in-place update)
// This preserves user data like npm global packages, auth tokens, and configurations
func (m Model) startUpdater(tool *registry.Tool) (tea.Model, tea.Cmd) {
	// Nil check: prevent panic when tool is nil
	if tool == nil {
		return m, nil
	}

	// Create installer model in update mode
	installer := NewInstallerModelForUpdate(tool, m.repoRoot)
	m.installer = &installer
	m.currentView = ViewInstaller

	// Initialize and start update
	initCmd := m.installer.Init()
	startCmd := func() tea.Msg {
		return InstallerStartMsg{Resume: false, Update: true}
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
			// Calculate max cursor: table tools + menu items
			tableToolCount := len(m.getTableTools())
			menuToolCount := len(m.getMenuTools()) // Ghostty, Feh
			menuItemCount := menuToolCount + 4     // Ghostty, Feh, Nerd Fonts, Extras, Boot Diagnostics, Exit
			if m.getUpdateCount() > 0 && !m.loading {
				menuItemCount++ // Add "Update All" option
			}
			maxCursor := tableToolCount + menuItemCount
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

	case "u", "U":
		// Update All shortcut - only works on dashboard when updates available
		if m.currentView == ViewDashboard && m.getUpdateCount() > 0 && !m.loading {
			return m.startBatchUpdate()
		}
		return m, nil

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
		tableTools := m.getTableTools()
		tableToolCount := len(tableTools)
		menuTools := m.getMenuTools()
		menuToolCount := len(menuTools)

		if m.mainCursor < tableToolCount {
			// Selected a tool from the table - go to tool detail view (consistent with menu tools)
			tool := tableTools[m.mainCursor]
			toolDetail := NewToolDetailModel(tool, ViewDashboard, m.state, m.cache, m.repoRoot)
			m.toolDetail = &toolDetail
			m.toolDetailFrom = ViewDashboard
			m.currentView = ViewToolDetail
			return m, m.toolDetail.Init()
		} else if m.mainCursor < tableToolCount+menuToolCount {
			// Selected a menu tool (Ghostty or Feh) - go to tool detail view
			menuToolIndex := m.mainCursor - tableToolCount
			tool := menuTools[menuToolIndex]
			toolDetail := NewToolDetailModel(tool, ViewDashboard, m.state, m.cache, m.repoRoot)
			m.toolDetail = &toolDetail
			m.toolDetailFrom = ViewDashboard
			m.currentView = ViewToolDetail
			return m, m.toolDetail.Init()
		} else {
			// Other menu item selected
			menuIndex := m.mainCursor - tableToolCount - menuToolCount
			updateCount := m.getUpdateCount()

			// If updates available, "Update All" is at index 0
			if updateCount > 0 && !m.loading {
				if menuIndex == 0 {
					// "Update All" selected - show preview first
					toUpdate := m.getToolsNeedingUpdates()
					if len(toUpdate) == 0 {
						return m, nil
					}
					// Copy status map for preview display
					m.state.mu.RLock()
					statuses := make(map[string]*cache.ToolStatus)
					for k, v := range m.state.statuses {
						statuses[k] = v
					}
					m.state.mu.RUnlock()
					preview := NewBatchPreviewModel(toUpdate, statuses, "Update", ViewDashboard)
					m.batchPreview = &preview
					m.currentView = ViewBatchPreview
					return m, nil
				}
				menuIndex-- // Offset for remaining items
			}

			switch menuIndex {
			case 0: // Nerd Fonts
				nerdFonts := NewNerdFontsModel(m.state, m.cache, m.repoRoot)
				m.nerdFonts = &nerdFonts
				m.currentView = ViewNerdFonts
				return m, m.nerdFonts.Init()
			case 1: // Extras
				extras := NewExtrasModel(m.state, m.cache, m.repoRoot)
				m.extras = &extras
				m.currentView = ViewExtras
				return m, m.extras.Init()
			case 2: // Boot Diagnostics
				diag := NewDiagnosticsModel(m.repoRoot, m.demoMode, m.sudoCached)
				m.diagnostics = &diag
				m.currentView = ViewDiagnostics
				return m, m.diagnostics.Init()
			case 3: // Exit
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

// getToolsNeedingUpdates returns all tools (main + extras) that have updates available
func (m Model) getToolsNeedingUpdates() []*registry.Tool {
	m.state.mu.RLock()
	defer m.state.mu.RUnlock()

	var needsUpdate []*registry.Tool

	// Check main tools
	for _, tool := range registry.GetMainTools() {
		if status, ok := m.state.statuses[tool.ID]; ok && status.NeedsUpdate() {
			needsUpdate = append(needsUpdate, tool)
		}
	}

	// Check extras tools
	for _, tool := range registry.GetExtrasTools() {
		if status, ok := m.state.statuses[tool.ID]; ok && status.NeedsUpdate() {
			needsUpdate = append(needsUpdate, tool)
		}
	}

	return needsUpdate
}

// getUpdateCount returns the number of tools with updates available
func (m Model) getUpdateCount() int {
	return len(m.getToolsNeedingUpdates())
}

// startBatchUpdate initiates update of all tools with available updates
func (m Model) startBatchUpdate() (tea.Model, tea.Cmd) {
	toUpdate := m.getToolsNeedingUpdates()

	if len(toUpdate) == 0 {
		return m, nil
	}

	// Reuse batch mode infrastructure
	m.batchQueue = toUpdate
	m.batchIndex = 0
	m.batchMode = true

	// Start with first tool
	firstTool := m.batchQueue[0]
	m.selectedTool = firstTool
	m.currentView = ViewInstaller

	return m, func() tea.Msg {
		return startInstallMsg{tool: firstTool, resume: false}
	}
}

// View renders the UI
func (m Model) View() string {
	switch m.currentView {
	case ViewDashboard:
		return m.viewDashboard()
	case ViewExtras:
		return m.viewExtras()
	case ViewNerdFonts:
		return m.viewNerdFonts()
	case ViewMCPServers:
		return m.viewMCPServers()
	case ViewMCPPrereq:
		return m.viewMCPPrereq()
	case ViewSecretsWizard:
		return m.viewSecretsWizard()
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
	case ViewToolDetail:
		if m.toolDetail != nil {
			return m.toolDetail.View()
		}
		return m.viewDashboard()
	case ViewBatchPreview:
		if m.batchPreview != nil {
			return m.batchPreview.View()
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

	// Updates available banner (shown when tools have updates)
	updateCount := m.getUpdateCount()
	if updateCount > 0 && !m.loading {
		plural := ""
		if updateCount > 1 {
			plural = "s"
		}
		banner := fmt.Sprintf("%s %d update%s available - press 'u' or select Update All",
			IconArrowUp, updateCount, plural)
		b.WriteString(StatusUpdateStyle.Render(banner))
		b.WriteString("\n\n")
	}

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

	// Help (show 'u' shortcut when updates available)
	helpText := "↑↓ navigate • enter select • r refresh • q quit"
	if m.getUpdateCount() > 0 && !m.loading {
		helpText = "↑↓ navigate • enter select • u update all • r refresh • q quit"
	}
	help := HelpStyle.Render(helpText)
	b.WriteString(help)

	return b.String()
}

// getTableTools returns only the tools to display in the main table (excludes menu-only tools)
func (m Model) getTableTools() []*registry.Tool {
	allMain := registry.GetMainTools()
	tableTools := make([]*registry.Tool, 0, 3)
	// Filter: only show nodejs, ai_tools, antigravity in table
	// Ghostty and Feh are now menu items for quick access to detail views
	for _, tool := range allMain {
		if tool.ID == "nodejs" || tool.ID == "ai_tools" || tool.ID == "antigravity" {
			tableTools = append(tableTools, tool)
		}
	}
	return tableTools
}

// getMenuTools returns tools that should appear as menu items (Ghostty, Feh)
func (m Model) getMenuTools() []*registry.Tool {
	menuTools := make([]*registry.Tool, 0, 2)
	if tool, ok := registry.GetTool("ghostty"); ok {
		menuTools = append(menuTools, tool)
	}
	if tool, ok := registry.GetTool("feh"); ok {
		menuTools = append(menuTools, tool)
	}
	return menuTools
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

	// Tools - only show table tools (nodejs, ai_tools, antigravity)
	tools := m.getTableTools()
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
					// Use section header style for "Bundled:" and "Globals:" headers
					if detail == "Bundled:" {
						b.WriteString(SectionHeaderStyle.Render(IconPackage + " Bundled:"))
						b.WriteString("\n")
					} else if detail == "Globals:" {
						b.WriteString(SectionHeaderStyle.Render(IconGear + " Globals:"))
						b.WriteString("\n")
					} else {
						b.WriteString(DetailStyle.Render("    " + detail))
						b.WriteString("\n")
					}
				}
			}
		}
	}

	return BoxStyle.Render(b.String())
}

func (m Model) renderMainMenu() string {
	var b strings.Builder

	tableTools := m.getTableTools()
	tableToolCount := len(tableTools)

	// Build menu items dynamically
	// Order: Ghostty, Feh, (Update All if available), Nerd Fonts, Extras, Boot Diagnostics, Exit
	menuItems := []string{}

	// Add Ghostty and Feh at the top (quick access to detail views)
	menuTools := m.getMenuTools()
	for _, tool := range menuTools {
		menuItems = append(menuItems, tool.DisplayName)
	}

	// Add "Update All" if updates available
	updateCount := m.getUpdateCount()
	if updateCount > 0 && !m.loading {
		menuItems = append(menuItems, fmt.Sprintf("Update All (%d)", updateCount))
	}

	menuItems = append(menuItems, "Nerd Fonts", "Extras", "Boot Diagnostics", "Exit")

	b.WriteString("\nChoose:\n")

	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.mainCursor == tableToolCount+i {
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

func (m Model) viewNerdFonts() string {
	if m.nerdFonts != nil {
		return m.nerdFonts.View()
	}
	return "Loading Nerd Fonts..."
}

func (m Model) viewMCPServers() string {
	if m.mcpServers != nil {
		return m.mcpServers.View()
	}
	return "Loading MCP Servers..."
}

func (m Model) viewMCPPrereq() string {
	if m.mcpPrereq != nil {
		return m.mcpPrereq.View()
	}
	return "Loading prerequisites..."
}

func (m Model) viewSecretsWizard() string {
	if m.secretsWizard != nil {
		return m.secretsWizard.View()
	}
	return "Loading secrets wizard..."
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
	case "Install", "Update":
		// Install/Update: allow smart routing to update if applicable
		return m, func() tea.Msg {
			return startInstallMsg{tool: m.selectedTool, resume: false, forceReinstall: false}
		}
	case "Reinstall":
		// Reinstall: force clean uninstall→install, skip update routing
		return m, func() tea.Msg {
			return startInstallMsg{tool: m.selectedTool, resume: false, forceReinstall: true}
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

// handleNerdFontInstall handles single font installation/uninstallation
func (m Model) handleNerdFontInstall(msg NerdFontInstallMsg) (tea.Model, tea.Cmd) {
	// Get nerdfonts tool as template for installation
	tool, ok := registry.GetTool("nerdfonts")
	if !ok {
		return m, nil
	}

	// Create a modified copy for single font operation
	singleFontTool := &registry.Tool{
		ID:          "nerdfonts-" + strings.ToLower(msg.FontName),
		DisplayName: "Nerd Font: " + msg.FontName,
		Category:    tool.Category,
		Scripts: registry.ToolScripts{
			Check:     tool.Scripts.Check,
			Install:   tool.Scripts.Install,   // Will be called with font arg
			Uninstall: tool.Scripts.Uninstall, // Will be called with font arg
		},
		FontArg: msg.FontName, // Pass font name as argument
	}

	m.selectedTool = singleFontTool

	switch msg.Action {
	case "install", "reinstall":
		// Create installer for single font
		installer := NewInstallerModelForSingleFont(singleFontTool, m.repoRoot, msg.FontName)
		m.installer = &installer
		m.currentView = ViewInstaller

		initCmd := m.installer.Init()
		startCmd := func() tea.Msg {
			return InstallerStartMsg{Resume: false}
		}
		return m, tea.Batch(initCmd, startCmd)

	case "uninstall":
		// Create uninstaller for single font
		installer := NewInstallerModelForSingleFontUninstall(singleFontTool, m.repoRoot, msg.FontName)
		m.installer = &installer
		m.currentView = ViewInstaller

		initCmd := m.installer.Init()
		startCmd := func() tea.Msg {
			return InstallerStartMsg{Resume: false, Uninstall: true}
		}
		return m, tea.Batch(initCmd, startCmd)
	}

	return m, nil
}
