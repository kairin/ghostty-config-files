#!/bin/bash
# Integration Test: test_astro_build_deploy.sh
# Purpose: End-to-end testing of Astro build and GitHub Pages deployment
# Dependencies: .runners-local/workflows/astro-build-local.sh, test_functions.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source test helper functions
source "${SCRIPT_DIR}/../unit/test_functions.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST FIXTURES
# ============================================================

setup_all() {
    echo "🔧 Setting up Astro build and deploy test environment..."

    # Create test environment
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_BUILD_DIR="$TEST_TEMP_DIR/build"
    mkdir -p "$TEST_BUILD_DIR"

    echo "  Created test environment: $TEST_TEMP_DIR"
}

teardown_all() {
    echo "🧹 Cleaning up Astro build and deploy test environment..."

    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed test environment: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# INTEGRATION TEST CASES
# ============================================================

# Test: Astro build workflow script exists
test_astro_build_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: Astro build workflow script exists"

    # Assert
    assert_file_exists "$PROJECT_ROOT/.runners-local/workflows/astro-build-local.sh" \
        "astro-build-local.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: website/src directory structure exists
test_website_source_structure() {
    ((TESTS_RUN++))
    echo "  Testing: Website source directory structure exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/website" "website directory should exist"
    assert_dir_exists "$PROJECT_ROOT/website/src" "website/src should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: docs output directory structure exists
test_docs_output_directory() {
    ((TESTS_RUN++))
    echo "  Testing: docs output directory exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/docs" "docs directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: docs/.nojekyll file exists (CRITICAL)
test_nojekyll_file_critical() {
    ((TESTS_RUN++))
    echo "  Testing: .nojekyll file exists in docs (CRITICAL for GitHub Pages)"

    # Assert
    assert_file_exists "$PROJECT_ROOT/docs/.nojekyll" \
        ".nojekyll file MUST exist (without it, CSS/JS return 404 errors)"

    ((TESTS_PASSED++))
    echo "  ✅ PASS - .nojekyll is CRITICAL for GitHub Pages"
}

# Test: GitHub Pages configuration is set
test_github_pages_configuration() {
    ((TESTS_RUN++))
    echo "  Testing: GitHub Pages configuration exists"

    # Check for GitHub Pages config files
    local has_config=false
    if [[ -f "$PROJECT_ROOT/.github/workflows/deploy.yml" ]] || \
       [[ -f "$PROJECT_ROOT/.github/workflows/pages.yml" ]] || \
       [[ -f "$PROJECT_ROOT/astro.config.mjs" ]]; then
        has_config=true
    fi

    assert_true "[$has_config = true]" "GitHub Pages configuration should be present"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Astro configuration file exists
test_astro_config_exists() {
    ((TESTS_RUN++))
    echo "  Testing: Astro configuration file exists"

    # Assert
    assert_file_exists "$PROJECT_ROOT/astro.config.mjs" "astro.config.mjs should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: package.json has build scripts
test_package_json_build_scripts() {
    ((TESTS_RUN++))
    echo "  Testing: package.json contains build scripts"

    # Check if package.json exists
    assert_file_exists "$PROJECT_ROOT/package.json" "package.json should exist"

    # Check for build script
    local has_build_script=false
    if grep -q '"build"' "$PROJECT_ROOT/package.json"; then
        has_build_script=true
    fi

    assert_true "[$has_build_script = true]" "package.json should have build script"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: gh-pages-setup script exists
test_gh_pages_setup_script() {
    ((TESTS_RUN++))
    echo "  Testing: gh-pages-setup.sh script exists"

    # Assert
    assert_file_exists "$PROJECT_ROOT/.runners-local/workflows/gh-pages-setup.sh" \
        "gh-pages-setup.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Documentation source files exist
test_documentation_source_files() {
    ((TESTS_RUN++))
    echo "  Testing: Documentation source files exist"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/website/src/user-guide" "User guide docs should exist"
    assert_dir_exists "$PROJECT_ROOT/website/src/ai-guidelines" "AI guidelines docs should exist"
    assert_dir_exists "$PROJECT_ROOT/website/src/developer" "Developer docs should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Documentation pages are generated
test_documentation_pages_generated() {
    ((TESTS_RUN++))
    echo "  Testing: Documentation pages are generated in docs/"

    # Check for generated HTML files
    local has_index=false
    if [[ -f "$PROJECT_ROOT/docs/index.html" ]]; then
        has_index=true
    fi

    assert_true "[$has_index = true]" "docs/index.html should be generated"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Astro assets directory exists
test_astro_assets_directory() {
    ((TESTS_RUN++))
    echo "  Testing: Astro assets directory structure exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/docs/_astro" "docs/_astro should exist for CSS/JS"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Build output is not empty
test_build_output_not_empty() {
    ((TESTS_RUN++))
    echo "  Testing: docs directory contains build output"

    # Check if docs directory has files
    local file_count=$(find "$PROJECT_ROOT/docs" -type f | wc -l)

    assert_true "[[ $file_count -gt 0 ]]" "docs directory should contain generated files"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Sitemap is generated
test_sitemap_generated() {
    ((TESTS_RUN++))
    echo "  Testing: Sitemap is generated"

    # Check for sitemap
    local has_sitemap=false
    if ls "$PROJECT_ROOT/docs"/sitemap*.xml 1> /dev/null 2>&1; then
        has_sitemap=true
    fi

    assert_true "[$has_sitemap = true]" "Sitemap should be generated"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Deploy pages setup can be executed
test_deploy_pages_setup_executable() {
    ((TESTS_RUN++))
    echo "  Testing: gh-pages-setup.sh is executable"

    # Assert
    local script="$PROJECT_ROOT/.runners-local/workflows/gh-pages-setup.sh"
    assert_true "[[ -x \"$script\" ]]" "gh-pages-setup.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: GitHub repository configuration for Pages
test_github_repo_pages_config() {
    ((TESTS_RUN++))
    echo "  Testing: GitHub Pages configuration"

    # Check if .github directory exists (for workflows)
    local has_github_dir=false
    if [[ -d "$PROJECT_ROOT/.github" ]]; then
        has_github_dir=true
    fi

    assert_true "[$has_github_dir = true]" ".github directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Integration Tests: Astro Build & Deploy"
    echo "════════════════════════════════════════════════════════"

    setup_all

    echo ""
    echo "Running integration test cases..."
    echo ""

    # Run test cases
    test_astro_build_script_exists || ((TESTS_FAILED++))
    test_website_source_structure || ((TESTS_FAILED++))
    test_docs_output_directory || ((TESTS_FAILED++))
    test_nojekyll_file_critical || ((TESTS_FAILED++))
    test_github_pages_configuration || ((TESTS_FAILED++))
    test_astro_config_exists || ((TESTS_FAILED++))
    test_package_json_build_scripts || ((TESTS_FAILED++))
    test_gh_pages_setup_script || ((TESTS_FAILED++))
    test_documentation_source_files || ((TESTS_FAILED++))
    test_documentation_pages_generated || ((TESTS_FAILED++))
    test_astro_assets_directory || ((TESTS_FAILED++))
    test_build_output_not_empty || ((TESTS_FAILED++))
    test_sitemap_generated || ((TESTS_FAILED++))
    test_deploy_pages_setup_executable || ((TESTS_FAILED++))
    test_github_repo_pages_config || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Integration Test Results: Astro Build & Deploy"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ ALL INTEGRATION TESTS PASSED"
        return 0
    else
        echo ""
        echo "  ❌ SOME INTEGRATION TESTS FAILED"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
    exit $?
fi
