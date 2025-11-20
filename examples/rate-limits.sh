#!/bin/sh
#
# WirePusher Rate Limit Monitoring Example
#
# This example demonstrates:
# - Monitoring rate limit information after API calls
# - Batch sending with rate limit awareness
# - Handling rate limit exhaustion gracefully
#
# Rate limits (default):
# - 50 requests per hour per token
# - Resets hourly based on first request timestamp
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
    echo "Usage: WIREPUSHER_TOKEN=your-token ./rate-limits.sh" >&2
    exit 1
fi

echo "=== WirePusher Rate Limit Monitoring ==="
echo ""

# Example 1: Single notification with rate limit check
echo "1. Sending notification and checking rate limits..."
echo ""

if wirepusher_send \
    --title "Rate Limit Test" \
    --message "Testing rate limit monitoring" \
    --type "test"; then

    echo ""
    echo "✓ Notification sent successfully!"
    echo ""

    # Check rate limit information (exported after API call)
    if [ -n "$WIREPUSHER_LAST_RATE_LIMIT" ]; then
        echo "Rate Limit Information:"
        echo "  Total allowed:  $WIREPUSHER_LAST_RATE_LIMIT requests/hour"
        echo "  Remaining:      $WIREPUSHER_LAST_RATE_REMAINING requests"
        echo "  Resets at:      $WIREPUSHER_LAST_RATE_RESET (Unix timestamp)"

        # Convert timestamp to human-readable format (if date command supports it)
        if date -r "$WIREPUSHER_LAST_RATE_RESET" >/dev/null 2>&1; then
            reset_time=$(date -r "$WIREPUSHER_LAST_RATE_RESET" "+%Y-%m-%d %H:%M:%S")
            echo "                  $reset_time"
        fi
    else
        echo "⚠ Rate limit headers not received from API"
    fi
else
    echo ""
    echo "✗ Failed to send notification (exit code: $?)"
    exit 1
fi

echo ""
echo "---"
echo ""

# Example 2: Batch sending with rate limit awareness
echo "2. Batch sending with rate limit monitoring..."
echo ""

# Number of notifications to send in batch
batch_size=5

echo "Sending $batch_size notifications..."
echo ""

for i in $(seq 1 $batch_size); do
    echo "Sending notification $i/$batch_size..."

    if wirepusher_send \
        --title "Batch Test $i" \
        --message "This is notification $i of $batch_size" \
        --type "batch-test" \
        --tag "batch"; then

        # Show rate limit after each send
        if [ -n "$WIREPUSHER_LAST_RATE_REMAINING" ]; then
            echo "  ✓ Sent ($WIREPUSHER_LAST_RATE_REMAINING requests remaining)"

            # Warn when getting close to rate limit
            if [ "$WIREPUSHER_LAST_RATE_REMAINING" -le 5 ]; then
                echo "  ⚠ Warning: Only $WIREPUSHER_LAST_RATE_REMAINING requests remaining!"

                if [ "$WIREPUSHER_LAST_RATE_REMAINING" -eq 0 ]; then
                    echo "  ⚠ Rate limit exhausted. Waiting for reset..."

                    # Calculate seconds until reset
                    current_time=$(date +%s)
                    seconds_until_reset=$((WIREPUSHER_LAST_RATE_RESET - current_time))

                    if [ $seconds_until_reset -gt 0 ]; then
                        echo "  ⏳ Sleeping for $seconds_until_reset seconds..."
                        sleep "$seconds_until_reset"
                        echo "  ✓ Rate limit should be reset now"
                    fi
                fi
            fi
        else
            echo "  ✓ Sent (rate limit info not available)"
        fi
    else
        exit_code=$?
        echo "  ✗ Failed (exit code: $exit_code)"

        # Handle rate limit error (exit code 3)
        if [ $exit_code -eq 3 ]; then
            echo ""
            echo "Rate limit exceeded. Stopping batch send."
            echo ""

            if [ -n "$WIREPUSHER_LAST_RATE_RESET" ]; then
                current_time=$(date +%s)
                seconds_until_reset=$((WIREPUSHER_LAST_RATE_RESET - current_time))

                if [ $seconds_until_reset -gt 0 ]; then
                    echo "Rate limit will reset in $seconds_until_reset seconds."

                    if date -r "$WIREPUSHER_LAST_RATE_RESET" >/dev/null 2>&1; then
                        reset_time=$(date -r "$WIREPUSHER_LAST_RATE_RESET" "+%Y-%m-%d %H:%M:%S")
                        echo "Reset time: $reset_time"
                    fi
                else
                    echo "Rate limit should be reset now. Try again."
                fi
            fi

            exit 3
        fi

        exit $exit_code
    fi

    echo ""

    # Small delay between requests to avoid hammering the API
    sleep 1
done

echo "✓ Batch send complete!"
echo ""
echo "---"
echo ""

# Example 3: Intelligent batch sending with automatic rate limit handling
echo "3. Intelligent batch sending (with automatic rate limit handling)..."
echo ""

send_with_rate_limit_handling() {
    local title="$1"
    local message="$2"
    local max_retries=3
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if wirepusher_send --title "$title" --message "$message"; then
            return 0
        fi

        exit_code=$?

        # Only retry on rate limit errors
        if [ $exit_code -eq 3 ]; then
            retry_count=$((retry_count + 1))

            if [ $retry_count -lt $max_retries ]; then
                echo "  ⚠ Rate limit hit. Waiting for reset (attempt $retry_count/$max_retries)..."

                if [ -n "$WIREPUSHER_LAST_RATE_RESET" ]; then
                    current_time=$(date +%s)
                    seconds_until_reset=$((WIREPUSHER_LAST_RATE_RESET - current_time + 5))

                    if [ $seconds_until_reset -gt 0 ]; then
                        echo "  ⏳ Sleeping for $seconds_until_reset seconds..."
                        sleep "$seconds_until_reset"
                    fi
                else
                    # If we don't have reset time, wait 60 seconds
                    echo "  ⏳ Sleeping for 60 seconds (rate limit reset time unknown)..."
                    sleep 60
                fi
            else
                echo "  ✗ Max retries reached"
                return $exit_code
            fi
        else
            # Non-rate-limit error, don't retry
            return $exit_code
        fi
    done

    return 3
}

# Send some test notifications with automatic rate limit handling
test_count=3

echo "Sending $test_count notifications with automatic rate limit handling..."
echo ""

for i in $(seq 1 $test_count); do
    echo "Sending notification $i/$test_count..."

    if send_with_rate_limit_handling \
        "Intelligent Batch $i" \
        "This is notification $i with automatic rate limit handling"; then

        if [ -n "$WIREPUSHER_LAST_RATE_REMAINING" ]; then
            echo "  ✓ Sent ($WIREPUSHER_LAST_RATE_REMAINING requests remaining)"
        else
            echo "  ✓ Sent"
        fi
    else
        echo "  ✗ Failed after retries"
        exit 1
    fi

    echo ""
    sleep 1
done

echo "✓ Intelligent batch send complete!"
echo ""
echo "---"
echo ""

# Final rate limit status
echo "Final rate limit status:"
if [ -n "$WIREPUSHER_LAST_RATE_LIMIT" ]; then
    echo "  Total allowed:  $WIREPUSHER_LAST_RATE_LIMIT requests/hour"
    echo "  Remaining:      $WIREPUSHER_LAST_RATE_REMAINING requests"

    # Calculate percentage used
    used=$((WIREPUSHER_LAST_RATE_LIMIT - WIREPUSHER_LAST_RATE_REMAINING))
    percentage=$((used * 100 / WIREPUSHER_LAST_RATE_LIMIT))

    echo "  Used:           $used requests ($percentage%)"

    if date -r "$WIREPUSHER_LAST_RATE_RESET" >/dev/null 2>&1; then
        reset_time=$(date -r "$WIREPUSHER_LAST_RATE_RESET" "+%Y-%m-%d %H:%M:%S")
        echo "  Resets at:      $reset_time"
    else
        echo "  Resets at:      $WIREPUSHER_LAST_RATE_RESET (Unix timestamp)"
    fi
else
    echo "  Rate limit information not available"
fi

echo ""
echo "=== All examples completed! ==="
