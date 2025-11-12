"""
Contract test for /local-cicd/astro-build endpoint
Tests the local Astro build simulation runner script

This test MUST FAIL initially as required by TDD approach.
Implementation in astro-build-local.sh will make this pass.
"""

import json
import subprocess
from pathlib import Path
from typing import Any, Dict

import pytest


class TestAstroBuildContract:
    """Contract tests for local Astro build simulation endpoint."""

    def setup_method(self) -> None:
        """Setup test environment."""
        self.runner_script = Path(".runners-local/workflows/astro-build-local.sh")
        self.project_root = Path.cwd()

    def test_astro_build_script_exists(self) -> None:
        """Test that astro-build-local.sh runner script exists."""
        assert self.runner_script.exists(), "astro-build-local.sh runner script must exist"

    def test_astro_build_script_executable(self) -> None:
        """Test that astro-build-local.sh is executable."""
        assert self.runner_script.is_file(), "Runner script must be a file"
        # This will fail until we create the script
        assert self.runner_script.stat().st_mode & 0o111, "Runner script must be executable"

    def test_astro_build_production_environment(self) -> None:
        """Test POST /local-cicd/astro-build with production environment."""
        # Simulate API call with production environment
        request_payload = {
            "environment": "production",
            "validation_level": "full"
        }

        # This will fail until we implement the runner script
        result = self._execute_astro_build(request_payload)

        # Expected response structure (OpenAPI contract)
        assert result["status"] == "success"
        assert "build_time" in result
        assert isinstance(result["build_time"], (int, float))
        assert result["build_time"] > 0
        assert "output_size" in result
        assert isinstance(result["output_size"], int)
        assert result["output_size"] > 0
        assert "performance_metrics" in result

    def test_astro_build_development_environment(self) -> None:
        """Test POST /local-cicd/astro-build with development environment."""
        request_payload = {
            "environment": "development",
            "validation_level": "basic"
        }

        # This will fail until we implement the runner script
        result = self._execute_astro_build(request_payload)

        assert result["status"] == "success"
        assert "build_time" in result
        assert "output_size" in result

    def test_astro_build_invalid_environment(self) -> None:
        """Test POST /local-cicd/astro-build with invalid environment returns 400."""
        request_payload = {
            "environment": "invalid",
            "validation_level": "full"
        }

        # This will fail until we implement error handling
        with pytest.raises(subprocess.CalledProcessError) as exc_info:
            self._execute_astro_build(request_payload)

        # Should return non-zero exit code for 400 error
        assert exc_info.value.returncode != 0

    def test_astro_build_missing_environment(self) -> None:
        """Test POST /local-cicd/astro-build with missing required environment."""
        request_payload = {
            "validation_level": "full"
        }

        # This will fail until we implement validation
        with pytest.raises(subprocess.CalledProcessError):
            self._execute_astro_build(request_payload)

    def test_astro_build_performance_metrics_structure(self) -> None:
        """Test that performance metrics match OpenAPI schema."""
        request_payload = {
            "environment": "production",
            "validation_level": "full"
        }

        # This will fail until we implement performance metrics
        result = self._execute_astro_build(request_payload)

        metrics = result["performance_metrics"]
        assert "lighthouse" in metrics
        assert "core_web_vitals" in metrics
        assert "bundle_sizes" in metrics

        # Lighthouse scores
        lighthouse = metrics["lighthouse"]
        assert lighthouse["performance"] >= 95
        assert lighthouse["accessibility"] >= 95
        assert lighthouse["best_practices"] >= 95
        assert lighthouse["seo"] >= 95

        # Core Web Vitals
        vitals = metrics["core_web_vitals"]
        assert vitals["first_contentful_paint"] <= 1.5
        assert vitals["largest_contentful_paint"] <= 2.5
        assert vitals["cumulative_layout_shift"] <= 0.1

        # Bundle sizes
        bundles = metrics["bundle_sizes"]
        assert bundles["initial_js"] <= 102400  # 100KB limit

    def _execute_astro_build(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the astro-build-local.sh script with given payload.

        This simulates the POST /local-cicd/astro-build API call.
        """
        # Convert payload to command line arguments
        cmd = [
            str(self.runner_script),
            "--environment", payload.get("environment", "production"),
            "--validation-level", payload.get("validation_level", "full"),
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