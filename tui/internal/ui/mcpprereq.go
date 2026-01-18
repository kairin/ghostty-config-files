// Package ui - mcpprereq.go provides the MCP prerequisites failure view
package ui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// MCPPrereqModel displays prerequisite/secret check results for an MCP server
type MCPPrereqModel struct {
	// Server being checked
	server *registry.MCPServer

	// Check results
	prereqResults []registry.PrerequisiteResult
	secretResults []registry.SecretResult

	// Navigation
	cursor int

	// Dimensions
	width  int
	height int
}

// NewMCPPrereqModel creates a new prerequisites view for a server
func NewMCPPrereqModel(server *registry.MCPServer) MCPPrereqModel {
	return MCPPrereqModel{
		server:        server,
		prereqResults: server.CheckAllPrerequisites(),
		secretResults: server.CheckSecrets(),
		cursor:        0,
	}
}

// Init initializes the model
func (m MCPPrereqModel) Init() tea.Cmd {
	return nil
}

// Update handles messages
func (m MCPPrereqModel) Update(msg tea.Msg) (MCPPrereqModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}
	return m, nil
}

// View renders the prerequisites check results
func (m MCPPrereqModel) View() string {
	var b strings.Builder

	// Header (magenta styling for MCP)
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("135")). // Magenta for MCP
		Bold(true)
	header := headerStyle.Render(fmt.Sprintf("Prerequisites for %s", m.server.DisplayName))
	b.WriteString(header)
	b.WriteString("\n\n")

	// Check if there are any failures
	hasFailures := false
	for _, r := range m.prereqResults {
		if !r.Passed {
			hasFailures = true
			break
		}
	}
	for _, r := range m.secretResults {
		if r.Secret.Required && !r.Present {
			hasFailures = true
			break
		}
	}

	if !hasFailures {
		// All prerequisites passed
		successStyle := lipgloss.NewStyle().Foreground(ColorSuccess)
		b.WriteString(successStyle.Render(IconCheckmark + " All prerequisites met!"))
		b.WriteString("\n\n")
	} else {
		// Show what's missing
		warningStyle := lipgloss.NewStyle().Foreground(ColorWarning)
		b.WriteString(warningStyle.Render("⚠ Some prerequisites are missing:"))
		b.WriteString("\n\n")
	}

	// Prerequisites section
	if len(m.prereqResults) > 0 {
		b.WriteString(SectionHeaderStyle.Render("Prerequisites:"))
		b.WriteString("\n")

		for _, result := range m.prereqResults {
			var icon string
			var style lipgloss.Style

			if result.Passed {
				icon = IconCheckmark
				style = StatusInstalledStyle
			} else {
				icon = IconCross
				style = StatusMissingStyle
			}

			line := fmt.Sprintf("  %s %s", icon, result.Prerequisite.Name)
			b.WriteString(style.Render(line))
			b.WriteString("\n")

			// Show fix instructions if failed
			if !result.Passed && result.FixInstructions != "" {
				fixStyle := lipgloss.NewStyle().
					Foreground(lipgloss.Color("245")). // Dim gray
					Italic(true)
				b.WriteString(fixStyle.Render(fmt.Sprintf("     → %s", result.FixInstructions)))
				b.WriteString("\n")
			}
		}
		b.WriteString("\n")
	}

	// Secrets section
	if len(m.secretResults) > 0 {
		b.WriteString(SectionHeaderStyle.Render("Required Secrets:"))
		b.WriteString("\n")

		for _, result := range m.secretResults {
			var icon string
			var style lipgloss.Style

			if result.Present {
				icon = IconCheckmark
				style = StatusInstalledStyle
			} else if !result.Secret.Required {
				icon = "○"
				style = StatusUnknownStyle
			} else {
				icon = IconCross
				style = StatusMissingStyle
			}

			requiredLabel := ""
			if result.Secret.Required {
				requiredLabel = " (required)"
			}

			line := fmt.Sprintf("  %s %s%s", icon, result.Secret.Name, requiredLabel)
			b.WriteString(style.Render(line))
			b.WriteString("\n")

			// Show how to get the secret if missing
			if !result.Present && result.Secret.GetURL != "" {
				fixStyle := lipgloss.NewStyle().
					Foreground(lipgloss.Color("245")).
					Italic(true)
				b.WriteString(fixStyle.Render(fmt.Sprintf("     → Get from: %s", result.Secret.GetURL)))
				b.WriteString("\n")
				b.WriteString(fixStyle.Render(fmt.Sprintf("     → Set: export %s=your-key", result.Secret.EnvVar)))
				b.WriteString("\n")
			}
		}
		b.WriteString("\n")
	}

	// Box with magenta border
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("135")).
		Padding(1, 2)

	content := boxStyle.Render(b.String())

	// Menu
	var menuBuilder strings.Builder
	menuBuilder.WriteString("\n")

	menuItems := []string{"Back"}
	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.cursor == i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		menuBuilder.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	// Help
	help := HelpStyle.Render("enter back • esc back")

	return content + menuBuilder.String() + "\n" + help
}

// HandleKey processes key presses
func (m *MCPPrereqModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	switch msg.String() {
	case "enter", "esc", "q":
		return nil, true // Signal to go back
	}
	return nil, false
}

// HasFailures returns true if any prerequisites or required secrets are missing
func (m MCPPrereqModel) HasFailures() bool {
	for _, r := range m.prereqResults {
		if !r.Passed {
			return true
		}
	}
	for _, r := range m.secretResults {
		if r.Secret.Required && !r.Present {
			return true
		}
	}
	return false
}

// GetServer returns the server being checked
func (m MCPPrereqModel) GetServer() *registry.MCPServer {
	return m.server
}
