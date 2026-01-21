// Package contracts defines types for MCP Server Dashboard
// NOTE: This is a design document, not production code.
// Actual implementation will be in tui/internal/

package contracts

// TransportType represents MCP transport protocol
type TransportType string

const (
	TransportStdio TransportType = "stdio"
	TransportHTTP  TransportType = "http"
)

// PrerequisiteType represents how to obtain a prerequisite value
type PrerequisiteType string

const (
	PrereqAPIKey PrerequisiteType = "api_key" // User provides API key
	PrereqPath   PrerequisiteType = "path"    // User provides file path
	PrereqAuto   PrerequisiteType = "auto"    // Auto-detect from system
)

// ServerStatus represents runtime status of an MCP server
type ServerStatus string

const (
	StatusConnected ServerStatus = "Connected" // In config, valid
	StatusNotAdded  ServerStatus = "Not Added" // Not in config
	StatusError     ServerStatus = "Error"     // In config, invalid
)

// Prerequisite defines a required input for server installation
type Prerequisite struct {
	Key         string           // Env var or config key
	Label       string           // Human-readable prompt
	Type        PrerequisiteType // How to obtain value
	AutoCommand string           // Command for auto-detect (optional)
	Required    bool             // Is this mandatory?
}

// ServerConfig matches Claude's mcpServers JSON structure
type ServerConfig struct {
	Type    string            `json:"type"`              // "stdio" or "http"
	Command string            `json:"command,omitempty"` // For stdio
	Args    []string          `json:"args,omitempty"`    // For stdio
	Env     map[string]string `json:"env,omitempty"`     // Environment vars
	URL     string            `json:"url,omitempty"`     // For http
}

// MCPServer represents a server in the registry
type MCPServer struct {
	ID             string         // Unique identifier
	DisplayName    string         // Human-readable name
	Description    string         // Short description
	Transport      TransportType  // stdio or http
	Prerequisites  []Prerequisite // Required inputs
	ConfigTemplate ServerConfig   // Default config template
}

// MCPServerState combines registry + runtime state for display
type MCPServerState struct {
	Server *MCPServer    // Registry definition
	Status ServerStatus  // Current status
	Config *ServerConfig // Current config (if installed)
}

// =============================================================================
// SKILLS DASHBOARD TYPES
// =============================================================================

// ItemType distinguishes skills from agents
type ItemType string

const (
	ItemTypeSkill ItemType = "skill" // Claude Code slash command
	ItemTypeAgent ItemType = "agent" // Claude Code agent definition
)

// ItemStatus represents installation state of a skill/agent
type ItemStatus string

const (
	ItemInstalled    ItemStatus = "Installed"     // File exists, matches source
	ItemNotInstalled ItemStatus = "Not Installed" // File only in project source
	ItemOutdated     ItemStatus = "Outdated"      // User file older than source
	ItemModified     ItemStatus = "Modified"      // User file newer than source
	ItemError        ItemStatus = "Error"         // File unreadable/corrupted
)

// SkillItem represents a skill or agent for the dashboard
type SkillItem struct {
	ID          string     // Unique identifier (filename without .md)
	DisplayName string     // Human-readable name
	Description string     // First line of markdown file
	Type        ItemType   // "skill" or "agent"
	Tier        string     // Agent tier (001, 002, etc.) - empty for skills
	SourcePath  string     // Path in project
	TargetPath  string     // Install path in user directory
	Status      ItemStatus // Current installation status
}
