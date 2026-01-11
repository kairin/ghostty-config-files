package main

import (
	"fmt"
	"log"

	"github.com/kairin/ghostty-installer/internal/detector"
)

func main() {
	// Detect system
	sysInfo, err := detector.DetectSystem()
	if err != nil {
		log.Fatalf("Failed to detect system: %v", err)
	}

	// Print system information
	fmt.Println("=== System Information ===")
	fmt.Printf("OS: %s\n", sysInfo.OS)
	fmt.Printf("Version: %s\n", sysInfo.OSVersionID)
	fmt.Printf("Architecture: %s\n", sysInfo.Architecture)
	fmt.Printf("Has Snap: %v\n", sysInfo.HasSnap)
	fmt.Printf("Desktop Environment: %s\n", sysInfo.DesktopEnv)
	fmt.Printf("Summary: %s\n\n", sysInfo.GetSystemSummary())

	// Get recommendation for Ghostty installation
	recommendation := detector.RecommendGhosttyMethod(sysInfo)

	fmt.Println("=== Ghostty Installation Recommendation ===")
	fmt.Printf("Recommended Method: %s\n", recommendation.Method)
	fmt.Printf("Reason: %s\n", recommendation.Reason)
	fmt.Printf("Estimated Time: %s\n", recommendation.EstimatedTime)

	if len(recommendation.Pros) > 0 {
		fmt.Println("\nPros:")
		for _, pro := range recommendation.Pros {
			fmt.Printf("  ✓ %s\n", pro)
		}
	}

	if len(recommendation.Cons) > 0 {
		fmt.Println("\nCons:")
		for _, con := range recommendation.Cons {
			fmt.Printf("  ✗ %s\n", con)
		}
	}

	if len(recommendation.Alternatives) > 0 {
		fmt.Println("\nAlternatives:")
		for _, alt := range recommendation.Alternatives {
			fmt.Printf("  - %s\n", alt)
		}
	}
}
