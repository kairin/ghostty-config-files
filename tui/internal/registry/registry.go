// Package registry provides the data-driven tool catalog
package registry

import "fmt"

// tools is the internal map of all tools
var tools = map[string]*Tool{
	// === MAIN TOOLS ===
	"feh": {
		ID:          "feh",
		DisplayName: "Feh",
		Description: "Lightweight image viewer",
		Category:    CategoryMain,
		Method:      MethodSource,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_feh.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_feh.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_feh.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_feh.sh",
			Install:     "scripts/004-reinstall/install_feh.sh",
			Confirm:     "scripts/005-confirm/confirm_feh.sh",
		},
		VersionCmd:   []string{"feh", "--version"},
		VersionRegex: `feh version (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/feh.md",
	},
	"ghostty": {
		ID:               "ghostty",
		DisplayName:      "Ghostty",
		Description:      "GPU-accelerated terminal emulator",
		Category:         CategoryMain,
		Method:           MethodSource,
		SupportedMethods: []InstallMethod{MethodSnap, MethodSource}, // Supports both snap and source builds
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_ghostty.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_ghostty.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_ghostty.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_ghostty.sh",
			Install:     "scripts/004-reinstall/install_ghostty.sh",
			Confirm:     "scripts/005-confirm/confirm_ghostty.sh",
		},
		VersionCmd:   []string{"ghostty", "--version"},
		VersionRegex: `Ghostty (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/ghostty.md",
	},
	"nerdfonts": {
		ID:          "nerdfonts",
		DisplayName: "Nerd Fonts",
		Description: "Developer fonts (8 families)",
		Category:    CategoryMain,
		Method:      MethodGitHubRelease,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_nerdfonts.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_nerdfonts.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_nerdfonts.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_nerdfonts.sh",
			Install:     "scripts/004-reinstall/install_nerdfonts.sh",
			Confirm:     "scripts/005-confirm/confirm_nerdfonts.sh",
		},
		VersionCmd:   []string{}, // Uses script-based detection
		VersionRegex: `v(\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/nerdfonts.md",
	},
	"nodejs": {
		ID:          "nodejs",
		DisplayName: "Node.js",
		Description: "JavaScript runtime via fnm",
		Category:    CategoryMain,
		Method:      MethodScript,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_nodejs.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_nodejs.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_nodejs.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_nodejs.sh",
			Install:     "scripts/004-reinstall/install_nodejs.sh",
			Confirm:     "scripts/005-confirm/confirm_nodejs.sh",
		},
		VersionCmd:   []string{"node", "--version"},
		VersionRegex: `v(\d+\.\d+\.\d+)`,
		HasGlobals:   true,
		DocsPath:     ".claude/instructions-for-agents/tools/nodejs.md",
	},
	"ai_tools": {
		ID:          "ai_tools",
		DisplayName: "Local AI Tools",
		Description: "Claude Code, Gemini CLI, Copilot",
		Category:    CategoryMain,
		Method:      MethodNPM,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_ai_tools.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_ai_tools.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_ai_tools.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_ai_tools.sh",
			Install:     "scripts/004-reinstall/install_ai_tools.sh",
			Confirm:     "scripts/005-confirm/confirm_ai_tools.sh",
		},
		IsAggregate: true,
		SubTools: []SubTool{
			{ID: "claude", Name: "Claude Code", Command: "claude"},
			{ID: "gemini", Name: "Gemini CLI", Command: "gemini"},
			{ID: "copilot", Name: "GitHub Copilot", Command: "gh copilot"},
		},
		DocsPath: ".claude/instructions-for-agents/tools/ai-cli-tools.md",
	},
	"antigravity": {
		ID:          "antigravity",
		DisplayName: "Google Antigravity",
		Description: "Agentic development platform",
		Category:    CategoryMain,
		Method:      MethodScript,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_antigravity.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_antigravity.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_antigravity.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_antigravity.sh",
			Install:     "scripts/004-reinstall/install_antigravity.sh",
			Confirm:     "scripts/005-confirm/confirm_antigravity.sh",
		},
		VersionCmd:   []string{"antigravity", "--version"},
		VersionRegex: `(\d+\.\d+\.\d+)`,
	},

	// === EXTRAS TOOLS ===
	"fastfetch": {
		ID:          "fastfetch",
		DisplayName: "Fastfetch",
		Description: "System info fetcher",
		Category:    CategoryExtras,
		Method:      MethodAPT,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_fastfetch.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_fastfetch.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_fastfetch.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_fastfetch.sh",
			Install:     "scripts/004-reinstall/install_fastfetch.sh",
			Confirm:     "scripts/005-confirm/confirm_fastfetch.sh",
		},
		VersionCmd:   []string{"fastfetch", "--version"},
		VersionRegex: `fastfetch (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/fastfetch.md",
	},
	"glow": {
		ID:          "glow",
		DisplayName: "Glow",
		Description: "Terminal markdown renderer",
		Category:    CategoryExtras,
		Method:      MethodCharmRepo,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_glow.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_glow.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_glow.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_glow.sh",
			Install:     "scripts/004-reinstall/install_glow.sh",
			Confirm:     "scripts/005-confirm/confirm_glow.sh",
		},
		VersionCmd:   []string{"glow", "--version"},
		VersionRegex: `glow version (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/glow.md",
	},
	"go": {
		ID:          "go",
		DisplayName: "Go",
		Description: "Go programming language",
		Category:    CategoryExtras,
		Method:      MethodTarball,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_go.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_go.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_go.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_go.sh",
			Install:     "scripts/004-reinstall/install_go.sh",
			Confirm:     "scripts/005-confirm/confirm_go.sh",
		},
		VersionCmd:   []string{"go", "version"},
		VersionRegex: `go(\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/go.md",
	},
	"gum": {
		ID:          "gum",
		DisplayName: "Gum",
		Description: "TUI component library",
		Category:    CategoryExtras,
		Method:      MethodCharmRepo,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_gum.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_gum.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_gum.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_gum.sh",
			Install:     "scripts/004-reinstall/install_gum.sh",
			Confirm:     "scripts/005-confirm/confirm_gum.sh",
		},
		VersionCmd:   []string{"gum", "--version"},
		VersionRegex: `gum version (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/gum.md",
	},
	"python_uv": {
		ID:          "python_uv",
		DisplayName: "Python/uv",
		Description: "Fast Python package manager",
		Category:    CategoryExtras,
		Method:      MethodScript,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_python_uv.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_python_uv.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_python_uv.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_python_uv.sh",
			Install:     "scripts/004-reinstall/install_python_uv.sh",
			Confirm:     "scripts/005-confirm/confirm_python_uv.sh",
		},
		VersionCmd:   []string{"uv", "--version"},
		VersionRegex: `uv (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/python-uv.md",
	},
	"vhs": {
		ID:          "vhs",
		DisplayName: "VHS",
		Description: "Terminal recording/GIF",
		Category:    CategoryExtras,
		Method:      MethodCharmRepo,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_vhs.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_vhs.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_vhs.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_vhs.sh",
			Install:     "scripts/004-reinstall/install_vhs.sh",
			Confirm:     "scripts/005-confirm/confirm_vhs.sh",
		},
		VersionCmd:   []string{"vhs", "--version"},
		VersionRegex: `vhs version (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/vhs.md",
	},
	"zsh": {
		ID:          "zsh",
		DisplayName: "ZSH + Plugins",
		Description: "ZSH + Oh My Zsh + Powerlevel10k + plugins",
		Category:    CategoryExtras,
		Method:      MethodAPT,
		Scripts: ToolScripts{
			Check:       "scripts/000-check/check_zsh.sh",
			Uninstall:   "scripts/001-uninstall/uninstall_zsh.sh",
			InstallDeps: "scripts/002-install-first-time/install_deps_zsh.sh",
			VerifyDeps:  "scripts/003-verify/verify_deps_zsh.sh",
			Install:     "scripts/004-reinstall/install_zsh.sh",
			Confirm:     "scripts/005-confirm/confirm_zsh.sh",
			Configure:   "scripts/004-reinstall/configure_zsh.sh",
		},
		VersionCmd:   []string{"zsh", "--version"},
		VersionRegex: `zsh (\d+\.\d+\.\d+)`,
		DocsPath:     ".claude/instructions-for-agents/tools/zsh.md",
	},
}

// Ordered lists for display
var mainToolIDs = []string{"feh", "ghostty", "nerdfonts", "nodejs", "ai_tools", "antigravity"}
var extrasToolIDs = []string{"fastfetch", "glow", "go", "gum", "python_uv", "vhs", "zsh"}

// GetTool returns a tool by ID
func GetTool(id string) (*Tool, bool) {
	t, ok := tools[id]
	return t, ok
}

// GetMainTools returns main tools in display order
func GetMainTools() []*Tool {
	return getToolsInOrder(mainToolIDs)
}

// GetExtrasTools returns extras tools in display order
func GetExtrasTools() []*Tool {
	return getToolsInOrder(extrasToolIDs)
}

// GetAllTools returns all tools
func GetAllTools() []*Tool {
	all := make([]*Tool, 0, len(tools))
	for _, t := range tools {
		all = append(all, t)
	}
	return all
}

// getToolsInOrder returns tools in the specified ID order
func getToolsInOrder(ids []string) []*Tool {
	result := make([]*Tool, 0, len(ids))
	for _, id := range ids {
		if t, ok := tools[id]; ok {
			result = append(result, t)
		}
	}
	return result
}

// MainToolCount returns the number of main tools
func MainToolCount() int {
	return len(mainToolIDs)
}

// ExtrasToolCount returns the number of extras tools
func ExtrasToolCount() int {
	return len(extrasToolIDs)
}

// String returns a human-readable representation of the tool
func (t *Tool) String() string {
	return fmt.Sprintf("%s (%s)", t.DisplayName, t.Method)
}
