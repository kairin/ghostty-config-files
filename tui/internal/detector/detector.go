// Package detector provides system detection using fastfetch
// and installation method recommendation for tools
package detector

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"

	"github.com/kairin/ghostty-installer/internal/registry"
)

// SystemInfo holds detected system information from fastfetch
type SystemInfo struct {
	OS           string // e.g., "ubuntu"
	OSName       string // e.g., "Ubuntu"
	OSVersion    string // e.g., "24.04.3 LTS (Noble Numbat)"
	OSVersionID  string // e.g., "24.04"
	Architecture string // e.g., "aarch64", "x86_64"
	HasSnap      bool   // Snap package manager available
	SnapCount    int    // Number of snap packages installed
	Kernel       string // e.g., "6.14.0-1015-nvidia"
	DesktopEnv   string // e.g., "GNOME", "KDE"
}

// InstallMethodRecommendation contains method recommendation with reasoning
type InstallMethodRecommendation struct {
	Method        registry.InstallMethod   // Recommended method
	Reason        string                   // Why this method is recommended
	Alternatives  []registry.InstallMethod // Alternative methods
	EstimatedTime string                   // e.g., "~30 seconds", "5-15 minutes"
	Pros          []string                 // Benefits of recommended method
	Cons          []string                 // Drawbacks of recommended method
}

// fastfetchOutput represents the JSON structure from fastfetch
type fastfetchOutput struct {
	Type   string          `json:"type"`
	Result json.RawMessage `json:"result"`
	Error  string          `json:"error,omitempty"`
}

// osResult represents the OS section from fastfetch JSON
type osResult struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	Version   string `json:"version"`
	VersionID string `json:"versionID"`
}

// kernelResult represents the Kernel section from fastfetch JSON
type kernelResult struct {
	Architecture string `json:"architecture"`
	Release      string `json:"release"`
}

// packagesResult represents the Packages section from fastfetch JSON
type packagesResult struct {
	Snap int `json:"snap,omitempty"`
}

// deResult represents the Desktop Environment section from fastfetch JSON
type deResult struct {
	Name string `json:"name"`
}

// DetectSystem runs fastfetch and parses system information
func DetectSystem() (*SystemInfo, error) {
	// Run fastfetch with JSON output
	cmd := exec.Command("fastfetch", "--format", "json")
	output, err := cmd.Output()
	if err != nil {
		// Fallback: if fastfetch fails, try basic detection
		return fallbackDetection()
	}

	// Parse JSON output
	return ParseFastfetchJSON(output)
}

// ParseFastfetchJSON parses fastfetch JSON output and extracts system info
func ParseFastfetchJSON(jsonData []byte) (*SystemInfo, error) {
	var entries []fastfetchOutput
	if err := json.Unmarshal(jsonData, &entries); err != nil {
		return nil, fmt.Errorf("failed to parse fastfetch JSON: %w", err)
	}

	info := &SystemInfo{}

	for _, entry := range entries {
		switch entry.Type {
		case "OS":
			var os osResult
			if err := json.Unmarshal(entry.Result, &os); err == nil {
				info.OS = os.ID
				info.OSName = os.Name
				info.OSVersion = os.Version
				info.OSVersionID = os.VersionID
			}

		case "Kernel":
			var kernel kernelResult
			if err := json.Unmarshal(entry.Result, &kernel); err == nil {
				info.Architecture = kernel.Architecture
				info.Kernel = kernel.Release
			}

		case "Packages":
			var packages packagesResult
			if err := json.Unmarshal(entry.Result, &packages); err == nil {
				info.SnapCount = packages.Snap
				if packages.Snap > 0 {
					info.HasSnap = true
				}
			}

		case "DE":
			var de deResult
			if err := json.Unmarshal(entry.Result, &de); err == nil {
				info.DesktopEnv = de.Name
			}
		}
	}

	// Additional snap detection if not found in packages
	if !info.HasSnap {
		if _, err := exec.LookPath("snap"); err == nil {
			info.HasSnap = true
		}
	}

	// Validate we got essential info
	if info.OS == "" || info.Architecture == "" {
		return nil, fmt.Errorf("incomplete system information from fastfetch")
	}

	return info, nil
}

// fallbackDetection provides basic system detection if fastfetch fails
func fallbackDetection() (*SystemInfo, error) {
	info := &SystemInfo{}

	// Try to get architecture
	if output, err := exec.Command("uname", "-m").Output(); err == nil {
		info.Architecture = strings.TrimSpace(string(output))
	}

	// Try to detect OS from /etc/os-release
	if output, err := exec.Command("bash", "-c", "source /etc/os-release && echo $ID").Output(); err == nil {
		info.OS = strings.TrimSpace(string(output))
	}

	// Check for snap
	if _, err := exec.LookPath("snap"); err == nil {
		info.HasSnap = true
	}

	if info.Architecture == "" || info.OS == "" {
		return nil, fmt.Errorf("failed to detect basic system information")
	}

	return info, nil
}

// RecommendGhosttyMethod analyzes system and recommends Ghostty installation method
func RecommendGhosttyMethod(info *SystemInfo) *InstallMethodRecommendation {
	// Rule 1: Ubuntu 24.04+ with snap available
	if info.OS == "ubuntu" && info.HasSnap && isVersionAtLeast(info.OSVersionID, "24.04") {
		// For ARM64, recommend snap (easier)
		if info.Architecture == "aarch64" {
			return &InstallMethodRecommendation{
				Method:        registry.MethodSnap,
				Reason:        "Fast installation on Ubuntu 24.04+ ARM64 with snap",
				Alternatives:  []registry.InstallMethod{registry.MethodSource},
				EstimatedTime: "~30 seconds",
				Pros: []string{
					"Quick installation",
					"Automatic updates via snap",
					"Maintained by publisher",
					"No build dependencies needed",
				},
				Cons: []string{
					"May be slightly behind latest version",
					"Snap confinement may limit some features",
				},
			}
		}

		// For x86_64, also recommend snap but mention source is viable
		return &InstallMethodRecommendation{
			Method:        registry.MethodSnap,
			Reason:        "Fast installation on Ubuntu 24.04+ with snap",
			Alternatives:  []registry.InstallMethod{registry.MethodSource},
			EstimatedTime: "~30 seconds",
			Pros: []string{
				"Quick installation",
				"Automatic updates via snap",
				"Maintained by publisher",
			},
			Cons: []string{
				"May be slightly behind latest version",
			},
		}
	}

	// Rule 2: Ubuntu 22.04 or older, or no snap - recommend source
	if info.OS == "ubuntu" && isVersionLessThan(info.OSVersionID, "24.04") {
		return &InstallMethodRecommendation{
			Method:        registry.MethodSource,
			Reason:        "Source build recommended for Ubuntu versions older than 24.04",
			Alternatives:  []registry.InstallMethod{},
			EstimatedTime: "5-15 minutes",
			Pros: []string{
				"Latest features and bug fixes",
				"Optimized for your system",
				"No snap dependency",
			},
			Cons: []string{
				"Longer build time",
				"Requires build dependencies (Zig, GTK4)",
				"Manual updates required",
			},
		}
	}

	// Rule 3: No snap available - source only
	if !info.HasSnap {
		return &InstallMethodRecommendation{
			Method:        registry.MethodSource,
			Reason:        "Snap not available on this system",
			Alternatives:  []registry.InstallMethod{},
			EstimatedTime: "5-15 minutes",
			Pros: []string{
				"Latest features and bug fixes",
				"Optimized for your system",
				"Full control over build",
			},
			Cons: []string{
				"Longer build time",
				"Requires build dependencies",
			},
		}
	}

	// Default: recommend source (most compatible)
	return &InstallMethodRecommendation{
		Method:        registry.MethodSource,
		Reason:        "Build from source for latest features",
		Alternatives:  []registry.InstallMethod{},
		EstimatedTime: "5-15 minutes",
		Pros: []string{
			"Latest features and bug fixes",
			"Optimized for your system",
		},
		Cons: []string{
			"Longer build time",
			"Requires build dependencies",
		},
	}
}

// isVersionAtLeast checks if version1 >= version2 (simple string comparison for Ubuntu versions)
func isVersionAtLeast(version1, version2 string) bool {
	// Simple version comparison for Ubuntu versions like "24.04", "22.04"
	// This works because Ubuntu uses YY.MM format
	return version1 >= version2
}

// isVersionLessThan checks if version1 < version2
func isVersionLessThan(version1, version2 string) bool {
	return version1 < version2
}

// GetSystemSummary returns a human-readable summary of the system
func (s *SystemInfo) GetSystemSummary() string {
	if s.OSVersion != "" && s.Architecture != "" {
		return fmt.Sprintf("%s (%s)", s.OSVersion, s.Architecture)
	}
	if s.OSName != "" && s.Architecture != "" {
		return fmt.Sprintf("%s (%s)", s.OSName, s.Architecture)
	}
	return "Unknown system"
}
