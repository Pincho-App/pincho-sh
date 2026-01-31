#!/bin/sh
#
# Cron Job Monitoring Example
#
# This script monitors disk space and memory usage, sending alerts
# when thresholds are exceeded. Ideal for running as a cron job.
#
# Add to crontab:
#   */15 * * * * /path/to/cron-job.sh
#
# Or run hourly:
#   0 * * * * /path/to/cron-job.sh
#

# Exit on error
set -e

# Source the library
. ../pincho.sh

# Configuration
DISK_THRESHOLD=80  # Alert if disk usage exceeds 80%
MEM_THRESHOLD=85   # Alert if memory usage exceeds 85%

# Check disk usage
check_disk_usage() {
    echo "Checking disk usage..."

    # Get disk usage for root filesystem (works on Linux and macOS)
    if df -h / | tail -1 | grep -q '[0-9]*%'; then
        usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

        if [ "$usage" -ge "$DISK_THRESHOLD" ]; then
            echo "⚠️  Disk usage is ${usage}% (threshold: ${DISK_THRESHOLD}%)"

            pincho_send \
                --title "⚠️ Disk Space Alert" \
                --message "Disk usage on $(hostname) is at ${usage}%\n\nThreshold: ${DISK_THRESHOLD}%\n\nPlease investigate and free up disk space." \
                --type "alert" \
                --tag "monitoring" \
                --tag "disk"

            return 0
        else
            echo "✓ Disk usage is ${usage}% (under threshold)"
        fi
    fi
}

# Check memory usage (Linux)
check_memory_usage_linux() {
    if ! command -v free >/dev/null 2>&1; then
        return 1
    fi

    echo "Checking memory usage (Linux)..."

    # Get memory usage percentage
    mem_info=$(free | grep Mem)
    total=$(echo "$mem_info" | awk '{print $2}')
    used=$(echo "$mem_info" | awk '{print $3}')
    usage=$((used * 100 / total))

    if [ "$usage" -ge "$MEM_THRESHOLD" ]; then
        echo "⚠️  Memory usage is ${usage}% (threshold: ${MEM_THRESHOLD}%)"

        pincho_send \
            --title "⚠️ Memory Alert" \
            --message "Memory usage on $(hostname) is at ${usage}%\n\nThreshold: ${MEM_THRESHOLD}%\n\nTop processes:\n$(ps aux --sort=-%mem | head -6)" \
            --type "alert" \
            --tag "monitoring" \
            --tag "memory"

        return 0
    else
        echo "✓ Memory usage is ${usage}% (under threshold)"
    fi
}

# Check memory usage (macOS)
check_memory_usage_macos() {
    if ! command -v vm_stat >/dev/null 2>&1; then
        return 1
    fi

    echo "Checking memory usage (macOS)..."

    # Get memory statistics
    vm_stats=$(vm_stat)
    pages_free=$(echo "$vm_stats" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    pages_active=$(echo "$vm_stats" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    pages_inactive=$(echo "$vm_stats" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    pages_wired=$(echo "$vm_stats" | grep "Pages wired" | awk '{print $4}' | sed 's/\.//')

    # Calculate usage (rough estimate)
    total=$((pages_free + pages_active + pages_inactive + pages_wired))
    used=$((pages_active + pages_wired))
    usage=$((used * 100 / total))

    if [ "$usage" -ge "$MEM_THRESHOLD" ]; then
        echo "⚠️  Memory usage is ${usage}% (threshold: ${MEM_THRESHOLD}%)"

        pincho_send \
            --title "⚠️ Memory Alert" \
            --message "Memory usage on $(hostname) is at ${usage}%\n\nThreshold: ${MEM_THRESHOLD}%\n\nTop processes:\n$(ps aux -m | head -6)" \
            --type "alert" \
            --tag "monitoring" \
            --tag "memory"

        return 0
    else
        echo "✓ Memory usage is ${usage}% (under threshold)"
    fi
}

# Main
echo "Starting system monitoring checks..."
echo ""

# Check disk usage
check_disk_usage

echo ""

# Check memory usage (try Linux first, then macOS)
if ! check_memory_usage_linux; then
    check_memory_usage_macos || echo "Memory monitoring not supported on this system"
fi

echo ""
echo "Monitoring checks complete!"
