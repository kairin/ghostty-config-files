"""
Integration test for Astro build workflow
Tests the complete Astro.build static site generation workflow

This test MUST FAIL initially as required by TDD approach.
Implementation will make this pass.
"""

import json
import subprocess
import tempfile
from pathlib import Path
from typing import Any, Dict

import pytest


class TestAstroBuildWorkflow:
    """Integration tests for complete Astro.build workflow."""

    def setup_method(self) -> None:
        """Setup test environment."""
        self.project_root = Path.cwd()
        self.astro_config = self.project_root / "astro.config.mjs"
        self.package_json = self.project_root / "package.json"
        self.src_dir = self.project_root / "src"
        self.dist_dir = self.project_root / "dist"

    def test_astro_config_exists_and_valid(self) -> None:
        """Test that Astro configuration exists and is valid."""
        assert self.astro_config.exists(), "astro.config.mjs must exist"

        # Read and validate basic structure
        content = self.astro_config.read_text()
        assert "export default defineConfig" in content, "Astro config must export defineConfig"
        assert "integrations" in content, "Astro config must include integrations"
        assert "tailwind" in content, "Tailwind integration must be configured"

    def test_astro_dependencies_installed(self) -> None:
        """Test that all required Astro dependencies are installed."""
        # Check package.json has required dependencies
        assert self.package_json.exists(), "package.json must exist"

        # Verify key dependencies are present
        result = subprocess.run(
            ["npm", "list", "astro", "@astrojs/tailwind", "typescript"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        # Should list dependencies without errors
        assert result.returncode == 0, f"Required dependencies not installed: {result.stderr}"

    def test_astro_typescript_strict_mode(self) -> None:
        """Test that TypeScript strict mode is enforced."""
        tsconfig_file = self.project_root / "tsconfig.json"

        # This will fail until we create tsconfig.json
        assert tsconfig_file.exists(), "tsconfig.json must exist for TypeScript support"

        content = tsconfig_file.read_text()
        config_data = json.loads(content)

        # Constitutional requirement: TypeScript strict mode
        assert config_data.get("compilerOptions", {}).get("strict") is True, "TypeScript strict mode must be enabled"

    def test_src_directory_structure(self) -> None:
        """Test that Astro source directory structure is correct."""
        # This will fail until we create the structure
        assert self.src_dir.exists(), "src/ directory must exist"

        required_subdirs = ["components", "layouts", "pages", "styles", "lib"]
        for subdir in required_subdirs:
            subdir_path = self.src_dir / subdir
            assert subdir_path.exists(), f"src/{subdir}/ directory must exist"

    def test_astro_build_command_execution(self) -> None:
        """Test that Astro build command executes successfully."""
        # This will fail until we have a complete Astro project
        result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        assert result.returncode == 0, f"Astro build failed: {result.stderr}"

    def test_build_output_structure(self) -> None:
        """Test that Astro build produces correct output structure."""
        # Run build first
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping output test: {build_result.stderr}")

        # This will fail until we have a working build
        assert self.dist_dir.exists(), "dist/ directory must be created by build"

        # Check for essential output files
        index_html = self.dist_dir / "index.html"
        assert index_html.exists(), "index.html must be generated"

        # Verify HTML structure
        html_content = index_html.read_text()
        assert "<!DOCTYPE html>" in html_content, "Generated HTML must be valid"
        assert "<html" in html_content, "HTML structure must be complete"

    def test_astro_dev_server_startup(self) -> None:
        """Test that Astro development server can start."""
        # This will fail until we have package.json scripts configured
        # Test that dev script exists
        with open(self.package_json) as f:
            package_data = json.load(f)

        scripts = package_data.get("scripts", {})
        assert "dev" in scripts, "npm run dev script must be configured"
        assert "astro dev" in scripts["dev"], "dev script must use astro dev"

    def test_constitutional_performance_targets(self) -> None:
        """Test that build output meets constitutional performance requirements."""
        # Build first
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping performance test: {build_result.stderr}")

        # Check JavaScript bundle size (constitutional requirement: <100KB)
        js_files = list(self.dist_dir.glob("**/*.js"))
        total_js_size = sum(f.stat().st_size for f in js_files)

        # Constitutional requirement: Initial JS bundle <100KB
        assert total_js_size <= 102400, f"JavaScript bundle size {total_js_size} bytes exceeds 100KB limit"

    def test_tailwind_css_integration(self) -> None:
        """Test that Tailwind CSS is properly integrated with Astro."""
        # This will fail until we have Tailwind configured
        tailwind_config = self.project_root / "tailwind.config.mjs"
        assert tailwind_config.exists(), "tailwind.config.mjs must exist"

        # Check that Tailwind is included in build output
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping Tailwind test: {build_result.stderr}")

        # Look for CSS files in output
        css_files = list(self.dist_dir.glob("**/*.css"))
        assert len(css_files) > 0, "CSS files must be generated in build output"

        # Check that at least one CSS file contains Tailwind classes
        tailwind_found = False
        for css_file in css_files:
            content = css_file.read_text()
            if any(keyword in content for keyword in ["--tw-", ".prose", ".container"]):
                tailwind_found = True
                break

        assert tailwind_found, "Tailwind CSS must be included in build output"

    def test_astro_islands_architecture(self) -> None:
        """Test that Astro's islands architecture is working correctly."""
        # This tests the fundamental Astro concept
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping islands test: {build_result.stderr}")

        # Check that build output is primarily static
        html_files = list(self.dist_dir.glob("**/*.html"))
        js_files = list(self.dist_dir.glob("**/*.js"))

        assert len(html_files) > 0, "Static HTML files must be generated"

        # Islands architecture should minimize JavaScript
        if js_files:
            total_js_size = sum(f.stat().st_size for f in js_files)
            total_html_size = sum(f.stat().st_size for f in html_files)

            # JS should be minimal compared to HTML (islands approach)
            js_ratio = total_js_size / (total_html_size + total_js_size)
            assert js_ratio < 0.3, "JavaScript should be minimal in islands architecture"

    def test_hot_reload_performance(self) -> None:
        """Test that hot reload meets performance requirements."""
        # This tests the constitutional requirement for <1 second hot reload
        # Note: This is a basic test - full testing would require actual dev server

        # Check that dev dependencies support hot reload
        with open(self.package_json) as f:
            package_data = json.load(f)

        # Verify Astro version supports efficient hot reload
        dependencies = {**package_data.get("dependencies", {}), **package_data.get("devDependencies", {})}
        astro_version = dependencies.get("astro", "")

        # Constitutional requirement: Astro >=4.0
        if astro_version:
            # Extract version number (handles ranges like "^5.13.9")
            version_num = astro_version.lstrip("^~>=")
            major_version = int(version_num.split(".")[0])
            assert major_version >= 4, f"Astro version {astro_version} does not meet >=4.0 requirement"

    def test_build_time_performance(self) -> None:
        """Test that build time meets constitutional requirements (<30 seconds)."""
        import time

        # Measure build time
        start_time = time.time()
        result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )
        build_time = time.time() - start_time

        if result.returncode != 0:
            pytest.skip(f"Build failed, skipping performance test: {result.stderr}")

        # Constitutional requirement: Build time <30 seconds
        assert build_time < 30, f"Build time {build_time:.2f}s exceeds 30s constitutional requirement"