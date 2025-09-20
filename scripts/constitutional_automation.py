#!/usr/bin/env python3
"""
Constitutional Automation Hub
Central hub for all constitutional automation scripts.

Constitutional Requirements:
- Zero GitHub Actions consumption
- Local CI/CD automation
- Performance monitoring
- Configuration validation
- Update management
"""

import asyncio
import sys
from pathlib import Path
from typing import Dict, List, Optional

import click
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

console = Console()


class ConstitutionalAutomationHub:
    """Central hub for constitutional automation scripts."""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.scripts_dir = project_root / "scripts"

        # Available automation scripts
        self.scripts = {
            "update-checker": {
                "script": "update_checker.py",
                "description": "Smart version detection and update management",
                "category": "maintenance"
            },
            "config-validator": {
                "script": "config_validator.py",
                "description": "Constitutional configuration validation",
                "category": "validation"
            },
            "performance-monitor": {
                "script": "performance_monitor.py",
                "description": "Core Web Vitals tracking and performance monitoring",
                "category": "performance"
            },
            "ci-cd-runner": {
                "script": "ci_cd_runner.py",
                "description": "Local CI/CD workflow execution",
                "category": "automation"
            }
        }

        # Predefined workflows
        self.workflows = {
            "health-check": [
                ("config-validator", ["--strict"]),
                ("update-checker", ["--check-only"]),
                ("performance-monitor", ["--url", "http://localhost:4321"])
            ],
            "pre-commit": [
                ("config-validator", ["--fix"]),
                ("ci-cd-runner", ["--workflow", "validation"])
            ],
            "full-validation": [
                ("ci-cd-runner", ["--workflow", "all"])
            ],
            "performance-check": [
                ("ci-cd-runner", ["--workflow", "performance"]),
                ("performance-monitor", ["--continuous", "--interval", "60"])
            ]
        }

    def list_scripts(self) -> None:
        """List all available automation scripts."""
        console.print(Panel("🤖 Constitutional Automation Scripts", style="bold blue"))

        table = Table(title="Available Scripts")
        table.add_column("Script", style="cyan")
        table.add_column("Category", style="yellow")
        table.add_column("Description", style="white")

        for name, info in self.scripts.items():
            table.add_row(name, info["category"], info["description"])

        console.print(table)

    def list_workflows(self) -> None:
        """List all available workflows."""
        console.print(Panel("⚙️ Predefined Workflows", style="bold green"))

        table = Table(title="Available Workflows")
        table.add_column("Workflow", style="cyan")
        table.add_column("Steps", style="white")

        for name, steps in self.workflows.items():
            step_list = " → ".join([step[0] for step in steps])
            table.add_row(name, step_list)

        console.print(table)

    async def run_script(self, script_name: str, args: List[str]) -> int:
        """Run a specific automation script."""
        if script_name not in self.scripts:
            console.print(f"❌ Unknown script: {script_name}")
            return 1

        script_info = self.scripts[script_name]
        script_path = self.scripts_dir / script_info["script"]

        if not script_path.exists():
            console.print(f"❌ Script not found: {script_path}")
            return 1

        console.print(f"🚀 Running {script_name}: {script_info['description']}")

        # Execute the script
        process = await asyncio.create_subprocess_exec(
            "python", str(script_path), *args,
            cwd=self.project_root
        )

        return_code = await process.wait()

        if return_code == 0:
            console.print(f"✅ {script_name} completed successfully")
        else:
            console.print(f"❌ {script_name} failed with exit code {return_code}")

        return return_code

    async def run_workflow(self, workflow_name: str) -> int:
        """Run a predefined workflow."""
        if workflow_name not in self.workflows:
            console.print(f"❌ Unknown workflow: {workflow_name}")
            return 1

        console.print(Panel(f"🔄 Running {workflow_name} Workflow", style="bold blue"))

        steps = self.workflows[workflow_name]
        overall_success = True

        for i, (script_name, args) in enumerate(steps, 1):
            console.print(f"\n📋 Step {i}/{len(steps)}: {script_name}")

            return_code = await self.run_script(script_name, args)

            if return_code != 0:
                console.print(f"❌ Workflow failed at step {i}: {script_name}")
                overall_success = False
                break

        if overall_success:
            console.print(Panel("✅ [bold green]Workflow completed successfully![/bold green]", style="green"))
            return 0
        else:
            console.print(Panel("❌ [bold red]Workflow failed![/bold red]", style="red"))
            return 1

    def show_help(self) -> None:
        """Show comprehensive help information."""
        console.print(Panel("📚 Constitutional Automation Help", style="bold blue"))

        console.print("[bold]Usage Examples:[/bold]")
        console.print("• [cyan]python scripts/constitutional_automation.py list[/cyan] - List all scripts")
        console.print("• [cyan]python scripts/constitutional_automation.py run update-checker --check-only[/cyan] - Check for updates")
        console.print("• [cyan]python scripts/constitutional_automation.py workflow health-check[/cyan] - Run health check")
        console.print("• [cyan]python scripts/constitutional_automation.py workflow full-validation[/cyan] - Full validation")

        console.print("\n[bold]Constitutional Compliance:[/bold]")
        console.print("• All scripts enforce constitutional requirements")
        console.print("• Zero GitHub Actions consumption")
        console.print("• Local CI/CD workflow execution")
        console.print("• Performance target validation")
        console.print("• Configuration compliance checking")

        console.print("\n[bold]Quick Start:[/bold]")
        console.print("1. Run health check: [cyan]constitutional_automation.py workflow health-check[/cyan]")
        console.print("2. Before committing: [cyan]constitutional_automation.py workflow pre-commit[/cyan]")
        console.print("3. Full validation: [cyan]constitutional_automation.py workflow full-validation[/cyan]")


@click.group()
@click.option("--project-root", type=click.Path(exists=True), default=".", help="Project root directory")
@click.pass_context
def cli(ctx, project_root: str):
    """Constitutional Automation Hub - Central control for all automation scripts."""
    ctx.ensure_object(dict)
    ctx.obj['project_root'] = Path(project_root).resolve()
    ctx.obj['hub'] = ConstitutionalAutomationHub(ctx.obj['project_root'])


@cli.command()
@click.pass_context
def list(ctx):
    """List all available automation scripts."""
    hub = ctx.obj['hub']
    hub.list_scripts()


@cli.command()
@click.pass_context
def workflows(ctx):
    """List all available workflows."""
    hub = ctx.obj['hub']
    hub.list_workflows()


@cli.command()
@click.argument("script_name")
@click.argument("args", nargs=-1)
@click.pass_context
def run(ctx, script_name: str, args: tuple):
    """Run a specific automation script with arguments."""
    hub = ctx.obj['hub']

    async def run_async():
        return await hub.run_script(script_name, list(args))

    try:
        exit_code = asyncio.run(run_async())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        console.print("\n[yellow]Execution cancelled by user[/yellow]")
        sys.exit(1)


@cli.command()
@click.argument("workflow_name")
@click.pass_context
def workflow(ctx, workflow_name: str):
    """Run a predefined workflow."""
    hub = ctx.obj['hub']

    async def run_async():
        return await hub.run_workflow(workflow_name)

    try:
        exit_code = asyncio.run(run_async())
        sys.exit(exit_code)
    except KeyboardInterrupt:
        console.print("\n[yellow]Workflow cancelled by user[/yellow]")
        sys.exit(1)


@cli.command()
@click.pass_context
def help(ctx):
    """Show comprehensive help and usage examples."""
    hub = ctx.obj['hub']
    hub.show_help()


if __name__ == "__main__":
    cli()