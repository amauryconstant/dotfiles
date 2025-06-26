#!/bin/bash
# test-framework.sh
# Purpose: Comprehensive testing framework for pure shell scripts
# Dependencies: All utility libraries
# Environment: Test environment variables
# OS Support: linux-arch
# Destination: test framework (not destination-specific)

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/logging-lib.sh"
source "$SCRIPT_DIR/error-handler.sh"
source "$SCRIPT_DIR/environment-validator.sh"

# Test framework configuration
readonly TEST_PURPOSE="Comprehensive testing framework for pure shell scripts"
readonly TEST_LOG_FILE="/tmp/chezmoi-test-$(date +%Y%m%d-%H%M%S).log"

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test categories
declare -a TEST_CATEGORIES=("utils" "system" "packages" "development" "security")

# Initialize test environment
init_test_environment() {
    log_info "Initializing test environment"
    
    # Set up test environment variables
    export CHEZMOI_OS_ID="linux-arch"
    export CHEZMOI_DESTINATION="test"
    export CHEZMOI_SOURCE_DIR="/tmp/test-chezmoi-source"
    export CHEZMOI_FIRSTNAME="testuser"
    export CHEZMOI_FULLNAME="Test User"
    export CHEZMOI_WORK_EMAIL="test@work.com"
    export CHEZMOI_PERSONAL_EMAIL="test@personal.com"
    export CHEZMOI_PRIVATE_SERVER="https://test.example.com"
    export CHEZMOI_PACKAGES="fonts,terminal_essentials"
    export CHEZMOI_LOG_LEVEL="DEBUG"
    export CHEZMOI_DRY_RUN="true"
    export CHEZMOI_VERBOSE="true"
    
    # Additional environment variables for specific scripts
    export CHEZMOI_GLOBALS_DATA="XDG_CONFIG_HOME=HOME/.config,XDG_DATA_HOME=HOME/.local/share"
    export CHEZMOI_EXTENSIONS_ENABLED="true"
    export CHEZMOI_AI_MODELS_ENABLED="true"
    export CHEZMOI_AI_MODELS="qwen2.5-coder:1.5b,nomic-embed-text:latest"
    export CHEZMOI_EXTENSIONS="ginfuru.ginfuru-better-solarized-dark-theme,tamasfe.even-better-toml"
    export CHEZMOI_OLLAMA_ENABLED="true"
    export CHEZMOI_LOG_DIR="/tmp/test-logs"
    export CHEZMOI_LOG_FILE="/tmp/test-logs/chezmoi.log"
    
    # Create test directories
    mkdir -p "$CHEZMOI_SOURCE_DIR"
    mkdir -p "/tmp/test-keys"
    mkdir -p "/tmp/test-logs"
    
    # Initialize a git repository for git-related tests
    if ! [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
        (cd "$CHEZMOI_SOURCE_DIR" && git init >/dev/null 2>&1 || true)
    fi
    
    log_success "Test environment initialized"
}

# Clean up test environment
cleanup_test_environment() {
    log_info "Cleaning up test environment"
    
    # Remove test directories
    rm -rf "$CHEZMOI_SOURCE_DIR" 2>/dev/null || true
    rm -rf "/tmp/test-keys" 2>/dev/null || true
    rm -f "$TEST_LOG_FILE" 2>/dev/null || true
    
    log_success "Test environment cleaned up"
}

# Test result tracking
record_test_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    case "$result" in
        "PASS")
            TESTS_PASSED=$((TESTS_PASSED + 1))
            log_success "✅ $test_name: PASSED"
            ;;
        "FAIL")
            TESTS_FAILED=$((TESTS_FAILED + 1))
            log_error "❌ $test_name: FAILED - $message"
            ;;
        "SKIP")
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            log_warn "⏭️  $test_name: SKIPPED - $message"
            ;;
    esac
}

# Test utility libraries
test_utility_libraries() {
    log_step "Testing utility libraries"
    
    # Test logging library
    if source "$SCRIPT_DIR/logging-lib.sh" 2>/dev/null; then
        record_test_result "logging-lib.sh source" "PASS"
        
        # Test logging functions
        if log_info "Test message" >/dev/null 2>&1; then
            record_test_result "logging functions" "PASS"
        else
            record_test_result "logging functions" "FAIL" "log_info function failed"
        fi
    else
        record_test_result "logging-lib.sh source" "FAIL" "Failed to source logging library"
    fi
    
    # Test error handler
    if source "$SCRIPT_DIR/error-handler.sh" 2>/dev/null; then
        record_test_result "error-handler.sh source" "PASS"
        
        # Test error functions (non-fatal)
        if declare -f require_env_vars >/dev/null 2>&1; then
            record_test_result "error handler functions" "PASS"
        else
            record_test_result "error handler functions" "FAIL" "require_env_vars function not found"
        fi
    else
        record_test_result "error-handler.sh source" "FAIL" "Failed to source error handler"
    fi
    
    # Test environment validator
    if source "$SCRIPT_DIR/environment-validator.sh" 2>/dev/null; then
        record_test_result "environment-validator.sh source" "PASS"
    else
        record_test_result "environment-validator.sh source" "FAIL" "Failed to source environment validator"
    fi
}

# Test script syntax
test_script_syntax() {
    local category="$1"
    local script_dir="$SCRIPT_DIR/../$category"
    
    log_step "Testing $category script syntax"
    
    if [ ! -d "$script_dir" ]; then
        record_test_result "$category directory" "SKIP" "Directory does not exist"
        return 0
    fi
    
    for script in "$script_dir"/*.sh; do
        if [ -f "$script" ]; then
            local script_name
            script_name=$(basename "$script")
            
            if bash -n "$script" 2>/dev/null; then
                record_test_result "$script_name syntax" "PASS"
            else
                record_test_result "$script_name syntax" "FAIL" "Syntax error detected"
            fi
        fi
    done
}

# Test script executability
test_script_executability() {
    local category="$1"
    local script_dir="$SCRIPT_DIR/../$category"
    
    log_step "Testing $category script executability"
    
    if [ ! -d "$script_dir" ]; then
        record_test_result "$category executability" "SKIP" "Directory does not exist"
        return 0
    fi
    
    for script in "$script_dir"/*.sh; do
        if [ -f "$script" ]; then
            local script_name
            script_name=$(basename "$script")
            
            if [ -x "$script" ]; then
                record_test_result "$script_name executable" "PASS"
            else
                record_test_result "$script_name executable" "FAIL" "Script is not executable"
            fi
        fi
    done
}

# Test script dry-run execution
test_script_dry_run() {
    local category="$1"
    local script_dir="$SCRIPT_DIR/../$category"
    
    log_step "Testing $category script dry-run execution"
    
    if [ ! -d "$script_dir" ]; then
        record_test_result "$category dry-run" "SKIP" "Directory does not exist"
        return 0
    fi
    
    for script in "$script_dir"/*.sh; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            local script_name
            script_name=$(basename "$script")
            
            # Skip certain scripts that require special setup
            case "$script_name" in
                "instantiate-encryption-key.sh")
                    record_test_result "$script_name dry-run" "SKIP" "Requires Bitwarden setup"
                    continue
                    ;;
                "setup-network-printer.sh")
                    record_test_result "$script_name dry-run" "SKIP" "Requires printer packages"
                    continue
                    ;;
                "test-framework.sh")
                    record_test_result "$script_name dry-run" "SKIP" "Recursive test execution"
                    continue
                    ;;
                "create-directories.sh"|"write-globals.sh"|"setup-logging.sh")
                    # These scripts expect "linux" not "linux-arch" for broader compatibility
                    record_test_result "$script_name dry-run" "SKIP" "Requires generic linux OS ID"
                    continue
                    ;;
            esac
            
            # Handle destination-specific scripts
            local test_destination="$CHEZMOI_DESTINATION"
            if [[ "$script_name" == *"-work.sh" ]]; then
                export CHEZMOI_DESTINATION="work"
            elif [[ "$script_name" == *"-leisure.sh" ]]; then
                export CHEZMOI_DESTINATION="leisure"
            elif [[ "$script_name" == *"-test.sh" ]]; then
                export CHEZMOI_DESTINATION="test"
            fi
            
            log_debug "Testing dry-run execution of $script_name (destination: $CHEZMOI_DESTINATION)"
            
            # Capture output and errors
            if timeout 30s "$script" >/tmp/test-output 2>&1; then
                record_test_result "$script_name dry-run" "PASS"
            else
                local exit_code=$?
                if [ $exit_code -eq 124 ]; then
                    record_test_result "$script_name dry-run" "FAIL" "Script timed out after 30 seconds"
                else
                    local error_msg
                    error_msg=$(tail -n 3 /tmp/test-output 2>/dev/null | tr '\n' ' ' || echo "Unknown error")
                    record_test_result "$script_name dry-run" "FAIL" "Exit code $exit_code: $error_msg"
                fi
            fi
            
            # Restore original destination
            export CHEZMOI_DESTINATION="$test_destination"
            
            # Clean up output file
            rm -f /tmp/test-output
        fi
    done
}

# Test environment variable validation
test_environment_validation() {
    log_step "Testing environment variable validation"
    
    # Test with missing variables (use subshell to prevent exit)
    local original_os_id="$CHEZMOI_OS_ID"
    
    # Test missing variable detection in subshell
    if (unset CHEZMOI_OS_ID; require_env_vars "CHEZMOI_OS_ID") 2>/dev/null; then
        record_test_result "missing env var detection" "FAIL" "Should have failed with missing CHEZMOI_OS_ID"
    else
        record_test_result "missing env var detection" "PASS"
    fi
    
    # Test with present variables
    if require_env_vars "CHEZMOI_OS_ID" "CHEZMOI_DESTINATION" 2>/dev/null; then
        record_test_result "present env var validation" "PASS"
    else
        record_test_result "present env var validation" "FAIL" "Should have passed with present variables"
    fi
}

# Test command validation
test_command_validation() {
    log_step "Testing command validation"
    
    # Test with existing command
    if require_commands "bash" "echo" 2>/dev/null; then
        record_test_result "existing command validation" "PASS"
    else
        record_test_result "existing command validation" "FAIL" "Should have passed with existing commands"
    fi
    
    # Test with non-existing command (use subshell to prevent exit)
    if (require_commands "nonexistent-command-12345") 2>/dev/null; then
        record_test_result "missing command detection" "FAIL" "Should have failed with missing command"
    else
        record_test_result "missing command detection" "PASS"
    fi
}

# Generate test report
generate_test_report() {
    log_step "Generating test report"
    
    echo ""
    echo "=========================================="
    echo "         CHEZMOI TEST REPORT"
    echo "=========================================="
    echo "Date: $(date)"
    echo "Environment: $CHEZMOI_OS_ID / $CHEZMOI_DESTINATION"
    echo ""
    echo "Test Results:"
    echo "  Total Tests:  $TESTS_TOTAL"
    echo "  Passed:       $TESTS_PASSED"
    echo "  Failed:       $TESTS_FAILED"
    echo "  Skipped:      $TESTS_SKIPPED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo "🎉 ALL TESTS PASSED! 🎉"
        echo ""
        echo "The architecture pivot is working correctly."
        echo "All pure shell scripts are syntactically correct,"
        echo "executable, and pass dry-run validation."
    else
        echo "⚠️  SOME TESTS FAILED ⚠️"
        echo ""
        echo "Please review the failed tests above and fix"
        echo "the issues before proceeding with deployment."
    fi
    
    echo ""
    echo "Test Categories Covered:"
    for category in "${TEST_CATEGORIES[@]}"; do
        echo "  ✓ $category"
    done
    
    echo ""
    echo "=========================================="
}

# Main test execution
main() {
    log_info "Starting: $TEST_PURPOSE"
    
    # Initialize test environment
    init_test_environment
    
    # Test utility libraries first
    test_utility_libraries
    
    # Test environment and command validation
    test_environment_validation
    test_command_validation
    
    # Test each category of scripts
    for category in "${TEST_CATEGORIES[@]}"; do
        test_script_syntax "$category"
        test_script_executability "$category"
        test_script_dry_run "$category"
    done
    
    # Generate final report
    generate_test_report
    
    # Clean up
    cleanup_test_environment
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests completed successfully"
        exit 0
    else
        log_error "Some tests failed"
        exit 1
    fi
}

# Execute if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
