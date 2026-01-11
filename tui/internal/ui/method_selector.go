package ui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/detector"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// methodSelectedMsg is sent when user confirms method selection
type methodSelectedMsg struct {
	method         registry.InstallMethod
	savePreference bool
	resume         bool
}

// backMsg is sent when user wants to go back to previous view
type backMsg struct{}

// MethodSelectorModel handles the method selection view
type MethodSelectorModel struct {
	tool            *registry.Tool
	recommendation  *detector.InstallMethodRecommendation
	methods         []registry.InstallMethod
	cursor          int
	savePreference  bool
	systemInfo      *detector.SystemInfo
	width           int
	height          int
}

// NewMethodSelector creates a new method selector
func NewMethodSelector(tool *registry.Tool, recommendation *detector.InstallMethodRecommendation, sysInfo *detector.SystemInfo) MethodSelectorModel {
	return MethodSelectorModel{
		tool:           tool,
		recommendation: recommendation,
		methods:        tool.SupportedMethods,
		cursor:         findRecommendedIndex(tool.SupportedMethods, recommendation.Method),
		savePreference: true, // Default to saving preference
		systemInfo:     sysInfo,
	}
}

// findRecommendedIndex finds the index of the recommended method
func findRecommendedIndex(methods []registry.InstallMethod, recommended registry.InstallMethod) int {
	for i, m := range methods {
		if m == recommended {
			return i
		}
	}
	return 0
}

// Init initializes the model
func (m MethodSelectorModel) Init() tea.Cmd {
	return nil
}

// Update handles user input
func (m MethodSelectorModel) Update(msg tea.Msg) (MethodSelectorModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}

		case "down", "j":
			if m.cursor < len(m.methods)-1 {
				m.cursor++
			}

		case "tab":
			// Toggle save preference checkbox
			m.savePreference = !m.savePreference

		case "enter":
			// Confirm selection
			return m, func() tea.Msg {
				return methodSelectedMsg{
					method:         m.methods[m.cursor],
					savePreference: m.savePreference,
				}
			}

		case "esc":
			// Cancel and go back
			return m, func() tea.Msg {
				return backMsg{}
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	return m, nil
}

// View renders the method selection UI
func (m MethodSelectorModel) View() string {
	var b strings.Builder

	// Title
	title := HeaderStyle.Render("Choose Installation Method for " + m.tool.DisplayName)
	b.WriteString(title + "\n\n")

	// System info
	if m.systemInfo != nil {
		sysInfo := HelpStyle.Render("System: " + m.systemInfo.GetSystemSummary())
		b.WriteString(sysInfo + "\n\n")
	}

	// Recommendation section
	b.WriteString(m.renderRecommendation())
	b.WriteString("\n")

	// Method options
	b.WriteString(m.renderMethods())
	b.WriteString("\n")

	// Save preference checkbox
	checkbox := " "
	if m.savePreference {
		checkbox = "x"
	}
	checkboxLine := fmt.Sprintf("[%s] Remember my choice for future installs", checkbox)
	b.WriteString(HelpStyle.Render(checkboxLine) + "\n\n")

	// Help text
	helpText := HelpStyle.Render("↑↓ select • enter confirm • tab toggle save • esc back")
	b.WriteString(helpText + "\n")

	return b.String()
}

// renderRecommendation renders the recommendation section
func (m MethodSelectorModel) renderRecommendation() string {
	if m.recommendation == nil {
		return ""
	}

	var b strings.Builder

	// Recommendation header
	recHeader := HighlightStyle.Render(fmt.Sprintf("RECOMMENDED: %s", getMethodDisplayName(m.recommendation.Method)))
	b.WriteString(recHeader + "\n")

	// Reason
	reason := HelpStyle.Render(m.recommendation.Reason)
	b.WriteString(reason + "\n")

	// Estimated time
	if m.recommendation.EstimatedTime != "" {
		timeInfo := HelpStyle.Render("Time: " + m.recommendation.EstimatedTime)
		b.WriteString(timeInfo + "\n")
	}

	// Pros
	if len(m.recommendation.Pros) > 0 {
		for _, pro := range m.recommendation.Pros {
			b.WriteString(SuccessStyle.Render("✓ "+pro) + "\n")
		}
	}

	// Cons
	if len(m.recommendation.Cons) > 0 {
		for _, con := range m.recommendation.Cons {
			b.WriteString(HelpStyle.Render("✗ "+con) + "\n")
		}
	}

	return b.String()
}

// renderMethods renders the method selection list
func (m MethodSelectorModel) renderMethods() string {
	var b strings.Builder

	for i, method := range m.methods {
		// Cursor indicator
		cursor := "  "
		if i == m.cursor {
			cursor = "> "
		}

		// Selection indicator
		indicator := "○"
		if i == m.cursor {
			indicator = "●"
		}

		// Method name
		methodName := getMethodDisplayName(method)

		// Recommendation tag
		tag := ""
		if m.recommendation != nil && method == m.recommendation.Method {
			tag = " " + HighlightStyle.Render("(Recommended)")
		}

		// Render line
		line := fmt.Sprintf("%s%s %s%s", cursor, indicator, methodName, tag)

		// Style based on selection
		if i == m.cursor {
			line = SelectedStyle.Render(line)
		}

		b.WriteString(line + "\n")

		// Add method details if selected
		if i == m.cursor {
			details := m.getMethodDetails(method)
			if details != "" {
				b.WriteString(HelpStyle.Render("  " + details) + "\n")
			}
		}
	}

	return b.String()
}

// getMethodDetails returns detailed information about a method
func (m MethodSelectorModel) getMethodDetails(method registry.InstallMethod) string {
	switch method {
	case registry.MethodSnap:
		return "Quick installation via snap package manager (~30 seconds)"
	case registry.MethodSource:
		return "Build from latest source code (5-15 minutes, requires Zig + GTK4)"
	default:
		return ""
	}
}

// getMethodDisplayName returns the human-readable name for a method
func getMethodDisplayName(method registry.InstallMethod) string {
	switch method {
	case registry.MethodSnap:
		return "Snap"
	case registry.MethodSource:
		return "Build from Source"
	case registry.MethodAPT:
		return "APT Package"
	case registry.MethodCharmRepo:
		return "Charm Repository"
	case registry.MethodTarball:
		return "Tarball"
	case registry.MethodScript:
		return "Install Script"
	case registry.MethodGitHubRelease:
		return "GitHub Release"
	case registry.MethodNPM:
		return "NPM"
	default:
		return string(method)
	}
}

// Styles for method selector
var (
	SelectedStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("170")) // Purple highlight

	HighlightStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("214")) // Orange

	SuccessStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("42")) // Green
)
