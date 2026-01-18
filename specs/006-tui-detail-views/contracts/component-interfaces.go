// Package contracts defines the interfaces for TUI Detail Views feature
// This file documents the expected API contracts - not compiled code

package contracts

import (
	tea "github.com/charmbracelet/bubbletea"
)

// ToolDetailModel interface - what tooldetail.go must implement
type ToolDetailModel interface {
	// Init returns initial command (spinner tick + status load)
	Init() tea.Cmd

	// Update handles Bubbletea messages, returns updated model and command
	Update(msg tea.Msg) (ToolDetailModel, tea.Cmd)

	// View renders the complete detail view as a string
	View() string

	// HandleKey processes keyboard input, returns command and navigation signal
	HandleKey(msg tea.KeyMsg) (tea.Cmd, bool)

	// Navigation helpers
	IsBackSelected() bool
	GetSelectedAction() string // "install", "reinstall", "uninstall", "configure", "back"
}

// Constructor contract
// NewToolDetailModel(tool *registry.Tool, returnTo View, state *sharedState, cache *cache.StatusCache, repoRoot string) ToolDetailModel

// ExtrasModel changes - remove table, add tool navigation
type ExtrasModelChanges interface {
	// View should render menu-only (no table)
	// Menu order: Fastfetch, Glow, Go, Gum, Python/uv, VHS, ZSH, Install All, Install Claude Config, MCP Servers, Back

	// HandleKey should navigate to ViewToolDetail on tool selection
	// Return tool ID and navigation signal when tool selected

	// GetSelectedExtraTool returns selected tool for navigation
	GetSelectedExtraTool() string // Returns tool ID or empty for non-tool items
}

// Model changes - support ViewToolDetail routing
type ModelChanges interface {
	// Switch to ViewToolDetail:
	// 1. Create ToolDetailModel with selected tool
	// 2. Set currentView = ViewToolDetail
	// 3. Track origin in toolDetailFrom

	// Handle ViewToolDetail back navigation:
	// 1. Check toolDetail.IsBackSelected()
	// 2. Set currentView = toolDetailFrom
	// 3. Clear toolDetail model

	// Menu order for main dashboard:
	// 1. Ghostty (→ ViewToolDetail)
	// 2. Feh (→ ViewToolDetail)
	// 3. Update All (N)
	// 4. Nerd Fonts (→ ViewNerdFonts)
	// 5. Extras (→ ViewExtras)
	// 6. Boot Diagnostics (→ ViewDiagnostics)
	// 7. Exit
}
