// Package registry defines the data-driven tool catalog
package registry

// InstallMethod describes how a tool is installed
type InstallMethod string

const (
	MethodSource        InstallMethod = "source"  // ghostty, feh
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
}

// SubTool represents a component of an aggregate tool (e.g., AI Tools)
type SubTool struct {
	ID      string // e.g., "claude"
	Name    string // e.g., "Claude Code"
	Command string // Command to check existence, e.g., "claude"
}

// Tool represents a single installable tool
type Tool struct {
	ID          string        // Unique identifier, e.g., "ghostty"
	DisplayName string        // Human-readable name, e.g., "Ghostty"
	Description string        // Short description
	Category    Category      // main or extras
	Method      InstallMethod // Installation method

	// Script paths
	Scripts ToolScripts

	// Version detection
	VersionCmd   []string // Command to get version, e.g., ["ghostty", "--version"]
	VersionRegex string   // Regex to extract version from output

	// Special behaviors
	IsAggregate bool      // True if this is a multi-tool aggregate (AI Tools)
	SubTools    []SubTool // Component tools for aggregates
	HasGlobals  bool      // Node.js-specific: track global packages

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
	default:
		return ""
	}
}
