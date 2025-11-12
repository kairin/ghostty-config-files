"""
Contract test for /local-cicd/gh-workflow endpoint
Tests the local GitHub Actions workflow simulation runner script

This test MUST FAIL initially as required by TDD approach.
Implementation in gh-workflow-local.sh will make this pass.
"""

import json
import subprocess
from pathlib import Path
from typing import Any, Dict

import pytest


class TestGitHubWorkflowContract:
    """Contract tests for local GitHub Actions workflow simulation endpoint."""

    def setup_method(self) -> None:
        """Setup test environment."""
        self.runner_script = Path(".runners-local/workflows/gh-workflow-local.sh")
        self.project_root = Path.cwd()

    def test_gh_workflow_script_exists(self) -> None:
        """Test that gh-workflow-local.sh runner script exists."""
        assert self.runner_script.exists(), "gh-workflow-local.sh runner script must exist"

    def test_gh_workflow_script_executable(self) -> None:
        """Test that gh-workflow-local.sh is executable."""
        assert self.runner_script.is_file(), "Runner script must be a file"
        # This will fail until we create the script
        assert self.runner_script.stat().st_mode & 0o111, "Runner script must be executable"

    def test_gh_workflow_all_type(self) -> None:
        """Test POST /local-cicd/gh-workflow with workflow_type 'all'."""
        request_payload = {
            "workflow_type": "all"
        }

        # This will fail until we implement the runner script
        result = self._execute_gh_workflow(request_payload)

        # Expected response structure (OpenAPI contract)
        assert result["status"] == "success"
        assert "execution_time" in result
        assert isinstance(result["execution_time"], (int, float))
        assert result["execution_time"] > 0
        assert "checks_passed" in result
        assert isinstance(result["checks_passed"], list)
        assert len(result["checks_passed"]) > 0
        assert "github_actions_consumption" in result
        assert result["github_actions_consumption"] == 0  # Must always be 0

    def test_gh_workflow_validate_type(self) -> None:
        """Test POST /local-cicd/gh-workflow with workflow_type 'validate'."""
        request_payload = {
            "workflow_type": "validate"
        }

        # This will fail until we implement validation workflow
        result = self._execute_gh_workflow(request_payload)

        assert result["status"] == "success"
        assert "execution_time" in result
        assert "checks_passed" in result
        assert result["github_actions_consumption"] == 0

        # Validate-specific checks
        checks = result["checks_passed"]
        assert any("configuration" in check.lower() for check in checks)
        assert any("typescript" in check.lower() for check in checks)

    def test_gh_workflow_test_type(self) -> None:
        """Test POST /local-cicd/gh-workflow with workflow_type 'test'."""
        request_payload = {
            "workflow_type": "test"
        }

        result = self._execute_gh_workflow(request_payload)

        assert result["status"] == "success"
        assert result["github_actions_consumption"] == 0

        # Test-specific checks
        checks = result["checks_passed"]
        assert any("test" in check.lower() for check in checks)

    def test_gh_workflow_build_type(self) -> None:
        """Test POST /local-cicd/gh-workflow with workflow_type 'build'."""
        request_payload = {
            "workflow_type": "build"
        }

        result = self._execute_gh_workflow(request_payload)

        assert result["status"] == "success"
        assert result["github_actions_consumption"] == 0

        # Build-specific checks
        checks = result["checks_passed"]
        assert any("build" in check.lower() for check in checks)

    def test_gh_workflow_deploy_type(self) -> None:
        """Test POST /local-cicd/gh-workflow with workflow_type 'deploy'."""
        request_payload = {
            "workflow_type": "deploy"
        }

        result = self._execute_gh_workflow(request_payload)

        assert result["status"] == "success"
        assert result["github_actions_consumption"] == 0

        # Deploy-specific checks
        checks = result["checks_passed"]
        assert any("deploy" in check.lower() for check in checks)

    def test_gh_workflow_with_skip_checks(self) -> None:
        """Test POST /local-cicd/gh-workflow with skip_checks array."""
        request_payload = {
            "workflow_type": "all",
            "skip_checks": ["lint", "typecheck"]
        }

        result = self._execute_gh_workflow(request_payload)

        assert result["status"] == "success"
        assert result["github_actions_consumption"] == 0

        # Verify skipped checks are not in passed checks
        checks = result["checks_passed"]
        assert not any("lint" in check.lower() for check in checks)
        assert not any("typecheck" in check.lower() for check in checks)

    def test_gh_workflow_missing_workflow_type(self) -> None:
        """Test POST /local-cicd/gh-workflow with missing required workflow_type."""
        request_payload = {
            "skip_checks": []
        }

        # This will fail until we implement validation
        with pytest.raises(subprocess.CalledProcessError):
            self._execute_gh_workflow(request_payload)

    def test_gh_workflow_invalid_workflow_type(self) -> None:
        """Test POST /local-cicd/gh-workflow with invalid workflow_type."""
        request_payload = {
            "workflow_type": "invalid_type"
        }

        # This will fail until we implement error handling
        with pytest.raises(subprocess.CalledProcessError) as exc_info:
            self._execute_gh_workflow(request_payload)

        # Should return non-zero exit code for 422 error
        assert exc_info.value.returncode != 0

    def test_gh_workflow_zero_github_actions_consumption(self) -> None:
        """Test that GitHub Actions consumption is always zero (constitutional requirement)."""
        request_payload = {
            "workflow_type": "all"
        }

        result = self._execute_gh_workflow(request_payload)

        # CRITICAL: Must always be 0 for constitutional compliance
        assert result["github_actions_consumption"] == 0
        assert "execution_time" in result
        # Local execution should be faster than GitHub Actions
        assert result["execution_time"] < 300  # Less than 5 minutes

    def _execute_gh_workflow(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the gh-workflow-local.sh script with given payload.

        This simulates the POST /local-cicd/gh-workflow API call.
        """
        # Convert payload to command line arguments
        cmd = [
            str(self.runner_script),
            "--workflow-type", payload.get("workflow_type", "all"),
            "--format", "json"
        ]

        # Add skip checks if provided
        if "skip_checks" in payload:
            for check in payload["skip_checks"]:
                cmd.extend(["--skip", check])

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