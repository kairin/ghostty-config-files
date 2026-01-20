// Package ui - batchpreview.go provides the batch operation preview view
package ui

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/cache"
	"github.com/kairin/ghostty-installer/internal/registry"
)

// BatchPreviewModel manages the batch preview screen
type BatchPreviewModel struct {
	// Items to preview
	toolItems []*registry.Tool
	fontItems []FontFamily
	isFont    bool

	// Context
	action     string
	returnView View

	// Statuses (for version display)
	statuses map[string]*cache.ToolStatus

	// Navigation: 0 = Confirm, 1 = Cancel
	cursor int

	// Flags
	confirmed bool
	cancelled bool

	// Dimensions
	width  int
	height int
}

// NewBatchPreviewModel creates a batch preview for tools
func NewBatchPreviewModel(
	items []*registry.Tool,
	statuses map[string]*cache.ToolStatus,
	action string,
	returnView View,
) BatchPreviewModel {
	return BatchPreviewModel{
		toolItems:  items,
		statuses:   statuses,
		action:     action,
		returnView: returnView,
		cursor:     0,
		isFont:     false,
	}
}

// NewBatchPreviewModelForFonts creates a batch preview for fonts
func NewBatchPreviewModelForFonts(
	fonts []FontFamily,
	action string,
	returnView View,
) BatchPreviewModel {
	return BatchPreviewModel{
		fontItems:  fonts,
		action:     action,
		returnView: returnView,
		cursor:     0,
		isFont:     true,
	}
}

// Init returns nil (no initialization commands needed)
func (m BatchPreviewModel) Init() tea.Cmd { return nil }

// Update handles keyboard input for the batch preview
func (m BatchPreviewModel) Update(msg tea.Msg) (BatchPreviewModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	case tea.KeyMsg:
		switch msg.String() {
		case "up", "k", "left", "h":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j", "right", "l":
			if m.cursor < 1 {
				m.cursor++
			}
		case "enter":
			if m.cursor == 0 {
				m.confirmed = true
			} else {
				m.cancelled = true
			}
		case "esc":
			m.cancelled = true
		}
	}
	return m, nil
}

// View renders the batch preview screen
func (m BatchPreviewModel) View() string {
	var b strings.Builder

	// Header
	count := len(m.toolItems)
	if m.isFont {
		count = len(m.fontItems)
	}
	title := fmt.Sprintf("%s %d %s", m.action, count, m.itemType())
	b.WriteString(HeaderStyle.Render(title))
	b.WriteString("\n\n")

	// Item list
	b.WriteString(m.renderItemList())
	b.WriteString("\n\n")

	// Buttons
	b.WriteString(m.renderButtons())
	b.WriteString("\n\n")

	// Help
	b.WriteString(HelpStyle.Render("  ←/→ navigate • enter select • esc cancel"))

	return b.String()
}

// itemType returns the pluralized type name
func (m BatchPreviewModel) itemType() string {
	if m.isFont {
		if len(m.fontItems) == 1 {
			return "Font"
		}
		return "Fonts"
	}
	if len(m.toolItems) == 1 {
		return "Tool"
	}
	return "Tools"
}

// renderItemList renders the list of items in a box
func (m BatchPreviewModel) renderItemList() string {
	var b strings.Builder

	if m.isFont {
		for _, font := range m.fontItems {
			icon := IconCross
			if font.Status == "Installed" {
				icon = IconCheckmark
			}
			b.WriteString(fmt.Sprintf("  %s %s\n", icon, font.DisplayName))
		}
	} else {
		for _, tool := range m.toolItems {
			status := m.statuses[tool.ID]
			icon := IconCross
			versionInfo := ""
			if status != nil {
				if status.IsInstalled() {
					icon = IconCheckmark
				}
				if status.NeedsUpdate() {
					icon = IconArrowUp
					versionInfo = fmt.Sprintf(" (%s → %s)", status.Version, status.LatestVer)
				}
			}
			b.WriteString(fmt.Sprintf("  %s %s%s\n", icon, tool.DisplayName, versionInfo))
		}
	}

	// Box styling
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(ColorPrimary).
		Padding(1, 2)

	return boxStyle.Render(strings.TrimSuffix(b.String(), "\n"))
}

// renderButtons renders the Confirm/Cancel buttons
func (m BatchPreviewModel) renderButtons() string {
	confirmStyle := lipgloss.NewStyle().Padding(0, 2).Border(lipgloss.RoundedBorder())
	cancelStyle := confirmStyle.Copy()

	if m.cursor == 0 {
		confirmStyle = confirmStyle.BorderForeground(ColorPrimary).Foreground(ColorPrimary).Bold(true)
		cancelStyle = cancelStyle.BorderForeground(ColorMuted)
	} else {
		confirmStyle = confirmStyle.BorderForeground(ColorMuted)
		cancelStyle = cancelStyle.BorderForeground(ColorPrimary).Foreground(ColorPrimary).Bold(true)
	}

	return lipgloss.JoinHorizontal(
		lipgloss.Center,
		confirmStyle.Render("Confirm"),
		"  ",
		cancelStyle.Render("Cancel"),
	)
}

// Query methods

// IsConfirmed returns true if user confirmed the batch operation
func (m BatchPreviewModel) IsConfirmed() bool { return m.confirmed }

// IsCancelled returns true if user cancelled the batch operation
func (m BatchPreviewModel) IsCancelled() bool { return m.cancelled }

// GetTools returns the slice of tools in the batch
func (m BatchPreviewModel) GetTools() []*registry.Tool { return m.toolItems }

// GetFonts returns the slice of fonts in the batch
func (m BatchPreviewModel) GetFonts() []FontFamily { return m.fontItems }

// GetReturnView returns the view to return to when exiting
func (m BatchPreviewModel) GetReturnView() View { return m.returnView }

// IsFont returns true if this is a font batch preview
func (m BatchPreviewModel) IsFont() bool { return m.isFont }
