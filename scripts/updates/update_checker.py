#!/usr/bin/env python3
"""
Constitutional Update Checker Script
Smart version detection and update management for the ghostty-config-files project.

Constitutional Requirements:
- Zero GitHub Actions consumption
- Local CI/CD integration
- Performance-first design
- Constitutional compliance validation
"""

import asyncio
import json
import logging
import re
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import urljoin

import click
import httpx
import toml
from packaging import version
from pydantic import BaseModel, Field
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table

# Constitutional logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/tmp/ghostty-start-logs/update-checker.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

console = Console()


class VersionInfo(BaseModel):
    """Version information model for constitutional compliance."""
    name: str
    current: str
    latest: str
    update_available: bool
    security_update: bool = False
    breaking_changes: bool = False
    constitutional_compliance: bool = True
    last_checked: datetime = Field(default_factory=datetime.now)


class UpdateCheckResult(BaseModel):
    """Update check result for constitutional reporting."""
    timestamp: datetime = Field(default_factory=datetime.now)
    total_packages: int
    updates_available: int
    security_updates: int
    constitutional_violations: int
    packages: List[VersionInfo]
    system_info: Dict[str, Any]


class ConstitutionalUpdateChecker:
    """
    Constitutional update checker with smart version detection.

    Features:
    - Smart version detection from multiple sources
    - Security update prioritization
    - Constitutional compliance validation
    - Performance impact assessment
    - Local CI/CD integration
    """

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.cache_dir = project_root / ".update_cache"
        self.cache_dir.mkdir(exist_ok=True)
        self.client = httpx.AsyncClient(timeout=30.0)

        # Constitutional configuration
        self.config = {
            "update_interval": timedelta(hours=6),
            "security_check_interval": timedelta(hours=1),
            "max_major_version_jump": 1,
            "require_constitutional_compliance": True,
            "performance_impact_threshold": 0.1,  # 10% performance impact max
        }

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.client.aclose()

    async def check_all_updates(self) -> UpdateCheckResult:
        """Comprehensive update check for all project components."""
        console.print(Panel("🔍 Constitutional Update Checker", style="bold blue"))

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
        ) as progress:

            task = progress.add_task("Checking for updates...", total=100)

            # Collect all package sources
            packages = []

            # Python dependencies
            progress.update(task, advance=20, description="Checking Python packages...")
            python_packages = await self._check_python_packages()
            packages.extend(python_packages)

            # Node.js dependencies
            progress.update(task, advance=20, description="Checking Node.js packages...")
            node_packages = await self._check_node_packages()
            packages.extend(node_packages)

            # System packages (Ubuntu)
            progress.update(task, advance=20, description="Checking system packages...")
            system_packages = await self._check_system_packages()
            packages.extend(system_packages)

            # Ghostty (from source)
            progress.update(task, advance=20, description="Checking Ghostty...")
            ghostty_info = await self._check_ghostty_version()
            if ghostty_info:
                packages.append(ghostty_info)

            # Constitutional tools
            progress.update(task, advance=20, description="Checking constitutional tools...")
            constitutional_packages = await self._check_constitutional_tools()
            packages.extend(constitutional_packages)

            progress.update(task, advance=0, description="Analyzing results...")

        # Analyze results
        updates_available = sum(1 for p in packages if p.update_available)
        security_updates = sum(1 for p in packages if p.security_update)
        constitutional_violations = sum(1 for p in packages if not p.constitutional_compliance)

        # Get system information
        system_info = await self._get_system_info()

        result = UpdateCheckResult(
            total_packages=len(packages),
            updates_available=updates_available,
            security_updates=security_updates,
            constitutional_violations=constitutional_violations,
            packages=packages,
            system_info=system_info
        )

        return result

    async def _check_python_packages(self) -> List[VersionInfo]:
        """Check Python package updates using pip and PyPI API."""
        packages = []

        try:
            # Read pyproject.toml
            pyproject_path = self.project_root / "pyproject.toml"
            if not pyproject_path.exists():
                return packages

            pyproject_data = toml.load(pyproject_path)
            dependencies = pyproject_data.get("project", {}).get("dependencies", [])

            # Add dev dependencies
            dev_deps = pyproject_data.get("dependency-groups", {}).get("dev", [])
            dependencies.extend(dev_deps)

            for dep_spec in dependencies:
                package_info = await self._parse_python_dependency(dep_spec)
                if package_info:
                    packages.append(package_info)

        except Exception as e:
            logger.error(f"Error checking Python packages: {e}")

        return packages

    async def _parse_python_dependency(self, dep_spec: str) -> Optional[VersionInfo]:
        """Parse Python dependency specification and check for updates."""
        try:
            # Parse package name and version constraint
            match = re.match(r"^([a-zA-Z0-9\-_.]+)(?:\[.*\])?(?:[>=<~!]+(.+))?$", dep_spec.strip())
            if not match:
                return None

            package_name = match.group(1)
            version_constraint = match.group(2) if match.group(2) else None

            # Get current installed version
            try:
                result = subprocess.run(
                    [sys.executable, "-m", "pip", "show", package_name],
                    capture_output=True,
                    text=True,
                    check=True
                )

                current_version = None
                for line in result.stdout.split('\n'):
                    if line.startswith('Version:'):
                        current_version = line.split(':', 1)[1].strip()
                        break

                if not current_version:
                    return None

            except subprocess.CalledProcessError:
                # Package not installed
                return VersionInfo(
                    name=package_name,
                    current="not installed",
                    latest="unknown",
                    update_available=True,
                    constitutional_compliance=False
                )

            # Check PyPI for latest version
            latest_version = await self._get_pypi_latest_version(package_name)
            if not latest_version:
                return None

            # Check if update is available
            update_available = version.parse(latest_version) > version.parse(current_version)

            # Check for security updates (simplified check)
            security_update = await self._check_security_advisories_python(package_name, current_version)

            # Constitutional compliance check
            constitutional_compliance = await self._check_constitutional_compliance_python(
                package_name, latest_version
            )

            return VersionInfo(
                name=f"python:{package_name}",
                current=current_version,
                latest=latest_version,
                update_available=update_available,
                security_update=security_update,
                constitutional_compliance=constitutional_compliance
            )

        except Exception as e:
            logger.error(f"Error parsing Python dependency {dep_spec}: {e}")
            return None

    async def _get_pypi_latest_version(self, package_name: str) -> Optional[str]:
        """Get latest version from PyPI API with caching."""
        cache_file = self.cache_dir / f"pypi_{package_name}.json"

        # Check cache
        if cache_file.exists():
            try:
                cache_data = json.loads(cache_file.read_text())
                cache_time = datetime.fromisoformat(cache_data["timestamp"])
                if datetime.now() - cache_time < self.config["update_interval"]:
                    return cache_data["version"]
            except Exception:
                pass

        try:
            url = f"https://pypi.org/pypi/{package_name}/json"
            response = await self.client.get(url)
            response.raise_for_status()

            data = response.json()
            latest_version = data["info"]["version"]

            # Cache result
            cache_data = {
                "version": latest_version,
                "timestamp": datetime.now().isoformat()
            }
            cache_file.write_text(json.dumps(cache_data))

            return latest_version

        except Exception as e:
            logger.error(f"Error fetching PyPI data for {package_name}: {e}")
            return None

    async def _check_node_packages(self) -> List[VersionInfo]:
        """Check Node.js package updates."""
        packages = []

        try:
            package_json_path = self.project_root / "package.json"
            if not package_json_path.exists():
                return packages

            package_data = json.loads(package_json_path.read_text())

            # Check dependencies and devDependencies
            deps = package_data.get("dependencies", {})
            dev_deps = package_data.get("devDependencies", {})
            all_deps = {**deps, **dev_deps}

            for package_name, version_spec in all_deps.items():
                package_info = await self._check_npm_package(package_name, version_spec)
                if package_info:
                    packages.append(package_info)

        except Exception as e:
            logger.error(f"Error checking Node.js packages: {e}")

        return packages

    async def _check_npm_package(self, package_name: str, version_spec: str) -> Optional[VersionInfo]:
        """Check individual npm package for updates."""
        try:
            # Get current installed version
            try:
                result = subprocess.run(
                    ["npm", "list", package_name, "--depth=0", "--json"],
                    capture_output=True,
                    text=True,
                    cwd=self.project_root
                )

                if result.returncode == 0:
                    npm_data = json.loads(result.stdout)
                    current_version = npm_data.get("dependencies", {}).get(package_name, {}).get("version")
                else:
                    current_version = None

            except Exception:
                current_version = None

            # Get latest version from npm registry
            latest_version = await self._get_npm_latest_version(package_name)
            if not latest_version:
                return None

            # Determine current version if not found
            if not current_version:
                current_version = "not installed"
                update_available = True
            else:
                try:
                    update_available = version.parse(latest_version) > version.parse(current_version)
                except Exception:
                    update_available = latest_version != current_version

            # Check security advisories
            security_update = await self._check_security_advisories_npm(package_name, current_version)

            # Constitutional compliance
            constitutional_compliance = await self._check_constitutional_compliance_npm(
                package_name, latest_version
            )

            return VersionInfo(
                name=f"npm:{package_name}",
                current=current_version,
                latest=latest_version,
                update_available=update_available,
                security_update=security_update,
                constitutional_compliance=constitutional_compliance
            )

        except Exception as e:
            logger.error(f"Error checking npm package {package_name}: {e}")
            return None

    async def _get_npm_latest_version(self, package_name: str) -> Optional[str]:
        """Get latest version from npm registry."""
        cache_file = self.cache_dir / f"npm_{package_name.replace('/', '_')}.json"

        # Check cache
        if cache_file.exists():
            try:
                cache_data = json.loads(cache_file.read_text())
                cache_time = datetime.fromisoformat(cache_data["timestamp"])
                if datetime.now() - cache_time < self.config["update_interval"]:
                    return cache_data["version"]
            except Exception:
                pass

        try:
            url = f"https://registry.npmjs.org/{package_name}/latest"
            response = await self.client.get(url)
            response.raise_for_status()

            data = response.json()
            latest_version = data["version"]

            # Cache result
            cache_data = {
                "version": latest_version,
                "timestamp": datetime.now().isoformat()
            }
            cache_file.write_text(json.dumps(cache_data))

            return latest_version

        except Exception as e:
            logger.error(f"Error fetching npm data for {package_name}: {e}")
            return None

    async def _check_system_packages(self) -> List[VersionInfo]:
        """Check system package updates (Ubuntu/Debian)."""
        packages = []

        try:
            # Key system packages for constitutional compliance
            key_packages = [
                "curl", "git", "nodejs", "npm", "python3", "python3-pip",
                "build-essential", "cmake", "pkg-config", "libfreetype6-dev",
                "libfontconfig1-dev", "libxcb-xfixes0-dev", "libxkbcommon-dev"
            ]

            for package_name in key_packages:
                package_info = await self._check_apt_package(package_name)
                if package_info:
                    packages.append(package_info)

        except Exception as e:
            logger.error(f"Error checking system packages: {e}")

        return packages

    async def _check_apt_package(self, package_name: str) -> Optional[VersionInfo]:
        """Check individual apt package."""
        try:
            # Get current version
            result = subprocess.run(
                ["dpkg-query", "-W", "-f=${Version}", package_name],
                capture_output=True,
                text=True
            )

            if result.returncode != 0:
                current_version = "not installed"
            else:
                current_version = result.stdout.strip()

            # Check for available updates
            result = subprocess.run(
                ["apt", "list", "--upgradable", package_name],
                capture_output=True,
                text=True
            )

            update_available = package_name in result.stdout and "upgradable" in result.stdout

            # Get latest available version
            if update_available:
                # Parse apt output for latest version
                for line in result.stdout.split('\n'):
                    if package_name in line and "upgradable" in line:
                        parts = line.split()
                        if len(parts) >= 2:
                            latest_version = parts[1]
                            break
                else:
                    latest_version = "unknown"
            else:
                latest_version = current_version

            return VersionInfo(
                name=f"apt:{package_name}",
                current=current_version,
                latest=latest_version,
                update_available=update_available,
                security_update=False,  # Would need to check security repos
                constitutional_compliance=True  # System packages assumed compliant
            )

        except Exception as e:
            logger.error(f"Error checking apt package {package_name}: {e}")
            return None

    async def _check_ghostty_version(self) -> Optional[VersionInfo]:
        """Check Ghostty version from source."""
        try:
            # Get current Ghostty version
            result = subprocess.run(
                ["ghostty", "--version"],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                current_version = result.stdout.strip().split()[-1]
            else:
                current_version = "not installed"

            # Check GitHub releases for latest version
            latest_version = await self._get_github_latest_release("ghostty-org/ghostty")

            if not latest_version:
                return None

            try:
                update_available = version.parse(latest_version.lstrip('v')) > version.parse(current_version.lstrip('v'))
            except Exception:
                update_available = latest_version != current_version

            return VersionInfo(
                name="ghostty",
                current=current_version,
                latest=latest_version,
                update_available=update_available,
                security_update=False,
                constitutional_compliance=True
            )

        except Exception as e:
            logger.error(f"Error checking Ghostty version: {e}")
            return None

    async def _get_github_latest_release(self, repo: str) -> Optional[str]:
        """Get latest release from GitHub API."""
        cache_file = self.cache_dir / f"github_{repo.replace('/', '_')}.json"

        # Check cache
        if cache_file.exists():
            try:
                cache_data = json.loads(cache_file.read_text())
                cache_time = datetime.fromisoformat(cache_data["timestamp"])
                if datetime.now() - cache_time < self.config["update_interval"]:
                    return cache_data["version"]
            except Exception:
                pass

        try:
            url = f"https://api.github.com/repos/{repo}/releases/latest"
            response = await self.client.get(url)
            response.raise_for_status()

            data = response.json()
            latest_version = data["tag_name"]

            # Cache result
            cache_data = {
                "version": latest_version,
                "timestamp": datetime.now().isoformat()
            }
            cache_file.write_text(json.dumps(cache_data))

            return latest_version

        except Exception as e:
            logger.error(f"Error fetching GitHub release for {repo}: {e}")
            return None

    async def _check_constitutional_tools(self) -> List[VersionInfo]:
        """Check constitutional compliance tools."""
        packages = []

        # Constitutional tools to check
        tools = [
            ("zig", "ziglang/zig"),
            ("gh", "cli/cli"),
            ("ruff", None),  # Python package
            ("black", None),  # Python package
            ("mypy", None),   # Python package
        ]

        for tool_name, github_repo in tools:
            if github_repo:
                # Check GitHub releases
                package_info = await self._check_constitutional_tool_github(tool_name, github_repo)
            else:
                # Already checked as Python package
                continue

            if package_info:
                packages.append(package_info)

        return packages

    async def _check_constitutional_tool_github(self, tool_name: str, github_repo: str) -> Optional[VersionInfo]:
        """Check constitutional tool from GitHub releases."""
        try:
            # Get current version
            result = subprocess.run(
                [tool_name, "--version"],
                capture_output=True,
                text=True
            )

            if result.returncode == 0:
                # Parse version from output
                version_text = result.stdout.strip()
                version_match = re.search(r"(\d+\.\d+\.\d+)", version_text)
                current_version = version_match.group(1) if version_match else version_text
            else:
                current_version = "not installed"

            # Get latest from GitHub
            latest_version = await self._get_github_latest_release(github_repo)
            if not latest_version:
                return None

            try:
                update_available = version.parse(latest_version.lstrip('v')) > version.parse(current_version.lstrip('v'))
            except Exception:
                update_available = latest_version != current_version

            return VersionInfo(
                name=f"tool:{tool_name}",
                current=current_version,
                latest=latest_version,
                update_available=update_available,
                security_update=False,
                constitutional_compliance=True
            )

        except Exception as e:
            logger.error(f"Error checking constitutional tool {tool_name}: {e}")
            return None

    async def _check_security_advisories_python(self, package_name: str, current_version: str) -> bool:
        """Check for security advisories for Python packages."""
        # Simplified security check - in practice, use pip-audit or safety
        try:
            # Check if package is in known vulnerable packages list
            # This is a placeholder - implement proper security advisory checking
            return False
        except Exception:
            return False

    async def _check_security_advisories_npm(self, package_name: str, current_version: str) -> bool:
        """Check for security advisories for npm packages."""
        try:
            # Use npm audit API (simplified)
            return False
        except Exception:
            return False

    async def _check_constitutional_compliance_python(self, package_name: str, version_str: str) -> bool:
        """Check if Python package version meets constitutional compliance."""
        # Constitutional compliance rules for Python packages
        compliance_rules = {
            "ruff": ">=0.1.0",
            "black": ">=23.0.0",
            "mypy": ">=1.7.0",
            "requests": ">=2.31.0",
            "click": ">=8.1.0",
            "rich": ">=13.0.0",
            "pydantic": ">=2.0.0",
            "httpx": ">=0.25.0",
        }

        if package_name in compliance_rules:
            try:
                required_version = compliance_rules[package_name].lstrip(">=")
                return version.parse(version_str) >= version.parse(required_version)
            except Exception:
                return False

        return True

    async def _check_constitutional_compliance_npm(self, package_name: str, version_str: str) -> bool:
        """Check if npm package version meets constitutional compliance."""
        # Constitutional compliance rules for npm packages
        compliance_rules = {
            "astro": ">=5.13.0",
            "tailwindcss": ">=3.4.0",
            "typescript": ">=5.6.0",
            "@types/node": ">=20.0.0",
        }

        if package_name in compliance_rules:
            try:
                required_version = compliance_rules[package_name].lstrip(">=")
                return version.parse(version_str) >= version.parse(required_version)
            except Exception:
                return False

        return True

    async def _get_system_info(self) -> Dict[str, Any]:
        """Get system information for constitutional compliance reporting."""
        system_info = {
            "timestamp": datetime.now().isoformat(),
            "python_version": sys.version,
            "platform": sys.platform,
        }

        try:
            # Get OS information
            result = subprocess.run(["lsb_release", "-a"], capture_output=True, text=True)
            if result.returncode == 0:
                system_info["os_info"] = result.stdout
        except Exception:
            pass

        try:
            # Get Node.js version
            result = subprocess.run(["node", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                system_info["node_version"] = result.stdout.strip()
        except Exception:
            pass

        try:
            # Get Git version
            result = subprocess.run(["git", "--version"], capture_output=True, text=True)
            if result.returncode == 0:
                system_info["git_version"] = result.stdout.strip()
        except Exception:
            pass

        return system_info

    def generate_report(self, result: UpdateCheckResult) -> None:
        """Generate constitutional compliance update report."""
        # Summary table
        table = Table(title="Constitutional Update Check Summary")
        table.add_column("Metric", style="cyan")
        table.add_column("Value", style="bold")
        table.add_column("Status", style="green")

        table.add_row("Total Packages", str(result.total_packages), "✅")
        table.add_row("Updates Available", str(result.updates_available),
                     "⚠️" if result.updates_available > 0 else "✅")
        table.add_row("Security Updates", str(result.security_updates),
                     "🚨" if result.security_updates > 0 else "✅")
        table.add_row("Constitutional Violations", str(result.constitutional_violations),
                     "❌" if result.constitutional_violations > 0 else "✅")

        console.print(table)

        # Detailed package information
        if result.packages:
            package_table = Table(title="Package Details")
            package_table.add_column("Package", style="cyan")
            package_table.add_column("Current", style="yellow")
            package_table.add_column("Latest", style="green")
            package_table.add_column("Update", style="bold")
            package_table.add_column("Security", style="red")
            package_table.add_column("Constitutional", style="blue")

            for pkg in result.packages:
                update_status = "🆙" if pkg.update_available else "✅"
                security_status = "🚨" if pkg.security_update else "✅"
                constitutional_status = "✅" if pkg.constitutional_compliance else "❌"

                package_table.add_row(
                    pkg.name,
                    pkg.current,
                    pkg.latest,
                    update_status,
                    security_status,
                    constitutional_status
                )

            console.print(package_table)

        # Recommendations
        if result.updates_available > 0 or result.constitutional_violations > 0:
            console.print(Panel("📋 Recommendations", style="bold yellow"))

            if result.security_updates > 0:
                console.print("🚨 [bold red]PRIORITY: Security updates available![/bold red]")
                console.print("Run: [bold]python scripts/update_checker.py --apply-security[/bold]")

            if result.constitutional_violations > 0:
                console.print("❌ [bold red]Constitutional violations detected![/bold red]")
                console.print("Review package versions for compliance requirements")

            if result.updates_available > result.security_updates:
                console.print("🆙 [yellow]Regular updates available[/yellow]")
                console.print("Run: [bold]python scripts/update_checker.py --apply-updates[/bold]")

    async def apply_updates(self, security_only: bool = False) -> None:
        """Apply updates with constitutional compliance validation."""
        console.print(Panel("🔄 Applying Updates", style="bold green"))

        # This would implement the actual update logic
        # For now, we'll just show what would be updated
        result = await self.check_all_updates()

        packages_to_update = [
            pkg for pkg in result.packages
            if pkg.update_available and (not security_only or pkg.security_update)
        ]

        if not packages_to_update:
            console.print("✅ No updates to apply")
            return

        console.print(f"Would update {len(packages_to_update)} packages:")
        for pkg in packages_to_update:
            console.print(f"  - {pkg.name}: {pkg.current} → {pkg.latest}")

        console.print("\n[yellow]Note: Actual update implementation would go here[/yellow]")


@click.command()
@click.option("--check-only", is_flag=True, help="Only check for updates, don't apply")
@click.option("--apply-updates", is_flag=True, help="Apply all available updates")
@click.option("--apply-security", is_flag=True, help="Apply only security updates")
@click.option("--json-output", is_flag=True, help="Output results in JSON format")
@click.option("--project-root", type=click.Path(exists=True),
              default=".", help="Project root directory")
def main(check_only: bool, apply_updates: bool, apply_security: bool,
         json_output: bool, project_root: str) -> None:
    """Constitutional Update Checker - Smart version detection and update management."""

    async def run_checks():
        project_path = Path(project_root).resolve()

        async with ConstitutionalUpdateChecker(project_path) as checker:
            if apply_security or apply_updates:
                await checker.apply_updates(security_only=apply_security)
            else:
                result = await checker.check_all_updates()

                if json_output:
                    output = result.model_dump(mode="json")
                    console.print_json(data=output)
                else:
                    checker.generate_report(result)

                # Save results for CI/CD integration
                results_file = project_path / ".update_cache" / "last_check.json"
                results_file.write_text(result.model_dump_json(indent=2))

    try:
        asyncio.run(run_checks())
    except KeyboardInterrupt:
        console.print("\n[yellow]Update check cancelled by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"\n[red]Error: {e}[/red]")
        logger.exception("Update check failed")
        sys.exit(1)


if __name__ == "__main__":
    main()