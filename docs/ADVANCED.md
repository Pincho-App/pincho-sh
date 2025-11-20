# Advanced Usage Guide

This document covers advanced patterns, integrations, and best practices for the WirePusher shell scripts.

## Table of Contents

- [Error Handling Patterns](#error-handling-patterns)
- [Rate Limit Awareness](#rate-limit-awareness)
- [Batch Sending Patterns](#batch-sending-patterns)
- [Environment Management](#environment-management)
- [Integration Patterns](#integration-patterns)
- [Debugging Techniques](#debugging-techniques)
- [Performance Considerations](#performance-considerations)

## Error Handling Patterns

The library uses exit codes to indicate success or failure. Understanding these codes enables robust error handling in automation.

### Exit Codes

| Code | Meaning | Recovery Action |
|------|---------|----------------|
| 0 | Success | Continue |
| 1 | Missing required parameters | Fix script arguments |
| 2 | curl not found | Install curl |
| 3 | curl execution failed | Check network, retry |
| 4 | API returned error | Check API response, token validity |

### Basic Error Handling

```bash
#!/bin/sh
. ./wirepusher.sh

# Simple error handling
if ! wirepusher_send "Alert" "Server check" "$TOKEN"; then
    echo "Failed to send notification" >&2
    exit 1
fi
```

### Comprehensive Error Handling

```bash
#!/bin/sh
. ./wirepusher.sh

send_with_handling() {
    local title="$1"
    local message="$2"
    local token="$3"
    local exit_code

    wirepusher_send "$title" "$message" "$token"
    exit_code=$?

    case $exit_code in
        0)
            echo "Success: Notification sent"
            return 0
            ;;
        1)
            echo "Error: Missing required parameters" >&2
            return 1
            ;;
        2)
            echo "Error: curl not found - install curl" >&2
            return 2
            ;;
        3)
            echo "Error: Network or curl failure - check connectivity" >&2
            return 3
            ;;
        4)
            echo "Error: API error - check token and message" >&2
            return 4
            ;;
        *)
            echo "Error: Unknown error code $exit_code" >&2
            return $exit_code
            ;;
    esac
}

# Usage
send_with_handling "Test" "Message" "$WIREPUSHER_TOKEN"
```

### Custom Retry Logic

Implement exponential backoff for transient failures:

```bash
#!/bin/sh
. ./wirepusher.sh

send_with_retry() {
    local title="$1"
    local message="$2"
    local token="$3"
    local max_attempts=5
    local attempt=1
    local delay=1

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..."

        if wirepusher_send "$title" "$message" "$token"; then
            echo "Success on attempt $attempt"
            return 0
        fi

        exit_code=$?

        # Only retry on network/API errors (exit codes 3-4)
        if [ $exit_code -eq 1 ] || [ $exit_code -eq 2 ]; then
            echo "Non-retryable error (exit code $exit_code)" >&2
            return $exit_code
        fi

        if [ $attempt -lt $max_attempts ]; then
            echo "Failed (exit code $exit_code), retrying in ${delay}s..."
            sleep $delay
            attempt=$((attempt + 1))
            delay=$((delay * 2))  # Exponential backoff
        else
            echo "All $max_attempts attempts failed" >&2
            return $exit_code
        fi
    done
}

# Usage
send_with_retry "Alert" "Important message" "$WIREPUSHER_TOKEN"
```

### Logging Errors

```bash
#!/bin/sh
. ./wirepusher.sh

send_with_logging() {
    local title="$1"
    local message="$2"
    local token="$3"
    local timestamp
    local result

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Capture both stdout and stderr
    result=$(wirepusher_send "$title" "$message" "$token" 2>&1)
    exit_code=$?

    # Log to file
    {
        echo "[$timestamp] title=\"$title\" status=$exit_code"
        if [ $exit_code -ne 0 ]; then
            echo "[$timestamp] error: $result"
        fi
    } >> /var/log/wirepusher.log

    # Also log to syslog if available
    if command -v logger >/dev/null 2>&1; then
        logger -t wirepusher -p user.info "Sent: title=\"$title\" status=$exit_code"
    fi

    return $exit_code
}
```

## Rate Limit Awareness

### Current Status

Rate limit monitoring is not yet available in the shell scripts (as of v2.0.0). The library will be updated to support this feature in a future release.

### Planned Feature

Future versions will expose rate limit information via environment variables:

```bash
# After sending a notification
wirepusher_send "Title" "Message" "$TOKEN"

# Check rate limit info (future feature)
echo "Remaining: $WIREPUSHER_LAST_RATE_REMAINING"
echo "Limit: $WIREPUSHER_LAST_RATE_LIMIT"
echo "Reset: $WIREPUSHER_LAST_RATE_RESET"
```

### Workaround: Manual Rate Limiting

Until built-in support is available, implement manual rate limiting:

```bash
#!/bin/sh
. ./wirepusher.sh

# Track sends per hour
RATE_LIMIT_FILE="/tmp/wirepusher_sends_$(date +%Y%m%d%H).txt"
MAX_SENDS_PER_HOUR=100

send_with_rate_limit() {
    local title="$1"
    local message="$2"
    local token="$3"
    local count=0

    # Count previous sends in this hour
    if [ -f "$RATE_LIMIT_FILE" ]; then
        count=$(wc -l < "$RATE_LIMIT_FILE")
    fi

    if [ "$count" -ge "$MAX_SENDS_PER_HOUR" ]; then
        echo "Rate limit reached: $count/$MAX_SENDS_PER_HOUR sends this hour" >&2
        return 1
    fi

    # Send notification
    if wirepusher_send "$title" "$message" "$token"; then
        # Track this send
        date +%s >> "$RATE_LIMIT_FILE"
        echo "Sent successfully ($((count + 1))/$MAX_SENDS_PER_HOUR)" this hour)"
        return 0
    else
        return $?
    fi
}
```

## Batch Sending Patterns

### Sequential Sending

Simple loop with error handling:

```bash
#!/bin/sh
. ./wirepusher.sh

# Read from file (format: title|message)
while IFS='|' read -r title message; do
    if ! wirepusher_send "$title" "$message" "$WIREPUSHER_TOKEN"; then
        echo "Failed: $title" >&2
    fi
    sleep 1  # Rate limiting: 1 second between sends
done < notifications.txt
```

### Parallel Sending with xargs

For faster processing of many notifications:

```bash
#!/bin/sh
. ./wirepusher.sh

# Create a send function that can be called in parallel
send_one() {
    local line="$1"
    local title="${line%%|*}"
    local message="${line#*|}"
    wirepusher_send "$title" "$message" "$WIREPUSHER_TOKEN"
}

export -f send_one
export WIREPUSHER_TOKEN

# Send 4 at a time
cat notifications.txt | xargs -P 4 -I {} sh -c 'send_one "{}"'
```

### Parallel Sending with GNU parallel

More advanced parallel processing:

```bash
#!/bin/sh
. ./wirepusher.sh

# Install GNU parallel: brew install parallel (macOS) or apt install parallel (Linux)

# Function to send one notification
send_one() {
    local title="$1"
    local message="$2"
    wirepusher_send "$title" "$message" "$WIREPUSHER_TOKEN"
}

export -f send_one wirepusher_send
export WIREPUSHER_TOKEN

# Process file with 4 parallel jobs
parallel --colsep '|' send_one {1} {2} :::: notifications.txt
```

### Batch with Rate Limit Awareness

Combining batch sending with manual rate limiting:

```bash
#!/bin/sh
. ./wirepusher.sh

send_batch() {
    local file="$1"
    local batch_size=50
    local count=0

    while IFS='|' read -r title message; do
        if wirepusher_send "$title" "$message" "$WIREPUSHER_TOKEN"; then
            count=$((count + 1))
            echo "Sent $count notifications"

            # Pause every batch_size sends
            if [ $((count % batch_size)) -eq 0 ]; then
                echo "Pausing after $batch_size sends..."
                sleep 60  # Wait 1 minute
            fi
        fi
    done < "$file"

    echo "Batch complete: $count notifications sent"
}

send_batch notifications.txt
```

## Environment Management

### Using .env Files

Store configuration in `.env` files:

```bash
# .env
WIREPUSHER_TOKEN=abc12345
WIREPUSHER_TYPE=production
WIREPUSHER_IMAGE_URL=https://example.com/logo.png
```

Load environment variables:

```bash
#!/bin/sh
. ./wirepusher.sh

# Load .env file
load_env() {
    if [ -f ".env" ]; then
        # Simple implementation (doesn't support complex values)
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            case "$key" in
                '#'*|'') continue ;;
            esac
            eval "export $key='$value'"
        done < .env
    else
        echo "Warning: .env file not found" >&2
    fi
}

load_env

# Use loaded environment variables
wirepusher_send "Alert" "Server status" "$WIREPUSHER_TOKEN"
```

### Multi-Environment Configuration

Support dev/staging/prod environments:

```bash
#!/bin/sh
. ./wirepusher.sh

# Default to development
ENV="${ENVIRONMENT:-development}"

# Load environment-specific config
case "$ENV" in
    production)
        WIREPUSHER_TOKEN="$PROD_TOKEN"
        WIREPUSHER_TYPE="prod-alerts"
        ;;
    staging)
        WIREPUSHER_TOKEN="$STAGING_TOKEN"
        WIREPUSHER_TYPE="staging-alerts"
        ;;
    development)
        WIREPUSHER_TOKEN="$DEV_TOKEN"
        WIREPUSHER_TYPE="dev-alerts"
        ;;
    *)
        echo "Unknown environment: $ENV" >&2
        exit 1
        ;;
esac

# Send with environment-specific configuration
wirepusher_send "[$ENV] Alert" "Deployment complete" "$WIREPUSHER_TOKEN" \
    --type "$WIREPUSHER_TYPE"
```

### Secret Managers

#### GCP Secret Manager

```bash
#!/bin/sh
. ./wirepusher.sh

# Fetch token from GCP Secret Manager
WIREPUSHER_TOKEN=$(gcloud secrets versions access latest \
    --secret="wirepusher-token" 2>/dev/null)

if [ -z "$WIREPUSHER_TOKEN" ]; then
    echo "Failed to fetch token from Secret Manager" >&2
    exit 1
fi

wirepusher_send "Alert" "Message" "$WIREPUSHER_TOKEN"
```

#### AWS Secrets Manager

```bash
#!/bin/sh
. ./wirepusher.sh

# Fetch token from AWS Secrets Manager
WIREPUSHER_TOKEN=$(aws secretsmanager get-secret-value \
    --secret-id wirepusher-token \
    --query SecretString \
    --output text 2>/dev/null)

if [ -z "$WIREPUSHER_TOKEN" ]; then
    echo "Failed to fetch token from AWS Secrets Manager" >&2
    exit 1
fi

wirepusher_send "Alert" "Message" "$WIREPUSHER_TOKEN"
```

#### HashiCorp Vault

```bash
#!/bin/sh
. ./wirepusher.sh

# Fetch token from Vault
WIREPUSHER_TOKEN=$(vault kv get -field=token secret/wirepusher 2>/dev/null)

if [ -z "$WIREPUSHER_TOKEN" ]; then
    echo "Failed to fetch token from Vault" >&2
    exit 1
fi

wirepusher_send "Alert" "Message" "$WIREPUSHER_TOKEN"
```

## Integration Patterns

### Systemd Service

Create a systemd service for periodic notifications:

```ini
# /etc/systemd/system/wirepusher-monitor.service
[Unit]
Description=WirePusher Monitoring Notifications
After=network.target

[Service]
Type=oneshot
User=monitoring
Environment="WIREPUSHER_TOKEN=abc12345"
ExecStart=/usr/local/bin/send-monitoring-alert.sh

[Install]
WantedBy=multi-user.target
```

With timer for periodic execution:

```ini
# /etc/systemd/system/wirepusher-monitor.timer
[Unit]
Description=Run WirePusher monitoring every hour

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
sudo systemctl enable --now wirepusher-monitor.timer
```

### Advanced Cron Integration

#### Cron with Error Notifications

```bash
# crontab -e
# Run script hourly, send notification on failure
0 * * * * /path/to/backup.sh || /path/to/send-failure-alert.sh "$?"
```

#### Cron with Success/Failure Notifications

```bash
#!/bin/sh
# send-backup-status.sh
. /path/to/wirepusher.sh

if /path/to/backup.sh; then
    wirepusher_send "Backup Success" "Hourly backup completed" "$WIREPUSHER_TOKEN"
else
    wirepusher_send "Backup Failed" "Check backup logs (exit code $?)" "$WIREPUSHER_TOKEN"
fi
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
deploy:
  script:
    - ./deploy.sh
  after_script:
    - |
      if [ $CI_JOB_STATUS = "success" ]; then
        sh -c '. ./wirepusher.sh && wirepusher_send "Deploy Success" "Deployed $CI_COMMIT_REF_NAME" "$WIREPUSHER_TOKEN"'
      else
        sh -c '. ./wirepusher.sh && wirepusher_send "Deploy Failed" "Check logs: $CI_JOB_URL" "$WIREPUSHER_TOKEN"'
      fi
```

### GitHub Actions

```yaml
# .github/workflows/notify.yml
name: Notify on Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        run: ./deploy.sh
      - name: Send notification
        if: always()
        env:
          WIREPUSHER_TOKEN: ${{ secrets.WIREPUSHER_TOKEN }}
        run: |
          . ./wirepusher.sh
          if [ "${{ job.status }}" = "success" ]; then
            wirepusher_send "Deploy Success" "Deployed to production" "$WIREPUSHER_TOKEN"
          else
            wirepusher_send "Deploy Failed" "Check workflow logs" "$WIREPUSHER_TOKEN"
          fi
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    environment {
        WIREPUSHER_TOKEN = credentials('wirepusher-token')
    }
    stages {
        stage('Build') {
            steps {
                sh './build.sh'
            }
        }
    }
    post {
        success {
            sh '''
                . ./wirepusher.sh
                wirepusher_send "Build Success" "Build #${BUILD_NUMBER} completed" "$WIREPUSHER_TOKEN"
            '''
        }
        failure {
            sh '''
                . ./wirepusher.sh
                wirepusher_send "Build Failed" "Build #${BUILD_NUMBER} failed - check ${BUILD_URL}" "$WIREPUSHER_TOKEN"
            '''
        }
    }
}
```

## Debugging Techniques

### Enable Verbose curl Output

```bash
#!/bin/sh

# Method 1: Modify wirepusher.sh temporarily
# Find the curl command and add -v flag:
curl -v -X POST ...

# Method 2: Create debug wrapper
debug_send() {
    local title="$1"
    local message="$2"
    local token="$3"

    echo "=== DEBUG: Sending notification ===" >&2
    echo "Title: $title" >&2
    echo "Message: $message" >&2
    echo "Token: ${token:0:3}..." >&2

    wirepusher_send "$title" "$message" "$token"
    local exit_code=$?

    echo "Exit code: $exit_code" >&2
    return $exit_code
}
```

### Test Mode (Dry Run)

```bash
#!/bin/sh
. ./wirepusher.sh

DRY_RUN="${DRY_RUN:-0}"

send_notification() {
    local title="$1"
    local message="$2"
    local token="$3"

    if [ "$DRY_RUN" = "1" ]; then
        echo "[DRY RUN] Would send: title=\"$title\" message=\"$message\""
        return 0
    else
        wirepusher_send "$title" "$message" "$token"
    fi
}

# Usage: DRY_RUN=1 ./script.sh
send_notification "Test" "Message" "$WIREPUSHER_TOKEN"
```

### JSON Validation

```bash
#!/bin/sh

validate_json() {
    local json="$1"

    if command -v jq >/dev/null 2>&1; then
        echo "$json" | jq . >/dev/null 2>&1
        return $?
    elif command -v python3 >/dev/null 2>&1; then
        echo "$json" | python3 -m json.tool >/dev/null 2>&1
        return $?
    else
        echo "Warning: No JSON validator available (install jq or python3)" >&2
        return 0
    fi
}

# Example: Validate before sending
json_payload='{"title":"Test","message":"Hello"}'
if validate_json "$json_payload"; then
    echo "JSON is valid"
else
    echo "JSON is invalid" >&2
fi
```

## Performance Considerations

### Parallel Execution

Use `xargs` or GNU `parallel` for concurrent sends:

```bash
# Sequential: ~10 seconds for 10 notifications
for i in $(seq 1 10); do
    wirepusher_send "Notification $i" "Message" "$TOKEN"
done

# Parallel (4 at a time): ~2.5 seconds for 10 notifications
seq 1 10 | xargs -P 4 -I {} sh -c '. ./wirepusher.sh && wirepusher_send "Notification {}" "Message" "$TOKEN"'
```

### Minimize curl Overhead

Reuse connections when possible:

```bash
# Bad: Multiple curl invocations
for file in logs/*.txt; do
    content=$(cat "$file")
    wirepusher_send "Log: $file" "$content" "$TOKEN"
done

# Better: Process in batches
find logs/ -name '*.txt' -print0 | xargs -0 -P 4 -I {} sh -c '
    . ./wirepusher.sh
    content=$(cat "{}")
    wirepusher_send "Log: {}" "$content" "$TOKEN"
'
```

### Avoid Expensive Operations in Loops

```bash
# Bad: Source script in every iteration
for i in $(seq 1 100); do
    . ./wirepusher.sh  # Sourced 100 times!
    wirepusher_send "Alert $i" "Message" "$TOKEN"
done

# Good: Source once
. ./wirepusher.sh
for i in $(seq 1 100); do
    wirepusher_send "Alert $i" "Message" "$TOKEN"
done
```

### Memory Efficiency

Be mindful of large messages:

```bash
# Bad: Load entire file into memory
large_file_content=$(cat very-large-file.txt)
wirepusher_send "File Content" "$large_file_content" "$TOKEN"

# Good: Send summary or truncate
summary=$(head -n 50 very-large-file.txt | tail -n 10)
wirepusher_send "File Summary" "$summary" "$TOKEN"
```

---

For basic usage examples, see the [examples/](../examples/) directory.
For security best practices, see [SECURITY.md](SECURITY.md).
