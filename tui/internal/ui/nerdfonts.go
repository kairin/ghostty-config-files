// Package ui - nerdfonts.go provides the Nerd Fonts management view with per-family control
package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/cache"
	"github.com/kairin/ghostty-installer/internal/executor"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// FontFamily represents a single Nerd Font family
type FontFamily struct {
	ID          string // "jetbrainsmono", "firacode", etc.
	DisplayName string // "JetBrainsMono", "FiraCode", etc.
	Status      string // "Installed", "Missing"
	Version     string // Font version if available
}

// NerdFontsModel manages the Nerd Fonts management view
type NerdFontsModel struct {
	// Tool selection
	cursor int
	fonts  []FontFamily

	// Parent tool
	tool *registry.Tool

	// State
	loading bool

	// Action menu state (for individual font selection)
	menuMode     bool     // true when showing action menu for a font
	actionItems  []string // ["Install", "Reinstall", "Uninstall", "Back"]
	actionCursor int      // cursor within action menu
	selectedFont *FontFamily // font being acted upon

	// Shared state (statuses and loading flags from parent)
	state *sharedState

	// Components
	spinner spinner.Model

	// Dimensions
	width  int
	height int

	// Cache and repo root for status checks
	cache    *cache.StatusCache
	repoRoot string
}

// NewNerdFontsModel creates a new Nerd Fonts model
func NewNerdFontsModel(state *sharedState, c *cache.StatusCache, repoRoot string) NerdFontsModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = SpinnerStyle

	// Initialize 8 font families (before registry check so we can use fonts in early return)
	fonts := []FontFamily{
		{ID: "jetbrainsmono", DisplayName: "JetBrainsMono", Status: "Loading...", Version: "-"},
		{ID: "firacode", DisplayName: "FiraCode", Status: "Loading...", Version: "-"},
		{ID: "hack", DisplayName: "Hack", Status: "Loading...", Version: "-"},
		{ID: "meslo", DisplayName: "Meslo", Status: "Loading...", Version: "-"},
		{ID: "cascadiacode", DisplayName: "CascadiaCode", Status: "Loading...", Version: "-"},
		{ID: "sourcecodepro", DisplayName: "SourceCodePro", Status: "Loading...", Version: "-"},
		{ID: "ibmplexmono", DisplayName: "IBMPlexMono", Status: "Loading...", Version: "-"},
		{ID: "iosevka", DisplayName: "Iosevka", Status: "Loading...", Version: "-"},
	}

	// Fetch nerdfonts tool from registry
	tool, ok := registry.GetTool("nerdfonts")
	if !ok || tool == nil {
		// Return model without tool - installation will be disabled
		return NerdFontsModel{
			cursor:   0,
			fonts:    fonts,
			tool:     nil,
			state:    state,
			spinner:  s,
			loading:  false, // Don't show loading if no tool available
			cache:    c,
			repoRoot: repoRoot,
		}
	}

	return NerdFontsModel{
		cursor:   0,
		fonts:    fonts,
		tool:     tool,
		state:    state,
		spinner:  s,
		loading:  true,
		cache:    c,
		repoRoot: repoRoot,
	}
}

// Init initializes the Nerd Fonts model
func (m NerdFontsModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		m.refreshNerdFontsStatus(),
	)
}

// refreshNerdFontsStatus returns a command that checks Nerd Fonts status
func (m NerdFontsModel) refreshNerdFontsStatus() tea.Cmd {
	// Check cache first
	if status, ok := m.cache.Get("nerdfonts"); ok {
		return func() tea.Msg {
			return nerdfontsStatusLoadedMsg{status: status}
		}
	}

	// Run check script
	repoRoot := m.repoRoot
	c := m.cache

	return func() tea.Msg {
		output, err := executor.RunCheck(repoRoot, "scripts/000-check/check_nerdfonts.sh")
		if err != nil {
			return nerdfontsStatusLoadedMsg{
				status: &cache.ToolStatus{ID: "nerdfonts", Status: "Unknown"},
			}
		}

		status := cache.ParseCheckOutput("nerdfonts", output)
		c.Set(status)

		return nerdfontsStatusLoadedMsg{status: status}
	}
}

// Nerd Fonts-specific messages
type (
	nerdfontsStatusLoadedMsg struct {
		status *cache.ToolStatus
	}
)

// Update handles messages for the Nerd Fonts model
func (m NerdFontsModel) Update(msg tea.Msg) (NerdFontsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd

	case nerdfontsStatusLoadedMsg:
		// Parse font status from Details field
		if msg.status != nil && len(msg.status.Details) > 0 {
			m.parseFontStatuses(msg.status)
		}
		m.loading = false
		return m, nil
	}

	return m, nil
}

// parseFontStatuses extracts individual font family status from the check output
func (m *NerdFontsModel) parseFontStatuses(status *cache.ToolStatus) {
	// Details format from check script: "   ✓ JetBrainsMono" or "   ✗ JetBrainsMono"
	for _, detail := range status.Details {
		trimmed := strings.TrimSpace(detail)
		if trimmed == "" || !strings.Contains(trimmed, "✓") && !strings.Contains(trimmed, "✗") {
			continue
		}

		// Parse status
		isInstalled := strings.Contains(trimmed, "✓")
		fontName := strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(trimmed, "✓"), "✗"))

		// Update font in our list
		for i := range m.fonts {
			if m.fonts[i].DisplayName == fontName {
				if isInstalled {
					m.fonts[i].Status = "Installed"
					m.fonts[i].Version = status.Version
				} else {
					m.fonts[i].Status = "Missing"
					m.fonts[i].Version = "-"
				}
				break
			}
		}
	}
}

// View renders the Nerd Fonts management dashboard
func (m NerdFontsModel) View() string {
	var b strings.Builder

	// Header (compact single line with purple styling for fonts)
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("141")). // Purple for fonts
		Bold(true)
	header := headerStyle.Render("Nerd Fonts Management • 8 Font Families")
	b.WriteString(header)
	b.WriteString("\n\n")

	// Status table
	b.WriteString(m.renderFontsTable())
	b.WriteString("\n")

	// Show action menu if in menu mode, otherwise show main menu
	if m.menuMode && m.selectedFont != nil {
		b.WriteString(m.renderActionMenu())
	} else {
		b.WriteString(m.renderNerdFontsMenu())
	}
	b.WriteString("\n")

	// Help
	var helpText string
	if m.menuMode {
		helpText = "↑↓ navigate • enter select • esc cancel"
	} else {
		helpText = "↑↓ navigate • enter select • r refresh • esc back"
	}
	help := HelpStyle.Render(helpText)
	b.WriteString(help)

	return b.String()
}

// renderFontsTable renders the fonts status table
func (m NerdFontsModel) renderFontsTable() string {
	var b strings.Builder

	// Column widths
	colFont := 20
	colStatus := 14
	colVersion := 26
	colLocation := 40

	// Header
	headerLine := fmt.Sprintf("%-*s %-*s %-*s %-*s",
		colFont, "FONT FAMILY",
		colStatus, "STATUS",
		colVersion, "VERSION",
		colLocation, "LOCATION",
	)
	b.WriteString(TableHeaderStyle.Render(headerLine))
	b.WriteString("\n")

	// Separator
	sep := strings.Repeat("─", colFont+colStatus+colVersion+colLocation+3)
	b.WriteString(lipgloss.NewStyle().Foreground(ColorMuted).Render(sep))
	b.WriteString("\n")

	// Font families
	for i, font := range m.fonts {
		// Determine status display
		var statusStr, versionStr, locationStr string
		var statusStyle lipgloss.Style

		if m.loading {
			statusStr = m.spinner.View() + " Loading"
			statusStyle = StatusUnknownStyle
			versionStr = "-"
			locationStr = "-"
		} else {
			if font.Status == "Installed" {
				statusStr = IconCheckmark + " Installed"
				statusStyle = StatusInstalledStyle
				versionStr = font.Version
				locationStr = fmt.Sprintf("~/.local/share/fonts/%s", font.DisplayName)
			} else {
				statusStr = IconCross + " Missing"
				statusStyle = StatusMissingStyle
				versionStr = "-"
				locationStr = "-"
			}
		}

		// Format row
		rowStyle := TableRowStyle
		if i == m.cursor && m.cursor < len(m.fonts) {
			rowStyle = TableSelectedStyle
		}

		row := fmt.Sprintf("%-*s %s%-*s %-*s %-*s",
			colFont, font.DisplayName,
			"",
			colStatus-1, statusStyle.Render(statusStr),
			colVersion, versionStr,
			colLocation, locationStr,
		)
		b.WriteString(rowStyle.Render(row))
		b.WriteString("\n")
	}

	// Box with purple border for fonts
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("141")). // Purple
		Padding(1, 2)

	return boxStyle.Render(b.String())
}

// renderNerdFontsMenu renders the Nerd Fonts menu options
func (m NerdFontsModel) renderNerdFontsMenu() string {
	var b strings.Builder

	fontCount := len(m.fonts)

	// Menu items: Individual fonts (0-7) + "Install All" (8) + "Back" (9)
	menuItems := []string{}

	// Calculate if any fonts are missing for "Install All" option
	missingCount := 0
	for _, font := range m.fonts {
		if font.Status != "Installed" {
			missingCount++
		}
	}

	// Show "Install All" only if some fonts are missing
	if missingCount > 0 && !m.loading {
		menuItems = append(menuItems, fmt.Sprintf("Install All (%d missing)", missingCount))
	}
	menuItems = append(menuItems, "Back")

	b.WriteString("\nChoose:\n")

	// Render menu items (Install All + Back)
	menuStartIndex := fontCount
	for i, item := range menuItems {
		cursor := " "
		style := MenuItemStyle
		if m.cursor == menuStartIndex+i {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	return b.String()
}

// renderActionMenu renders the action menu for a selected font
func (m NerdFontsModel) renderActionMenu() string {
	var b strings.Builder

	// Show which font is selected
	fontStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("141")). // Purple
		Bold(true)
	b.WriteString(fmt.Sprintf("\nActions for %s:\n", fontStyle.Render(m.selectedFont.DisplayName)))

	// Render action items
	for i, item := range m.actionItems {
		cursor := " "
		style := MenuItemStyle
		if i == m.actionCursor {
			cursor = ">"
			style = MenuSelectedStyle
		}
		b.WriteString(fmt.Sprintf("%s %s\n", MenuCursorStyle.Render(cursor), style.Render(item)))
	}

	return b.String()
}

// HandleKey processes key presses in Nerd Fonts view
func (m *NerdFontsModel) HandleKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	// Handle action menu mode separately
	if m.menuMode {
		return m.handleActionMenuKey(msg)
	}

	// Calculate menu boundaries
	fontCount := len(m.fonts)
	missingCount := 0
	for _, font := range m.fonts {
		if font.Status != "Installed" {
			missingCount++
		}
	}

	// Menu item count: Install All (conditional) + Back
	menuItemCount := 1 // Back
	if missingCount > 0 && !m.loading {
		menuItemCount++ // Install All
	}

	maxCursor := fontCount + menuItemCount - 1

	switch msg.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		} else {
			m.cursor = maxCursor // Wrap to bottom
		}
		return nil, false

	case "down", "j":
		if m.cursor < maxCursor {
			m.cursor++
		} else {
			m.cursor = 0 // Wrap to top
		}
		return nil, false

	case "r":
		// Refresh status
		m.loading = true
		m.cache.Invalidate("nerdfonts")
		return tea.Batch(
			m.spinner.Tick,
			m.refreshNerdFontsStatus(),
		), false

	case "enter":
		// Handle selection
		if m.cursor < fontCount {
			// Selected a font family - show action menu
			m.showActionMenu(&m.fonts[m.cursor])
			return nil, false
		} else {
			// Menu item selected (Install All or Back)
			return nil, true
		}
	}

	return nil, false
}

// showActionMenu prepares and displays the action menu for a font
func (m *NerdFontsModel) showActionMenu(font *FontFamily) {
	m.selectedFont = font
	m.menuMode = true
	m.actionCursor = 0

	// Build action items based on font status
	if font.Status == "Installed" {
		m.actionItems = []string{"Reinstall", "Uninstall", "Back"}
	} else {
		m.actionItems = []string{"Install", "Back"}
	}
}

// handleActionMenuKey processes key presses when in action menu mode
func (m *NerdFontsModel) handleActionMenuKey(msg tea.KeyMsg) (tea.Cmd, bool) {
	switch msg.String() {
	case "up", "k":
		if m.actionCursor > 0 {
			m.actionCursor--
		} else {
			m.actionCursor = len(m.actionItems) - 1 // Wrap to bottom
		}
		return nil, false

	case "down", "j":
		if m.actionCursor < len(m.actionItems)-1 {
			m.actionCursor++
		} else {
			m.actionCursor = 0 // Wrap to top
		}
		return nil, false

	case "esc":
		// Cancel action menu
		m.menuMode = false
		m.selectedFont = nil
		m.actionItems = nil
		m.actionCursor = 0
		return nil, false

	case "enter":
		// Execute selected action
		if m.actionCursor < len(m.actionItems) {
			action := m.actionItems[m.actionCursor]
			switch action {
			case "Install", "Reinstall":
				// Return command to install single font
				cmd := m.installSingleFont(m.selectedFont.DisplayName)
				m.menuMode = false
				m.selectedFont = nil
				m.actionItems = nil
				m.actionCursor = 0
				return cmd, false
			case "Uninstall":
				// Return command to uninstall font
				cmd := m.uninstallSingleFont(m.selectedFont.DisplayName)
				m.menuMode = false
				m.selectedFont = nil
				m.actionItems = nil
				m.actionCursor = 0
				return cmd, false
			case "Back":
				m.menuMode = false
				m.selectedFont = nil
				m.actionItems = nil
				m.actionCursor = 0
				return nil, false
			}
		}
	}

	return nil, false
}

// GetSelectedFont returns the currently selected font, or nil for menu items
func (m NerdFontsModel) GetSelectedFont() *FontFamily {
	if m.cursor < len(m.fonts) {
		return &m.fonts[m.cursor]
	}
	return nil
}

// IsInstallAllSelected returns true if "Install All" is selected
func (m NerdFontsModel) IsInstallAllSelected() bool {
	fontCount := len(m.fonts)
	missingCount := 0
	for _, font := range m.fonts {
		if font.Status != "Installed" {
			missingCount++
		}
	}

	// Install All is at index fontCount if it's shown
	if missingCount > 0 && !m.loading {
		return m.cursor == fontCount
	}
	return false
}

// IsBackSelected returns true if "Back" is selected
func (m NerdFontsModel) IsBackSelected() bool {
	fontCount := len(m.fonts)
	missingCount := 0
	for _, font := range m.fonts {
		if font.Status != "Installed" {
			missingCount++
		}
	}

	// Back is at the last position
	if missingCount > 0 && !m.loading {
		return m.cursor == fontCount+1 // Install All + Back
	}
	return m.cursor == fontCount // Just Back
}

// NerdFontInstallMsg signals a single font installation request
type NerdFontInstallMsg struct {
	FontName string
	Action   string // "install", "reinstall", "uninstall"
}

// installSingleFont returns a command that triggers single font installation
func (m *NerdFontsModel) installSingleFont(fontName string) tea.Cmd {
	return func() tea.Msg {
		return NerdFontInstallMsg{
			FontName: fontName,
			Action:   "install",
		}
	}
}

// uninstallSingleFont returns a command that triggers single font uninstallation
func (m *NerdFontsModel) uninstallSingleFont(fontName string) tea.Cmd {
	return func() tea.Msg {
		return NerdFontInstallMsg{
			FontName: fontName,
			Action:   "uninstall",
		}
	}
}
