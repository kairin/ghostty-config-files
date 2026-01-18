// Package registry defines the data-driven tool catalog
package registry

// InstallMethod describes how a tool is installed
type InstallMethod string

const (
	MethodSource        InstallMethod = "source"  // ghostty, feh
	MethodSnap          InstallMethod = "snap"    // ghostty (alternative)
	MethodCharmRepo     InstallMethod = "charm"   // gum, glow, vhs
	MethodAPT           InstallMethod = "apt"     // fastfetch, zsh
	MethodTarball       InstallMethod = "tarball" // go
	MethodScript        InstallMethod = "script"  // python_uv, nodejs (fnm)
	MethodGitHubRelease InstallMethod = "github"  // nerdfonts
	MethodNPM           InstallMethod = "npm"     // ai_tools
)

// Category groups tools in the TUI menu
type Category string

const (
	CategoryMain   Category = "main"
	CategoryExtras Category = "extras"
)

// ToolScripts defines the paths to installation scripts (relative to repo root)
type ToolScripts struct {
	Check       string // scripts/000-check/check_{id}.sh
	Uninstall   string // scripts/001-uninstall/uninstall_{id}.sh
	InstallDeps string // scripts/002-install-first-time/install_deps_{id}.sh
	VerifyDeps  string // scripts/003-verify/verify_deps_{id}.sh
	Install     string // scripts/004-reinstall/install_{id}.sh
	Confirm     string // scripts/005-confirm/confirm_{id}.sh
	Configure   string // scripts/configure_{id}.sh (optional post-installation configuration)
	Update      string // scripts/007-update/update_{id}.sh (in-place update, preserves data)
}

// SubTool represents a component of an aggregate tool (e.g., AI Tools)
type SubTool struct {
	ID      string // e.g., "claude"
	Name    string // e.g., "Claude Code"
	Command string // Command to check existence, e.g., "claude"
}

// BundledTool represents a required dependency installed with the parent tool
// Unlike SubTools (optional components), these are always installed together
type BundledTool struct {
	ID          string // e.g., "fnm"
	Name        string // e.g., "fnm (Fast Node Manager)"
	Description string // e.g., "Cross-platform Node.js version manager"
	VersionCmd  string // e.g., "fnm --version" (for display only)
}

// Tool represents a single installable tool
type Tool struct {
	ID          string        // Unique identifier, e.g., "ghostty"
	DisplayName string        // Human-readable name, e.g., "Ghostty"
	Description string        // Short description
	Category    Category      // main or extras
	Method      InstallMethod // Default installation method

	// Multi-method support (new)
	MethodOverride   InstallMethod   // User-selected method override (runtime only, not persisted here)
	SupportedMethods []InstallMethod // Methods this tool supports (e.g., [MethodSnap, MethodSource])

	// Script paths
	Scripts ToolScripts

	// Version detection
	VersionCmd   []string // Command to get version, e.g., ["ghostty", "--version"]
	VersionRegex string   // Regex to extract version from output

	// Special behaviors
	IsAggregate  bool           // True if this is a multi-tool aggregate (AI Tools)
	SubTools     []SubTool      // Component tools for aggregates
	HasGlobals   bool           // Node.js-specific: track global packages
	BundledTools []BundledTool  // Required dependencies installed with this tool (e.g., fnm for Node.js)

	// Font-specific (for per-family Nerd Font installation)
	FontArg string // Font family name to pass to install script (e.g., "JetBrainsMono")

	// Documentation
	DocsPath string // Path to tool documentation
}

// GetScriptPath returns the script path for a given stage
func (t *Tool) GetScriptPath(stage string) string {
	switch stage {
	case "check":
		return t.Scripts.Check
	case "uninstall":
		return t.Scripts.Uninstall
	case "install_deps":
		return t.Scripts.InstallDeps
	case "verify_deps":
		return t.Scripts.VerifyDeps
	case "install":
		return t.Scripts.Install
	case "confirm":
		return t.Scripts.Confirm
	case "update":
		return t.Scripts.Update
	default:
		return ""
	}
}

// HasUpdateScript returns true if tool has an in-place update script
func (t *Tool) HasUpdateScript() bool {
	return t.Scripts.Update != ""
}

// GetActiveMethod returns the active installation method
// Returns MethodOverride if set, otherwise returns default Method
func (t *Tool) GetActiveMethod() InstallMethod {
	if t.MethodOverride != "" {
		return t.MethodOverride
	}
	return t.Method
}

// SupportsMultipleMethods returns true if this tool supports more than one installation method
func (t *Tool) SupportsMultipleMethods() bool {
	return len(t.SupportedMethods) > 1
}
