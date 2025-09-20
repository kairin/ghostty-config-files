# Scripts Documentation


## config_validator.py

**Description**: Constitutional Configuration Validator Validates project configuration files for constitutional compliance.  Constitutional Requirements: - Zero GitHub Actions consumption validation - Local CI/CD compliance checking - Performance target enforcement - Constitutional principle adherence

**Functions**:
```python
def generate_report(self, result: ValidationResult) -> None:
def main(fix: bool, json_output: bool, project_root: str, strict: bool) -> None:
```

**Usage**: `python scripts/config_validator.py`


## ci_cd_runner.py

**Description**: Constitutional CI/CD Runner Local CI/CD integration scripts for zero GitHub Actions consumption.  Constitutional Requirements: - Zero GitHub Actions consumption - Local workflow execution - Constitutional compliance validation - Performance target enforcement - Branch preservation strategy

**Functions**:
```python
def generate_report(self, result: CICDResult) -> None:
def main(workflow: str, parallel: bool, json_output: bool, project_root: str, save_results: bool) -> None:
```

**Usage**: `python scripts/ci_cd_runner.py`


## update_checker.py

**Description**: Constitutional Update Checker Script Smart version detection and update management for the ghostty-config-files project.  Constitutional Requirements: - Zero GitHub Actions consumption - Local CI/CD integration - Performance-first design - Constitutional compliance validation

**Functions**:
```python
def generate_report(self, result: UpdateCheckResult) -> None:
def main(check_only: bool, apply_updates: bool, apply_security: bool,
```

**Usage**: `python scripts/update_checker.py`


## branch_manager.py

**Description**: Constitutional Branch Management Automation Automated branch management with constitutional compliance validation  Constitutional Requirements: - Zero GitHub Actions consumption - Branch preservation strategy - Constitutional naming convention - Performance monitoring - Local validation

**Functions**:
```python
def setup_logging(self):
def serialize_branch(branch):
```

**Usage**: `python scripts/branch_manager.py`


## constitutional_automation.py

**Description**: Constitutional Automation Hub Central hub for all constitutional automation scripts.  Constitutional Requirements: - Zero GitHub Actions consumption - Local CI/CD automation - Performance monitoring - Configuration validation - Update management

**Functions**:
```python
def list_scripts(self) -> None:
def list_workflows(self) -> None:
def show_help(self) -> None:
def cli(ctx, project_root: str):
def list(ctx):
def workflows(ctx):
def run(ctx, script_name: str, args: tuple):
def workflow(ctx, workflow_name: str):
def help(ctx):
```

**Usage**: `python scripts/constitutional_automation.py`


## doc_generator.py

**Description**: Constitutional Documentation Generator Automated documentation generation with constitutional compliance validation  Constitutional Requirements: - Zero GitHub Actions consumption - Local documentation generation only - Performance monitoring for doc generation - Constitutional compliance validation - Multi-format output support

**Functions**:
```python
def setup_logging(self):
```

**Usage**: `python scripts/doc_generator.py`


## performance_monitor.py

**Description**: Constitutional Performance Monitor Core Web Vitals tracking and performance monitoring for constitutional compliance.  Constitutional Requirements: - Lighthouse 95+ performance scores - Core Web Vitals within constitutional targets - Bundle size optimization tracking - Real-time performance validation

**Functions**:
```python
def generate_report(self, metrics: PerformanceMetrics) -> None:
def main(url: str, continuous: bool, interval: int, json_output: bool, project_root: str) -> None:
```

**Usage**: `python scripts/performance_monitor.py`

