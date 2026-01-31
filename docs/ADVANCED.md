# Advanced Usage Guide

Advanced patterns, integrations, and best practices for Pincho shell scripts.

## Table of Contents

- [Error Handling Patterns](#error-handling-patterns)
- [Rate Limit Management](#rate-limit-management)
- [Batch Sending Patterns](#batch-sending-patterns)
- [NotifAI (Text-to-Notification)](#notifai-text-to-notification)
- [Environment Management](#environment-management)
- [Integration Patterns](#integration-patterns)
- [Shell Scripting Best Practices](#shell-scripting-best-practices)
- [Debugging Techniques](#debugging-techniques)

## Error Handling Patterns

### Exit Codes

| Code | Meaning | Recovery Action |
|------|---------|----------------|
| 0 | Success | Continue |
| 1 | Authentication error | Fix token |
| 2 | Validation error | Fix parameters |
| 3 | Rate limit error | Wait and retry |
| 4 | Network error | Check connection, retry |

### Comprehensive Error Handling with Retry Logic

```bash
#!/bin/sh
. ./pincho.sh

send_with_retry() {
    local title="$1"
    local message="$2"
    local max_attempts=5
    local attempt=1
    local delay=1

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..."

        if pincho_send "$title" "$message"; then
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
```

### Logging with Syslog Integration

```bash
#!/bin/sh
. ./pincho.sh

send_with_logging() {
    local title="$1"
    local message="$2"
    local timestamp
    local result

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    result=$(pincho_send "$title" "$message" 2>&1)
    exit_code=$?

    # Log to file
    {
        echo "[$timestamp] title=\"$title\" status=$exit_code"
        if [ $exit_code -ne 0 ]; then
            echo "[$timestamp] error: $result"
        fi
    } >> /var/log/pincho.log

    # Log to syslog if available
    if command -v logger >/dev/null 2>&1; then
        logger -t pincho -p user.info "Sent: title=\"$title\" status=$exit_code"
    fi

    return $exit_code
}
```

## Rate Limit Management

### Tracking Rate Limits

```bash
#!/bin/sh
. ./pincho.sh

send_with_rate_check() {
    local title="$1"
    local message="$2"

    pincho_send "$title" "$message"
    exit_code=$?

    if [ -n "$PINCHO_LAST_RATE_REMAINING" ]; then
        echo "Rate limit: $PINCHO_LAST_RATE_REMAINING remaining"

        # Warn if approaching limit
        if [ "$PINCHO_LAST_RATE_REMAINING" -lt 10 ]; then
            echo "WARNING: Only $PINCHO_LAST_RATE_REMAINING requests remaining!" >&2
        fi
    fi

    return $exit_code
}
```

### Batch with Rate Limit Pauses

```bash
#!/bin/sh
. ./pincho.sh

send_batch() {
    local file="$1"
    local batch_size=50
    local count=0

    while IFS='|' read -r title message; do
        if pincho_send "$title" "$message"; then
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
```

## Batch Sending Patterns

### Sequential with Error Handling

```bash
#!/bin/sh
. ./pincho.sh

# Read from file (format: title|message)
while IFS='|' read -r title message; do
    if ! pincho_send "$title" "$message"; then
        echo "Failed: $title" >&2
    fi
    sleep 1  # Rate limiting: 1 second between sends
done < notifications.txt
```

### Parallel Sending with xargs

```bash
#!/bin/sh
. ./pincho.sh

send_one() {
    local line="$1"
    local title="${line%%|*}"
    local message="${line#*|}"
    pincho_send "$title" "$message"
}

export -f send_one
export PINCHO_TOKEN

# Send 4 at a time
cat notifications.txt | xargs -P 4 -I {} sh -c 'send_one "{}"'
```

### GNU parallel (Advanced)

```bash
#!/bin/sh
. ./pincho.sh

send_one() {
    local title="$1"
    local message="$2"
    pincho_send "$title" "$message"
}

export -f send_one pincho_send
export PINCHO_TOKEN

# Process file with 4 parallel jobs
parallel --colsep '|' send_one {1} {2} :::: notifications.txt
```

## NotifAI (Text-to-Notification)

NotifAI uses AI to convert free-form text into structured notifications. Useful for automation workflows where you have log messages, alerts, or status updates that should become notifications.

### Basic Usage

```bash
#!/bin/sh
. ./pincho.sh

# Convert simple text
pincho_notifai "Deploy server and restart all services"

# With type
pincho_notifai --text "SSL certificate expires in 7 days" --type "security"

# From command output
disk_status=$(df -h / | tail -1)
pincho_notifai "Disk status: $disk_status"
```

### Processing Log Files

```bash
#!/bin/sh
. ./pincho.sh

# Send errors from log file
tail -n 50 /var/log/app.log | grep ERROR | while read -r line; do
    pincho_notifai "$line" --type "errors"
    sleep 1  # Rate limiting
done
```

### CI/CD Integration

```bash
#!/bin/sh
. ./pincho.sh

# Convert build status to notification
build_output=$(make build 2>&1 | tail -10)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    pincho_notifai "Build succeeded. $build_output" --type "ci-cd"
else
    pincho_notifai "Build failed with exit code $exit_code. $build_output" --type "ci-cd"
fi
```

### Monitoring Automation

```bash
#!/bin/sh
. ./pincho.sh

# Check service health and convert to notification
check_service() {
    local service="$1"

    if systemctl is-active --quiet "$service"; then
        status="running"
    else
        status="stopped"
        pincho_notifai "Service $service is $status - requires attention" --type "monitoring"
    fi
}

check_service "nginx"
check_service "postgresql"
check_service "redis"
```

### Processing Complex Status Messages

```bash
#!/bin/sh
. ./pincho.sh

# Aggregate system metrics
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
mem=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
disk=$(df -h / | awk 'NR==2{print $5}')

status="System health check: CPU usage ${cpu}%, Memory usage ${mem}, Disk usage ${disk}"
pincho_notifai "$status" --type "monitoring"
```

### Batch Processing with NotifAI

```bash
#!/bin/sh
. ./pincho.sh

# Process alerts from file
while read -r alert; do
    if pincho_notifai "$alert" --type "alerts"; then
        echo "Processed: $alert"
    else
        echo "Failed: $alert" >&2
    fi
    sleep 2  # Rate limiting (50 requests/hour)
done < alerts.txt
```

### Error Handling with NotifAI

```bash
#!/bin/sh
. ./pincho.sh

send_notifai_with_retry() {
    local text="$1"
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if pincho_notifai "$text"; then
            return 0
        fi

        exit_code=$?

        # Only retry on network/API errors
        if [ $exit_code -eq 1 ] || [ $exit_code -eq 2 ]; then
            echo "Non-retryable error (exit code $exit_code)" >&2
            return $exit_code
        fi

        if [ $attempt -lt $max_attempts ]; then
            echo "Attempt $attempt failed, retrying..." >&2
            sleep $((attempt * 2))
            attempt=$((attempt + 1))
        else
            echo "All attempts failed" >&2
            return $exit_code
        fi
    done
}
```

## Environment Management

### Multi-Environment Configuration

```bash
#!/bin/sh
. ./pincho.sh

# Default to development
ENV="${ENVIRONMENT:-development}"

case "$ENV" in
    production)
        PINCHO_TOKEN="$PROD_TOKEN"
        NOTIFICATION_TYPE="prod-alerts"
        ;;
    staging)
        PINCHO_TOKEN="$STAGING_TOKEN"
        NOTIFICATION_TYPE="staging-alerts"
        ;;
    development)
        PINCHO_TOKEN="$DEV_TOKEN"
        NOTIFICATION_TYPE="dev-alerts"
        ;;
    *)
        echo "Unknown environment: $ENV" >&2
        exit 1
        ;;
esac

pincho_send \
    --title "[$ENV] Alert" \
    --message "Deployment complete" \
    --type "$NOTIFICATION_TYPE"
```

### Secret Manager Integration

**GCP Secret Manager:**
```bash
PINCHO_TOKEN=$(gcloud secrets versions access latest \
    --secret="pincho-token" 2>/dev/null)

if [ -z "$PINCHO_TOKEN" ]; then
    echo "Failed to fetch token from Secret Manager" >&2
    exit 1
fi
```

**AWS Secrets Manager:**
```bash
PINCHO_TOKEN=$(aws secretsmanager get-secret-value \
    --secret-id pincho-token \
    --query SecretString \
    --output text 2>/dev/null)
```

**HashiCorp Vault:**
```bash
PINCHO_TOKEN=$(vault kv get -field=token secret/pincho 2>/dev/null)
```

## Integration Patterns

### Systemd Service with Timer

Service file (`/etc/systemd/system/pincho-monitor.service`):
```ini
[Unit]
Description=Pincho Monitoring Notifications
After=network.target

[Service]
Type=oneshot
User=monitoring
Environment="PINCHO_TOKEN=pnc_your_token"
ExecStart=/usr/local/bin/send-monitoring-alert.sh

[Install]
WantedBy=multi-user.target
```

Timer file (`/etc/systemd/system/pincho-monitor.timer`):
```ini
[Unit]
Description=Run Pincho monitoring every hour

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h

[Install]
WantedBy=timers.target
```

Enable: `sudo systemctl enable --now pincho-monitor.timer`

### Cron with Success/Failure Notifications

```bash
#!/bin/sh
# send-backup-status.sh
. /usr/local/lib/pincho/pincho.sh

if /path/to/backup.sh; then
    pincho_send "Backup Success" "Hourly backup completed"
else
    pincho_send "Backup Failed" "Check backup logs (exit code $?)"
fi
```

Crontab entry:
```bash
# Run script hourly with status notifications
0 * * * * /path/to/send-backup-status.sh
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
        sh -c '. ./pincho.sh && pincho_send "Deploy Success" "Deployed $CI_COMMIT_REF_NAME"'
      else
        sh -c '. ./pincho.sh && pincho_send "Deploy Failed" "Check logs: $CI_JOB_URL"'
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
          PINCHO_TOKEN: ${{ secrets.PINCHO_TOKEN }}
        run: |
          . ./pincho.sh
          if [ "${{ job.status }}" = "success" ]; then
            pincho_send "Deploy Success" "Deployed to production"
          else
            pincho_send "Deploy Failed" "Check workflow logs"
          fi
```

### Jenkins Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    environment {
        PINCHO_TOKEN = credentials('pincho-token')
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
                . ./pincho.sh
                pincho_send "Build Success" "Build #${BUILD_NUMBER} completed"
            '''
        }
        failure {
            sh '''
                . ./pincho.sh
                pincho_send "Build Failed" "Build #${BUILD_NUMBER} failed - check ${BUILD_URL}"
            '''
        }
    }
}
```

## Shell Scripting Best Practices

### POSIX Compliance

**POSIX-compliant (portable across sh, bash, dash, ash):**
```bash
#!/bin/sh
# Works on any POSIX shell

# Use [ ] for tests (not [[ ]])
if [ "$var" = "value" ]; then
    echo "Match"
fi

# Use = for string comparison (not ==)
# Use -eq for numeric comparison
if [ "$count" -eq 10 ]; then
    echo "Count is 10"
fi

# Avoid bash-specific features
# NO: [[ ]], process substitution <(), arrays
```

**Bash-specific (requires bash):**
```bash
#!/bin/bash
# Requires bash, won't work with /bin/sh on some systems

# Double brackets for advanced tests
if [[ "$var" == "value" ]]; then
    echo "Match"
fi

# Arrays
declare -a notifications=("Alert 1" "Alert 2")

# Process substitution
while read -r line; do
    echo "$line"
done < <(command)
```

### Performance Best Practices

**Source once, not in loops:**
```bash
# Bad: Source script 100 times
for i in $(seq 1 100); do
    . ./pincho.sh  # Sourced 100 times!
    pincho_send "Alert $i" "Message"
done

# Good: Source once
. ./pincho.sh
for i in $(seq 1 100); do
    pincho_send "Alert $i" "Message"
done
```

**Use parallel execution:**
```bash
# Sequential: ~10 seconds for 10 notifications
for i in $(seq 1 10); do
    pincho_send "Notification $i" "Message"
done

# Parallel (4 at a time): ~2.5 seconds for 10 notifications
seq 1 10 | xargs -P 4 -I {} sh -c '. ./pincho.sh && pincho_send "Notification {}" "Message"'
```

**Memory efficiency:**
```bash
# Bad: Load entire file into memory
large_file_content=$(cat very-large-file.txt)
pincho_send "File Content" "$large_file_content"

# Good: Send summary or truncate
summary=$(head -n 50 very-large-file.txt | tail -n 10)
pincho_send "File Summary" "$summary"
```

### Security Best Practices

**Secure credential storage:**
```bash
# Bad: Credentials in script
PINCHO_TOKEN="pnc_abc123..."

# Good: Environment variables
export PINCHO_TOKEN  # Set externally

# Better: Secret managers
PINCHO_TOKEN=$(gcloud secrets versions access latest --secret="pincho-token")
```

**Validate inputs:**
```bash
#!/bin/sh
. ./pincho.sh

# Validate required environment variables
if [ -z "$PINCHO_TOKEN" ]; then
    echo "Error: PINCHO_TOKEN not set" >&2
    exit 1
fi

# Sanitize user input
title=$(echo "$1" | tr -d '\n\r' | cut -c1-256)
message=$(echo "$2" | tr -d '\r' | cut -c1-4096)

pincho_send "$title" "$message"
```

## Debugging Techniques

### Debug Wrapper

```bash
#!/bin/sh

debug_send() {
    local title="$1"
    local message="$2"

    echo "=== DEBUG: Sending notification ===" >&2
    echo "Title: $title" >&2
    echo "Message: $message" >&2
    echo "Token: ${PINCHO_TOKEN:0:8}..." >&2

    pincho_send "$title" "$message"
    local exit_code=$?

    echo "Exit code: $exit_code" >&2

    # Show rate limit info if available
    if [ -n "$PINCHO_LAST_RATE_REMAINING" ]; then
        echo "Rate remaining: $PINCHO_LAST_RATE_REMAINING" >&2
    fi

    return $exit_code
}
```

### Dry Run Mode

```bash
#!/bin/sh
. ./pincho.sh

DRY_RUN="${DRY_RUN:-0}"

send_notification() {
    local title="$1"
    local message="$2"

    if [ "$DRY_RUN" = "1" ]; then
        echo "[DRY RUN] Would send: title=\"$title\" message=\"$message\""
        return 0
    else
        pincho_send "$title" "$message"
    fi
}

# Usage: DRY_RUN=1 ./script.sh
```

### Verbose Mode

```bash
#!/bin/sh
set -x  # Enable command tracing
. ./pincho.sh

pincho_send "Test" "Message"

set +x  # Disable command tracing
```

## Troubleshooting

### "Authentication failed"

Check token:
```bash
echo "Token: ${PINCHO_TOKEN:0:8}..."
echo "Length: ${#PINCHO_TOKEN}"
```

Verify in app: Settings → Help → copy token

### "curl: command not found"

Install curl:
```bash
# Debian/Ubuntu
sudo apt-get install curl

# RedHat/CentOS
sudo yum install curl

# Alpine
apk add curl
```

### Network errors

Test connectivity:
```bash
curl -I https://pincho.com
```

Check DNS resolution:
```bash
nslookup pincho.com
```

### Rate limit debugging

```bash
#!/bin/sh
. ./pincho.sh

pincho_send "Test" "Message"

echo "Limit: $PINCHO_LAST_RATE_LIMIT"
echo "Remaining: $PINCHO_LAST_RATE_REMAINING"
echo "Reset: $PINCHO_LAST_RATE_RESET"

# Convert reset timestamp to readable date
if [ -n "$PINCHO_LAST_RATE_RESET" ]; then
    date -d "@$PINCHO_LAST_RATE_RESET" 2>/dev/null || \
    date -r "$PINCHO_LAST_RATE_RESET" 2>/dev/null
fi
```

---

For basic usage, see [README.md](../README.md).
For security practices, see [SECURITY.md](SECURITY.md).
For complete examples, see [examples/](../examples/).
