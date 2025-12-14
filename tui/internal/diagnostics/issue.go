// Package diagnostics - issue.go defines boot issue types and severity levels
package diagnostics

import "strings"

// IssueSeverity represents the severity level of a boot issue
type IssueSeverity int

const (
	// SeverityCritical - Issues that prevent system functionality
	SeverityCritical IssueSeverity = iota
	// SeverityModerate - Issues that may slow boot or cause warnings
	SeverityModerate
	// SeverityLow - Cosmetic issues or known bugs with no impact
	SeverityLow
)

// String returns the string representation of severity
func (s IssueSeverity) String() string {
	switch s {
	case SeverityCritical:
		return "CRITICAL"
	case SeverityModerate:
		return "MODERATE"
	case SeverityLow:
		return "LOW"
	default:
		return "UNKNOWN"
	}
}

// ParseSeverity parses a severity string from detector output
func ParseSeverity(s string) IssueSeverity {
	switch strings.ToUpper(strings.TrimSpace(s)) {
	case "CRITICAL":
		return SeverityCritical
	case "MODERATE":
		return SeverityModerate
	case "LOW":
		return SeverityLow
	default:
		return SeverityLow
	}
}

// FixableStatus represents whether an issue can be fixed
type FixableStatus string

const (
	FixableYes   FixableStatus = "YES"
	FixableNo    FixableStatus = "NO"
	FixableMaybe FixableStatus = "MAYBE"
)

// Issue represents a single boot diagnostic issue
// Parsed from detector script output: TYPE|SEVERITY|NAME|DESCRIPTION|FIXABLE|FIX_COMMAND
type Issue struct {
	Type        string        // Issue type (ORPHANED_SERVICE, FAILED_SERVICE, etc.)
	Severity    IssueSeverity // CRITICAL, MODERATE, LOW
	Name        string        // Service/component name
	Description string        // Human-readable description
	Fixable     FixableStatus // YES, NO, MAYBE
	FixCommand  string        // Command to fix the issue
}

// IsFixable returns true if the issue can be fixed
func (i Issue) IsFixable() bool {
	return i.Fixable == FixableYes || i.Fixable == FixableMaybe
}

// RequiresSudo returns true if the fix command requires sudo
func (i Issue) RequiresSudo() bool {
	return strings.HasPrefix(i.FixCommand, "sudo ")
}

// ParseIssue parses a single pipe-delimited line into an Issue
// Format: TYPE|SEVERITY|NAME|DESCRIPTION|FIXABLE|FIX_COMMAND
func ParseIssue(line string) *Issue {
	line = strings.TrimSpace(line)
	if line == "" || strings.HasPrefix(line, "#") {
		return nil
	}

	parts := strings.Split(line, "|")
	if len(parts) < 6 {
		return nil
	}

	fixable := FixableStatus(strings.ToUpper(strings.TrimSpace(parts[4])))
	if fixable != FixableYes && fixable != FixableNo && fixable != FixableMaybe {
		fixable = FixableNo
	}

	return &Issue{
		Type:        strings.TrimSpace(parts[0]),
		Severity:    ParseSeverity(parts[1]),
		Name:        strings.TrimSpace(parts[2]),
		Description: strings.TrimSpace(parts[3]),
		Fixable:     fixable,
		FixCommand:  strings.TrimSpace(parts[5]),
	}
}

// ParseIssues parses multiple lines of detector output into issues
func ParseIssues(output string) []*Issue {
	lines := strings.Split(output, "\n")
	issues := make([]*Issue, 0, len(lines))

	for _, line := range lines {
		if issue := ParseIssue(line); issue != nil {
			issues = append(issues, issue)
		}
	}

	return issues
}

// GroupBySeverity groups issues by severity level
func GroupBySeverity(issues []*Issue) map[IssueSeverity][]*Issue {
	groups := map[IssueSeverity][]*Issue{
		SeverityCritical: {},
		SeverityModerate: {},
		SeverityLow:      {},
	}

	for _, issue := range issues {
		groups[issue.Severity] = append(groups[issue.Severity], issue)
	}

	return groups
}

// CountFixable counts how many issues are fixable
func CountFixable(issues []*Issue) int {
	count := 0
	for _, issue := range issues {
		if issue.IsFixable() {
			count++
		}
	}
	return count
}

// GetFixableIssues returns only fixable issues
func GetFixableIssues(issues []*Issue) []*Issue {
	fixable := make([]*Issue, 0)
	for _, issue := range issues {
		if issue.IsFixable() {
			fixable = append(fixable, issue)
		}
	}
	return fixable
}

// SeparateBySudo separates fixable issues by sudo requirement
func SeparateBySudo(issues []*Issue) (userLevel, sudoLevel []*Issue) {
	userLevel = make([]*Issue, 0)
	sudoLevel = make([]*Issue, 0)

	for _, issue := range issues {
		if !issue.IsFixable() || issue.FixCommand == "" {
			continue
		}
		if issue.RequiresSudo() {
			sudoLevel = append(sudoLevel, issue)
		} else {
			userLevel = append(userLevel, issue)
		}
	}

	return userLevel, sudoLevel
}
