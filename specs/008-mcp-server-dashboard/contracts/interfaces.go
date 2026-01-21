// Package contracts defines interfaces for Claude Config Dashboards
// NOTE: This is a design document, not production code.
// Actual implementation will be in tui/internal/

package contracts

import tea "github.com/charmbracelet/bubbletea"

// =============================================================================
// MCP SERVERS INTERFACES
// =============================================================================

// MCPRegistry provides access to available MCP servers
type MCPRegistry interface {
	// All returns all registered MCP servers
	All() []*MCPServer

	// Get returns a server by ID, or nil if not found
	Get(id string) *MCPServer

	// Count returns total number of registered servers
	Count() int
}

// ClaudeConfig provides read/write access to ~/.claude.json
type ClaudeConfig interface {
	// Load reads and parses the config file
	// Creates empty config if file doesn't exist
	Load() error

	// GetMCPServers returns all configured MCP servers
	GetMCPServers() map[string]*ServerConfig

	// HasServer checks if a server is configured
	HasServer(id string) bool

	// AddServer adds or updates a server configuration
	AddServer(id string, config *ServerConfig) error

	// RemoveServer removes a server configuration
	RemoveServer(id string) error

	// Save writes the config back to file atomically
	Save() error
}

// MCPInstaller handles MCP server installation workflow
type MCPInstaller interface {
	// Install adds a server to the config
	// Prompts for prerequisites if needed
	Install(server *MCPServer) error

	// Remove removes a server from the config
	Remove(serverID string) error

	// GetStatus returns the current status of a server
	GetStatus(serverID string) MCPServerStatus
}

// =============================================================================
// SKILLS DASHBOARD INTERFACES
// =============================================================================

// SkillsRegistry provides access to available skills and agents
type SkillsRegistry interface {
	// LoadAll scans source directories and returns all items
	LoadAll(projectRoot string) ([]SkillItem, error)

	// GetSkills returns only skills
	GetSkills() []SkillItem

	// GetAgents returns only agents
	GetAgents() []SkillItem

	// Get returns an item by ID, or nil if not found
	Get(id string) *SkillItem

	// SkillCount returns number of skills
	SkillCount() int

	// AgentCount returns number of agents
	AgentCount() int
}

// SkillsManager handles skills/agents installation
type SkillsManager interface {
	// Install copies a skill/agent to user directory
	Install(item *SkillItem) error

	// Remove deletes a skill/agent from user directory
	Remove(item *SkillItem) error

	// Update reinstalls a skill/agent (copy from source)
	Update(item *SkillItem) error

	// InstallAll installs all skills and agents
	InstallAll(items []SkillItem) (installed int, failed int, err error)

	// GetStatus computes current status of an item
	GetStatus(item *SkillItem) ItemStatus

	// RefreshStatus updates status for all items
	RefreshStatus(items []SkillItem) []SkillItem
}

// =============================================================================
// TUI VIEW INTERFACES
// =============================================================================

// MCPView defines the MCP dashboard TUI view
type MCPView interface {
	// Init initializes the view
	Init() tea.Cmd

	// Update handles messages/events
	Update(msg tea.Msg) (tea.Model, tea.Cmd)

	// View renders the current state
	View() string
}

// SkillsView defines the Skills dashboard TUI view
type SkillsView interface {
	// Init initializes the view
	Init() tea.Cmd

	// Update handles messages/events
	Update(msg tea.Msg) (tea.Model, tea.Cmd)

	// View renders the current state
	View() string
}
