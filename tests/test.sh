#!/bin/sh
#
# Test Suite for Pincho Shell Scripts
#
# This test suite validates the core functionality without requiring external tools.
# It uses a mock HTTP server approach by testing the JSON generation logic.
#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Mock environment variables for testing
export PINCHO_TOKEN="test_token"
export PINCHO_URL="http://localhost:9999/send"  # Non-existent URL for safety

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Source the library (handle both running from tests/ and repo root)
if [ -f "${SCRIPT_DIR}/../pincho.sh" ]; then
    . "${SCRIPT_DIR}/../pincho.sh"
elif [ -f "./pincho.sh" ]; then
    . ./pincho.sh
else
    echo "Error: Cannot find pincho.sh" >&2
    exit 1
fi

# Test framework functions
test_start() {
    TESTS_RUN=$((TESTS_RUN + 1))
    printf "Test %d: %s ... " "$TESTS_RUN" "$1"
}

test_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    printf "${GREEN}PASS${NC}\n"
}

test_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf "${RED}FAIL${NC}\n"
    if [ -n "$1" ]; then
        printf "  Error: %s\n" "$1"
    fi
}

# Test: JSON escaping
test_json_escaping() {
    test_start "JSON escaping with quotes"

    input='Hello "World"'
    expected='Hello \"World\"'
    result=$(_pincho_escape_json "$input")

    if [ "$result" = "$expected" ]; then
        test_pass
    else
        test_fail "Expected: $expected, Got: $result"
    fi
}

# Test: JSON escaping with backslashes
test_json_escaping_backslash() {
    test_start "JSON escaping with backslashes"

    input='C:\Users\Test'
    result=$(_pincho_escape_json "$input")

    # Should escape backslashes
    if echo "$result" | grep -q '\\\\'; then
        test_pass
    else
        test_fail "Backslashes not properly escaped"
    fi
}

# Test: Validation - missing title
test_validation_missing_title() {
    test_start "Validation error on missing title"

    # Capture output and exit code
    output=$(pincho_send "" "Message" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 2 ] && echo "$output" | grep -q "Title is required"; then
        test_pass
    else
        test_fail "Expected validation error for missing title"
    fi
}

# Test: Validation - missing message
test_validation_missing_message() {
    test_start "Validation error on missing message"

    output=$(pincho_send "Title" "" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 2 ] && echo "$output" | grep -q "Message is required"; then
        test_pass
    else
        test_fail "Expected validation error for missing message"
    fi
}

# Test: Validation - missing token
test_validation_missing_token() {
    test_start "Validation error on missing token"

    # Temporarily unset token
    old_token="$PINCHO_TOKEN"
    unset PINCHO_TOKEN

    output=$(pincho_send "Title" "Message" 2>&1)
    exit_code=$?

    # Restore token
    export PINCHO_TOKEN="$old_token"

    if [ $exit_code -eq 2 ] && echo "$output" | grep -q "PINCHO_TOKEN"; then
        test_pass
    else
        test_fail "Expected validation error for missing token"
    fi
}

# Test: Validation - title too long
test_validation_title_too_long() {
    test_start "Validation error on title too long"

    long_title=$(printf 'a%.0s' $(seq 1 257))
    output=$(pincho_send "$long_title" "Message" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 2 ] && echo "$output" | grep -q "256 characters"; then
        test_pass
    else
        test_fail "Expected validation error for title too long"
    fi
}

# Test: Validation - message too long
test_validation_message_too_long() {
    test_start "Validation error on message too long"

    long_message=$(printf 'a%.0s' $(seq 1 4097))
    output=$(pincho_send "Title" "$long_message" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 2 ] && echo "$output" | grep -q "4096 characters"; then
        test_pass
    else
        test_fail "Expected validation error for message too long"
    fi
}

# Test: Named arguments parsing
test_named_arguments() {
    test_start "Named arguments parsing"

    # This will fail with network error, but we're testing argument parsing
    output=$(pincho_send --title "Test" --message "Message" --type "info" 2>&1)

    # Should not fail with validation error
    if ! echo "$output" | grep -q "Title is required"; then
        test_pass
    else
        test_fail "Named arguments not parsed correctly"
    fi
}

# Test: Dependency check
test_dependency_check() {
    test_start "Dependency check for curl"

    if pincho_check_dependencies >/dev/null 2>&1; then
        test_pass
    else
        test_fail "Dependency check failed"
    fi
}

# Test: Version function
test_version_function() {
    test_start "Version function returns output"

    output=$(pincho_version)

    if [ -n "$output" ] && echo "$output" | grep -q "Pincho"; then
        test_pass
    else
        test_fail "Version function did not return expected output"
    fi
}

# Run all tests
run_tests() {
    printf "\n"
    printf "=======================================================\n"
    printf "  Pincho Shell Scripts Test Suite\n"
    printf "=======================================================\n\n"

    test_json_escaping
    test_json_escaping_backslash
    test_validation_missing_title
    test_validation_missing_message
    test_validation_missing_token
    test_validation_title_too_long
    test_validation_message_too_long
    test_named_arguments
    test_dependency_check
    test_version_function

    printf "\n"
    printf "=======================================================\n"
    printf "  Test Results\n"
    printf "=======================================================\n"
    printf "Tests run:    %d\n" "$TESTS_RUN"
    printf "${GREEN}Tests passed: %d${NC}\n" "$TESTS_PASSED"

    if [ $TESTS_FAILED -gt 0 ]; then
        printf "${RED}Tests failed: %d${NC}\n" "$TESTS_FAILED"
        printf "\n"
        return 1
    else
        printf "Tests failed: %d\n" "$TESTS_FAILED"
        printf "\n${GREEN}All tests passed!${NC}\n\n"
        return 0
    fi
}

# Main
run_tests
