#!/bin/sh
#
# WirePusher Error Handling Example
#
# This example demonstrates:
# - Comprehensive error handling patterns
# - Exit code checking and interpretation
# - Retry logic with exponential backoff
# - Error-specific recovery strategies
# - Logging and debugging techniques
#
# Exit codes:
#   0 - Success
#   1 - Authentication error (401, 403)
#   2 - Validation error (400, 404)
#   3 - Rate limit error (429)
#   4 - Network or other error
#
# Environment variables:
#   WIREPUSHER_TOKEN - Your API token (required)
#

set -e  # Exit on error

# Source the WirePusher library
# shellcheck disable=SC1091
. "$(dirname "$0")/../wirepusher.sh"

# Check for required environment variables
if [ -z "$WIREPUSHER_TOKEN" ]; then
    echo "Error: WIREPUSHER_TOKEN environment variable is required" >&2
    echo "Usage: WIREPUSHER_TOKEN=your-token ./error-handling.sh" >&2
    exit 1
fi

echo "=== WirePusher Error Handling Examples ==="
echo ""

# Example 1: Simple error handling with exit code check
echo "1. Simple error handling (exit code check)..."
echo ""

if wirepusher_send \
    --title "Error Handling Test" \
    --message "Testing basic error handling" \
    --type "test"; then
    echo "✓ Notification sent successfully!"
else
    exit_code=$?
    echo "✗ Failed with exit code: $exit_code" >&2

    case $exit_code in
        1)
            echo "  → Authentication error: Check your WIREPUSHER_TOKEN" >&2
            ;;
        2)
            echo "  → Validation error: Check your parameters" >&2
            ;;
        3)
            echo "  → Rate limit error: Too many requests" >&2
            ;;
        4)
            echo "  → Network or API error: Check connectivity" >&2
            ;;
        *)
            echo "  → Unknown error code: $exit_code" >&2
            ;;
    esac

    exit $exit_code
fi

echo ""
echo "---"
echo ""

# Example 2: Retry logic with exponential backoff
echo "2. Retry logic with exponential backoff..."
echo ""

send_with_retry() {
    local title="$1"
    local message="$2"
    local max_attempts="${3:-5}"  # Default 5 attempts
    local attempt=1
    local delay=1

    while [ $attempt -le $max_attempts ]; do
        echo "  Attempt $attempt of $max_attempts..."

        if wirepusher_send --title "$title" --message "$message"; then
            echo "  ✓ Success on attempt $attempt"
            return 0
        fi

        exit_code=$?

        # Only retry on network/API errors (exit codes 3-4)
        # Don't retry authentication or validation errors (exit codes 1-2)
        if [ $exit_code -eq 1 ] || [ $exit_code -eq 2 ]; then
            echo "  ✗ Non-retryable error (exit code $exit_code)" >&2
            return $exit_code
        fi

        if [ $attempt -lt $max_attempts ]; then
            echo "  ⚠ Failed (exit code $exit_code), retrying in ${delay}s..."
            sleep $delay
            attempt=$((attempt + 1))
            delay=$((delay * 2))  # Exponential backoff: 1s, 2s, 4s, 8s, 16s
        else
            echo "  ✗ All $max_attempts attempts failed" >&2
            return $exit_code
        fi
    done
}

send_with_retry "Retry Test" "Testing retry logic with exponential backoff"

echo ""
echo "---"
echo ""

# Example 3: Error-specific recovery strategies
echo "3. Error-specific recovery strategies..."
echo ""

send_with_recovery() {
    local title="$1"
    local message="$2"
    local max_retries=3

    # Attempt to send
    if wirepusher_send --title "$title" --message "$message"; then
        return 0
    fi

    exit_code=$?

    echo "  ⚠ Initial send failed (exit code $exit_code)"

    case $exit_code in
        1)
            # Authentication error - check token and fail fast
            echo "  ✗ Authentication error: Invalid or expired token" >&2
            echo "  → Please verify WIREPUSHER_TOKEN is correct" >&2
            return 1
            ;;

        2)
            # Validation error - try with simpler parameters
            echo "  ⚠ Validation error: Attempting with simplified message..."

            # Retry with truncated/simplified message
            simple_message=$(printf '%s' "$message" | head -c 100)

            if wirepusher_send --title "$title" --message "$simple_message"; then
                echo "  ✓ Success with simplified message"
                return 0
            else
                echo "  ✗ Still failed with simplified message" >&2
                return 2
            fi
            ;;

        3)
            # Rate limit error - wait and retry
            echo "  ⚠ Rate limit exceeded: Waiting for reset..."

            if [ -n "$WIREPUSHER_LAST_RATE_RESET" ]; then
                current_time=$(date +%s)
                wait_time=$((WIREPUSHER_LAST_RATE_RESET - current_time + 5))

                if [ $wait_time -gt 0 ] && [ $wait_time -le 3600 ]; then
                    echo "  ⏳ Waiting $wait_time seconds for rate limit reset..."
                    sleep "$wait_time"

                    if wirepusher_send --title "$title" --message "$message"; then
                        echo "  ✓ Success after rate limit reset"
                        return 0
                    fi
                fi
            else
                # Unknown reset time, wait a minute
                echo "  ⏳ Waiting 60 seconds (reset time unknown)..."
                sleep 60

                if wirepusher_send --title "$title" --message "$message"; then
                    echo "  ✓ Success after wait"
                    return 0
                fi
            fi

            echo "  ✗ Failed after rate limit wait" >&2
            return 3
            ;;

        4)
            # Network error - retry with exponential backoff
            echo "  ⚠ Network error: Retrying with exponential backoff..."

            retry_count=1
            delay=2

            while [ $retry_count -le $max_retries ]; do
                echo "  ⏳ Retry $retry_count/$max_retries after ${delay}s delay..."
                sleep $delay

                if wirepusher_send --title "$title" --message "$message"; then
                    echo "  ✓ Success on retry $retry_count"
                    return 0
                fi

                retry_count=$((retry_count + 1))
                delay=$((delay * 2))
            done

            echo "  ✗ Failed after $max_retries retries" >&2
            return 4
            ;;

        *)
            echo "  ✗ Unknown error code: $exit_code" >&2
            return $exit_code
            ;;
    esac
}

send_with_recovery "Recovery Test" "Testing error-specific recovery strategies"

echo ""
echo "---"
echo ""

# Example 4: Logging and debugging patterns
echo "4. Logging and debugging..."
echo ""

# Enable debug mode by uncommenting this line
# set -x

send_with_logging() {
    local title="$1"
    local message="$2"
    local log_file="${3:-/tmp/wirepusher.log}"

    # Log the attempt
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Sending notification: title='$title'" >> "$log_file"

    # Capture output
    output=$(wirepusher_send --title "$title" --message "$message" 2>&1)
    exit_code=$?

    # Log the result
    if [ $exit_code -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ✓ Success: $output" >> "$log_file"
        echo "  ✓ Notification sent (logged to $log_file)"
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ✗ Failed (exit code $exit_code): $output" >> "$log_file"
        echo "  ✗ Failed (exit code $exit_code, logged to $log_file)" >&2

        # Also log rate limit information if available
        if [ -n "$WIREPUSHER_LAST_RATE_REMAINING" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Rate limit: $WIREPUSHER_LAST_RATE_REMAINING remaining" >> "$log_file"
        fi

        return $exit_code
    fi
}

# Create log file if it doesn't exist
touch /tmp/wirepusher.log

send_with_logging "Logging Test" "Testing logging and debugging patterns" "/tmp/wirepusher.log"

echo ""
echo "Recent log entries:"
tail -n 3 /tmp/wirepusher.log | sed 's/^/  /'

# Disable debug mode
# set +x

echo ""
echo "---"
echo ""

# Example 5: Batch sending with error tracking
echo "5. Batch sending with error tracking..."
echo ""

batch_send_with_tracking() {
    local notifications="$1"  # Newline-separated "title|message" pairs
    local success_count=0
    local failure_count=0
    local total_count=0

    echo "$notifications" | while IFS='|' read -r title message; do
        [ -z "$title" ] && continue

        total_count=$((total_count + 1))
        echo "  Sending: $title..."

        if wirepusher_send --title "$title" --message "$message"; then
            success_count=$((success_count + 1))
            echo "    ✓ Sent ($success_count/$total_count)"
        else
            failure_count=$((failure_count + 1))
            echo "    ✗ Failed (exit code $?)"
        fi

        # Small delay between sends
        sleep 1
    done

    echo ""
    echo "  Summary:"
    echo "    Total:    $total_count"
    echo "    Success:  $success_count"
    echo "    Failed:   $failure_count"

    # Return failure if any notifications failed
    if [ $failure_count -gt 0 ]; then
        return 1
    fi

    return 0
}

# Test batch sending
notifications="
Error Tracking Test 1|First notification in batch
Error Tracking Test 2|Second notification in batch
Error Tracking Test 3|Third notification in batch
"

if batch_send_with_tracking "$notifications"; then
    echo ""
    echo "✓ All notifications sent successfully!"
else
    echo ""
    echo "⚠ Some notifications failed"
fi

echo ""
echo "---"
echo ""

# Example 6: Defensive programming practices
echo "6. Defensive programming practices..."
echo ""

safe_send() {
    local title="$1"
    local message="$2"

    # Validate inputs
    if [ -z "$title" ]; then
        echo "Error: Title is required" >&2
        return 1
    fi

    if [ -z "$message" ]; then
        echo "Error: Message is required" >&2
        return 1
    fi

    # Check title length (max 256 chars)
    title_len=$(printf '%s' "$title" | wc -c | tr -d ' ')
    if [ "$title_len" -gt 256 ]; then
        echo "Warning: Title too long ($title_len chars), truncating..." >&2
        title=$(printf '%s' "$title" | head -c 256)
    fi

    # Check message length (max 4096 chars)
    message_len=$(printf '%s' "$message" | wc -c | tr -d ' ')
    if [ "$message_len" -gt 4096 ]; then
        echo "Warning: Message too long ($message_len chars), truncating..." >&2
        message=$(printf '%s' "$message" | head -c 4096)
    fi

    # Sanitize special characters that might cause issues
    # (Note: The library already handles JSON escaping, this is just an example)

    # Check if token is set
    if [ -z "$WIREPUSHER_TOKEN" ]; then
        echo "Error: WIREPUSHER_TOKEN not set" >&2
        return 1
    fi

    # Send with error handling
    if ! wirepusher_send --title "$title" --message "$message"; then
        exit_code=$?
        echo "Error: Failed to send notification (exit code $exit_code)" >&2
        return $exit_code
    fi

    return 0
}

# Test with valid input
safe_send "Defensive Test" "Testing defensive programming practices"

echo "  ✓ Defensive send successful"

# Test with long title (will be truncated)
long_title="This is an extremely long title that exceeds the maximum length of 256 characters. It will be automatically truncated by the safe_send function to prevent API validation errors. This demonstrates defensive programming by handling edge cases gracefully instead of failing abruptly."

echo ""
echo "  Testing with long title (300+ chars)..."
safe_send "$long_title" "Testing automatic truncation"

echo ""
echo "---"
echo ""

echo "=== All error handling examples completed! ==="
echo ""
echo "Key takeaways:"
echo "  1. Always check exit codes and handle errors appropriately"
echo "  2. Use retry logic for transient errors (network, rate limit)"
echo "  3. Don't retry authentication or validation errors"
echo "  4. Implement exponential backoff to avoid hammering the API"
echo "  5. Log errors for debugging and monitoring"
echo "  6. Validate inputs before sending to catch errors early"
echo "  7. Use error-specific recovery strategies for better reliability"
