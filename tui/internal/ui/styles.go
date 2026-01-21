// Package ui provides the Bubbletea TUI implementation
package ui

import "github.com/charmbracelet/lipgloss"

// Colors used throughout the UI
var (
	ColorPrimary   = lipgloss.Color("212") // Magenta/pink
	ColorSuccess   = lipgloss.Color("42")  // Green
	ColorWarning   = lipgloss.Color("214") // Orange/yellow
	ColorError     = lipgloss.Color("196") // Red
	ColorMuted     = lipgloss.Color("240") // Gray
	ColorHighlight = lipgloss.Color("39")  // Cyan
	ColorExtras    = lipgloss.Color("99")  // Cyan for extras dashboard
	ColorCritical  = lipgloss.Color("196") // Red for critical issues
	ColorModerate  = lipgloss.Color("214") // Orange for moderate issues
	ColorLow       = lipgloss.Color("240") // Gray for low-priority issues
)

// Nerd Font icons
const (
	IconCheckmark = "\uf00c" //
	IconArrowUp   = "\uf062" //
	IconCross     = "\uf00d" //
	IconFolder    = "\uf07b" //
	IconTag       = "\uf02b" //
	IconGear      = "\uf013" //
	IconWrench    = "\uf0ad" //
	IconWarning   = "\uf071" //
	IconCircle    = "\uf111" //  (for low severity)
	IconInfo      = "\uf05a" //  (for info)
	IconPackage   = "\uf487" //  (for bundled tools)
)

// Style definitions
var (
	// Header styles (compact - no border for space efficiency)
	HeaderStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(ColorPrimary).
			MarginTop(1).
			MarginBottom(1)

	// Dashboard table styles
	TableHeaderStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(ColorHighlight).
				Padding(0, 1)

	TableRowStyle = lipgloss.NewStyle().
			Padding(0, 1)

	TableSelectedStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(ColorPrimary).
				Padding(0, 1)

	// Status styles
	StatusInstalledStyle = lipgloss.NewStyle().
				Foreground(ColorSuccess)

	StatusUpdateStyle = lipgloss.NewStyle().
				Foreground(ColorWarning)

	StatusMissingStyle = lipgloss.NewStyle().
				Foreground(ColorError)

	StatusUnknownStyle = lipgloss.NewStyle().
				Foreground(ColorMuted)

	// Detail line styles (sub-items like npm versions, globals)
	DetailStyle = lipgloss.NewStyle().
			Foreground(ColorMuted).
			PaddingLeft(4)

	// Section header styles for details (Bundled:, Globals:)
	SectionHeaderStyle = lipgloss.NewStyle().
				Foreground(ColorHighlight).
				Bold(true).
				PaddingLeft(4)

	// Menu styles
	MenuItemStyle = lipgloss.NewStyle().
			PaddingLeft(2)

	MenuSelectedStyle = lipgloss.NewStyle().
				Foreground(ColorPrimary).
				Bold(true).
				PaddingLeft(2)

	MenuCursorStyle = lipgloss.NewStyle().
			Foreground(ColorPrimary)

	// Footer/help styles
	HelpStyle = lipgloss.NewStyle().
			Foreground(ColorMuted).
			Margin(1, 0)

	// Spinner/progress styles
	SpinnerStyle = lipgloss.NewStyle().
			Foreground(ColorPrimary)

	ProgressDescStyle = lipgloss.NewStyle().
				Bold(true)

	// Output line styles (for installation output)
	OutputLineStyle = lipgloss.NewStyle().
			Foreground(ColorMuted).
			PaddingLeft(4)

	OutputErrorStyle = lipgloss.NewStyle().
				Foreground(ColorError).
				PaddingLeft(4)

	// Box styles
	BoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(ColorPrimary).
			Padding(0, 1)

	WarningBoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(ColorWarning).
			Foreground(ColorWarning).
			Padding(0, 1)

	// Extras dashboard styles (cyan border)
	ExtrasBoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(ColorExtras).
			Padding(0, 1)

	// Extras header (compact - no border for space efficiency)
	ExtrasHeaderStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(ColorExtras).
				MarginTop(1).
				MarginBottom(1)

	// Diagnostics severity styles
	SeverityCriticalStyle = lipgloss.NewStyle().
				Foreground(ColorCritical).
				Bold(true)

	SeverityModerateStyle = lipgloss.NewStyle().
				Foreground(ColorModerate)

	SeverityLowStyle = lipgloss.NewStyle().
				Foreground(ColorLow)

	// Diagnostics issue styles
	IssueFixableStyle = lipgloss.NewStyle().
				Foreground(ColorSuccess).
				Bold(true)

	IssueNotFixableStyle = lipgloss.NewStyle().
				Foreground(ColorMuted)

	// SpecKit Updater styles
	SpecKitHeaderStyle = lipgloss.NewStyle().
				Bold(true).
				Foreground(ColorHighlight).
				MarginTop(1).
				MarginBottom(1)

	SpecKitBoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(ColorHighlight).
			Padding(0, 1)

	// Diff view styles
	DiffAddedStyle = lipgloss.NewStyle().
			Foreground(ColorSuccess)

	DiffRemovedStyle = lipgloss.NewStyle().
				Foreground(ColorError)

	DiffContextStyle = lipgloss.NewStyle().
				Foreground(ColorMuted)

	DiffHeaderStyle = lipgloss.NewStyle().
			Foreground(ColorHighlight).
			Bold(true)
)

// GetStatusStyle returns the appropriate style for a status string
func GetStatusStyle(status string) lipgloss.Style {
	switch status {
	case "INSTALLED":
		return StatusInstalledStyle
	case "Not Installed", "NOT_INSTALLED":
		return StatusMissingStyle
	case "Update":
		return StatusUpdateStyle
	default:
		return StatusUnknownStyle
	}
}

// GetStatusIcon returns the appropriate icon for a status
func GetStatusIcon(status string, needsUpdate bool) string {
	if status != "INSTALLED" && status != "Not Installed" && status != "NOT_INSTALLED" {
		return IconCross
	}
	if needsUpdate {
		return IconArrowUp
	}
	if status == "INSTALLED" {
		return IconCheckmark
	}
	return IconCross
}
