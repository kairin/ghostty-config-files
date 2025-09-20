"""
Integration test for uv environment setup
Tests the complete uv Python environment initialization

This test MUST FAIL initially as required by TDD approach.
Implementation will make this pass.
"""

import subprocess
import sys
from pathlib import Path
from typing import Any, Dict

import pytest


class TestUvEnvironmentSetup:
    """Integration tests for uv Python environment setup."""

    def setup_method(self) -> None:
        """Setup test environment."""
        self.project_root = Path.cwd()
        self.pyproject_file = self.project_root / "pyproject.toml"
        self.venv_dir = self.project_root / ".venv"

    def test_uv_is_installed_and_version_compliant(self) -> None:
        """Test that uv is installed and meets version requirements (>=0.4.0)."""
        try:
            result = subprocess.run(
                ["uv", "--version"],
                capture_output=True,
                text=True,
                check=True
            )
            version_output = result.stdout.strip()

            # Extract version number
            version_str = version_output.split()[1]  # "uv 0.8.15" -> "0.8.15"
            major, minor, patch = map(int, version_str.split('.'))

            # Constitutional requirement: >=0.4.0
            assert major > 0 or (major == 0 and minor >= 4), f"uv version {version_str} does not meet >=0.4.0 requirement"

        except (subprocess.CalledProcessError, FileNotFoundError):
            pytest.fail("uv is not installed or not accessible in PATH")

    def test_pyproject_toml_exists_and_valid(self) -> None:
        """Test that pyproject.toml exists and has valid configuration."""
        assert self.pyproject_file.exists(), "pyproject.toml must exist"

        # Read and validate content
        content = self.pyproject_file.read_text()

        # Constitutional requirements
        assert "requires-python = \">=3.12\"" in content, "Python version must be >=3.12"
        assert "[tool.ruff]" in content, "Ruff configuration must be present"
        assert "[tool.black]" in content, "Black configuration must be present"
        assert "[tool.mypy]" in content, "MyPy configuration must be present"
        assert "strict = true" in content, "MyPy strict mode must be enabled"

    def test_virtual_environment_creation(self) -> None:
        """Test that uv can create a virtual environment."""
        # This might fail if venv doesn't exist yet
        if not self.venv_dir.exists():
            # Try to create it
            result = subprocess.run(
                ["uv", "sync"],
                capture_output=True,
                text=True,
                cwd=self.project_root
            )
            # This will fail until we have complete setup
            assert result.returncode == 0, f"uv sync failed: {result.stderr}"

        assert self.venv_dir.exists(), "Virtual environment directory must exist"
        assert self.venv_dir.is_dir(), "Virtual environment must be a directory"

    def test_python_version_in_venv(self) -> None:
        """Test that virtual environment uses correct Python version."""
        python_executable = self.venv_dir / "bin" / "python"
        if not python_executable.exists():
            # Try Windows path
            python_executable = self.venv_dir / "Scripts" / "python.exe"

        # This will fail until venv is properly set up
        assert python_executable.exists(), "Python executable must exist in virtual environment"

        result = subprocess.run(
            [str(python_executable), "--version"],
            capture_output=True,
            text=True,
            check=True
        )

        version_output = result.stdout.strip()
        # Extract version: "Python 3.12.11" -> "3.12.11"
        version_str = version_output.split()[1]
        major, minor = map(int, version_str.split('.')[:2])

        # Constitutional requirement: Python 3.12+
        assert major == 3 and minor >= 12, f"Python version {version_str} does not meet >=3.12 requirement"

    def test_dev_dependencies_installation(self) -> None:
        """Test that development dependencies are installed correctly."""
        # This will fail until we run uv sync
        result = subprocess.run(
            ["uv", "run", "python", "-c", "import ruff, black, mypy, pytest"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        assert result.returncode == 0, f"Development dependencies not installed: {result.stderr}"

    def test_ruff_configuration_and_execution(self) -> None:
        """Test that Ruff is configured and can run."""
        # This will fail until we have Python files to check
        result = subprocess.run(
            ["uv", "run", "ruff", "check", "."],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        # Should run without errors (even if no files found)
        # Exit code 0 (no issues) or specific codes are acceptable
        assert result.returncode in [0, 1], f"Ruff execution failed unexpectedly: {result.stderr}"

    def test_black_configuration_and_execution(self) -> None:
        """Test that Black is configured and can run."""
        result = subprocess.run(
            ["uv", "run", "black", "--check", "."],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        # Should run without critical errors
        assert result.returncode in [0, 1], f"Black execution failed unexpectedly: {result.stderr}"

    def test_mypy_configuration_and_execution(self) -> None:
        """Test that MyPy is configured and can run."""
        # This will fail until we have typed Python files
        result = subprocess.run(
            ["uv", "run", "mypy", "."],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        # MyPy may fail without Python files, but should not crash
        assert result.returncode in [0, 1, 2], f"MyPy execution failed unexpectedly: {result.stderr}"

    def test_pytest_execution(self) -> None:
        """Test that pytest can run (may have no tests initially)."""
        result = subprocess.run(
            ["uv", "run", "pytest", "--version"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        assert result.returncode == 0, f"Pytest not working: {result.stderr}"
        assert "pytest" in result.stdout, "Pytest version output not as expected"

    def test_uv_lock_file_generation(self) -> None:
        """Test that uv generates and maintains lock file."""
        lock_file = self.project_root / "uv.lock"

        if not lock_file.exists():
            # Try to generate it
            result = subprocess.run(
                ["uv", "lock"],
                capture_output=True,
                text=True,
                cwd=self.project_root
            )
            assert result.returncode == 0, f"uv lock failed: {result.stderr}"

        assert lock_file.exists(), "uv.lock file must exist for reproducible builds"

    def test_constitutional_python_management_compliance(self) -> None:
        """Test that setup complies with uv-First Python Management principle."""
        # Verify no other Python package managers are in use
        forbidden_files = [
            "requirements.txt",
            "setup.py",
            "Pipfile",
            "poetry.lock",
            "conda.yml",
            "environment.yml"
        ]

        for forbidden_file in forbidden_files:
            file_path = self.project_root / forbidden_file
            assert not file_path.exists(), f"Forbidden package manager file {forbidden_file} found. uv-First principle violated."

    def test_environment_reproducibility(self) -> None:
        """Test that environment can be reproduced from lock file."""
        # This tests the constitutional requirement for reproducible builds
        lock_file = self.project_root / "uv.lock"

        if lock_file.exists():
            # Test that sync works from lock file
            result = subprocess.run(
                ["uv", "sync", "--frozen"],
                capture_output=True,
                text=True,
                cwd=self.project_root
            )
            assert result.returncode == 0, f"Environment reproduction from lock file failed: {result.stderr}"

    def test_performance_benchmarks(self) -> None:
        """Test that uv meets performance expectations."""
        import time

        # Benchmark dependency resolution (should be faster than pip)
        start_time = time.time()
        result = subprocess.run(
            ["uv", "sync", "--no-install"],  # Just resolve, don't install
            capture_output=True,
            text=True,
            cwd=self.project_root
        )
        resolution_time = time.time() - start_time

        # uv should be significantly faster than traditional tools
        assert resolution_time < 30, f"Dependency resolution took {resolution_time}s, should be <30s"
        assert result.returncode == 0, f"Dependency resolution failed: {result.stderr}"