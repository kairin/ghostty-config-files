package detector

import (
	"testing"

	"github.com/kairin/ghostty-installer/internal/registry"
)

func TestParseFastfetchJSON(t *testing.T) {
	testJSON := []byte(`[
		{
			"type": "OS",
			"result": {
				"id": "ubuntu",
				"name": "Ubuntu",
				"version": "24.04.3 LTS (Noble Numbat)",
				"versionID": "24.04"
			}
		},
		{
			"type": "Kernel",
			"result": {
				"architecture": "aarch64",
				"release": "6.14.0-1015-nvidia"
			}
		},
		{
			"type": "Packages",
			"result": {
				"snap": 16
			}
		},
		{
			"type": "DE",
			"result": {
				"name": "GNOME"
			}
		}
	]`)

	info, err := ParseFastfetchJSON(testJSON)
	if err != nil {
		t.Fatalf("ParseFastfetchJSON failed: %v", err)
	}

	if info.OS != "ubuntu" {
		t.Errorf("Expected OS ubuntu, got %s", info.OS)
	}

	if info.OSVersionID != "24.04" {
		t.Errorf("Expected OSVersionID 24.04, got %s", info.OSVersionID)
	}

	if info.Architecture != "aarch64" {
		t.Errorf("Expected Architecture aarch64, got %s", info.Architecture)
	}

	if !info.HasSnap {
		t.Error("Expected HasSnap to be true")
	}

	if info.SnapCount != 16 {
		t.Errorf("Expected SnapCount 16, got %d", info.SnapCount)
	}

	if info.DesktopEnv != "GNOME" {
		t.Errorf("Expected DesktopEnv GNOME, got %s", info.DesktopEnv)
	}
}

func TestRecommendGhosttyMethod_Ubuntu2404_ARM64_Snap(t *testing.T) {
	info := &SystemInfo{
		OS:           "ubuntu",
		OSVersionID:  "24.04",
		Architecture: "aarch64",
		HasSnap:      true,
	}

	rec := RecommendGhosttyMethod(info)

	if rec.Method != registry.MethodSnap {
		t.Errorf("Expected MethodSnap, got %s", rec.Method)
	}

	if rec.EstimatedTime != "~30 seconds" {
		t.Errorf("Expected ~30 seconds, got %s", rec.EstimatedTime)
	}

	if len(rec.Alternatives) == 0 {
		t.Error("Expected alternatives to be provided")
	}

	if rec.Alternatives[0] != registry.MethodSource {
		t.Errorf("Expected MethodSource as alternative, got %s", rec.Alternatives[0])
	}
}

func TestRecommendGhosttyMethod_Ubuntu2204_Snap(t *testing.T) {
	info := &SystemInfo{
		OS:           "ubuntu",
		OSVersionID:  "22.04",
		Architecture: "x86_64",
		HasSnap:      true,
	}

	rec := RecommendGhosttyMethod(info)

	// Ubuntu 22.04 should recommend source build
	if rec.Method != registry.MethodSource {
		t.Errorf("Expected MethodSource for Ubuntu 22.04, got %s", rec.Method)
	}

	if rec.EstimatedTime != "5-15 minutes" {
		t.Errorf("Expected 5-15 minutes, got %s", rec.EstimatedTime)
	}
}

func TestRecommendGhosttyMethod_NoSnap(t *testing.T) {
	info := &SystemInfo{
		OS:           "ubuntu",
		OSVersionID:  "24.04",
		Architecture: "x86_64",
		HasSnap:      false,
	}

	rec := RecommendGhosttyMethod(info)

	// No snap should force source build
	if rec.Method != registry.MethodSource {
		t.Errorf("Expected MethodSource when snap unavailable, got %s", rec.Method)
	}

	if len(rec.Alternatives) != 0 {
		t.Error("Expected no alternatives when snap unavailable")
	}
}

func TestRecommendGhosttyMethod_Ubuntu2404_x86_64_Snap(t *testing.T) {
	info := &SystemInfo{
		OS:           "ubuntu",
		OSVersionID:  "24.04",
		Architecture: "x86_64",
		HasSnap:      true,
	}

	rec := RecommendGhosttyMethod(info)

	// Ubuntu 24.04 x86_64 with snap should recommend snap
	if rec.Method != registry.MethodSnap {
		t.Errorf("Expected MethodSnap, got %s", rec.Method)
	}

	if len(rec.Alternatives) == 0 {
		t.Error("Expected source as alternative")
	}
}

func TestIsVersionAtLeast(t *testing.T) {
	tests := []struct {
		version1 string
		version2 string
		expected bool
	}{
		{"24.04", "24.04", true},
		{"24.04", "22.04", true},
		{"22.04", "24.04", false},
		{"24.10", "24.04", true},
		{"23.10", "24.04", false},
	}

	for _, tt := range tests {
		result := isVersionAtLeast(tt.version1, tt.version2)
		if result != tt.expected {
			t.Errorf("isVersionAtLeast(%s, %s) = %v, expected %v",
				tt.version1, tt.version2, result, tt.expected)
		}
	}
}

func TestGetSystemSummary(t *testing.T) {
	tests := []struct {
		name     string
		info     *SystemInfo
		expected string
	}{
		{
			name: "Full version info",
			info: &SystemInfo{
				OSVersion:    "Ubuntu 24.04.3 LTS (Noble Numbat)",
				Architecture: "aarch64",
			},
			expected: "Ubuntu 24.04.3 LTS (Noble Numbat) (aarch64)",
		},
		{
			name: "Only OS name",
			info: &SystemInfo{
				OSName:       "Ubuntu",
				Architecture: "x86_64",
			},
			expected: "Ubuntu (x86_64)",
		},
		{
			name:     "Unknown system",
			info:     &SystemInfo{},
			expected: "Unknown system",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := tt.info.GetSystemSummary()
			if result != tt.expected {
				t.Errorf("GetSystemSummary() = %q, expected %q", result, tt.expected)
			}
		})
	}
}
