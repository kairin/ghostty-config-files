// Package ui - secretswizard.go provides the MCP secrets setup wizard
package ui

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// SecretsWizardModel guides user through setting up MCP secrets
type SecretsWizardModel struct {
	// Step tracking
	step     int                   // Current step (0 = intro, 1+ = secret prompts)
	secrets  []registry.MCPSecret  // Secrets to configure
	values   map[string]string     // EnvVar -> value (entered by user)
	existing map[string]string     // EnvVar -> value (already in file)

	// Input
	input textinput.Model

	// State
	finished bool
	skipped  bool
	err      error

	// Dimensions
	width  int
	height int
}

// NewSecretsWizardModel creates a new secrets wizard
func NewSecretsWizardModel() SecretsWizardModel {
	ti := textinput.New()
	ti.Placeholder = "Enter your API key..."
	ti.CharLimit = 256
	ti.Width = 60
	ti.EchoMode = textinput.EchoPassword // Hide input

	// Gather all required secrets from MCP servers
	allSecrets := collectAllRequiredSecrets()

	// Read existing secrets file
	existing := parseExistingSecrets()

	// Filter to only missing secrets
	missingSecrets := filterMissingSecrets(allSecrets, existing)

	return SecretsWizardModel{
		step:     0, // Start at intro
		secrets:  missingSecrets,
		values:   make(map[string]string),
		existing: existing,
		input:    ti,
	}
}

// collectAllRequiredSecrets gathers all secrets from MCP registry
func collectAllRequiredSecrets() []registry.MCPSecret {
	var allSecrets []registry.MCPSecret
	seen := make(map[string]bool)

	for _, server := range registry.GetAllMCPServers() {
		for _, secret := range server.Secrets {
			if !seen[secret.EnvVar] {
				seen[secret.EnvVar] = true
				allSecrets = append(allSecrets, secret)
			}
		}
	}
	return allSecrets
}

// parseExistingSecrets reads ~/.mcp-secrets and returns existing values
func parseExistingSecrets() map[string]string {
	existing := make(map[string]string)

	home, err := os.UserHomeDir()
	if err != nil {
		return existing
	}

	file, err := os.Open(filepath.Join(home, ".mcp-secrets"))
	if err != nil {
		return existing // File doesn't exist
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Skip comments and empty lines
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Parse: export VAR="value" or export VAR='value' or VAR=value
		line = strings.TrimPrefix(line, "export ")
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])
			// Remove surrounding quotes
			value = strings.Trim(value, "\"'")
			if value != "" {
				existing[key] = value
			}
		}
	}

	return existing
}

// filterMissingSecrets returns secrets that aren't already set
func filterMissingSecrets(all []registry.MCPSecret, existing map[string]string) []registry.MCPSecret {
	var missing []registry.MCPSecret
	for _, secret := range all {
		if _, ok := existing[secret.EnvVar]; !ok {
			// Also check environment
			if os.Getenv(secret.EnvVar) == "" {
				missing = append(missing, secret)
			}
		}
	}
	return missing
}

// Init initializes the wizard
func (m SecretsWizardModel) Init() tea.Cmd {
	return textinput.Blink
}

// Update handles messages
func (m SecretsWizardModel) Update(msg tea.Msg) (SecretsWizardModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		return m.handleKey(msg)
	}

	// Update text input
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

// handleKey processes key presses
func (m SecretsWizardModel) handleKey(msg tea.KeyMsg) (SecretsWizardModel, tea.Cmd) {
	switch msg.String() {
	case "ctrl+c", "q":
		m.finished = true
		m.skipped = true
		return m, nil

	case "esc":
		if m.step == 0 {
			// Exit from intro
			m.finished = true
			m.skipped = true
		} else {
			// Skip current secret
			m.step++
			if m.step > len(m.secrets) {
				m.finished = true
				// Write any values we collected
				if len(m.values) > 0 {
					m.writeSecretsFile()
				}
			} else {
				m.input.SetValue("")
				m.input.Focus()
			}
		}
		return m, nil

	case "enter":
		if m.step == 0 {
			// Move to first secret
			if len(m.secrets) == 0 {
				m.finished = true
			} else {
				m.step = 1
				m.input.Focus()
			}
			return m, textinput.Blink
		}

		// Save current value and move to next
		currentIdx := m.step - 1
		if currentIdx < len(m.secrets) {
			value := strings.TrimSpace(m.input.Value())
			if value != "" {
				m.values[m.secrets[currentIdx].EnvVar] = value
			}
		}

		m.step++
		if m.step > len(m.secrets) {
			m.finished = true
			m.writeSecretsFile()
		} else {
			m.input.SetValue("")
			m.input.Focus()
		}
		return m, textinput.Blink
	}

	// Forward to text input
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

// writeSecretsFile creates or updates ~/.mcp-secrets
func (m *SecretsWizardModel) writeSecretsFile() {
	home, err := os.UserHomeDir()
	if err != nil {
		m.err = err
		return
	}

	secretsPath := filepath.Join(home, ".mcp-secrets")

	// Merge existing with new values
	merged := make(map[string]string)
	for k, v := range m.existing {
		merged[k] = v
	}
	for k, v := range m.values {
		merged[k] = v
	}

	// Write file
	var lines []string
	lines = append(lines, "# MCP Server Secrets")
	lines = append(lines, "# Generated by TUI Secrets Wizard")
	lines = append(lines, "# Source this file: source ~/.mcp-secrets")
	lines = append(lines, "")

	for envVar, value := range merged {
		lines = append(lines, fmt.Sprintf("export %s=\"%s\"", envVar, value))
	}
	lines = append(lines, "")

	content := strings.Join(lines, "\n")
	err = os.WriteFile(secretsPath, []byte(content), 0600) // Restrictive permissions
	if err != nil {
		m.err = err
	}
}

// View renders the wizard
func (m SecretsWizardModel) View() string {
	var b strings.Builder

	// Header
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("135")). // Magenta for MCP
		Bold(true)
	header := headerStyle.Render("MCP Secrets Setup Wizard")
	b.WriteString(header)
	b.WriteString("\n\n")

	// Check if finished
	if m.finished {
		return m.viewFinished()
	}

	// Intro step
	if m.step == 0 {
		return m.viewIntro()
	}

	// Secret input step
	return m.viewSecretInput()
}

// viewIntro renders the introduction screen
func (m SecretsWizardModel) viewIntro() string {
	var b strings.Builder

	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("135")).
		Bold(true)
	b.WriteString(headerStyle.Render("MCP Secrets Setup Wizard"))
	b.WriteString("\n\n")

	if len(m.secrets) == 0 {
		successStyle := lipgloss.NewStyle().Foreground(ColorSuccess)
		b.WriteString(successStyle.Render(IconCheckmark + " All MCP secrets are already configured!"))
		b.WriteString("\n\n")
		b.WriteString("Press Enter to continue.")
	} else {
		b.WriteString("This wizard will help you configure API keys for MCP servers.\n\n")

		b.WriteString(fmt.Sprintf("Secrets to configure: %d\n\n", len(m.secrets)))

		for _, secret := range m.secrets {
			b.WriteString(fmt.Sprintf("  • %s (%s)\n", secret.Name, secret.EnvVar))
		}

		b.WriteString("\n")
		b.WriteString("Your secrets will be saved to ~/.mcp-secrets\n")
		b.WriteString("Source this file in your shell config to make them available.\n")
	}

	// Box with magenta border
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("135")).
		Padding(1, 2)

	content := boxStyle.Render(b.String())

	// Help
	help := HelpStyle.Render("enter start • esc cancel")

	return content + "\n\n" + help
}

// viewSecretInput renders a secret input prompt
func (m SecretsWizardModel) viewSecretInput() string {
	var b strings.Builder

	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("135")).
		Bold(true)
	b.WriteString(headerStyle.Render("MCP Secrets Setup Wizard"))
	b.WriteString("\n\n")

	currentIdx := m.step - 1
	if currentIdx >= len(m.secrets) {
		return m.viewFinished()
	}

	secret := m.secrets[currentIdx]

	// Progress indicator
	progressStyle := lipgloss.NewStyle().Foreground(ColorMuted)
	b.WriteString(progressStyle.Render(fmt.Sprintf("Step %d of %d", m.step, len(m.secrets))))
	b.WriteString("\n\n")

	// Secret name and description
	nameStyle := lipgloss.NewStyle().Bold(true).Foreground(ColorHighlight)
	b.WriteString(nameStyle.Render(secret.Name))
	b.WriteString("\n")
	b.WriteString(secret.Description)
	b.WriteString("\n\n")

	// Show where to get it
	if secret.GetURL != "" {
		urlStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("245"))
		b.WriteString(urlStyle.Render(fmt.Sprintf("Get your key at: %s", secret.GetURL)))
		b.WriteString("\n\n")
	}

	// Environment variable name
	envStyle := lipgloss.NewStyle().Foreground(ColorWarning)
	b.WriteString(fmt.Sprintf("Environment variable: %s\n\n", envStyle.Render(secret.EnvVar)))

	// Input field
	b.WriteString(m.input.View())
	b.WriteString("\n")

	// Box with magenta border
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("135")).
		Padding(1, 2)

	content := boxStyle.Render(b.String())

	// Help
	help := HelpStyle.Render("enter save • esc skip • ctrl+c cancel")

	return content + "\n\n" + help
}

// viewFinished renders the completion screen
func (m SecretsWizardModel) viewFinished() string {
	var b strings.Builder

	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("135")).
		Bold(true)
	b.WriteString(headerStyle.Render("MCP Secrets Setup Wizard"))
	b.WriteString("\n\n")

	if m.skipped {
		warnStyle := lipgloss.NewStyle().Foreground(ColorWarning)
		b.WriteString(warnStyle.Render("Wizard cancelled."))
		b.WriteString("\n")
	} else if m.err != nil {
		errStyle := lipgloss.NewStyle().Foreground(ColorError)
		b.WriteString(errStyle.Render(fmt.Sprintf("Error: %s", m.err.Error())))
		b.WriteString("\n")
	} else if len(m.values) == 0 && len(m.existing) == 0 {
		infoStyle := lipgloss.NewStyle().Foreground(ColorMuted)
		b.WriteString(infoStyle.Render("No secrets were configured."))
		b.WriteString("\n")
	} else {
		successStyle := lipgloss.NewStyle().Foreground(ColorSuccess)
		b.WriteString(successStyle.Render(IconCheckmark + " Secrets saved to ~/.mcp-secrets"))
		b.WriteString("\n\n")

		if len(m.values) > 0 {
			b.WriteString(fmt.Sprintf("Configured %d new secret(s):\n", len(m.values)))
			for envVar := range m.values {
				b.WriteString(fmt.Sprintf("  • %s\n", envVar))
			}
			b.WriteString("\n")
		}

		noteStyle := lipgloss.NewStyle().Foreground(ColorWarning)
		b.WriteString(noteStyle.Render("Important: "))
		b.WriteString("Add this to your shell config:\n")
		b.WriteString("  source ~/.mcp-secrets\n")
	}

	// Box with magenta border
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("135")).
		Padding(1, 2)

	content := boxStyle.Render(b.String())

	// Help
	help := HelpStyle.Render("enter/esc back")

	return content + "\n\n" + help
}

// HandleKey processes key presses for external handling
func (m *SecretsWizardModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	// Check if finished
	if m.finished {
		switch msg.String() {
		case "enter", "esc", "q":
			return nil, true // Signal to go back
		}
	}
	return nil, false
}

// IsFinished returns true if wizard is complete
func (m SecretsWizardModel) IsFinished() bool {
	return m.finished
}
