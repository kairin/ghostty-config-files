// Package ui provides the Bubbletea TUI implementation
package ui

import (
	"fmt"

	"github.com/charmbracelet/bubbles/key"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ConfirmResult is sent when the user confirms or cancels
type ConfirmResult struct {
	Confirmed bool
	Context   interface{} // Optional context to pass back
}

// ConfirmModel implements a confirmation dialog
type ConfirmModel struct {
	question string
	focused  int         // 0=No, 1=Yes
	context  interface{} // Context to pass back with result
	width    int
	height   int
}

// Confirm key bindings
type confirmKeyMap struct {
	Left   key.Binding
	Right  key.Binding
	Tab    key.Binding
	Enter  key.Binding
	Escape key.Binding
	Yes    key.Binding
	No     key.Binding
}

var confirmKeys = confirmKeyMap{
	Left: key.NewBinding(
		key.WithKeys("left", "h"),
		key.WithHelp("←/h", "no"),
	),
	Right: key.NewBinding(
		key.WithKeys("right", "l"),
		key.WithHelp("→/l", "yes"),
	),
	Tab: key.NewBinding(
		key.WithKeys("tab"),
		key.WithHelp("tab", "switch"),
	),
	Enter: key.NewBinding(
		key.WithKeys("enter"),
		key.WithHelp("enter", "confirm"),
	),
	Escape: key.NewBinding(
		key.WithKeys("esc"),
		key.WithHelp("esc", "cancel"),
	),
	Yes: key.NewBinding(
		key.WithKeys("y", "Y"),
		key.WithHelp("y", "yes"),
	),
	No: key.NewBinding(
		key.WithKeys("n", "N"),
		key.WithHelp("n", "no"),
	),
}

// NewConfirmModel creates a new confirmation dialog
func NewConfirmModel(question string, context interface{}) ConfirmModel {
	return ConfirmModel{
		question: question,
		focused:  0, // Default to "No" for safety
		context:  context,
		width:    50,
		height:   7,
	}
}

// Init implements tea.Model
func (m ConfirmModel) Init() tea.Cmd {
	return nil
}

// Update implements tea.Model
func (m ConfirmModel) Update(msg tea.Msg) (ConfirmModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch {
		case key.Matches(msg, confirmKeys.Left):
			m.focused = 0 // No
		case key.Matches(msg, confirmKeys.Right):
			m.focused = 1 // Yes
		case key.Matches(msg, confirmKeys.Tab):
			m.focused = 1 - m.focused // Toggle
		case key.Matches(msg, confirmKeys.Enter):
			return m, func() tea.Msg {
				return ConfirmResult{
					Confirmed: m.focused == 1,
					Context:   m.context,
				}
			}
		case key.Matches(msg, confirmKeys.Escape), key.Matches(msg, confirmKeys.No):
			return m, func() tea.Msg {
				return ConfirmResult{
					Confirmed: false,
					Context:   m.context,
				}
			}
		case key.Matches(msg, confirmKeys.Yes):
			return m, func() tea.Msg {
				return ConfirmResult{
					Confirmed: true,
					Context:   m.context,
				}
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	return m, nil
}

// View implements tea.Model
func (m ConfirmModel) View() string {
	// Button styles
	buttonStyle := lipgloss.NewStyle().
		Padding(0, 3).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(ColorMuted)

	selectedButtonStyle := lipgloss.NewStyle().
		Padding(0, 3).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(ColorPrimary).
		Foreground(ColorPrimary).
		Bold(true)

	dangerButtonStyle := lipgloss.NewStyle().
		Padding(0, 3).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(ColorError).
		Foreground(ColorError).
		Bold(true)

	// Render buttons
	var noButton, yesButton string
	if m.focused == 0 {
		noButton = selectedButtonStyle.Render("  No  ")
		yesButton = buttonStyle.Render(" Yes ")
	} else {
		noButton = buttonStyle.Render("  No  ")
		yesButton = dangerButtonStyle.Render(" Yes ")
	}

	buttons := lipgloss.JoinHorizontal(lipgloss.Center, noButton, "    ", yesButton)

	// Question with warning icon
	questionStyle := lipgloss.NewStyle().
		Foreground(ColorWarning).
		Bold(true)
	questionText := questionStyle.Render(IconWarning + "  " + m.question)

	// Help text
	helpText := HelpStyle.Render("[←/→] Select  [Enter] Confirm  [Esc] Cancel  [Y/N] Quick select")

	// Compose the dialog
	content := lipgloss.JoinVertical(
		lipgloss.Center,
		"",
		questionText,
		"",
		buttons,
		"",
		helpText,
	)

	// Dialog box style
	dialogStyle := lipgloss.NewStyle().
		Border(lipgloss.DoubleBorder()).
		BorderForeground(ColorWarning).
		Padding(1, 4).
		Width(60)

	dialog := dialogStyle.Render(content)

	// Center the dialog on screen
	return lipgloss.Place(
		m.width,
		m.height,
		lipgloss.Center,
		lipgloss.Center,
		dialog,
	)
}

// SetSize sets the dialog dimensions for centering
func (m *ConfirmModel) SetSize(width, height int) {
	m.width = width
	m.height = height
}

// ConfirmUninstall creates a confirmation dialog for uninstalling a tool
func ConfirmUninstall(toolName string, context interface{}) ConfirmModel {
	question := fmt.Sprintf("Uninstall %s? This action cannot be undone.", toolName)
	return NewConfirmModel(question, context)
}
