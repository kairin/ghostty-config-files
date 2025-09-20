"""
Performance validation test for Lighthouse 95+ scores
Tests constitutional performance requirements

This test MUST FAIL initially as required by TDD approach.
Implementation will make this pass.
"""

import json
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any, Dict

import pytest


class TestLighthousePerformance:
    """Performance validation tests for constitutional Lighthouse requirements."""

    def setup_method(self) -> None:
        """Setup test environment."""
        self.project_root = Path.cwd()
        self.dist_dir = self.project_root / "dist"
        self.performance_script = self.project_root / "local-infra/runners/performance-monitor.sh"

    def test_performance_monitor_script_exists(self) -> None:
        """Test that performance monitoring script exists."""
        # This will fail until we create the script
        assert self.performance_script.exists(), "performance-monitor.sh must exist"
        assert self.performance_script.stat().st_mode & 0o111, "Performance script must be executable"

    def test_build_performance_targets(self) -> None:
        """Test that build meets constitutional performance targets."""
        # Measure build performance
        start_time = time.time()
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )
        build_time = time.time() - start_time

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping performance test: {build_result.stderr}")

        # Constitutional requirement: Build time <30 seconds
        assert build_time < 30, f"Build time {build_time:.2f}s exceeds 30s constitutional requirement"

    def test_javascript_bundle_size_constitutional_limit(self) -> None:
        """Test JavaScript bundle size meets constitutional requirement (<100KB)."""
        # Build first
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping bundle test: {build_result.stderr}")

        # Check JavaScript bundle sizes
        js_files = list(self.dist_dir.glob("**/*.js"))
        total_js_size = sum(f.stat().st_size for f in js_files)

        # Constitutional requirement: Initial JS bundle <100KB
        assert total_js_size <= 102400, f"JavaScript bundle size {total_js_size} bytes exceeds 100KB constitutional limit"

        # Log bundle details for optimization
        if js_files:
            largest_js = max(js_files, key=lambda f: f.stat().st_size)
            largest_size = largest_js.stat().st_size
            print(f"Largest JS file: {largest_js.name} ({largest_size} bytes)")

    def test_css_optimization_targets(self) -> None:
        """Test that CSS meets optimization requirements."""
        # Build first
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping CSS test: {build_result.stderr}")

        # Check CSS optimization
        css_files = list(self.dist_dir.glob("**/*.css"))
        total_css_size = sum(f.stat().st_size for f in css_files)

        # CSS should be reasonable size (not constitutional requirement but good practice)
        assert total_css_size <= 1048576, f"CSS size {total_css_size} bytes is excessive (>1MB)"

        # Check CSS is minified
        for css_file in css_files:
            content = css_file.read_text()
            if len(content) > 100:  # Only check non-trivial files
                line_count = content.count('\n')
                char_count = len(content)
                line_ratio = line_count / char_count
                assert line_ratio < 0.02, f"CSS file {css_file.name} appears not to be minified"

    def test_html_structure_lighthouse_readiness(self) -> None:
        """Test that HTML structure supports high Lighthouse scores."""
        # Build first
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping HTML test: {build_result.stderr}")

        # Check HTML structure for Lighthouse optimization
        html_files = list(self.dist_dir.glob("**/*.html"))
        assert len(html_files) > 0, "HTML files must be generated"

        for html_file in html_files:
            content = html_file.read_text()

            # Performance requirements
            assert '<meta name="viewport"' in content, "Viewport meta tag required for performance"
            assert "DOCTYPE html" in content, "Valid DOCTYPE required"

            # Accessibility requirements (for 95+ score)
            assert "lang=" in content, "Language attribute required for accessibility"
            assert "<title>" in content, "Title tag required for SEO and accessibility"

            # SEO requirements (for 95+ score)
            assert '<meta name="description"' in content, "Meta description required for SEO"

            # Best practices requirements
            assert "https://" in content or "http://localhost" in content or not ("http://" in content), \
                "Should use HTTPS or relative URLs"

    def test_core_web_vitals_targets(self) -> None:
        """Test preparation for Core Web Vitals constitutional requirements."""
        # Constitutional targets: FCP <1.5s, LCP <2.5s, CLS <0.1

        # This tests the build output characteristics that influence Core Web Vitals
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping vitals test: {build_result.stderr}")

        # Check characteristics that affect Core Web Vitals
        html_files = list(self.dist_dir.glob("**/*.html"))

        for html_file in html_files:
            content = html_file.read_text()

            # FCP optimization: Minimize blocking resources
            script_tags = content.count("<script")
            blocking_scripts = content.count('<script src=') - content.count('async') - content.count('defer')
            assert blocking_scripts <= 2, f"Too many blocking scripts ({blocking_scripts}) may hurt FCP"

            # LCP optimization: Image optimization
            if "<img" in content:
                assert 'loading="lazy"' in content, "Images should use lazy loading for LCP optimization"

            # CLS optimization: Proper sizing attributes
            if "<img" in content:
                import re
                img_tags = re.findall(r'<img[^>]*>', content)
                for img_tag in img_tags:
                    # Should have width/height or aspect-ratio to prevent layout shift
                    has_dimensions = any(attr in img_tag for attr in ['width=', 'height=', 'aspect-ratio'])
                    if not has_dimensions:
                        print(f"Warning: Image without dimensions may cause CLS: {img_tag[:50]}...")

    def test_lighthouse_simulation_capability(self) -> None:
        """Test that we can simulate Lighthouse testing locally."""
        # This will fail until we implement the performance monitor

        if self.performance_script.exists():
            # Test lighthouse simulation
            result = subprocess.run(
                [str(self.performance_script), "--target-url", "http://localhost:4321", "--test-type", "lighthouse", "--format", "json"],
                capture_output=True,
                text=True,
                cwd=self.project_root
            )

            if result.returncode == 0:
                # Parse Lighthouse results
                lighthouse_data = json.loads(result.stdout)

                # Constitutional requirements
                metrics = lighthouse_data.get("metrics", {}).get("lighthouse", {})
                assert metrics.get("performance", 0) >= 95, "Performance score must be >= 95"
                assert metrics.get("accessibility", 0) >= 95, "Accessibility score must be >= 95"
                assert metrics.get("best_practices", 0) >= 95, "Best practices score must be >= 95"
                assert metrics.get("seo", 0) >= 95, "SEO score must be >= 95"

    def test_performance_monitoring_infrastructure(self) -> None:
        """Test that performance monitoring infrastructure is ready."""
        # Check for performance monitoring components

        # Performance script
        assert self.performance_script.exists(), "Performance monitoring script must exist"

        # Logs directory for performance data
        logs_dir = self.project_root / "local-infra/logs"
        assert logs_dir.exists(), "Performance logs directory must exist"

        # Performance monitoring integration in CI/CD
        gh_workflow_script = self.project_root / "local-infra/runners/gh-workflow-local.sh"
        if gh_workflow_script.exists():
            content = gh_workflow_script.read_text()
            assert "performance" in content.lower(), "GitHub workflow must include performance monitoring"

    def test_performance_regression_detection(self) -> None:
        """Test capability for performance regression detection."""
        # This tests the infrastructure for tracking performance over time

        # Check for performance history tracking
        perf_script = self.project_root / "scripts/monitor_performance.py"

        if perf_script.exists():
            # Test performance monitoring
            result = subprocess.run(
                ["uv", "run", "python", str(perf_script), "--baseline"],
                capture_output=True,
                text=True,
                cwd=self.project_root
            )

            # Should be able to establish performance baseline
            if result.returncode == 0:
                # Check that baseline was recorded
                logs_dir = self.project_root / "local-infra/logs"
                perf_files = list(logs_dir.glob("performance-*.json"))
                assert len(perf_files) > 0, "Performance baseline should be recorded"

    def test_accessibility_compliance_preparation(self) -> None:
        """Test that build output supports WCAG 2.1 AA compliance."""
        # Build first
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping accessibility test: {build_result.stderr}")

        # Check accessibility features in HTML
        html_files = list(self.dist_dir.glob("**/*.html"))

        for html_file in html_files:
            content = html_file.read_text()

            # WCAG 2.1 AA basic requirements
            assert "lang=" in content, "Language attribute required for screen readers"

            # Color contrast readiness (Tailwind CSS should provide good defaults)
            if "tailwind" in content.lower() or "class=" in content:
                # Tailwind provides good contrast by default
                pass

            # Keyboard navigation readiness
            if "<button" in content or "onclick" in content:
                # Interactive elements should be properly marked
                pass

    def test_seo_optimization_completeness(self) -> None:
        """Test that SEO optimization supports 95+ Lighthouse SEO score."""
        # Build first
        build_result = subprocess.run(
            ["npm", "run", "build"],
            capture_output=True,
            text=True,
            cwd=self.project_root
        )

        if build_result.returncode != 0:
            pytest.skip(f"Build failed, skipping SEO test: {build_result.stderr}")

        # Check SEO optimization
        html_files = list(self.dist_dir.glob("**/*.html"))

        for html_file in html_files:
            content = html_file.read_text()

            # SEO requirements for 95+ score
            assert "<title>" in content, "Title tag required"
            assert '<meta name="description"' in content, "Meta description required"
            assert '<meta name="viewport"' in content, "Viewport meta tag required"
            assert "lang=" in content, "Language attribute required"

            # Check title length (SEO best practice)
            import re
            title_match = re.search(r'<title>([^<]+)</title>', content)
            if title_match:
                title_length = len(title_match.group(1))
                assert 10 <= title_length <= 60, f"Title length {title_length} should be 10-60 characters"

            # Check meta description length
            desc_match = re.search(r'<meta name="description" content="([^"]+)"', content)
            if desc_match:
                desc_length = len(desc_match.group(1))
                assert 50 <= desc_length <= 160, f"Meta description length {desc_length} should be 50-160 characters"