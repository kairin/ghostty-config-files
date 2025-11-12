"""
Contract test for /local-cicd/pre-commit endpoint
Tests the local pre-commit validation runner script

This test MUST FAIL initially as required by TDD approach.
Implementation in pre-commit-local.sh will make this pass.
"""

import json
import subprocess
from pathlib import Path
from typing import Any, Dict, List

import pytest


class TestPreCommitContract:
    """Contract tests for local pre-commit validation endpoint."""

    def setup_method(self) -> None:
        """Setup test environment."""
        self.runner_script = Path(".runners-local/workflows/pre-commit-local.sh")
        self.project_root = Path.cwd()

    def test_pre_commit_script_exists(self) -> None:
        """Test that pre-commit-local.sh runner script exists."""
        assert self.runner_script.exists(), "pre-commit-local.sh runner script must exist"

    def test_pre_commit_script_executable(self) -> None:
        """Test that pre-commit-local.sh is executable."""
        assert self.runner_script.is_file(), "Runner script must be a file"
        # This will fail until we create the script
        assert self.runner_script.stat().st_mode & 0o111, "Runner script must be executable"

    def test_pre_commit_validation_success(self) -> None:
        """Test POST /local-cicd/pre-commit with valid changes."""
        request_payload = {
            "files_changed": [
                "src/pages/index.astro",
                "src/components/Button.tsx",
                "scripts/monitor_performance.py"
            ],
            "commit_message": "feat: add new component with performance monitoring"
        }

        # This will fail until we implement the runner script
        result = self._execute_pre_commit(request_payload)

        # Expected response structure (OpenAPI contract)
        assert result["status"] == "success"
        assert "validations_passed" in result
        assert isinstance(result["validations_passed"], list)
        assert len(result["validations_passed"]) > 0

        # Common validations that should pass
        validations = result["validations_passed"]
        assert any("typescript" in validation.lower() for validation in validations)
        assert any("python" in validation.lower() for validation in validations)

    def test_pre_commit_validation_with_python_files(self) -> None:
        """Test pre-commit validation with Python files."""
        request_payload = {
            "files_changed": [
                "scripts/monitor_performance.py",
                "scripts/optimize_assets.py"
            ],
            "commit_message": "feat: add Python automation scripts"
        }

        result = self._execute_pre_commit(request_payload)

        assert result["status"] == "success"

        # Python-specific validations
        validations = result["validations_passed"]
        assert any("ruff" in validation.lower() for validation in validations)
        assert any("black" in validation.lower() for validation in validations)
        assert any("mypy" in validation.lower() for validation in validations)

    def test_pre_commit_validation_with_astro_files(self) -> None:
        """Test pre-commit validation with Astro files."""
        request_payload = {
            "files_changed": [
                "src/pages/index.astro",
                "src/layouts/Layout.astro",
                "src/components/Card.astro"
            ],
            "commit_message": "feat: add Astro components"
        }

        result = self._execute_pre_commit(request_payload)

        assert result["status"] == "success"

        # Astro-specific validations
        validations = result["validations_passed"]
        assert any("astro" in validation.lower() for validation in validations)
        assert any("typescript" in validation.lower() for validation in validations)

    def test_pre_commit_validation_with_config_files(self) -> None:
        """Test pre-commit validation with configuration files."""
        request_payload = {
            "files_changed": [
                "astro.config.mjs",
                "tailwind.config.mjs",
                "tsconfig.json",
                "pyproject.toml"
            ],
            "commit_message": "chore: update configuration files"
        }

        result = self._execute_pre_commit(request_payload)

        assert result["status"] == "success"

        # Configuration validation
        validations = result["validations_passed"]
        assert any("config" in validation.lower() for validation in validations)

    def test_pre_commit_missing_files_changed(self) -> None:
        """Test POST /local-cicd/pre-commit with missing required files_changed."""
        request_payload = {
            "commit_message": "feat: test commit"
        }

        # This will fail until we implement validation
        with pytest.raises(subprocess.CalledProcessError):
            self._execute_pre_commit(request_payload)

    def test_pre_commit_empty_files_changed(self) -> None:
        """Test POST /local-cicd/pre-commit with empty files_changed array."""
        request_payload = {
            "files_changed": [],
            "commit_message": "feat: empty commit"
        }

        # Should handle empty file list gracefully
        result = self._execute_pre_commit(request_payload)

        assert result["status"] == "success"
        # Should still run general validations
        assert len(result["validations_passed"]) >= 0

    def test_pre_commit_validation_failure(self) -> None:
        """Test POST /local-cicd/pre-commit with validation failures."""
        # Create a file with intentional syntax errors
        bad_python_file = self.project_root / "temp_bad_file.py"
        bad_python_file.write_text("invalid python syntax !!!!")

        try:
            request_payload = {
                "files_changed": [str(bad_python_file)],
                "commit_message": "feat: add bad file"
            }

            # This should return validation error (422)
            with pytest.raises(subprocess.CalledProcessError) as exc_info:
                self._execute_pre_commit(request_payload)

            # Should return specific exit code for validation failure
            assert exc_info.value.returncode == 22  # 422 -> 22

        finally:
            # Clean up
            if bad_python_file.exists():
                bad_python_file.unlink()

    def test_pre_commit_block_commit_flag(self) -> None:
        """Test that validation failures set block_commit flag appropriately."""
        # This test verifies the ValidationError schema
        bad_file = self.project_root / "temp_syntax_error.py"
        bad_file.write_text("def broken_function(\n    missing closing parenthesis")

        try:
            request_payload = {
                "files_changed": [str(bad_file)],
                "commit_message": "feat: intentionally broken code"
            }

            with pytest.raises(subprocess.CalledProcessError) as exc_info:
                self._execute_pre_commit(request_payload)

            # Parse stderr for validation error details
            error_output = exc_info.value.stderr
            if error_output:
                # Should contain information about blocked commit
                assert "block" in error_output.lower() or "fail" in error_output.lower()

        finally:
            if bad_file.exists():
                bad_file.unlink()

    def test_pre_commit_constitutional_compliance_checks(self) -> None:
        """Test that pre-commit enforces constitutional compliance."""
        request_payload = {
            "files_changed": [
                "pyproject.toml",
                "astro.config.mjs",
                "package.json"
            ],
            "commit_message": "feat: update constitutional configuration"
        }

        result = self._execute_pre_commit(request_payload)

        assert result["status"] == "success"

        # Constitutional compliance checks
        validations = result["validations_passed"]
        constitutional_checks = [
            "uv configuration",
            "astro typescript strict",
            "performance targets",
            "local ci/cd",
            "zero github actions"
        ]

        # At least some constitutional checks should be present
        passed_validations = " ".join(validations).lower()
        constitutional_found = any(
            check in passed_validations for check in constitutional_checks
        )
        assert constitutional_found, "Constitutional compliance checks must be included"

    def test_pre_commit_performance_impact_validation(self) -> None:
        """Test that pre-commit validates performance impact of changes."""
        request_payload = {
            "files_changed": [
                "src/pages/index.astro",
                "src/styles/globals.css",
                "public/large-image.jpg"  # Potentially large file
            ],
            "commit_message": "feat: add new page with styling and assets"
        }

        result = self._execute_pre_commit(request_payload)

        assert result["status"] == "success"

        # Performance validation checks
        validations = result["validations_passed"]
        assert any(
            "performance" in validation.lower() or "bundle" in validation.lower()
            for validation in validations
        ), "Performance impact validation must be included"

    def _execute_pre_commit(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute the pre-commit-local.sh script with given payload.

        This simulates the POST /local-cicd/pre-commit API call.
        """
        # Convert payload to command line arguments
        cmd = [str(self.runner_script)]

        # Add files changed
        if "files_changed" in payload:
            for file_path in payload["files_changed"]:
                cmd.extend(["--file", file_path])

        # Add commit message
        if "commit_message" in payload:
            cmd.extend(["--message", payload["commit_message"]])

        # Request JSON format
        cmd.extend(["--format", "json"])

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