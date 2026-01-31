# Pincho Shell Scripts - Examples

Practical examples for the Pincho shell scripts.

## Prerequisites

- **curl** - Install via `brew install curl`, `apt install curl`, or `yum install curl`
- **API Token** - Get from [pincho.dev](https://pincho.dev), set as `export PINCHO_TOKEN="your-token"`
- **Shell** - Any POSIX shell (sh, bash, zsh, etc.)

## Quick Start

```bash
export PINCHO_TOKEN="pnc_your_token"
cd examples
./simple.sh
```

## Available Examples

### simple.sh - Basic Usage

Demonstrates positional and named arguments:
```bash
./simple.sh

# Positional: pincho_send "Title" "Message"
# Named: pincho_send --title "Title" --message "Message" --type "type"
```

### cron-job.sh - Periodic Monitoring

Monitors disk (>80%), memory (>90%), and system load:
```bash
./cron-job.sh

# Add to crontab:
# */15 * * * * PINCHO_TOKEN="token" /path/to/cron-job.sh
```

### monitoring.sh - System Health Checks

Service status, SSL certificates, and disk space monitoring:
```bash
./monitoring.sh

# Customize services list:
SERVICES="nginx postgresql redis your-service"
```

### git-hook.sh - Git Integration

Install as post-receive hook to notify on git push:
```bash
cp git-hook.sh /path/to/repo/.git/hooks/post-receive
chmod +x /path/to/repo/.git/hooks/post-receive
```

Reports: repo name, branch, author, commit message, commit count

### ci-pipeline.sh - CI/CD Integration

Pipeline notifications for started/success/failed states:
```bash
./ci-pipeline.sh started
./ci-pipeline.sh success
./ci-pipeline.sh failed
```

**GitLab CI:**
```yaml
deploy:
  after_script:
    - ./ci-pipeline.sh $CI_JOB_STATUS
```

**GitHub Actions:**
```yaml
- name: Notify
  if: always()
  run: ./ci-pipeline.sh ${{ job.status }}
```

**Jenkins:**
```groovy
post {
  success { sh './ci-pipeline.sh success' }
  failure { sh './ci-pipeline.sh failed' }
}
```

### error-handling.sh - Retry Logic

Demonstrates comprehensive error handling with exponential backoff:
```bash
./error-handling.sh
```

Features: retry logic, exit code handling, logging, exponential backoff

### rate-limits.sh - Rate Limit Tracking

Monitor and track API rate limits:
```bash
./rate-limits.sh
```

Shows remaining requests, limit warnings, reset time tracking

### parallel-send.sh - Batch Operations

Send multiple notifications efficiently:
```bash
./parallel-send.sh
```

Demonstrates: sequential batch, parallel with xargs, GNU parallel

### notifai.sh - AI Text-to-Notification

Convert free-form text to structured notifications:
```bash
./notifai.sh

# Examples:
# pincho_notifai "Deploy server and restart services"
# pincho_notifai --text "SSL cert expires in 7 days" --type "security"
```

Demonstrates: NotifAI endpoint, AI conversion, multiple text formats

## Common Patterns

**Token configuration:**
```bash
export PINCHO_TOKEN="pnc_abc12345"    # Before running
PINCHO_TOKEN="pnc_abc" ./simple.sh    # Inline
export PINCHO_TOKEN=$(cat ~/.token)   # From file
```

**Batch operations:**
```bash
for server in web1 web2 web3; do
    pincho_send "Server $server" "Status OK"
done

while read -r line; do
    pincho_send "Alert" "$line"
done < notifications.txt
```

**Conditional notifications:**
```bash
usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$usage" -gt 80 ]; then
    pincho_send "Disk Alert" "Disk usage: ${usage}%"
fi
```

**With options:**
```bash
pincho_send \
    --title "Deploy Complete" \
    --message "v1.2.3" \
    --type "deployment" \
    --tag "prod" \
    --image "https://example.com/success.png" \
    --action "https://dashboard.example.com"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `curl: command not found` | Install: `brew install curl`, `apt install curl`, `yum install curl` |
| Exit code 4 / Failed to send | Check token validity and network connectivity |
| `Permission denied` | Run `chmod +x script-name.sh` |
| `No such file or directory: pincho.sh` | Source from correct path: `. ../pincho.sh` |
| Messages not appearing | Verify token, ensure app is signed in, enable notifications |

**Debug API connectivity:**
```bash
curl -v https://pincho.com
echo "Token: ${PINCHO_TOKEN:0:8}..."
```

## Documentation

- **[README.md](../README.md)** - Quick start and API reference
- **[docs/ADVANCED.md](../docs/ADVANCED.md)** - Advanced patterns, integrations, debugging
- **[docs/SECURITY.md](../docs/SECURITY.md)** - Security best practices
- **[docs/CONTRIBUTING.md](../docs/CONTRIBUTING.md)** - Development guide

All examples use POSIX shell syntax and work with sh, bash, zsh, dash on macOS, Linux, and BSD.
