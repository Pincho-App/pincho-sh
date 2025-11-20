# WirePusher Shell Scripts - Examples

This directory contains practical examples demonstrating various use cases for the WirePusher shell scripts.

## Prerequisites

Before running these examples, ensure you have:

1. **curl installed** - Required by the WirePusher library:
   ```bash
   # Check if curl is installed
   which curl

   # Install if needed
   # macOS: brew install curl
   # Ubuntu/Debian: sudo apt install curl
   # RHEL/CentOS: sudo yum install curl
   ```

2. **API Token** - Get your token from [wirepusher.dev](https://wirepusher.dev):
   ```bash
   export WIREPUSHER_TOKEN="your-token-here"
   ```

3. **Shell** - POSIX-compatible shell (sh, bash, dash, zsh, etc.)

## Quick Start

1. Clone the repository or download the scripts
2. Set your API token:
   ```bash
   export WIREPUSHER_TOKEN="abc12345"
   ```
3. Navigate to the examples directory:
   ```bash
   cd examples
   ```
4. Run an example:
   ```bash
   ./simple.sh
   ```

## Available Examples

### 1. simple.sh - Basic Usage

**What it does**: Demonstrates fundamental WirePusher usage with both positional and named arguments.

**Use case**: Learning the basics, quick testing

**Run it**:
```bash
export WIREPUSHER_TOKEN="your-token"
./simple.sh
```

**Key concepts**:
- Environment variable configuration
- Positional arguments (`wirepusher_send "Title" "Message"`)
- Named arguments with `--title`, `--message`, `--type`, `--tag`
- Basic error handling

**Example output**:
```
Sending simple notification...
✓ Notification sent successfully!

Sending notification with options...
✓ Notification sent successfully!

All notifications sent successfully!
```

---

### 2. notifai.sh - AI-Powered Notifications

**What it does**: Uses NotifAI to convert natural language into structured push notifications.

**Use case**: Quick notifications without manually structuring title/message

**Run it**:
```bash
export WIREPUSHER_TOKEN="your-token"
./notifai.sh
```

**Key concepts**:
- `wirepusher_notifai()` function
- Natural language to structured notification
- AI-powered title/message generation

**Example**:
```bash
# Instead of:
wirepusher_send "Deploy Complete" "Production deployment finished successfully"

# Use NotifAI:
wirepusher_notifai "the production deployment just finished successfully"
# → AI generates appropriate title and message
```

---

### 3. cron-job.sh - Periodic Monitoring

**What it does**: Monitors disk space and memory usage, sending alerts when thresholds are exceeded.

**Use case**: System monitoring, scheduled health checks

**Run it manually**:
```bash
export WIREPUSHER_TOKEN="your-token"
./cron-job.sh
```

**Add to crontab** for periodic execution:
```bash
# Edit crontab
crontab -e

# Add line to run every 15 minutes:
*/15 * * * * WIREPUSHER_TOKEN="your-token" /path/to/examples/cron-job.sh
```

**What it monitors**:
- Disk space usage (alerts if > 80%)
- Memory usage (alerts if > 90%)
- System load

**Key concepts**:
- Threshold-based alerting
- System metrics collection (`df`, `free`, `uptime`)
- Cron integration

---

### 4. monitoring.sh - System Health Checks

**What it does**: Performs comprehensive health checks: service status, SSL certificates, and disk space.

**Use case**: Scheduled system health monitoring, DevOps automation

**Run it**:
```bash
export WIREPUSHER_TOKEN="your-token"
./monitoring.sh
```

**What it checks**:
- Systemd service status (nginx, postgresql, redis, etc.)
- SSL certificate expiration (alerts if < 30 days)
- Disk space (alerts if > 80%)

**Customize** by editing the services list:
```bash
# Edit monitoring.sh
SERVICES="nginx postgresql redis your-service-here"
```

**Key concepts**:
- Service health monitoring
- SSL certificate validation
- Multiple check types in one script
- Conditional notifications (only send on problems)

---

### 5. git-hook.sh - Git Integration

**What it does**: Sends notifications when code is pushed to a Git repository.

**Use case**: Team collaboration, deployment tracking

**Installation**:
```bash
# 1. Copy to your repository's hooks directory
cp git-hook.sh /path/to/your/repo/.git/hooks/post-receive

# 2. Make it executable
chmod +x /path/to/your/repo/.git/hooks/post-receive

# 3. Set token in hook file or environment
export WIREPUSHER_TOKEN="your-token"
```

**What it reports**:
- Repository name
- Branch pushed to
- Commit author
- Commit message
- Number of commits

**Key concepts**:
- Git hook integration
- Parsing Git output
- Team notification patterns

**Example notification**:
```
Title: Git Push: main branch
Message:
Repository: my-project
Branch: main
Author: John Doe
Commits: 3
Latest: Add new feature (#123)
```

---

### 6. ci-pipeline.sh - CI/CD Integration

**What it does**: Sends notifications for CI/CD pipeline events (started, success, failure).

**Use case**: Continuous integration, deployment pipelines

**Run it**:
```bash
export WIREPUSHER_TOKEN="your-token"
./ci-pipeline.sh started   # Pipeline started
./ci-pipeline.sh success   # Pipeline succeeded
./ci-pipeline.sh failed    # Pipeline failed
```

**Integrations**:

#### GitLab CI
```yaml
# .gitlab-ci.yml
deploy:
  script:
    - ./deploy.sh
  after_script:
    - cd scripts && ./ci-pipeline.sh $CI_JOB_STATUS
```

#### GitHub Actions
```yaml
# .github/workflows/deploy.yml
- name: Notify
  if: always()
  run: ./ci-pipeline.sh ${{ job.status }}
```

#### Jenkins
```groovy
// Jenkinsfile
post {
    success { sh './ci-pipeline.sh success' }
    failure { sh './ci-pipeline.sh failed' }
}
```

**Key concepts**:
- Pipeline state notifications
- CI/CD environment variable detection
- Cross-platform CI integration

---

## Common Patterns

### Pattern 1: Environment Variable Configuration

All examples support environment-based configuration:

```bash
# Method 1: Export before running
export WIREPUSHER_TOKEN="abc12345"
./simple.sh

# Method 2: Inline environment variable
WIREPUSHER_TOKEN="abc12345" ./simple.sh

# Method 3: Load from file
export WIREPUSHER_TOKEN=$(cat ~/.wirepusher/token)
./simple.sh
```

### Pattern 2: Error Handling

Examples demonstrate different error handling approaches:

```bash
# Simple: Exit on error
set -e
wirepusher_send "Title" "Message"

# Conditional: Check exit code
if wirepusher_send "Title" "Message"; then
    echo "Success!"
else
    echo "Failed with code $?"
fi

# Capture exit code
wirepusher_send "Title" "Message"
exit_code=$?
if [ $exit_code -ne 0 ]; then
    echo "Error: Exit code $exit_code"
fi
```

### Pattern 3: Batch Operations

Send multiple notifications:

```bash
# Sequential
for server in web1 web2 web3; do
    wirepusher_send "Server $server" "Status OK" "$WIREPUSHER_TOKEN"
done

# From file
while read -r line; do
    wirepusher_send "Alert" "$line" "$WIREPUSHER_TOKEN"
done < notifications.txt
```

### Pattern 4: Conditional Notifications

Only send on specific conditions:

```bash
# Check disk space
usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$usage" -gt 80 ]; then
    wirepusher_send "Disk Alert" "Disk usage: ${usage}%" "$WIREPUSHER_TOKEN"
fi

# Check service status
if ! systemctl is-active --quiet nginx; then
    wirepusher_send "Service Down" "nginx is not running" "$WIREPUSHER_TOKEN"
fi
```

## Advanced Usage

For advanced patterns and integration techniques, see:

- **[docs/ADVANCED.md](../docs/ADVANCED.md)** - Comprehensive advanced usage guide
  - Error handling patterns
  - Retry logic
  - Parallel sending
  - Environment management
  - Integration patterns (systemd, cron, CI/CD)
  - Debugging techniques

- **[docs/SECURITY.md](../docs/SECURITY.md)** - Security best practices
  - Token storage
  - Input validation
  - Permissions
  - Secret managers

## Customization

### Modify an Example

1. Copy the example:
   ```bash
   cp simple.sh my-custom-script.sh
   ```

2. Edit for your needs:
   ```bash
   # Change notification title, message, type, tags
   wirepusher_send \
       --title "My Custom Alert" \
       --message "Custom message here" \
       --type "custom-type" \
       --tag "mytag"
   ```

3. Make it executable:
   ```bash
   chmod +x my-custom-script.sh
   ```

### Add Images or Actions

```bash
# With image
wirepusher_send \
    --title "Deploy Complete" \
    --message "v1.2.3 deployed" \
    --image-url "https://example.com/success.png"

# With action URL
wirepusher_send \
    --title "Check Dashboard" \
    --message "New metrics available" \
    --action-url "https://dashboard.example.com"
```

## Troubleshooting

### "curl: command not found"

**Solution**: Install curl using your package manager:
```bash
# macOS
brew install curl

# Ubuntu/Debian
sudo apt update && sudo apt install curl

# RHEL/CentOS
sudo yum install curl

# Alpine Linux
apk add curl
```

### "Failed to send notification" (Exit code 4)

**Possible causes**:
- Invalid API token
- Network connectivity issues
- API service unavailable

**Debug**:
```bash
# Test API connectivity
curl -v https://api.wirepusher.dev

# Verify token (should return 401 if invalid)
curl -H "Authorization: Bearer your-token" https://api.wirepusher.dev/send
```

### "Permission denied"

**Solution**: Make script executable:
```bash
chmod +x example-name.sh
```

### "No such file or directory: wirepusher.sh"

**Solution**: Ensure you're running from the examples directory or update the source path:
```bash
# From examples directory
. ../wirepusher.sh

# From elsewhere
. /full/path/to/wirepusher.sh
```

### Messages not appearing on device

**Checklist**:
1. Verify token is correct
2. Check you're using the right token (personal vs team)
3. Ensure WirePusher app is installed and signed in
4. Check device notification permissions
5. Test with simple.sh to verify basic functionality

## Getting Help

- **Documentation**: See [README.md](../README.md) for full documentation
- **Advanced patterns**: See [docs/ADVANCED.md](../docs/ADVANCED.md)
- **Security**: See [docs/SECURITY.md](../docs/SECURITY.md)
- **Issues**: Report bugs at https://gitlab.com/wirepusher/wirepusher-sh/-/issues
- **Support**: Email support@wirepusher.dev

## Contributing Examples

Have a useful example? We'd love to include it!

1. Fork the repository
2. Create your example script
3. Add documentation to this README
4. Submit a merge request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

**Note**: All examples use POSIX-compatible shell syntax and work with `sh`, `bash`, `dash`, `zsh`, and other POSIX shells. They have been tested on macOS, Linux, and BSD systems.
