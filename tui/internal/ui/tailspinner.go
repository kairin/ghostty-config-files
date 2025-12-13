// Package ui - tailspinner.go provides a spinner component with scrollable output tail
package ui

import (
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/kairin/ghostty-installer/internal/executor"
)

const (
	// DefaultMaxLines is the maximum number of lines to keep in memory
	DefaultMaxLines = 500
	// DefaultDisplayLines is the number of lines visible in the viewport
	DefaultDisplayLines = 5
	// BatchSize is the number of lines to batch before updating UI
	BatchSize = 10
	// BatchTimeout is how long to wait before flushing a partial batch
	BatchTimeout = 50 * time.Millisecond
)

// TailSpinner combines a spinner with a scrollable output viewport
type TailSpinner struct {
	// Components
	spinner  spinner.Model
	viewport viewport.Model

	// Output state
	lines        []string
	maxLines     int
	displayLines int

	// Running state
	isRunning bool
	title     string
	stage     string

	// Dimensions
	width  int
	height int

	// Styling
	titleStyle  lipgloss.Style
	stageStyle  lipgloss.Style
	outputStyle lipgloss.Style
	errorStyle  lipgloss.Style
}

// NewTailSpinner creates a new TailSpinner with default settings
func NewTailSpinner() TailSpinner {
	s := spinner.New()
	s.Spinner = spinner.Points // Braille-like spinner
	s.Style = SpinnerStyle

	vp := viewport.New(80, DefaultDisplayLines)
	vp.Style = lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(ColorMuted).
		Padding(0, 1)

	return TailSpinner{
		spinner:      s,
		viewport:     vp,
		lines:        make([]string, 0, DefaultMaxLines),
		maxLines:     DefaultMaxLines,
		displayLines: DefaultDisplayLines,
		titleStyle:   lipgloss.NewStyle().Bold(true).Foreground(ColorPrimary),
		stageStyle:   lipgloss.NewStyle().Foreground(ColorHighlight),
		outputStyle:  OutputLineStyle,
		errorStyle:   OutputErrorStyle,
	}
}

// Init initializes the TailSpinner
func (t TailSpinner) Init() tea.Cmd {
	return t.spinner.Tick
}

// TailSpinnerMsg types for message passing
type (
	// OutputBatchMsg contains a batch of output lines
	OutputBatchMsg struct {
		Lines []executor.OutputLine
	}

	// SetRunningMsg sets the running state
	SetRunningMsg struct {
		Running bool
		Title   string
		Stage   string
	}

	// ClearOutputMsg clears all output lines
	ClearOutputMsg struct{}
)

// Update handles messages
func (t TailSpinner) Update(msg tea.Msg) (TailSpinner, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		t.width = msg.Width
		t.height = msg.Height
		t.viewport.Width = msg.Width - 4 // Account for borders/padding
		t.viewport.Height = t.displayLines
		return t, nil

	case spinner.TickMsg:
		if t.isRunning {
			var cmd tea.Cmd
			t.spinner, cmd = t.spinner.Update(msg)
			cmds = append(cmds, cmd)
		}
		return t, tea.Batch(cmds...)

	case OutputBatchMsg:
		for _, line := range msg.Lines {
			t.addLine(line)
		}
		t.updateViewport()
		return t, nil

	case SetRunningMsg:
		t.isRunning = msg.Running
		t.title = msg.Title
		t.stage = msg.Stage
		if msg.Running {
			cmds = append(cmds, t.spinner.Tick)
		}
		return t, tea.Batch(cmds...)

	case ClearOutputMsg:
		t.lines = t.lines[:0]
		t.updateViewport()
		return t, nil
	}

	// Update viewport for scroll
	var cmd tea.Cmd
	t.viewport, cmd = t.viewport.Update(msg)
	if cmd != nil {
		cmds = append(cmds, cmd)
	}

	return t, tea.Batch(cmds...)
}

// addLine adds a new line to the output buffer
func (t *TailSpinner) addLine(line executor.OutputLine) {
	// Format line with timestamp if desired
	text := line.Text

	// Apply truncation if line is too long
	if t.width > 0 && len(text) > t.width-8 {
		text = text[:t.width-11] + "..."
	}

	// Style based on error status
	var styledLine string
	if line.IsError {
		styledLine = t.errorStyle.Render(text)
	} else {
		styledLine = t.outputStyle.Render(text)
	}

	t.lines = append(t.lines, styledLine)

	// Trim old lines if over max
	if len(t.lines) > t.maxLines {
		t.lines = t.lines[len(t.lines)-t.maxLines:]
	}
}

// updateViewport updates the viewport content with latest lines
func (t *TailSpinner) updateViewport() {
	// Show last N lines
	start := 0
	if len(t.lines) > t.displayLines {
		start = len(t.lines) - t.displayLines
	}

	content := strings.Join(t.lines[start:], "\n")
	t.viewport.SetContent(content)
	t.viewport.GotoBottom()
}

// View renders the TailSpinner
func (t TailSpinner) View() string {
	var b strings.Builder

	// Title line with spinner
	if t.isRunning {
		b.WriteString(t.spinner.View())
		b.WriteString(" ")
	}

	if t.title != "" {
		b.WriteString(t.titleStyle.Render(t.title))
	}
	if t.stage != "" {
		b.WriteString(" - ")
		b.WriteString(t.stageStyle.Render(t.stage))
	}
	b.WriteString("\n")

	// Output viewport
	b.WriteString(t.viewport.View())

	return b.String()
}

// SetDimensions sets the width and height
func (t *TailSpinner) SetDimensions(width, height int) {
	t.width = width
	t.height = height
	t.viewport.Width = width - 4
	t.viewport.Height = t.displayLines
}

// SetTitle sets the spinner title
func (t *TailSpinner) SetTitle(title string) {
	t.title = title
}

// SetStage sets the current stage description
func (t *TailSpinner) SetStage(stage string) {
	t.stage = stage
}

// Start starts the spinner
func (t *TailSpinner) Start() tea.Cmd {
	t.isRunning = true
	return t.spinner.Tick
}

// Stop stops the spinner
func (t *TailSpinner) Stop() {
	t.isRunning = false
}

// Clear clears all output lines
func (t *TailSpinner) Clear() {
	t.lines = t.lines[:0]
	t.updateViewport()
}

// LineCount returns the number of lines in the buffer
func (t TailSpinner) LineCount() int {
	return len(t.lines)
}

// SetDisplayLines sets the number of visible lines
func (t *TailSpinner) SetDisplayLines(n int) {
	t.displayLines = n
	t.viewport.Height = n
	t.updateViewport()
}

// BatchOutputCmd returns a command that batches output from a channel
// This prevents UI overwhelming on fast output
func BatchOutputCmd(outputChan <-chan executor.OutputLine) tea.Cmd {
	return func() tea.Msg {
		batch := make([]executor.OutputLine, 0, BatchSize)
		timeout := time.NewTimer(BatchTimeout)
		defer timeout.Stop()

		for {
			select {
			case line, ok := <-outputChan:
				if !ok {
					// Channel closed - return final batch
					if len(batch) > 0 {
						return OutputBatchMsg{Lines: batch}
					}
					return nil
				}
				batch = append(batch, line)
				if len(batch) >= BatchSize {
					return OutputBatchMsg{Lines: batch}
				}

			case <-timeout.C:
				if len(batch) > 0 {
					return OutputBatchMsg{Lines: batch}
				}
				timeout.Reset(BatchTimeout)
			}
		}
	}
}
