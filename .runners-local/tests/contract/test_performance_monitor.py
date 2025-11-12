"""
Contract test for /local-cicd/performance-monitor endpoint
Tests the local performance monitoring runner script

This test MUST FAIL initially as required by TDD approach.
Implementation in performance-monitor.sh will make this pass.
"""

import json
import subprocess
from pathlib import Path
from typing import Any, Dict

import pytest


class TestPerformanceMonitorContract:
    """Contract tests for local performance monitoring endpoint."""

    def setup_method(self) -> None:
        """Setup test environment."""
        self.runner_script = Path(".runners-local/workflows/performance-monitor.sh")
        self.project_root = Path.cwd()

    def test_performance_monitor_script_exists(self) -> None:
        """Test that performance-monitor.sh runner script exists."""
        assert self.runner_script.exists(), "performance-monitor.sh runner script must exist"

    def test_performance_monitor_script_executable(self) -> None:
        """Test that performance-monitor.sh is executable."""
        assert self.runner_script.is_file(), "Runner script must be a file"
        # This will fail until we create the script
        assert self.runner_script.stat().st_mode & 0o111, "Runner script must be executable"

    def test_performance_monitor_lighthouse_test(self) -> None:
        """Test POST /local-cicd/performance-monitor with lighthouse test."""
        request_payload = {
            "target_url": "http://localhost:4321",
            "test_type": "lighthouse"
        }

        # This will fail until we implement the runner script
        result = self._execute_performance_monitor(request_payload)

        # Expected response structure (OpenAPI contract)
        assert result["status"] == "success"
        assert "metrics" in result
        assert "recommendations" in result
        assert isinstance(result["recommendations"], list)

        # Verify metrics structure
        metrics = result["metrics"]
        self._validate_lighthouse_metrics(metrics)

    def test_performance_monitor_core_web_vitals_test(self) -> None:
        """Test POST /local-cicd/performance-monitor with core-web-vitals test."""
        request_payload = {
            "target_url": "http://localhost:4321",
            "test_type": "core-web-vitals"
        }

        result = self._execute_performance_monitor(request_payload)

        assert result["status"] == "success"
        assert "metrics" in result

        # Verify Core Web Vitals structure
        metrics = result["metrics"]
        assert "core_web_vitals" in metrics

        vitals = metrics["core_web_vitals"]
        assert "first_contentful_paint" in vitals
        assert "largest_contentful_paint" in vitals
        assert "cumulative_layout_shift" in vitals

        # Constitutional performance targets
        assert vitals["first_contentful_paint"] <= 1.5
        assert vitals["largest_contentful_paint"] <= 2.5
        assert vitals["cumulative_layout_shift"] <= 0.1

    def test_performance_monitor_accessibility_test(self) -> None:
        """Test POST /local-cicd/performance-monitor with accessibility test."""
        request_payload = {
            "target_url": "http://localhost:4321",
            "test_type": "accessibility"
        }

        result = self._execute_performance_monitor(request_payload)

        assert result["status"] == "success"
        metrics = result["metrics"]

        # Accessibility-specific metrics
        assert "lighthouse" in metrics
        lighthouse = metrics["lighthouse"]
        assert lighthouse["accessibility"] >= 95  # Constitutional requirement

    def test_performance_monitor_security_test(self) -> None:
        """Test POST /local-cicd/performance-monitor with security test."""
        request_payload = {
            "target_url": "http://localhost:4321",
            "test_type": "security"
        }

        result = self._execute_performance_monitor(request_payload)

        assert result["status"] == "success"
        assert "metrics" in result
        assert "recommendations" in result

        # Security-specific recommendations
        recommendations = result["recommendations"]
        assert len(recommendations) >= 0  # May have no issues

    def test_performance_monitor_missing_target_url(self) -> None:
        """Test POST /local-cicd/performance-monitor with missing required target_url."""
        request_payload = {
            "test_type": "lighthouse"
        }

        # This will fail until we implement validation
        with pytest.raises(subprocess.CalledProcessError):
            self._execute_performance_monitor(request_payload)

    def test_performance_monitor_invalid_url(self) -> None:
        """Test POST /local-cicd/performance-monitor with invalid URL format."""
        request_payload = {
            "target_url": "not-a-valid-url",
            "test_type": "lighthouse"
        }

        # This will fail until we implement URL validation
        with pytest.raises(subprocess.CalledProcessError) as exc_info:
            self._execute_performance_monitor(request_payload)

        # Should return non-zero exit code for 400 error
        assert exc_info.value.returncode != 0

    def test_performance_monitor_unreachable_url(self) -> None:
        """Test POST /local-cicd/performance-monitor with unreachable URL."""
        request_payload = {
            "target_url": "http://localhost:9999",  # Likely unreachable
            "test_type": "lighthouse"
        }

        # Should handle unreachable URLs gracefully
        with pytest.raises(subprocess.CalledProcessError):
            self._execute_performance_monitor(request_payload)

    def test_performance_monitor_bundle_size_validation(self) -> None:
        """Test that bundle size monitoring enforces constitutional limits."""
        request_payload = {
            "target_url": "http://localhost:4321",
            "test_type": "lighthouse"
        }

        result = self._execute_performance_monitor(request_payload)

        metrics = result["metrics"]
        assert "bundle_sizes" in metrics

        bundles = metrics["bundle_sizes"]
        assert "initial_js" in bundles

        # Constitutional requirement: <100KB initial JS
        assert bundles["initial_js"] <= 102400  # 100KB in bytes

    def test_performance_monitor_constitutional_compliance(self) -> None:
        """Test that all constitutional performance requirements are enforced."""
        request_payload = {
            "target_url": "http://localhost:4321",
            "test_type": "lighthouse"
        }

        result = self._execute_performance_monitor(request_payload)

        metrics = result["metrics"]
        self._validate_constitutional_compliance(metrics)

    def _validate_lighthouse_metrics(self, metrics: Dict[str, Any]) -> None:
        """Validate Lighthouse metrics structure and values."""
        assert "lighthouse" in metrics

        lighthouse = metrics["lighthouse"]
        assert "performance" in lighthouse
        assert "accessibility" in lighthouse
        assert "best_practices" in lighthouse
        assert "seo" in lighthouse

        # Constitutional requirements: all scores >= 95
        assert lighthouse["performance"] >= 95
        assert lighthouse["accessibility"] >= 95
        assert lighthouse["best_practices"] >= 95
        assert lighthouse["seo"] >= 95

    def _validate_constitutional_compliance(self, metrics: Dict[str, Any]) -> None:
        """Validate that all constitutional performance requirements are met."""
        # Lighthouse scores >= 95
        self._validate_lighthouse_metrics(metrics)

        # Core Web Vitals targets
        if "core_web_vitals" in metrics:
            vitals = metrics["core_web_vitals"]
            assert vitals["first_contentful_paint"] <= 1.5
            assert vitals["largest_contentful_paint"] <= 2.5
            assert vitals["cumulative_layout_shift"] <= 0.1

        # Bundle size limits
        if "bundle_sizes" in metrics:
            bundles = metrics["bundle_sizes"]
            assert bundles["initial_js"] <= 102400  # 100KB

    def _execute_performance_monitor(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the performance-monitor.sh script with given payload.

        This simulates the POST /local-cicd/performance-monitor API call.
        """
        # Convert payload to command line arguments
        cmd = [
            str(self.runner_script),
            "--target-url", payload.get("target_url", ""),
            "--test-type", payload.get("test_type", "lighthouse"),
            "--format", "json"
        ]

        # This will fail until we create and implement the script
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
            cwd=self.project_root
        )

        # Parse JSON response
        return json.loads(result.stdout)