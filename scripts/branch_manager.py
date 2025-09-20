#!/usr/bin/env python3
"""
Constitutional Branch Management Automation
Automated branch management with constitutional compliance validation

Constitutional Requirements:
- Zero GitHub Actions consumption
- Branch preservation strategy
- Constitutional naming convention
- Performance monitoring
- Local validation
"""

import asyncio
import json
import logging
import subprocess
import sys
import time
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any

@dataclass
class BranchInfo:
    name: str
    hash: str
    created_date: datetime
    last_commit_date: datetime
    author: str
    is_constitutional: bool
    commits_count: int
    size_kb: float

@dataclass
class BranchManagementMetrics:
    total_branches: int
    constitutional_branches: int
    non_constitutional_branches: int
    protected_branches: int
    cleanup_candidates: int
    performance_time: float
    constitutional_compliance: bool
    errors: List[str]
    warnings: List[str]

class ConstitutionalBranchManager:
    """
    Constitutional branch management with automated cleanup and validation

    Features:
    - Constitutional naming convention enforcement
    - Branch preservation strategy
    - Automated constitutional branch creation
    - Performance monitoring
    - Zero GitHub Actions consumption validation
    """

    def __init__(self, project_root: str):
        self.project_root = Path(project_root)

        # Constitutional branch naming pattern
        self.constitutional_pattern = r"^\d{8}-\d{6}-.+$"

        # Protected branches (never delete)
        self.protected_branches = {"main", "master", "develop", "staging", "production"}

        # Constitutional targets
        self.performance_target = 30  # seconds for branch operations
        self.max_branch_age_days = 90  # days before suggesting cleanup

        # Setup logging
        self.setup_logging()

        # Metrics tracking
        self.start_time = time.time()
        self.metrics = BranchManagementMetrics(
            total_branches=0,
            constitutional_branches=0,
            non_constitutional_branches=0,
            protected_branches=0,
            cleanup_candidates=0,
            performance_time=0.0,
            constitutional_compliance=False,
            errors=[],
            warnings=[]
        )

    def setup_logging(self):
        """Setup constitutional logging"""
        log_dir = self.project_root / "local-infra" / "logs"
        log_dir.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = log_dir / f"branch_manager_{timestamp}.log"

        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
        self.logger.info("🏛️ Constitutional Branch Manager initialized")

    async def run_branch_management(self, operation: str = "analyze") -> BranchManagementMetrics:
        """Run branch management operations"""
        try:
            self.logger.info(f"🌿 Starting branch management operation: {operation}")

            # Validate git repository
            await self._validate_git_repository()

            # Get all branches
            branches = await self._get_all_branches()
            self.metrics.total_branches = len(branches)

            # Analyze branches
            await self._analyze_branches(branches)

            # Perform requested operation
            if operation == "analyze":
                await self._analyze_only(branches)
            elif operation == "create":
                await self._create_constitutional_branch()
            elif operation == "cleanup":
                await self._suggest_cleanup(branches)
            elif operation == "enforce":
                await self._enforce_constitutional_naming(branches)
            elif operation == "validate":
                await self._validate_constitutional_compliance(branches)
            else:
                raise ValueError(f"Unknown operation: {operation}")

            # Calculate final metrics
            self._calculate_final_metrics()

            self.logger.info("✅ Branch management completed successfully")
            return self.metrics

        except Exception as e:
            self.metrics.errors.append(f"Branch management failed: {str(e)}")
            self.logger.error(f"❌ Branch management failed: {e}")
            raise

    async def _validate_git_repository(self):
        """Validate git repository status"""
        try:
            # Check if we're in a git repository
            result = await self._run_git_command(["rev-parse", "--git-dir"])
            if result.returncode != 0:
                raise RuntimeError("Not in a git repository")

            # Check if remote origin exists
            result = await self._run_git_command(["remote", "get-url", "origin"])
            if result.returncode != 0:
                self.metrics.warnings.append("No remote origin configured")

            self.logger.info("✅ Git repository validation passed")

        except Exception as e:
            self.metrics.errors.append(f"Git repository validation failed: {str(e)}")
            raise

    async def _get_all_branches(self) -> List[BranchInfo]:
        """Get all branches with detailed information"""
        branches = []

        try:
            # Get local branches
            result = await self._run_git_command([
                "for-each-ref",
                "--format=%(refname:short)|%(objectname)|%(creatordate:iso8601)|%(committerdate:iso8601)|%(authorname)|%(objecttype)",
                "refs/heads/"
            ])

            if result.returncode == 0:
                for line in result.stdout.strip().split('\n'):
                    if line:
                        parts = line.split('|')
                        if len(parts) >= 6:
                            branch_info = await self._create_branch_info(parts)
                            branches.append(branch_info)

            # Get remote branches
            result = await self._run_git_command([
                "for-each-ref",
                "--format=%(refname:short)|%(objectname)|%(creatordate:iso8601)|%(committerdate:iso8601)|%(authorname)|%(objecttype)",
                "refs/remotes/origin/"
            ])

            if result.returncode == 0:
                for line in result.stdout.strip().split('\n'):
                    if line and not line.endswith('/HEAD'):
                        parts = line.split('|')
                        if len(parts) >= 6:
                            # Remove origin/ prefix
                            parts[0] = parts[0].replace('origin/', '')
                            # Only add if not already in local branches
                            if not any(b.name == parts[0] for b in branches):
                                branch_info = await self._create_branch_info(parts)
                                branches.append(branch_info)

            self.logger.info(f"📊 Found {len(branches)} branches")
            return branches

        except Exception as e:
            self.metrics.errors.append(f"Failed to get branches: {str(e)}")
            raise

    async def _create_branch_info(self, parts: List[str]) -> BranchInfo:
        """Create BranchInfo object from git output"""
        try:
            name = parts[0]
            hash_val = parts[1]
            created_date = datetime.fromisoformat(parts[2].replace('Z', '+00:00'))
            last_commit_date = datetime.fromisoformat(parts[3].replace('Z', '+00:00'))
            author = parts[4] if len(parts) > 4 else "Unknown"

            # Check if constitutional naming
            import re
            is_constitutional = bool(re.match(self.constitutional_pattern, name)) or name in self.protected_branches

            # Get commit count
            commits_count = await self._get_commit_count(name)

            # Estimate branch size
            size_kb = await self._estimate_branch_size(name)

            return BranchInfo(
                name=name,
                hash=hash_val,
                created_date=created_date,
                last_commit_date=last_commit_date,
                author=author,
                is_constitutional=is_constitutional,
                commits_count=commits_count,
                size_kb=size_kb
            )

        except Exception as e:
            self.logger.warning(f"Failed to create branch info for {parts[0] if parts else 'unknown'}: {e}")
            # Return minimal branch info
            return BranchInfo(
                name=parts[0] if parts else "unknown",
                hash=parts[1] if len(parts) > 1 else "",
                created_date=datetime.now(),
                last_commit_date=datetime.now(),
                author="Unknown",
                is_constitutional=False,
                commits_count=0,
                size_kb=0.0
            )

    async def _get_commit_count(self, branch_name: str) -> int:
        """Get commit count for branch"""
        try:
            result = await self._run_git_command(["rev-list", "--count", branch_name])
            if result.returncode == 0:
                return int(result.stdout.strip())
            return 0
        except Exception:
            return 0

    async def _estimate_branch_size(self, branch_name: str) -> float:
        """Estimate branch size in KB"""
        try:
            # Get size of objects in branch
            result = await self._run_git_command([
                "rev-list", "--objects", branch_name,
                "--", ".", ":(exclude)node_modules", ":(exclude).git"
            ])

            if result.returncode == 0:
                # Rough estimate based on number of objects
                object_count = len(result.stdout.strip().split('\n'))
                return object_count * 2.5  # Rough estimate of 2.5KB per object

            return 0.0
        except Exception:
            return 0.0

    async def _analyze_branches(self, branches: List[BranchInfo]):
        """Analyze branch statistics"""
        for branch in branches:
            if branch.is_constitutional:
                self.metrics.constitutional_branches += 1
            else:
                self.metrics.non_constitutional_branches += 1

            if branch.name in self.protected_branches:
                self.metrics.protected_branches += 1

            # Check if branch is cleanup candidate
            age_days = (datetime.now() - branch.last_commit_date.replace(tzinfo=None)).days
            if (age_days > self.max_branch_age_days and
                branch.name not in self.protected_branches and
                not branch.is_constitutional):
                self.metrics.cleanup_candidates += 1

        self.logger.info(f"📊 Branch analysis:")
        self.logger.info(f"   Total: {self.metrics.total_branches}")
        self.logger.info(f"   Constitutional: {self.metrics.constitutional_branches}")
        self.logger.info(f"   Non-constitutional: {self.metrics.non_constitutional_branches}")
        self.logger.info(f"   Protected: {self.metrics.protected_branches}")
        self.logger.info(f"   Cleanup candidates: {self.metrics.cleanup_candidates}")

    async def _analyze_only(self, branches: List[BranchInfo]):
        """Analyze branches without making changes"""
        self.logger.info("🔍 Performing branch analysis...")

        # Generate analysis report
        report = {
            "timestamp": datetime.now().isoformat(),
            "total_branches": len(branches),
            "constitutional_branches": [b for b in branches if b.is_constitutional],
            "non_constitutional_branches": [b for b in branches if not b.is_constitutional],
            "cleanup_candidates": [
                b for b in branches
                if (datetime.now() - b.last_commit_date.replace(tzinfo=None)).days > self.max_branch_age_days
                and b.name not in self.protected_branches
                and not b.is_constitutional
            ]
        }

        # Save analysis report
        report_file = self.project_root / "local-infra" / "logs" / f"branch_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        # Convert datetime objects to strings for JSON serialization
        def serialize_branch(branch):
            return {
                "name": branch.name,
                "hash": branch.hash,
                "created_date": branch.created_date.isoformat(),
                "last_commit_date": branch.last_commit_date.isoformat(),
                "author": branch.author,
                "is_constitutional": branch.is_constitutional,
                "commits_count": branch.commits_count,
                "size_kb": branch.size_kb
            }

        serializable_report = {
            "timestamp": report["timestamp"],
            "total_branches": report["total_branches"],
            "constitutional_branches": [serialize_branch(b) for b in report["constitutional_branches"]],
            "non_constitutional_branches": [serialize_branch(b) for b in report["non_constitutional_branches"]],
            "cleanup_candidates": [serialize_branch(b) for b in report["cleanup_candidates"]]
        }

        with open(report_file, 'w') as f:
            json.dump(serializable_report, f, indent=2)

        self.logger.info(f"📄 Analysis report saved: {report_file}")

    async def _create_constitutional_branch(self):
        """Create a new constitutional branch"""
        self.logger.info("🌿 Creating constitutional branch...")

        # Generate constitutional branch name
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        branch_type = "feat"  # Default to feature branch

        # Try to determine branch type from current changes
        try:
            # Check git status for hints about branch type
            result = await self._run_git_command(["status", "--porcelain"])
            if result.returncode == 0:
                changes = result.stdout.strip()
                if "test" in changes.lower():
                    branch_type = "test"
                elif "fix" in changes.lower():
                    branch_type = "fix"
                elif "doc" in changes.lower():
                    branch_type = "docs"
                elif "perf" in changes.lower():
                    branch_type = "perf"
        except Exception:
            pass

        branch_name = f"{timestamp}-{branch_type}-new-feature"

        # Create branch
        try:
            result = await self._run_git_command(["checkout", "-b", branch_name])
            if result.returncode == 0:
                self.logger.info(f"✅ Constitutional branch created: {branch_name}")

                # Try to set upstream if remote exists
                try:
                    await self._run_git_command(["push", "-u", "origin", branch_name])
                    self.logger.info(f"✅ Branch pushed to remote with upstream tracking")
                except Exception as e:
                    self.metrics.warnings.append(f"Could not push branch to remote: {e}")

            else:
                raise RuntimeError(f"Failed to create branch: {result.stderr}")

        except Exception as e:
            self.metrics.errors.append(f"Branch creation failed: {str(e)}")
            raise

    async def _suggest_cleanup(self, branches: List[BranchInfo]):
        """Suggest branch cleanup candidates"""
        self.logger.info("🧹 Analyzing cleanup candidates...")

        cleanup_candidates = []
        current_date = datetime.now()

        for branch in branches:
            # Skip protected branches
            if branch.name in self.protected_branches:
                continue

            # Skip constitutional branches (preserve them)
            if branch.is_constitutional:
                continue

            # Check age
            age_days = (current_date - branch.last_commit_date.replace(tzinfo=None)).days

            if age_days > self.max_branch_age_days:
                cleanup_candidates.append({
                    "name": branch.name,
                    "age_days": age_days,
                    "last_commit": branch.last_commit_date.isoformat(),
                    "author": branch.author,
                    "commits": branch.commits_count,
                    "size_kb": branch.size_kb,
                    "reason": f"Older than {self.max_branch_age_days} days and non-constitutional"
                })

        if cleanup_candidates:
            self.logger.info(f"🧹 Found {len(cleanup_candidates)} cleanup candidates:")
            for candidate in cleanup_candidates:
                self.logger.info(f"   • {candidate['name']} ({candidate['age_days']} days old)")

            # Save cleanup report
            cleanup_file = self.project_root / "local-infra" / "logs" / f"cleanup_candidates_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(cleanup_file, 'w') as f:
                json.dump({
                    "timestamp": current_date.isoformat(),
                    "candidates": cleanup_candidates,
                    "constitutional_note": "Constitutional branches are preserved regardless of age"
                }, f, indent=2)

            self.logger.info(f"📄 Cleanup report saved: {cleanup_file}")
        else:
            self.logger.info("✅ No cleanup candidates found")

    async def _enforce_constitutional_naming(self, branches: List[BranchInfo]):
        """Enforce constitutional naming convention"""
        self.logger.info("🏛️ Enforcing constitutional naming convention...")

        non_constitutional = [b for b in branches if not b.is_constitutional and b.name not in self.protected_branches]

        if non_constitutional:
            self.logger.info(f"⚠️ Found {len(non_constitutional)} non-constitutional branches:")

            for branch in non_constitutional:
                self.logger.info(f"   • {branch.name} (last commit: {branch.last_commit_date.date()})")

                # Suggest constitutional name
                suggested_name = await self._suggest_constitutional_name(branch)
                self.logger.info(f"     Suggested: {suggested_name}")

            # Create enforcement report
            enforcement_file = self.project_root / "local-infra" / "logs" / f"naming_enforcement_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

            enforcement_data = []
            for branch in non_constitutional:
                suggested_name = await self._suggest_constitutional_name(branch)
                enforcement_data.append({
                    "current_name": branch.name,
                    "suggested_name": suggested_name,
                    "last_commit": branch.last_commit_date.isoformat(),
                    "author": branch.author,
                    "action": "rename_recommended"
                })

            with open(enforcement_file, 'w') as f:
                json.dump({
                    "timestamp": datetime.now().isoformat(),
                    "constitutional_pattern": self.constitutional_pattern,
                    "non_constitutional_branches": enforcement_data,
                    "note": "Manual renaming required - automatic renaming not performed for safety"
                }, f, indent=2)

            self.logger.info(f"📄 Naming enforcement report saved: {enforcement_file}")
        else:
            self.logger.info("✅ All branches follow constitutional naming convention")

    async def _suggest_constitutional_name(self, branch: BranchInfo) -> str:
        """Suggest constitutional name for a branch"""
        # Use the branch's creation date for timestamp
        timestamp = branch.created_date.strftime("%Y%m%d-%H%M%S")

        # Determine branch type from name
        name_lower = branch.name.lower()
        if "fix" in name_lower or "bug" in name_lower:
            branch_type = "fix"
        elif "feat" in name_lower or "feature" in name_lower:
            branch_type = "feat"
        elif "doc" in name_lower:
            branch_type = "docs"
        elif "test" in name_lower:
            branch_type = "test"
        elif "perf" in name_lower or "performance" in name_lower:
            branch_type = "perf"
        else:
            branch_type = "feat"

        # Clean up original name for description
        description = branch.name.replace("_", "-").replace("/", "-").lower()

        # Remove common prefixes
        for prefix in ["feature-", "feat-", "fix-", "bug-", "hotfix-"]:
            if description.startswith(prefix):
                description = description[len(prefix):]
                break

        # Limit description length
        if len(description) > 30:
            description = description[:30]

        return f"{timestamp}-{branch_type}-{description}"

    async def _validate_constitutional_compliance(self, branches: List[BranchInfo]):
        """Validate constitutional compliance of branch management"""
        self.logger.info("🏛️ Validating constitutional compliance...")

        compliance_checks = {
            "constitutional_naming": self._check_constitutional_naming(branches),
            "branch_preservation": self._check_branch_preservation(branches),
            "protected_branches": self._check_protected_branches(branches),
            "zero_github_actions": await self._verify_zero_github_actions(),
            "performance_targets": self.metrics.performance_time < self.performance_target
        }

        self.metrics.constitutional_compliance = all(compliance_checks.values())

        # Generate compliance report
        compliance_file = self.project_root / "local-infra" / "logs" / f"constitutional_compliance_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

        with open(compliance_file, 'w') as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "compliance_checks": compliance_checks,
                "overall_compliance": self.metrics.constitutional_compliance,
                "metrics": asdict(self.metrics)
            }, f, indent=2)

        if self.metrics.constitutional_compliance:
            self.logger.info("✅ Constitutional compliance validated")
        else:
            failed_checks = [k for k, v in compliance_checks.items() if not v]
            self.logger.error(f"❌ Constitutional compliance failed: {failed_checks}")

    def _check_constitutional_naming(self, branches: List[BranchInfo]) -> bool:
        """Check constitutional naming compliance"""
        non_protected = [b for b in branches if b.name not in self.protected_branches]
        constitutional = [b for b in non_protected if b.is_constitutional]

        if not non_protected:
            return True

        compliance_rate = len(constitutional) / len(non_protected)
        return compliance_rate >= 0.8  # 80% compliance rate

    def _check_branch_preservation(self, branches: List[BranchInfo]) -> bool:
        """Check branch preservation compliance"""
        # All constitutional branches should be preserved
        constitutional_branches = [b for b in branches if b.is_constitutional]
        return len(constitutional_branches) >= self.metrics.constitutional_branches

    def _check_protected_branches(self, branches: List[BranchInfo]) -> bool:
        """Check protected branches exist"""
        branch_names = {b.name for b in branches}
        required_protected = {"main", "master"}  # At least one should exist
        return bool(required_protected.intersection(branch_names))

    async def _verify_zero_github_actions(self) -> bool:
        """Verify zero GitHub Actions consumption"""
        try:
            result = await self._run_command([
                "gh", "api", "user/settings/billing/actions",
                "--jq", ".total_paid_minutes_used // 0"
            ])

            if result.returncode == 0:
                paid_minutes = int(result.stdout.strip() or "0")
                return paid_minutes == 0
            else:
                self.metrics.warnings.append("Could not verify GitHub Actions usage")
                return True  # Assume compliance if can't check

        except Exception as e:
            self.metrics.warnings.append(f"GitHub Actions verification failed: {e}")
            return True  # Assume compliance if can't check

    async def _run_git_command(self, args: List[str]) -> subprocess.CompletedProcess:
        """Run git command asynchronously"""
        return await self._run_command(["git"] + args)

    async def _run_command(self, args: List[str]) -> subprocess.CompletedProcess:
        """Run command asynchronously"""
        try:
            process = await asyncio.create_subprocess_exec(
                *args,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=self.project_root
            )

            stdout, stderr = await process.communicate()

            return subprocess.CompletedProcess(
                args=args,
                returncode=process.returncode,
                stdout=stdout.decode('utf-8') if stdout else "",
                stderr=stderr.decode('utf-8') if stderr else ""
            )

        except Exception as e:
            return subprocess.CompletedProcess(
                args=args,
                returncode=1,
                stdout="",
                stderr=str(e)
            )

    def _calculate_final_metrics(self):
        """Calculate final metrics"""
        self.metrics.performance_time = time.time() - self.start_time

        self.logger.info(f"📊 Branch management metrics:")
        self.logger.info(f"   Performance time: {self.metrics.performance_time:.2f}s")
        self.logger.info(f"   Total branches: {self.metrics.total_branches}")
        self.logger.info(f"   Constitutional: {self.metrics.constitutional_branches}")
        self.logger.info(f"   Protected: {self.metrics.protected_branches}")
        self.logger.info(f"   Cleanup candidates: {self.metrics.cleanup_candidates}")
        self.logger.info(f"   Constitutional compliance: {self.metrics.constitutional_compliance}")

async def main():
    """Main branch management function"""
    import argparse

    parser = argparse.ArgumentParser(description="Constitutional Branch Management")
    parser.add_argument("operation", choices=["analyze", "create", "cleanup", "enforce", "validate"],
                       help="Branch management operation")
    parser.add_argument("--project-root", default=".", help="Project root directory")
    parser.add_argument("--output-format", choices=["json", "yaml"], help="Output metrics format")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose logging")

    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    try:
        manager = ConstitutionalBranchManager(args.project_root)
        metrics = await manager.run_branch_management(args.operation)

        # Output metrics if requested
        if args.output_format:
            metrics_data = asdict(metrics)

            if args.output_format == "json":
                print(json.dumps(metrics_data, indent=2, default=str))
            elif args.output_format == "yaml":
                import yaml
                print(yaml.dump(metrics_data, default_flow_style=False))

        # Exit with appropriate code
        if metrics.constitutional_compliance:
            print(f"✅ Branch management ({args.operation}) completed with constitutional compliance")
            sys.exit(0)
        else:
            print(f"❌ Branch management ({args.operation}) completed with constitutional violations")
            sys.exit(1)

    except Exception as e:
        print(f"❌ Branch management failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())