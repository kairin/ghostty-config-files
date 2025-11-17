---
title: "Testing Guide"
description: "Testing strategy and execution for Ghostty Configuration Files"
pubDate: 2025-10-27
author: "Development Team"
tags: ["development", "testing", "quality"]
techStack: ["Bash 5.x+", "ShellCheck", "Pytest"]
difficulty: "intermediate"
---

# Testing Guide

This guide explains the testing strategy for the Ghostty Configuration Files repository.

## Testing Stack

- **ShellCheck**: Static analysis for bash scripts
- **Custom Test Framework**: Bash-based unit testing
- **Integration Tests**: End-to-end workflow validation
- **Performance Testing**: Startup time and resource usage

## Running Tests

### All Tests

```bash
./.runners-local/.runners-local/workflows/test-runner.sh
```

### Unit Tests

```bash
# Run all unit tests
./.runners-local/tests/unit/test_common_utils.sh

# Run specific module tests
./.runners-local/tests/unit/test_install_modules.sh
./.runners-local/tests/unit/test_config_modules.sh
```

### ShellCheck

```bash
# Validate all scripts
./.runners-local/tests/validation/run_shellcheck.sh

# Validate specific script
shellcheck scripts/common.sh
```

### Validation Tests

```bash
# All validation checks
./manage.sh validate

# Specific validation
./manage.sh validate --type config
./manage.sh validate --type performance
./manage.sh validate --type dependencies
```

## Writing Tests

### Unit Test Template

```bash
#!/bin/bash
# Unit Test: test_mymodule.sh

set -euo pipefail

# Source test helpers
source "$(dirname "${BASH_SOURCE[0]}")/test_functions.sh"

# Source module under test
source "../../../scripts/mymodule.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test case
test_function_name() {
    ((TESTS_RUN++))
    echo "  Testing: function description"

    # Arrange
    local input="test"

    # Act
    local result
    result=$(my_function "$input")
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Exit code should be 0"
    assert_contains "$result" "expected" "Should contain expected text"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Run tests
run_all_tests() {
    test_function_name
    # ... more tests ...

    # Summary
    echo "Tests: $TESTS_RUN, Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"
    [[ $TESTS_FAILED -eq 0 ]]
}

run_all_tests
```

### Test Assertions

Available assertion functions:

```bash
assert_equals <expected> <actual> <message>
assert_not_equals <expected> <actual> <message>
assert_contains <haystack> <needle> <message>
assert_true <condition> <message>
assert_file_exists <path> <message>
```

## Performance Testing

### Startup Time

```bash
# Measure script startup
time ./manage.sh --version

# Target: <500ms
```

### Module Load Time

```bash
# Measure module loading
time bash -c 'source scripts/common.sh && echo "loaded"'

# Target: <100ms per module
```

### Full Workflow

```bash
# Measure complete installation (dry-run)
time ./manage.sh install --dry-run

# Target: <2s for help/dry-run
```

## CI/CD Integration

### Local Workflow

```bash
# Complete validation workflow
./.runners-local/.runners-local/workflows/gh-workflow-local.sh all
```

### Pre-Commit Checks

Automatically run before each commit:
- ShellCheck validation
- .nojekyll file verification
- Configuration syntax check

## Test Coverage

### Current Coverage

- **Common Utilities**: 20+ test cases (✅ 100% coverage)
- **Progress Reporting**: 4+ test cases (✅ 100% coverage)
- **Backup Utilities**: 7+ test cases (✅ 100% coverage)
- **Install Modules**: Pending (Phase 5)
- **Config Modules**: Pending (Phase 5)

### Adding Coverage

When adding new modules:
1. Create corresponding test file
2. Achieve >90% function coverage
3. Include edge case tests
4. Verify performance <10s per module

## Debugging Tests

### Verbose Output

```bash
# Enable debug output
DEBUG=1 ./.runners-local/tests/unit/test_common_utils.sh
```

### Specific Test

```bash
# Run single test function
bash -c 'source test_functions.sh; source test_mymodule.sh; test_specific_case'
```

### Test Failures

When tests fail:
1. Check error message
2. Review test assertion
3. Verify module behavior
4. Update test or fix code

## Related Documentation

- [Architecture Guide](architecture.md)
- [Contributing Guide](contributing.md)
- [AI Guidelines](../ai-guidelines/core-principles.md)
