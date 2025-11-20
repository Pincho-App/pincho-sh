#!/bin/sh
#
# WirePusher Parallel Send Example
#
# This example demonstrates:
# - Parallel notification sending using xargs
# - Parallel sending with GNU parallel (if available)
# - Performance comparison: sequential vs parallel
# - Safe parallel patterns with rate limit awareness
#
# Requirements:
# - xargs (standard on most systems)
# - parallel (GNU parallel, optional but recommended for advanced features)
#   Install: apt install parallel / brew install parallel
#
# Environment variables:
#   WIREPUSHER_TOKEN - Your API token (required)
#

# Note: Using 'set -e' is NOT recommended for parallel examples
# because we want to handle errors gracefully

# Source the WirePusher library
# shellcheck disable=SC1091
. "$(dirname "$0")/../wirepusher.sh"

# Check for required environment variables
if [ -z "$WIREPUSHER_TOKEN" ]; then
    echo "Error: WIREPUSHER_TOKEN environment variable is required" >&2
    echo "Usage: WIREPUSHER_TOKEN=your-token ./parallel-send.sh" >&2
    exit 1
fi

echo "=== WirePusher Parallel Sending Examples ==="
echo ""

# Helper function to send a single notification (for parallel processing)
send_one() {
    local number="$1"

    if wirepusher_send \
        --title "Parallel Test $number" \
        --message "This is notification $number sent in parallel" \
        --type "parallel-test" \
        --tag "batch"; then
        echo "✓ Sent notification $number"
        return 0
    else
        echo "✗ Failed notification $number (exit code $?)" >&2
        return 1
    fi
}

# Export the function and token for subshells
export -f send_one 2>/dev/null || true
export WIREPUSHER_TOKEN

# Example 1: Sequential sending (baseline)
echo "1. Sequential sending (baseline)..."
echo ""

sequential_count=5

echo "Sending $sequential_count notifications sequentially..."
start_time=$(date +%s)

for i in $(seq 1 $sequential_count); do
    send_one "$i"
done

end_time=$(date +%s)
sequential_duration=$((end_time - start_time))

echo ""
echo "✓ Sequential send completed in ${sequential_duration}s"
echo ""
echo "---"
echo ""

# Example 2: Parallel sending with xargs
echo "2. Parallel sending with xargs..."
echo ""

xargs_count=5
max_parallel=3  # Limit concurrent requests to avoid overwhelming API

echo "Sending $xargs_count notifications in parallel (max $max_parallel concurrent)..."
start_time=$(date +%s)

# Generate notification numbers and pipe to xargs
# -P: max parallel processes
# -n: max args per process
# -I: replacement string
seq 1 $xargs_count | xargs -P "$max_parallel" -n 1 -I {} sh -c '
    . "$(dirname "$0")/../wirepusher.sh"
    send_one() {
        local number="$1"
        if wirepusher_send \
            --title "xargs Test $number" \
            --message "Notification $number via xargs" \
            --type "xargs-test"; then
            echo "✓ Sent notification $number"
            return 0
        else
            echo "✗ Failed notification $number" >&2
            return 1
        fi
    }
    send_one {}
' sh

end_time=$(date +%s)
xargs_duration=$((end_time - start_time))

echo ""
echo "✓ Parallel send (xargs) completed in ${xargs_duration}s"

if [ $xargs_duration -lt $sequential_duration ]; then
    speedup=$((sequential_duration * 100 / xargs_duration))
    echo "  → ${speedup}% faster than sequential"
else
    echo "  → Similar time to sequential (overhead from parallelism)"
fi

echo ""
echo "---"
echo ""

# Example 3: GNU parallel (if available)
if command -v parallel >/dev/null 2>&1; then
    echo "3. Parallel sending with GNU parallel..."
    echo ""

    parallel_count=5

    echo "Sending $parallel_count notifications with GNU parallel..."
    start_time=$(date +%s)

    # GNU parallel with progress bar and job control
    seq 1 $parallel_count | parallel --jobs 3 --progress '
        . "$(dirname "$0")/../wirepusher.sh"
        if wirepusher_send \
            --title "GNU Parallel Test {}" \
            --message "Notification {} via GNU parallel" \
            --type "parallel-test"; then
            echo "✓ Sent notification {}"
        else
            echo "✗ Failed notification {}" >&2
            exit 1
        fi
    '

    end_time=$(date +%s)
    parallel_duration=$((end_time - start_time))

    echo ""
    echo "✓ Parallel send (GNU parallel) completed in ${parallel_duration}s"

    if [ $parallel_duration -lt $sequential_duration ]; then
        speedup=$((sequential_duration * 100 / parallel_duration))
        echo "  → ${speedup}% faster than sequential"
    fi

    echo ""
    echo "---"
    echo ""
else
    echo "3. GNU parallel not installed (skipping)..."
    echo ""
    echo "Install GNU parallel for advanced parallel features:"
    echo "  - Ubuntu/Debian: sudo apt install parallel"
    echo "  - macOS: brew install parallel"
    echo "  - RHEL/CentOS: sudo yum install parallel"
    echo ""
    echo "---"
    echo ""
fi

# Example 4: Parallel sending with rate limit awareness
echo "4. Parallel sending with rate limit awareness..."
echo ""

# This demonstrates a safe pattern that respects rate limits
# by checking remaining requests and adjusting concurrency

safe_parallel_send() {
    local total_count="$1"
    local max_concurrent="${2:-3}"

    echo "Sending $total_count notifications with rate limit awareness..."
    echo ""

    # Send first notification to get rate limit info
    echo "Checking rate limit status..."
    if ! wirepusher_send \
        --title "Rate Check" \
        --message "Checking rate limit before parallel send" \
        --type "rate-check"; then
        echo "✗ Failed to send initial notification" >&2
        return 1
    fi

    if [ -n "$WIREPUSHER_LAST_RATE_REMAINING" ]; then
        remaining=$WIREPUSHER_LAST_RATE_REMAINING
        echo "Rate limit status: $remaining requests remaining"

        if [ "$remaining" -lt "$total_count" ]; then
            echo "⚠ Warning: Only $remaining requests remaining, but trying to send $total_count"
            echo "  → Adjusting batch size to avoid rate limit..."
            total_count=$remaining
        fi
    else
        echo "⚠ Rate limit info not available, proceeding with caution..."
    fi

    echo ""
    echo "Sending $total_count notifications in parallel (max $max_concurrent concurrent)..."

    # Use xargs for parallel sending
    seq 1 "$total_count" | xargs -P "$max_concurrent" -n 1 -I {} sh -c '
        . "$(dirname "$0")/../wirepusher.sh"
        if wirepusher_send \
            --title "Safe Parallel {}" \
            --message "Notification {} with rate limit awareness" \
            --type "safe-parallel"; then
            echo "✓ Sent notification {}"
        else
            exit_code=$?
            echo "✗ Failed notification {} (exit code $exit_code)" >&2

            # Exit on rate limit to stop further parallel sends
            if [ $exit_code -eq 3 ]; then
                echo "⚠ Rate limit hit, stopping parallel send" >&2
                exit 3
            fi

            exit $exit_code
        fi
    ' sh

    return $?
}

safe_parallel_send 8 3

echo ""
echo "✓ Safe parallel send completed"
echo ""
echo "---"
echo ""

# Example 5: Reading from file for parallel sending
echo "5. Parallel sending from file..."
echo ""

# Create a temporary file with notification data (CSV format: title,message,type)
notifications_file=$(mktemp)
cat > "$notifications_file" <<'EOF'
File Test 1,First notification from file,file-test
File Test 2,Second notification from file,file-test
File Test 3,Third notification from file,file-test
File Test 4,Fourth notification from file,file-test
File Test 5,Fifth notification from file,file-test
EOF

echo "Sending notifications from file: $notifications_file"
echo ""

# Read file and send in parallel using xargs
cat "$notifications_file" | xargs -P 3 -n 1 -I {} sh -c '
    . "$(dirname "$0")/../wirepusher.sh"

    # Parse CSV line
    line="{}"
    title=$(echo "$line" | cut -d, -f1)
    message=$(echo "$line" | cut -d, -f2)
    type=$(echo "$line" | cut -d, -f3)

    if wirepusher_send --title "$title" --message "$message" --type "$type"; then
        echo "✓ Sent: $title"
    else
        echo "✗ Failed: $title" >&2
        exit 1
    fi
' sh

# Clean up
rm -f "$notifications_file"

echo ""
echo "✓ File-based parallel send completed"
echo ""
echo "---"
echo ""

# Performance summary
echo "=== Performance Summary ==="
echo ""
echo "Sequential: ${sequential_duration}s (baseline)"
echo "xargs:      ${xargs_duration}s"

if command -v parallel >/dev/null 2>&1; then
    echo "GNU parallel: ${parallel_duration}s"
fi

echo ""
echo "Key takeaways:"
echo "  1. Parallel sending can significantly reduce total time for batch operations"
echo "  2. Limit concurrency (3-5 concurrent) to avoid overwhelming the API"
echo "  3. Always check rate limits before large parallel batches"
echo "  4. Use xargs for simple parallelism (available everywhere)"
echo "  5. Use GNU parallel for advanced features (progress bars, job control)"
echo "  6. Handle errors gracefully - one failure shouldn't stop the whole batch"
echo "  7. Consider API rate limits when setting max concurrent requests"
echo ""
echo "=== All parallel sending examples completed! ==="
