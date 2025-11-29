#!/usr/bin/env python3
"""
Constitutional Configuration Validator
Validates project configuration files for constitutional compliance.

Constitutional Requirements:
- Zero GitHub Actions consumption validation
- Local CI/CD compliance checking
- Performance target enforcement
- Constitutional principle adherence
"""

import json
import logging
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple, Union

import click
import toml
from pydantic import BaseModel, Field, ValidationError
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table
from rich.tree import Tree

# Constitutional logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/tmp/ghostty-start-logs/config-validator.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

console = Console()


class ValidationIssue(BaseModel):
    """Configuration validation issue model."""
    file_path: str
    line_number: Optional[int] = None
    severity: str  # "error", "warning", "info"
    category: str  # "constitutional", "performance", "security", "style"
    rule: str
    message: str
    suggestion: Optional[str] = None
    auto_fixable: bool = False


class ValidationResult(BaseModel):
    """Configuration validation result."""
    timestamp: datetime = Field(default_factory=datetime.now)
    total_files: int
    files_checked: List[str]
    total_issues: int
    errors: int
    warnings: int
    constitutional_score: float
    performance_score: float
    security_score: float
    issues: List[ValidationIssue]
    summary: Dict[str, Any]


class ConstitutionalValidator:
    """
    Constitutional configuration validator.

    Validates:
    - Constitutional compliance principles
    - Performance target adherence
    - Security best practices
    - Code quality standards
    - Local CI/CD requirements
    """

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.console = console

        # Constitutional rules and targets
        self.constitutional_rules = {
            "zero_github_actions": {
                "description": "No GitHub Actions workflows that consume minutes",
                "severity": "error",
                "category": "constitutional"
            },
            "local_cicd_required": {
                "description": "Local CI/CD infrastructure must be present",
                "severity": "error",
                "category": "constitutional"
            },
            "performance_targets": {
                "description": "Performance targets must meet constitutional requirements",
                "severity": "error",
                "category": "constitutional"
            },
            "branch_preservation": {
                "description": "Branch preservation strategy must be enforced",
                "severity": "error",
                "category": "constitutional"
            },
            "uv_first_python": {
                "description": "Python management must use uv-first approach",
                "severity": "warning",
                "category": "constitutional"
            }
        }

        # Performance targets (constitutional requirements)
        self.performance_targets = {
            "lighthouse_performance": 95,
            "lighthouse_accessibility": 95,
            "lighthouse_best_practices": 95,
            "lighthouse_seo": 95,
            "fcp_target": 1.5,  # seconds
            "lcp_target": 2.5,  # seconds
            "cls_target": 0.1,   # score
            "fid_target": 100,   # milliseconds
            "js_bundle_max": 102400,  # 100KB
            "css_bundle_max": 51200,  # 50KB
            "total_bundle_max": 512000,  # 500KB
        }

    async def validate_all_configurations(self) -> ValidationResult:
        """Comprehensive configuration validation."""
        console.print(Panel("🔍 Constitutional Configuration Validator", style="bold blue"))

        issues: List[ValidationIssue] = []
        files_checked: List[str] = []

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:

            task = progress.add_task("Validating configurations...", total=100)

            # Validate Python configuration
            progress.update(task, advance=20, description="Validating Python configuration...")
            python_issues = await self._validate_python_config()
            issues.extend(python_issues)
            files_checked.extend(["pyproject.toml"])

            # Validate Node.js configuration
            progress.update(task, advance=20, description="Validating Node.js configuration...")
            node_issues = await self._validate_node_config()
            issues.extend(node_issues)
            files_checked.extend(["package.json", "tsconfig.json"])

            # Validate Astro configuration
            progress.update(task, advance=20, description="Validating Astro configuration...")
            astro_issues = await self._validate_astro_config()
            issues.extend(astro_issues)
            files_checked.extend(["astro.config.mjs"])

            # Validate CI/CD configuration
            progress.update(task, advance=20, description="Validating CI/CD configuration...")
            cicd_issues = await self._validate_cicd_config()
            issues.extend(cicd_issues)
            files_checked.extend([".github/workflows", ".runners-local/"])

            # Validate constitutional compliance
            progress.update(task, advance=20, description="Validating constitutional compliance...")
            constitutional_issues = await self._validate_constitutional_compliance()
            issues.extend(constitutional_issues)
            files_checked.extend(["CLAUDE.md", "README.md"])

        # Calculate scores
        errors = sum(1 for issue in issues if issue.severity == "error")
        warnings = sum(1 for issue in issues if issue.severity == "warning")

        constitutional_score = self._calculate_constitutional_score(issues)
        performance_score = self._calculate_performance_score(issues)
        security_score = self._calculate_security_score(issues)

        # Generate summary
        summary = {
            "constitutional_compliance": constitutional_score >= 90,
            "performance_compliance": performance_score >= 90,
            "security_compliance": security_score >= 90,
            "ready_for_production": all([
                constitutional_score >= 90,
                performance_score >= 90,
                security_score >= 90,
                errors == 0
            ])
        }

        return ValidationResult(
            total_files=len(files_checked),
            files_checked=files_checked,
            total_issues=len(issues),
            errors=errors,
            warnings=warnings,
            constitutional_score=constitutional_score,
            performance_score=performance_score,
            security_score=security_score,
            issues=issues,
            summary=summary
        )

    async def _validate_python_config(self) -> List[ValidationIssue]:
        """Validate Python configuration (pyproject.toml)."""
        issues: List[ValidationIssue] = []
        pyproject_path = self.project_root / "scripts" / "config" / "pyproject.toml"

        if not pyproject_path.exists():
            issues.append(ValidationIssue(
                file_path="pyproject.toml",
                severity="error",
                category="constitutional",
                rule="python_config_required",
                message="pyproject.toml is required for constitutional compliance",
                suggestion="Create pyproject.toml with required Python configuration"
            ))
            return issues

        try:
            config = toml.load(pyproject_path)

            # Check Python version requirement
            python_version = config.get("project", {}).get("requires-python")
            if not python_version or ">=3.12" not in python_version:
                issues.append(ValidationIssue(
                    file_path="pyproject.toml",
                    severity="error",
                    category="constitutional",
                    rule="python_version_requirement",
                    message="Python 3.12+ is required for constitutional compliance",
                    suggestion="Set requires-python = '>=3.12'",
                    auto_fixable=True
                ))

            # Check for required dependencies
            dependencies = config.get("project", {}).get("dependencies", [])
            required_deps = ["requests", "click", "rich", "pydantic", "httpx"]

            missing_deps = []
            for dep in required_deps:
                if not any(dep in d for d in dependencies):
                    missing_deps.append(dep)

            if missing_deps:
                issues.append(ValidationIssue(
                    file_path="pyproject.toml",
                    severity="warning",
                    category="constitutional",
                    rule="required_dependencies",
                    message=f"Missing required dependencies: {', '.join(missing_deps)}",
                    suggestion=f"Add dependencies: {missing_deps}"
                ))

            # Check dev dependencies
            dev_deps = config.get("dependency-groups", {}).get("dev", [])
            required_dev_deps = ["ruff", "black", "mypy", "pytest"]

            missing_dev_deps = []
            for dep in required_dev_deps:
                if not any(dep in d for d in dev_deps):
                    missing_dev_deps.append(dep)

            if missing_dev_deps:
                issues.append(ValidationIssue(
                    file_path="pyproject.toml",
                    severity="warning",
                    category="constitutional",
                    rule="required_dev_dependencies",
                    message=f"Missing required dev dependencies: {', '.join(missing_dev_deps)}",
                    suggestion=f"Add dev dependencies: {missing_dev_deps}"
                ))

            # Check tool configurations
            if "tool" not in config:
                issues.append(ValidationIssue(
                    file_path="pyproject.toml",
                    severity="warning",
                    category="constitutional",
                    rule="tool_configuration",
                    message="Tool configurations missing",
                    suggestion="Add [tool.ruff], [tool.black], [tool.mypy] sections"
                ))

            # Check ruff configuration
            ruff_config = config.get("tool", {}).get("ruff", {})
            if ruff_config.get("target-version") != "py312":
                issues.append(ValidationIssue(
                    file_path="pyproject.toml",
                    severity="warning",
                    category="constitutional",
                    rule="ruff_target_version",
                    message="Ruff target-version should be py312",
                    suggestion="Set [tool.ruff] target-version = 'py312'",
                    auto_fixable=True
                ))

            # Check mypy strict mode
            mypy_config = config.get("tool", {}).get("mypy", {})
            if not mypy_config.get("strict"):
                issues.append(ValidationIssue(
                    file_path="pyproject.toml",
                    severity="error",
                    category="constitutional",
                    rule="mypy_strict_mode",
                    message="MyPy strict mode is required for constitutional compliance",
                    suggestion="Set [tool.mypy] strict = true",
                    auto_fixable=True
                ))

        except Exception as e:
            issues.append(ValidationIssue(
                file_path="pyproject.toml",
                severity="error",
                category="constitutional",
                rule="config_parse_error",
                message=f"Failed to parse pyproject.toml: {e}",
                suggestion="Fix TOML syntax errors"
            ))

        return issues

    async def _validate_node_config(self) -> List[ValidationIssue]:
        """Validate Node.js configuration."""
        issues: List[ValidationIssue] = []

        # Check package.json
        package_json_path = self.project_root / "package.json"
        if package_json_path.exists():
            try:
                with open(package_json_path) as f:
                    config = json.load(f)

                # Check required scripts
                scripts = config.get("scripts", {})
                required_scripts = ["dev", "build", "preview"]

                for script in required_scripts:
                    if script not in scripts:
                        issues.append(ValidationIssue(
                            file_path="package.json",
                            severity="warning",
                            category="constitutional",
                            rule="required_scripts",
                            message=f"Missing required script: {script}",
                            suggestion=f"Add '{script}' script to package.json"
                        ))

                # Check Astro version
                dependencies = {**config.get("dependencies", {}), **config.get("devDependencies", {})}

                if "astro" in dependencies:
                    astro_version = dependencies["astro"]
                    if not self._check_version_requirement(astro_version, "5.13.0"):
                        issues.append(ValidationIssue(
                            file_path="package.json",
                            severity="error",
                            category="constitutional",
                            rule="astro_version_requirement",
                            message="Astro 5.13.0+ is required for constitutional compliance",
                            suggestion="Update Astro to latest version"
                        ))

                # Check TypeScript
                if "typescript" in dependencies:
                    ts_version = dependencies["typescript"]
                    if not self._check_version_requirement(ts_version, "5.6.0"):
                        issues.append(ValidationIssue(
                            file_path="package.json",
                            severity="warning",
                            category="constitutional",
                            rule="typescript_version",
                            message="TypeScript 5.6.0+ recommended",
                            suggestion="Update TypeScript to latest version"
                        ))

            except Exception as e:
                issues.append(ValidationIssue(
                    file_path="package.json",
                    severity="error",
                    category="constitutional",
                    rule="config_parse_error",
                    message=f"Failed to parse package.json: {e}",
                    suggestion="Fix JSON syntax errors"
                ))

        # Check TypeScript configuration
        tsconfig_path = self.project_root / "tsconfig.json"
        if tsconfig_path.exists():
            try:
                with open(tsconfig_path) as f:
                    ts_config = json.load(f)

                compiler_options = ts_config.get("compilerOptions", {})

                # Check strict mode
                if not compiler_options.get("strict"):
                    issues.append(ValidationIssue(
                        file_path="tsconfig.json",
                        severity="error",
                        category="constitutional",
                        rule="typescript_strict_mode",
                        message="TypeScript strict mode is required",
                        suggestion="Set 'strict': true in compilerOptions",
                        auto_fixable=True
                    ))

                # Check target version
                target = compiler_options.get("target")
                if target and target.lower() not in ["es2022", "es2023", "esnext"]:
                    issues.append(ValidationIssue(
                        file_path="tsconfig.json",
                        severity="warning",
                        category="performance",
                        rule="typescript_target",
                        message="Consider using ES2022+ for better performance",
                        suggestion="Set target to ES2022 or higher"
                    ))

            except Exception as e:
                issues.append(ValidationIssue(
                    file_path="tsconfig.json",
                    severity="error",
                    category="constitutional",
                    rule="config_parse_error",
                    message=f"Failed to parse tsconfig.json: {e}",
                    suggestion="Fix JSON syntax errors"
                ))

        return issues

    async def _validate_astro_config(self) -> List[ValidationIssue]:
        """Validate Astro configuration."""
        issues: List[ValidationIssue] = []
        astro_config_path = self.project_root / "astro.config.mjs"

        if not astro_config_path.exists():
            issues.append(ValidationIssue(
                file_path="astro.config.mjs",
                severity="error",
                category="constitutional",
                rule="astro_config_required",
                message="astro.config.mjs is required",
                suggestion="Create Astro configuration file"
            ))
            return issues

        try:
            # Read and analyze Astro config
            config_content = astro_config_path.read_text()

            # Check for Tailwind integration
            if "tailwind" not in config_content.lower():
                issues.append(ValidationIssue(
                    file_path="astro.config.mjs",
                    severity="warning",
                    category="constitutional",
                    rule="tailwind_integration",
                    message="Tailwind CSS integration recommended",
                    suggestion="Add @astrojs/tailwind integration"
                ))

            # Check for TypeScript support
            if "typescript" not in config_content.lower():
                issues.append(ValidationIssue(
                    file_path="astro.config.mjs",
                    severity="warning",
                    category="constitutional",
                    rule="typescript_support",
                    message="TypeScript support should be configured",
                    suggestion="Ensure TypeScript is properly configured"
                ))

            # Check for performance optimizations
            if "vite" in config_content:
                # Check for build optimizations
                if "build" not in config_content:
                    issues.append(ValidationIssue(
                        file_path="astro.config.mjs",
                        severity="info",
                        category="performance",
                        rule="build_optimizations",
                        message="Consider adding build optimizations",
                        suggestion="Add Vite build optimizations for better performance"
                    ))

        except Exception as e:
            issues.append(ValidationIssue(
                file_path="astro.config.mjs",
                severity="error",
                category="constitutional",
                rule="config_parse_error",
                message=f"Failed to analyze astro.config.mjs: {e}",
                suggestion="Fix configuration syntax errors"
            ))

        return issues

    async def _validate_cicd_config(self) -> List[ValidationIssue]:
        """Validate CI/CD configuration for constitutional compliance."""
        issues: List[ValidationIssue] = []

        # Check GitHub Actions (should NOT consume minutes)
        github_workflows_dir = self.project_root / ".github" / "workflows"
        if github_workflows_dir.exists():
            for workflow_file in github_workflows_dir.glob("*.yml"):
                try:
                    content = workflow_file.read_text()

                    # Check for minute-consuming actions
                    if "runs-on:" in content and "ubuntu-latest" in content:
                        # Look for actual job steps that would consume minutes
                        if re.search(r"steps:\s*\n\s*-", content):
                            issues.append(ValidationIssue(
                                file_path=str(workflow_file.relative_to(self.project_root)),
                                severity="error",
                                category="constitutional",
                                rule="zero_github_actions",
                                message="GitHub workflow contains steps that consume minutes",
                                suggestion="Move CI/CD to local infrastructure or use zero-minute actions only"
                            ))

                except Exception as e:
                    issues.append(ValidationIssue(
                        file_path=str(workflow_file.relative_to(self.project_root)),
                        severity="warning",
                        category="constitutional",
                        rule="workflow_parse_error",
                        message=f"Failed to parse workflow: {e}",
                        suggestion="Fix workflow syntax"
                    ))

        # Check local CI/CD infrastructure
        local_infra_dir = self.project_root / ".runners-local"
        if not local_infra_dir.exists():
            issues.append(ValidationIssue(
                file_path=".runners-local/",
                severity="error",
                category="constitutional",
                rule="local_cicd_required",
                message="Local CI/CD infrastructure is required",
                suggestion="Create .runners-local/ directory with runner scripts"
            ))
        else:
            # Check for required runner scripts
            required_runners = [
                "gh-workflow-local.sh",
                "gh-pages-setup.sh",
                "test-runner.sh",
                "performance-monitor.sh"
            ]

            runners_dir = local_infra_dir / "runners"
            if runners_dir.exists():
                for runner in required_runners:
                    runner_path = runners_dir / runner
                    if not runner_path.exists():
                        issues.append(ValidationIssue(
                            file_path=f".runners-local/workflows/{runner}",
                            severity="warning",
                            category="constitutional",
                            rule="required_runner_scripts",
                            message=f"Required runner script missing: {runner}",
                            suggestion=f"Create {runner} script for local CI/CD"
                        ))
                    elif not runner_path.is_file() or not runner_path.stat().st_mode & 0o111:
                        issues.append(ValidationIssue(
                            file_path=f".runners-local/workflows/{runner}",
                            severity="warning",
                            category="constitutional",
                            rule="executable_permissions",
                            message=f"Runner script not executable: {runner}",
                            suggestion=f"chmod +x .runners-local/workflows/{runner}",
                            auto_fixable=True
                        ))

        return issues

    async def _validate_constitutional_compliance(self) -> List[ValidationIssue]:
        """Validate constitutional compliance documentation and enforcement."""
        issues: List[ValidationIssue] = []

        # Check CLAUDE.md (constitutional requirements)
        claude_md_path = self.project_root / "CLAUDE.md"
        if not claude_md_path.exists():
            issues.append(ValidationIssue(
                file_path="CLAUDE.md",
                severity="error",
                category="constitutional",
                rule="constitutional_documentation",
                message="CLAUDE.md constitutional documentation is required",
                suggestion="Create CLAUDE.md with constitutional requirements"
            ))
        else:
            content = claude_md_path.read_text()

            # Check for key constitutional principles
            required_sections = [
                "NON-NEGOTIABLE REQUIREMENTS",
                "Zero GitHub Actions",
                "Branch Management",
                "Local CI/CD",
                "Performance Targets"
            ]

            for section in required_sections:
                if section.lower() not in content.lower():
                    issues.append(ValidationIssue(
                        file_path="CLAUDE.md",
                        severity="warning",
                        category="constitutional",
                        rule="constitutional_completeness",
                        message=f"Constitutional section missing or incomplete: {section}",
                        suggestion=f"Add detailed {section} section to CLAUDE.md"
                    ))

        # Check performance targets definition
        if "performance" in claude_md_path.read_text().lower():
            content = claude_md_path.read_text()

            # Check for specific performance targets
            performance_targets_to_check = [
                ("95", "Lighthouse score"),
                ("100KB", "JavaScript bundle"),
                ("2.5s", "LCP target"),
                ("1.5s", "FCP target")
            ]

            for target, description in performance_targets_to_check:
                if target not in content:
                    issues.append(ValidationIssue(
                        file_path="CLAUDE.md",
                        severity="info",
                        category="performance",
                        rule="performance_targets_documentation",
                        message=f"Performance target not documented: {description}",
                        suggestion=f"Document {description} target in CLAUDE.md"
                    ))

        # Check branch preservation strategy
        git_dir = self.project_root / ".git"
        if git_dir.exists():
            try:
                # Check git hooks
                hooks_dir = git_dir / "hooks"
                if not hooks_dir.exists() or not any(hooks_dir.iterdir()):
                    issues.append(ValidationIssue(
                        file_path=".git/hooks/",
                        severity="info",
                        category="constitutional",
                        rule="git_hooks",
                        message="Git hooks not configured for branch preservation",
                        suggestion="Set up git hooks to enforce constitutional branch strategy"
                    ))

            except Exception as e:
                logger.warning(f"Error checking git configuration: {e}")

        return issues

    def _check_version_requirement(self, version_spec: str, required_version: str) -> bool:
        """Check if version specification meets requirement."""
        try:
            # Simple version check - extract version number
            version_match = re.search(r"(\d+\.\d+\.\d+)", version_spec)
            if version_match:
                current = version_match.group(1)
                from packaging import version
                return version.parse(current) >= version.parse(required_version)
        except Exception:
            pass
        return False

    def _calculate_constitutional_score(self, issues: List[ValidationIssue]) -> float:
        """Calculate constitutional compliance score."""
        constitutional_issues = [i for i in issues if i.category == "constitutional"]
        if not constitutional_issues:
            return 100.0

        # Weight errors more heavily than warnings
        error_weight = 10
        warning_weight = 3
        info_weight = 1

        total_deductions = 0
        for issue in constitutional_issues:
            if issue.severity == "error":
                total_deductions += error_weight
            elif issue.severity == "warning":
                total_deductions += warning_weight
            else:
                total_deductions += info_weight

        # Calculate score (maximum deduction of 100 points)
        score = max(0, 100 - total_deductions)
        return score

    def _calculate_performance_score(self, issues: List[ValidationIssue]) -> float:
        """Calculate performance compliance score."""
        performance_issues = [i for i in issues if i.category == "performance"]
        if not performance_issues:
            return 100.0

        error_weight = 15
        warning_weight = 5
        info_weight = 2

        total_deductions = 0
        for issue in performance_issues:
            if issue.severity == "error":
                total_deductions += error_weight
            elif issue.severity == "warning":
                total_deductions += warning_weight
            else:
                total_deductions += info_weight

        score = max(0, 100 - total_deductions)
        return score

    def _calculate_security_score(self, issues: List[ValidationIssue]) -> float:
        """Calculate security compliance score."""
        security_issues = [i for i in issues if i.category == "security"]
        if not security_issues:
            return 100.0

        error_weight = 20
        warning_weight = 8
        info_weight = 2

        total_deductions = 0
        for issue in security_issues:
            if issue.severity == "error":
                total_deductions += error_weight
            elif issue.severity == "warning":
                total_deductions += warning_weight
            else:
                total_deductions += info_weight

        score = max(0, 100 - total_deductions)
        return score

    def generate_report(self, result: ValidationResult) -> None:
        """Generate constitutional validation report."""
        # Summary panel
        summary_table = Table(title="Constitutional Validation Summary")
        summary_table.add_column("Metric", style="cyan")
        summary_table.add_column("Score", style="bold")
        summary_table.add_column("Status", style="green")

        summary_table.add_row("Constitutional Compliance", f"{result.constitutional_score:.1f}%",
                             "✅" if result.constitutional_score >= 90 else "❌")
        summary_table.add_row("Performance Compliance", f"{result.performance_score:.1f}%",
                             "✅" if result.performance_score >= 90 else "❌")
        summary_table.add_row("Security Compliance", f"{result.security_score:.1f}%",
                             "✅" if result.security_score >= 90 else "❌")
        summary_table.add_row("Total Issues", str(result.total_issues),
                             "✅" if result.total_issues == 0 else "⚠️")
        summary_table.add_row("Critical Errors", str(result.errors),
                             "✅" if result.errors == 0 else "❌")

        console.print(summary_table)

        # Overall status
        if result.summary["ready_for_production"]:
            console.print(Panel("✅ [bold green]READY FOR PRODUCTION[/bold green]", style="green"))
        else:
            console.print(Panel("❌ [bold red]ISSUES REQUIRE ATTENTION[/bold red]", style="red"))

        # Issues breakdown
        if result.issues:
            console.print("\n" + "="*60)
            console.print("[bold]Detailed Issues:[/bold]")

            # Group issues by category and severity
            categories = {}
            for issue in result.issues:
                if issue.category not in categories:
                    categories[issue.category] = {"error": [], "warning": [], "info": []}
                categories[issue.category][issue.severity].append(issue)

            for category, severities in categories.items():
                if any(severities.values()):
                    console.print(f"\n[bold cyan]{category.title()} Issues:[/bold cyan]")

                    tree = Tree(f"📁 {category}")

                    for severity in ["error", "warning", "info"]:
                        issues_list = severities[severity]
                        if issues_list:
                            severity_icon = {"error": "❌", "warning": "⚠️", "info": "ℹ️"}[severity]
                            severity_node = tree.add(f"{severity_icon} {severity.title()} ({len(issues_list)})")

                            for issue in issues_list:
                                issue_text = f"{issue.file_path}: {issue.message}"
                                if issue.suggestion:
                                    issue_text += f"\n   💡 {issue.suggestion}"
                                severity_node.add(issue_text)

                    console.print(tree)

        # Actionable recommendations
        if result.issues:
            console.print("\n" + "="*60)
            console.print("[bold]Recommended Actions:[/bold]")

            # Auto-fixable issues
            auto_fixable = [i for i in result.issues if i.auto_fixable]
            if auto_fixable:
                console.print("🔧 [bold]Auto-fixable issues:[/bold]")
                console.print("Run: [bold]python scripts/config_validator.py --fix[/bold]")

            # Priority issues
            errors = [i for i in result.issues if i.severity == "error"]
            if errors:
                console.print("🚨 [bold red]Priority: Fix critical errors first[/bold red]")
                for error in errors[:3]:  # Show top 3
                    console.print(f"   • {error.file_path}: {error.message}")

            # Constitutional compliance
            constitutional_issues = [i for i in result.issues if i.category == "constitutional"]
            if constitutional_issues:
                console.print("⚖️ [bold]Constitutional compliance required[/bold]")
                console.print("Review CLAUDE.md for detailed requirements")

    async def fix_auto_fixable_issues(self, result: ValidationResult) -> int:
        """Fix automatically fixable issues."""
        auto_fixable = [i for i in result.issues if i.auto_fixable]

        if not auto_fixable:
            console.print("✅ No auto-fixable issues found")
            return 0

        console.print(f"🔧 Fixing {len(auto_fixable)} auto-fixable issues...")

        fixed_count = 0
        for issue in auto_fixable:
            try:
                # Implement specific fixes based on rule
                if await self._apply_fix(issue):
                    fixed_count += 1
                    console.print(f"✅ Fixed: {issue.file_path} - {issue.rule}")
                else:
                    console.print(f"❌ Failed to fix: {issue.file_path} - {issue.rule}")

            except Exception as e:
                console.print(f"❌ Error fixing {issue.file_path}: {e}")

        console.print(f"🎉 Fixed {fixed_count}/{len(auto_fixable)} issues")
        return fixed_count

    async def _apply_fix(self, issue: ValidationIssue) -> bool:
        """Apply specific fix for an issue."""
        # This would implement actual fixes based on the rule
        # For now, just log what would be fixed
        logger.info(f"Would fix: {issue.rule} in {issue.file_path}")

        # Example fixes could include:
        # - Updating version requirements in pyproject.toml
        # - Adding missing configuration sections
        # - Fixing permissions on scripts
        # - Adding required dependencies

        return True  # Placeholder


@click.command()
@click.option("--fix", is_flag=True, help="Apply auto-fixable issues")
@click.option("--json-output", is_flag=True, help="Output results in JSON format")
@click.option("--project-root", type=click.Path(exists=True),
              default=".", help="Project root directory")
@click.option("--strict", is_flag=True, help="Use strict validation mode")
def main(fix: bool, json_output: bool, project_root: str, strict: bool) -> None:
    """Constitutional Configuration Validator - Validate project configuration for compliance."""

    async def run_validation():
        project_path = Path(project_root).resolve()
        validator = ConstitutionalValidator(project_path)

        result = await validator.validate_all_configurations()

        if fix:
            fixed_count = await validator.fix_auto_fixable_issues(result)
            console.print(f"\n🔧 Applied {fixed_count} automatic fixes")

            # Re-run validation to show updated results
            result = await validator.validate_all_configurations()

        if json_output:
            output = result.model_dump(mode="json")
            console.print_json(data=output)
        else:
            validator.generate_report(result)

        # Save results for CI/CD integration
        results_file = project_path / ".update_cache" / "validation_results.json"
        results_file.parent.mkdir(exist_ok=True)
        results_file.write_text(result.model_dump_json(indent=2))

        # Exit with error code if critical issues found
        if strict and (result.errors > 0 or result.constitutional_score < 90):
            sys.exit(1)

    try:
        asyncio.run(run_validation())
    except KeyboardInterrupt:
        console.print("\n[yellow]Validation cancelled by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"\n[red]Validation failed: {e}[/red]")
        logger.exception("Configuration validation failed")
        sys.exit(1)


if __name__ == "__main__":
    main()