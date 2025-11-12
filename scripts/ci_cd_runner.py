#!/usr/bin/env python3
"""
Constitutional CI/CD Runner
Local CI/CD integration scripts for zero GitHub Actions consumption.

Constitutional Requirements:
- Zero GitHub Actions consumption
- Local workflow execution
- Constitutional compliance validation
- Performance target enforcement
- Branch preservation strategy
"""

import asyncio
import json
import logging
import os
import shutil
import subprocess
import sys
import tempfile
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import click
from pydantic import BaseModel, Field
from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from rich.table import Table
from rich.tree import Tree

# Constitutional logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/tmp/ghostty-start-logs/ci-cd-runner.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

console = Console()


class WorkflowStep(BaseModel):
    """Individual workflow step model."""
    name: str
    description: str
    command: List[str]
    working_directory: Optional[str] = None
    timeout: int = 300  # 5 minutes default
    required: bool = True
    constitutional_check: bool = False


class WorkflowResult(BaseModel):
    """Workflow execution result."""
    step_name: str
    success: bool
    duration: float
    output: str
    error: Optional[str] = None
    constitutional_compliance: bool = True
    exit_code: int = 0


class CICDResult(BaseModel):
    """Complete CI/CD execution result."""
    timestamp: datetime = Field(default_factory=datetime.now)
    workflow_name: str
    total_steps: int
    successful_steps: int
    failed_steps: int
    total_duration: float
    constitutional_compliance: bool
    step_results: List[WorkflowResult]
    summary: Dict[str, Any]


class ConstitutionalCICD:
    """
    Constitutional CI/CD runner for local workflow execution.

    Features:
    - Zero GitHub Actions consumption
    - Local workflow execution
    - Constitutional compliance validation
    - Performance target enforcement
    - Branch preservation
    - Parallel step execution where possible
    """

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.scripts_dir = project_root / "scripts"
        self.local_infra_dir = project_root / ".runners-local"

        # Constitutional workflows
        self.workflows = {
            "validation": self._define_validation_workflow(),
            "performance": self._define_performance_workflow(),
            "build": self._define_build_workflow(),
            "test": self._define_test_workflow(),
            "deploy": self._define_deploy_workflow(),
            "constitutional": self._define_constitutional_workflow()
        }

    def _define_validation_workflow(self) -> List[WorkflowStep]:
        """Define validation workflow steps."""
        return [
            WorkflowStep(
                name="python_lint",
                description="Python code linting with ruff",
                command=["python", "-m", "ruff", "check", "--fix", "scripts/"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="python_format",
                description="Python code formatting with black",
                command=["python", "-m", "black", "scripts/"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="python_typecheck",
                description="Python type checking with mypy",
                command=["python", "-m", "mypy", "scripts/"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="config_validation",
                description="Constitutional configuration validation",
                command=["python", "scripts/config_validator.py", "--strict"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="dependency_check",
                description="Dependency update checking",
                command=["python", "scripts/update_checker.py", "--check-only"],
                constitutional_check=True
            )
        ]

    def _define_performance_workflow(self) -> List[WorkflowStep]:
        """Define performance testing workflow steps."""
        return [
            WorkflowStep(
                name="build_project",
                description="Build project for performance testing",
                command=["npm", "run", "build"],
                timeout=120
            ),
            WorkflowStep(
                name="performance_check",
                description="Constitutional performance monitoring",
                command=["python", "scripts/performance_monitor.py", "--url", "http://localhost:4321"],
                constitutional_check=True,
                timeout=180
            ),
            WorkflowStep(
                name="bundle_analysis",
                description="Bundle size analysis",
                command=["npm", "run", "build", "--", "--analyze"],
                required=False
            )
        ]

    def _define_build_workflow(self) -> List[WorkflowStep]:
        """Define build workflow steps."""
        return [
            WorkflowStep(
                name="install_dependencies",
                description="Install project dependencies",
                command=["npm", "ci"]
            ),
            WorkflowStep(
                name="typescript_check",
                description="TypeScript type checking",
                command=["npm", "run", "astro", "check"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="build_production",
                description="Production build",
                command=["npm", "run", "build"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="build_verification",
                description="Verify build artifacts",
                command=["ls", "-la", "dist/"],
                constitutional_check=True
            )
        ]

    def _define_test_workflow(self) -> List[WorkflowStep]:
        """Define testing workflow steps."""
        return [
            WorkflowStep(
                name="unit_tests",
                description="Run unit tests",
                command=["python", "-m", "pytest", "scripts/", "-v"],
                required=False  # May not exist yet
            ),
            WorkflowStep(
                name="integration_tests",
                description="Run integration tests",
                command=["npm", "run", "test"],
                required=False  # May not exist yet
            ),
            WorkflowStep(
                name="accessibility_tests",
                description="Accessibility compliance testing",
                command=["npm", "run", "test:a11y"],
                required=False  # May not exist yet
            )
        ]

    def _define_deploy_workflow(self) -> List[WorkflowStep]:
        """Define deployment workflow steps."""
        return [
            WorkflowStep(
                name="pre_deploy_validation",
                description="Pre-deployment validation",
                command=["python", "scripts/config_validator.py", "--strict"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="performance_validation",
                description="Performance validation before deploy",
                command=["python", "scripts/performance_monitor.py"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="build_production",
                description="Production build for deployment",
                command=["npm", "run", "build"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="deploy_preview",
                description="Deploy to preview environment",
                command=["npm", "run", "preview"],
                required=False
            )
        ]

    def _define_constitutional_workflow(self) -> List[WorkflowStep]:
        """Define constitutional compliance workflow."""
        return [
            WorkflowStep(
                name="constitutional_validation",
                description="Comprehensive constitutional compliance check",
                command=["python", "scripts/config_validator.py", "--strict"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="performance_targets",
                description="Performance target validation",
                command=["python", "scripts/performance_monitor.py"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="update_compliance",
                description="Dependency update compliance",
                command=["python", "scripts/update_checker.py", "--check-only"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="branch_strategy_check",
                description="Branch preservation strategy validation",
                command=["git", "log", "--oneline", "-10"],
                constitutional_check=True
            ),
            WorkflowStep(
                name="local_cicd_check",
                description="Local CI/CD infrastructure validation",
                command=["ls", "-la", ".runners-local/workflows/"],
                constitutional_check=True
            )
        ]

    async def run_workflow(self, workflow_name: str, parallel: bool = False) -> CICDResult:
        """Run specified workflow."""
        if workflow_name not in self.workflows:
            raise ValueError(f"Unknown workflow: {workflow_name}. Available: {list(self.workflows.keys())}")

        steps = self.workflows[workflow_name]
        console.print(Panel(f"🚀 Running {workflow_name.title()} Workflow", style="bold blue"))

        start_time = time.time()
        step_results: List[WorkflowResult] = []

        if parallel and self._can_run_parallel(steps):
            step_results = await self._run_steps_parallel(steps)
        else:
            step_results = await self._run_steps_sequential(steps)

        total_duration = time.time() - start_time

        # Calculate results
        successful_steps = sum(1 for r in step_results if r.success)
        failed_steps = len(step_results) - successful_steps
        constitutional_compliance = all(r.constitutional_compliance for r in step_results if r.success)

        result = CICDResult(
            workflow_name=workflow_name,
            total_steps=len(steps),
            successful_steps=successful_steps,
            failed_steps=failed_steps,
            total_duration=total_duration,
            constitutional_compliance=constitutional_compliance,
            step_results=step_results,
            summary={
                "workflow_success": failed_steps == 0,
                "constitutional_compliant": constitutional_compliance,
                "performance_summary": self._extract_performance_summary(step_results),
                "recommendations": self._generate_recommendations(step_results)
            }
        )

        return result

    def _can_run_parallel(self, steps: List[WorkflowStep]) -> bool:
        """Check if steps can be run in parallel."""
        # Simple heuristic: steps that don't depend on build artifacts can run in parallel
        parallel_safe_commands = ["ruff", "black", "mypy", "git"]
        return all(
            any(cmd in step.command[0] for cmd in parallel_safe_commands)
            for step in steps
        )

    async def _run_steps_sequential(self, steps: List[WorkflowStep]) -> List[WorkflowResult]:
        """Run workflow steps sequentially."""
        results: List[WorkflowResult] = []

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            console=console,
        ) as progress:

            task = progress.add_task("Running workflow...", total=len(steps))

            for step in steps:
                progress.update(task, description=f"Running {step.name}...")

                result = await self._execute_step(step)
                results.append(result)

                # Stop on critical failure
                if not result.success and step.required:
                    console.print(f"❌ Critical step failed: {step.name}")
                    break

                progress.advance(task)

        return results

    async def _run_steps_parallel(self, steps: List[WorkflowStep]) -> List[WorkflowResult]:
        """Run workflow steps in parallel where possible."""
        console.print("🔄 Running steps in parallel...")

        tasks = [self._execute_step(step) for step in steps]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Handle exceptions
        processed_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                processed_results.append(WorkflowResult(
                    step_name=steps[i].name,
                    success=False,
                    duration=0.0,
                    output="",
                    error=str(result),
                    constitutional_compliance=False,
                    exit_code=1
                ))
            else:
                processed_results.append(result)

        return processed_results

    async def _execute_step(self, step: WorkflowStep) -> WorkflowResult:
        """Execute individual workflow step."""
        start_time = time.time()

        try:
            # Set working directory
            cwd = self.project_root
            if step.working_directory:
                cwd = cwd / step.working_directory

            # Execute command
            process = await asyncio.create_subprocess_exec(
                *step.command,
                cwd=cwd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )

            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=step.timeout
                )
            except asyncio.TimeoutError:
                process.kill()
                return WorkflowResult(
                    step_name=step.name,
                    success=False,
                    duration=time.time() - start_time,
                    output="",
                    error=f"Step timed out after {step.timeout}s",
                    constitutional_compliance=False,
                    exit_code=124  # Timeout exit code
                )

            duration = time.time() - start_time
            success = process.returncode == 0
            output = stdout.decode() if stdout else ""
            error = stderr.decode() if stderr else None

            # Check constitutional compliance for relevant steps
            constitutional_compliance = True
            if step.constitutional_check and success:
                constitutional_compliance = await self._validate_constitutional_compliance(step, output)

            return WorkflowResult(
                step_name=step.name,
                success=success,
                duration=duration,
                output=output,
                error=error,
                constitutional_compliance=constitutional_compliance,
                exit_code=process.returncode
            )

        except Exception as e:
            duration = time.time() - start_time
            return WorkflowResult(
                step_name=step.name,
                success=False,
                duration=duration,
                output="",
                error=str(e),
                constitutional_compliance=False,
                exit_code=1
            )

    async def _validate_constitutional_compliance(self, step: WorkflowStep, output: str) -> bool:
        """Validate constitutional compliance for a step."""
        # Step-specific constitutional validation
        if "performance" in step.name:
            # Check if performance targets are met
            return "CONSTITUTIONAL COMPLIANCE: PASSED" in output or "constitutional_compliance: true" in output

        elif "config" in step.name:
            # Check configuration compliance
            return "READY FOR PRODUCTION" in output

        elif "ruff" in step.command[0]:
            # Ruff should pass without errors for constitutional compliance
            return step.name in output and "error" not in output.lower()

        elif "mypy" in step.command[0]:
            # MyPy should pass strict checking
            return "Success: no issues found" in output or output.strip() == ""

        # Default: assume compliance if step succeeded
        return True

    def _extract_performance_summary(self, results: List[WorkflowResult]) -> Dict[str, Any]:
        """Extract performance summary from step results."""
        performance_summary = {
            "total_workflow_time": sum(r.duration for r in results),
            "slowest_step": max(results, key=lambda r: r.duration).step_name if results else None,
            "average_step_time": sum(r.duration for r in results) / len(results) if results else 0,
            "steps_under_30s": sum(1 for r in results if r.duration < 30),
            "constitutional_performance": all(r.constitutional_compliance for r in results if r.success)
        }

        return performance_summary

    def _generate_recommendations(self, results: List[WorkflowResult]) -> List[str]:
        """Generate recommendations based on workflow results."""
        recommendations = []

        # Check for failed steps
        failed_steps = [r for r in results if not r.success]
        if failed_steps:
            recommendations.append(f"Fix {len(failed_steps)} failed step(s)")

        # Check for slow steps
        slow_steps = [r for r in results if r.duration > 60]
        if slow_steps:
            recommendations.append("Optimize slow steps for better performance")

        # Check for constitutional compliance
        non_compliant = [r for r in results if not r.constitutional_compliance]
        if non_compliant:
            recommendations.append("Address constitutional compliance violations")

        # Performance recommendations
        total_time = sum(r.duration for r in results)
        if total_time > 300:  # 5 minutes
            recommendations.append("Consider parallel execution to reduce workflow time")

        if not recommendations:
            recommendations.append("All checks passed! Workflow is constitutionally compliant.")

        return recommendations

    def generate_report(self, result: CICDResult) -> None:
        """Generate CI/CD workflow report."""
        # Workflow status
        if result.summary["workflow_success"] and result.constitutional_compliance:
            status_panel = Panel("✅ [bold green]WORKFLOW SUCCESSFUL - CONSTITUTIONALLY COMPLIANT[/bold green]", style="green")
        elif result.summary["workflow_success"]:
            status_panel = Panel("⚠️ [bold yellow]WORKFLOW SUCCESSFUL - COMPLIANCE ISSUES[/bold yellow]", style="yellow")
        else:
            status_panel = Panel("❌ [bold red]WORKFLOW FAILED[/bold red]", style="red")

        console.print(status_panel)

        # Workflow summary
        summary_table = Table(title=f"{result.workflow_name.title()} Workflow Summary")
        summary_table.add_column("Metric", style="cyan")
        summary_table.add_column("Value", style="bold")
        summary_table.add_column("Status", style="green")

        summary_table.add_row("Total Steps", str(result.total_steps), "ℹ️")
        summary_table.add_row("Successful", str(result.successful_steps),
                             "✅" if result.successful_steps == result.total_steps else "⚠️")
        summary_table.add_row("Failed", str(result.failed_steps),
                             "✅" if result.failed_steps == 0 else "❌")
        summary_table.add_row("Duration", f"{result.total_duration:.1f}s",
                             "✅" if result.total_duration < 300 else "⚠️")
        summary_table.add_row("Constitutional Compliance", str(result.constitutional_compliance),
                             "✅" if result.constitutional_compliance else "❌")

        console.print(summary_table)

        # Step details
        steps_table = Table(title="Step Execution Details")
        steps_table.add_column("Step", style="cyan")
        steps_table.add_column("Duration", style="yellow")
        steps_table.add_column("Status", style="green")
        steps_table.add_column("Constitutional", style="blue")

        for step_result in result.step_results:
            status = "✅" if step_result.success else "❌"
            compliance = "✅" if step_result.constitutional_compliance else "❌"

            steps_table.add_row(
                step_result.step_name,
                f"{step_result.duration:.1f}s",
                status,
                compliance
            )

        console.print(steps_table)

        # Performance summary
        perf_summary = result.summary["performance_summary"]
        console.print(f"\n[bold]Performance Summary:[/bold]")
        console.print(f"• Total workflow time: {perf_summary['total_workflow_time']:.1f}s")
        console.print(f"• Slowest step: {perf_summary['slowest_step']}")
        console.print(f"• Average step time: {perf_summary['average_step_time']:.1f}s")
        console.print(f"• Steps under 30s: {perf_summary['steps_under_30s']}/{result.total_steps}")

        # Recommendations
        recommendations = result.summary["recommendations"]
        if recommendations:
            console.print(f"\n[bold]Recommendations:[/bold]")
            for rec in recommendations:
                console.print(f"• {rec}")

        # Failed step details
        failed_steps = [r for r in result.step_results if not r.success]
        if failed_steps:
            console.print(f"\n[bold red]Failed Step Details:[/bold red]")
            for step in failed_steps:
                console.print(f"\n❌ [bold]{step.step_name}[/bold]")
                if step.error:
                    console.print(f"   Error: {step.error}")
                if step.output:
                    console.print(f"   Output: {step.output[:200]}...")

    async def run_all_workflows(self) -> Dict[str, CICDResult]:
        """Run all available workflows."""
        console.print(Panel("🔄 Running All Constitutional Workflows", style="bold blue"))

        results = {}
        for workflow_name in self.workflows.keys():
            console.print(f"\n{'='*60}")
            console.print(f"Starting {workflow_name.title()} Workflow")

            try:
                result = await self.run_workflow(workflow_name)
                results[workflow_name] = result

                # Stop on critical workflow failure
                if not result.summary["workflow_success"] and workflow_name in ["constitutional", "validation"]:
                    console.print(f"❌ Critical workflow failed: {workflow_name}")
                    break

            except Exception as e:
                console.print(f"❌ Workflow {workflow_name} failed with exception: {e}")
                logger.exception(f"Workflow {workflow_name} failed")

        return results

    async def save_results(self, results: Dict[str, CICDResult]) -> None:
        """Save workflow results for analysis."""
        results_dir = self.project_root / ".update_cache" / "cicd_results"
        results_dir.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        for workflow_name, result in results.items():
            result_file = results_dir / f"{workflow_name}_{timestamp}.json"
            result_file.write_text(result.model_dump_json(indent=2))

        # Save summary
        summary_file = results_dir / f"summary_{timestamp}.json"
        summary = {
            "timestamp": timestamp,
            "total_workflows": len(results),
            "successful_workflows": sum(1 for r in results.values() if r.summary["workflow_success"]),
            "constitutional_compliant": sum(1 for r in results.values() if r.constitutional_compliance),
            "total_duration": sum(r.total_duration for r in results.values()),
            "workflows": {name: r.summary for name, r in results.items()}
        }
        summary_file.write_text(json.dumps(summary, indent=2))

        console.print(f"📊 Results saved to {results_dir}")


@click.command()
@click.option("--workflow", type=click.Choice(["validation", "performance", "build", "test", "deploy", "constitutional", "all"]),
              default="all", help="Workflow to run")
@click.option("--parallel", is_flag=True, help="Run steps in parallel where possible")
@click.option("--json-output", is_flag=True, help="Output results in JSON format")
@click.option("--project-root", type=click.Path(exists=True),
              default=".", help="Project root directory")
@click.option("--save-results", is_flag=True, default=True, help="Save results to disk")
def main(workflow: str, parallel: bool, json_output: bool, project_root: str, save_results: bool) -> None:
    """Constitutional CI/CD Runner - Local workflow execution with zero GitHub Actions consumption."""

    async def run_cicd():
        project_path = Path(project_root).resolve()
        cicd = ConstitutionalCICD(project_path)

        if workflow == "all":
            results = await cicd.run_all_workflows()

            if json_output:
                output = {name: result.model_dump(mode="json") for name, result in results.items()}
                console.print_json(data=output)
            else:
                # Generate summary report
                console.print("\n" + "="*80)
                console.print(Panel("📊 All Workflows Summary", style="bold green"))

                summary_table = Table(title="Workflow Results")
                summary_table.add_column("Workflow", style="cyan")
                summary_table.add_column("Success", style="green")
                summary_table.add_column("Duration", style="yellow")
                summary_table.add_column("Constitutional", style="blue")

                for name, result in results.items():
                    success = "✅" if result.summary["workflow_success"] else "❌"
                    compliance = "✅" if result.constitutional_compliance else "❌"

                    summary_table.add_row(
                        name.title(),
                        success,
                        f"{result.total_duration:.1f}s",
                        compliance
                    )

                console.print(summary_table)

                # Overall status
                all_successful = all(r.summary["workflow_success"] for r in results.values())
                all_compliant = all(r.constitutional_compliance for r in results.values())

                if all_successful and all_compliant:
                    console.print(Panel("✅ [bold green]ALL WORKFLOWS SUCCESSFUL AND CONSTITUTIONALLY COMPLIANT[/bold green]", style="green"))
                else:
                    console.print(Panel("❌ [bold red]WORKFLOW FAILURES OR COMPLIANCE ISSUES DETECTED[/bold red]", style="red"))

            if save_results:
                await cicd.save_results(results)

            # Exit with error if any workflow failed or compliance issues
            if not all(r.summary["workflow_success"] and r.constitutional_compliance for r in results.values()):
                sys.exit(1)

        else:
            result = await cicd.run_workflow(workflow, parallel=parallel)

            if json_output:
                output = result.model_dump(mode="json")
                console.print_json(data=output)
            else:
                cicd.generate_report(result)

            if save_results:
                await cicd.save_results({workflow: result})

            # Exit with error if workflow failed or not compliant
            if not result.summary["workflow_success"] or not result.constitutional_compliance:
                sys.exit(1)

    try:
        asyncio.run(run_cicd())
    except KeyboardInterrupt:
        console.print("\n[yellow]CI/CD execution cancelled by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"\n[red]CI/CD execution failed: {e}[/red]")
        logger.exception("CI/CD execution failed")
        sys.exit(1)


if __name__ == "__main__":
    main()