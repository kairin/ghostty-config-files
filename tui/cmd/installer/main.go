// Ghostty Installer TUI - Go + Bubbletea implementation
package main

import (
	"fmt"
	"os"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/kairin/ghostty-installer/internal/ui"
)

func main() {
	// Determine repo root (parent of tui/)
	execPath, err := os.Executable()
	if err != nil {
		execPath, _ = os.Getwd()
	}

	// If running from tui/cmd/installer, go up 3 levels
	// If running from repo root, use current dir
	repoRoot := findRepoRoot(execPath)
	if repoRoot == "" {
		// Fallback to current directory
		repoRoot, _ = os.Getwd()
	}

	// Check for demo mode flag
	demoMode := false
	for _, arg := range os.Args[1:] {
		if arg == "--demo" || arg == "-d" {
			demoMode = true
		}
	}

	// Create and run the TUI
	m := ui.NewModel(repoRoot, demoMode)
	p := tea.NewProgram(m, tea.WithAltScreen())

	if _, err := p.Run(); err != nil {
		fmt.Printf("Error running program: %v\n", err)
		os.Exit(1)
	}
}

// findRepoRoot locates the repository root by looking for CLAUDE.md
func findRepoRoot(startPath string) string {
	// Start from the directory containing the executable
	dir := filepath.Dir(startPath)

	// Walk up the directory tree
	for i := 0; i < 10; i++ { // Max 10 levels up
		// Check for CLAUDE.md (repo root marker)
		claudeMd := filepath.Join(dir, "CLAUDE.md")
		if _, err := os.Stat(claudeMd); err == nil {
			return dir
		}

		// Check for start.sh (repo root marker)
		startSh := filepath.Join(dir, "start.sh")
		if _, err := os.Stat(startSh); err == nil {
			return dir
		}

		// Go up one level
		parent := filepath.Dir(dir)
		if parent == dir {
			break // Reached filesystem root
		}
		dir = parent
	}

	return ""
}
