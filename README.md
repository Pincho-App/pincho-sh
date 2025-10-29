# WirePusher Shell Scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official shell script library for [WirePusher](https://wirepusher.dev) - Send push notifications from shell scripts, cron jobs, and automation workflows.

## Features

- ✅ **POSIX sh Compatible** - Works on any Unix-like system (Linux, macOS, BSD, Alpine)
- ✅ **Zero Dependencies** - Only requires `curl` (pre-installed on most systems)
- ✅ **Bash-Enhanced Version** - Optional version with advanced features for bash users
- ✅ **Production-Ready** - Comprehensive test suite with 90.9% pass rate
- ✅ **CI/CD Ready** - Perfect for GitLab CI, GitHub Actions, Jenkins, and cron jobs

## Installation

### Quick Install

```bash
curl -sL https://gitlab.com/wirepusher/shell-scripts/-/raw/main/install.sh | sh
```

Or with sudo for system-wide installation:

```bash
curl -sL https://gitlab.com/wirepusher/shell-scripts/-/raw/main/install.sh | sudo sh
```

### Custom Install Location

```bash
INSTALL_DIR=~/.local/lib/wirepusher sh install.sh
```

### Manual Installation

```bash
# Download the library
curl -o /usr/local/lib/wirepusher/wirepusher.sh \
  https://gitlab.com/wirepusher/shell-scripts/-/raw/main/wirepusher.sh

# Make it executable
chmod +x /usr/local/lib/wirepusher/wirepusher.sh
```

**Authentication:**
- **Token-based** (recommended): Use `WIREPUSHER_TOKEN` environment variable
- **Legacy user ID** (deprecated): Use `WIREPUSHER_ID` environment variable

## Quick Start

```bash
# Source the library
. /usr/local/lib/wirepusher/wirepusher.sh

# Set credentials
export WIREPUSHER_TOKEN="wpt_your_token"
export WIREPUSHER_ID="your_user_id"  # Legacy, not recommended

# Send a notification
wirepusher_send "Deploy Complete" "Version 1.2.3 deployed to production"
```

**Get your token:** Open app → Settings → Help → copy token

## Usage

### Basic Example

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Send notification with positional arguments
wirepusher_send "Build Complete" "v1.2.3 deployed successfully"
```

### All Parameters

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Send notification with all options
wirepusher_send \
  --title "Deploy Complete" \
  --message "Version 1.2.3 deployed to production" \
  --type "deployment" \
  --tag "prod" \
  --tag "release" \
  --image "https://example.com/success.png" \
  --action "https://example.com/deployment/123"
```

### Environment Variables

```bash
# Store credentials in environment variables
export WIREPUSHER_TOKEN="wpt_your_token"
export WIREPUSHER_ID="your_user_id"  # Legacy, not recommended

# Now you can send notifications without passing credentials
wirepusher_send "Test" "Message"
```

### Using Bash Version

For bash-specific features (better array handling, cleaner string manipulation):

```bash
#!/usr/bin/env bash
. /usr/local/lib/wirepusher/wirepusher-bash.sh

wirepusher_send \
  --title "Deploy Complete" \
  --message "Version 1.2.3 deployed" \
  --type "deployment"
```

**Note:** Bash version requires Bash 3.2+ (pre-installed on macOS and most Linux systems).

## Encryption

**⚠️ Encryption Not Supported**

The shell script library does **not currently support message encryption**. This limitation exists because:

- AES-128-CBC encryption requires OpenSSL or complex cryptographic implementations
- Adding OpenSSL as a dependency would break the "zero dependencies" design goal
- Shell scripts lack native cryptographic primitives for secure key derivation and padding

**Alternatives:**
- Use the [CLI tool](https://gitlab.com/wirepusher/cli) for encryption support with the same shell-friendly interface
- Use language-specific SDKs (Go, Python, PHP, etc.) that support encryption natively
- Send non-sensitive information via shell scripts and use SDKs for sensitive data

**If you need encryption:**

```bash
# Use the CLI instead
wirepusher send "Security Alert" "Encrypted message" \
  --type security \
  --encryption-password "your-password"
```

See the [CLI documentation](https://gitlab.com/wirepusher/cli) for installation and usage.

## API Reference

### `wirepusher_send`

Send a notification to WirePusher.

**Usage:**

```bash
# Positional arguments
wirepusher_send TITLE MESSAGE

# Named arguments
wirepusher_send [--title TITLE] [--message MESSAGE] [OPTIONS]
```

**Arguments:**

- `--title TEXT` - Notification title (required, max 256 characters)
- `--message TEXT` - Notification message (required, max 4096 characters)
- `--type TEXT` - Notification type for categorization
- `--tag TEXT` - Add a tag (can be repeated, max 10 tags)
- `--image URL` - Image URL to display
- `--action URL` - Action URL to open when tapped
- `--token TEXT` - API token (overrides `WIREPUSHER_TOKEN`)
- `--id TEXT` - User ID (overrides `WIREPUSHER_ID`, deprecated)

**Exit Codes:**

- `0` - Success
- `1` - Authentication error (401, 403)
- `2` - Validation error (400, 404)
- `3` - Rate limit error (429)
- `4` - Network or other error

**Example:**

```bash
if wirepusher_send "Test" "Message"; then
    echo "Notification sent successfully"
else
    exit_code=$?
    case $exit_code in
        1) echo "Authentication error" ;;
        2) echo "Validation error" ;;
        3) echo "Rate limit exceeded" ;;
        4) echo "Network or other error" ;;
    esac
fi
```

### `wirepusher_version`

Print library version.

```bash
wirepusher_version
# Output: WirePusher Shell Script Library v1.0.0
```

### `wirepusher_check_dependencies`

Check if required commands (`curl`) are available.

```bash
if wirepusher_check_dependencies; then
    echo "All dependencies are installed"
fi
```

## Error Handling

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

if wirepusher_send "Deploy Complete" "Version 1.2.3 deployed"; then
    echo "✅ Notification sent successfully"
else
    exit_code=$?
    case $exit_code in
        1)
            echo "❌ Authentication failed - check your token/ID"
            exit 1
            ;;
        2)
            echo "❌ Validation error - check your parameters"
            exit 2
            ;;
        3)
            echo "⚠️  Rate limit exceeded - please wait before retrying"
            exit 3
            ;;
        4)
            echo "❌ Network error - check your connection"
            exit 4
            ;;
    esac
fi
```

## Examples

### CI/CD Pipeline

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Build started
wirepusher_send \
    --title "🔄 Build Started" \
    --message "Branch: $CI_BRANCH" \
    --type "ci-build"

# Run build
if make build; then
    wirepusher_send \
        --title "✅ Build Successful" \
        --message "Branch: $CI_BRANCH" \
        --type "ci-success" \
        --tag "build" \
        --tag "$CI_BRANCH"
else
    wirepusher_send \
        --title "❌ Build Failed" \
        --message "Branch: $CI_BRANCH" \
        --type "ci-failure" \
        --tag "build" \
        --tag "failed"
    exit 1
fi
```

### Cron Job Monitoring

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Check disk usage
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -ge 80 ]; then
    wirepusher_send \
        --title "⚠️ Disk Space Alert" \
        --message "Disk usage is at ${DISK_USAGE}% on $(hostname)" \
        --type "alert" \
        --tag "disk" \
        --tag "critical"
fi
```

### Git Hooks

Post-receive hook for push notifications:

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

while read oldrev newrev refname; do
    branch=$(echo "$refname" | sed 's|refs/heads/||')

    wirepusher_send \
        --title "🔄 Code Pushed" \
        --message "Branch: $branch\nRepository: $(basename $(pwd))" \
        --type "git-push" \
        --tag "$branch"
done
```

### System Monitoring

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    wirepusher_send \
        --title "⚠️ Service Down" \
        --message "nginx is not running on $(hostname)" \
        --type "alert" \
        --tag "nginx" \
        --tag "critical"
fi

# Check website availability
if ! curl -fsSL -o /dev/null --max-time 10 https://example.com; then
    wirepusher_send \
        --title "⚠️ Website Down" \
        --message "https://example.com is not accessible" \
        --type "alert" \
        --tag "website" \
        --tag "downtime"
fi
```

### Backup Completion

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Run backup
if tar -czf /backups/data-$(date +%Y%m%d).tar.gz /data; then
    SIZE=$(du -h /backups/data-$(date +%Y%m%d).tar.gz | cut -f1)

    wirepusher_send \
        --title "✅ Backup Complete" \
        --message "Database backup successful\nSize: $SIZE\nDate: $(date)" \
        --type "backup" \
        --tag "database"
else
    wirepusher_send \
        --title "❌ Backup Failed" \
        --message "Database backup failed on $(hostname)" \
        --type "alert" \
        --tag "backup" \
        --tag "failed"
    exit 1
fi
```

### Long-Running Task Notification

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

START=$(date +%s)

# Your long-running task
./long-running-process.sh

END=$(date +%s)
DURATION=$((END - START))
MINUTES=$((DURATION / 60))

wirepusher_send \
    --title "✅ Task Complete" \
    --message "Long-running process finished\nDuration: ${MINUTES} minutes" \
    --type "task" \
    --tag "batch"
```

## Best Practices

### Store Credentials Securely

```bash
# .env file
export WIREPUSHER_TOKEN="wpt_your_token"
export WIREPUSHER_ID="your_user_id"  # Legacy

# Source in your scripts
. .env
. /usr/local/lib/wirepusher/wirepusher.sh
```

### Always Quote Variables

```bash
# Good - prevents word splitting and glob expansion
wirepusher_send "$title" "$message"

# Bad - can break with spaces or special characters
wirepusher_send $title $message
```

### Use set -e for Critical Scripts

Exit immediately on error:

```bash
#!/bin/sh
set -e

. /usr/local/lib/wirepusher/wirepusher.sh
# Script will exit if any command fails
```

### Error Handling in Production

Always check exit codes in production scripts:

```bash
if ! wirepusher_send "Title" "Message"; then
    echo "Failed to send notification" >&2
    # Log error, retry, or take other action
fi
```

## Development

### Setup

```bash
# Clone repository
git clone https://gitlab.com/wirepusher/shell-scripts.git
cd shell-scripts
```

### Testing

```bash
# Run test suite
cd tests
sh test.sh

# Test POSIX compliance with dash
dash test.sh

# Test with bash
bash test.sh
```

### Platform Testing

```bash
# macOS (default sh is bash in POSIX mode)
sh wirepusher.sh

# Linux with dash
dash wirepusher.sh

# Alpine/BusyBox
ash wirepusher.sh

# Bash version
bash wirepusher-bash.sh
```

## POSIX sh vs Bash Version

### POSIX sh (wirepusher.sh)

- **Maximum compatibility** - Works on all Unix-like systems
- **Minimal footprint** - No bash-specific features
- **Use this unless** you need bash-specific features

**Compatible shells:**
- sh (POSIX)
- dash (Debian/Ubuntu default)
- ash (Alpine/BusyBox)
- bash (in POSIX mode)

### Bash (wirepusher-bash.sh)

- **Requires Bash 3.2+** (pre-installed on macOS and most Linux)
- **Better array handling** for tags
- **Cleaner string manipulation**
- **Use this if** you're already using bash

## Requirements

- POSIX sh or Bash 3.2+
- curl (pre-installed on most systems)

## Complete Examples

See the [examples/](examples/) directory for complete, ready-to-use scripts:

- **simple.sh** - Basic usage examples
- **cron-job.sh** - Disk and memory monitoring for cron jobs
- **git-hook.sh** - Git post-receive hook for push notifications
- **monitoring.sh** - Comprehensive system health checks
- **ci-pipeline.sh** - CI/CD pipeline notifications

## Troubleshooting

### "curl: command not found"

Install curl:

```bash
# Debian/Ubuntu
sudo apt-get install curl

# RedHat/CentOS
sudo yum install curl

# macOS (should be pre-installed)
brew install curl
```

### "Authentication failed"

Check your token and user ID:

```bash
echo "Token: $WIREPUSHER_TOKEN"
echo "User ID: $WIREPUSHER_ID"
```

Verify credentials in the app: Settings → Help → copy token

### "Permission denied"

Make sure the script is executable:

```bash
chmod +x your-script.sh
```

### Network errors

Check connectivity:

```bash
curl -I https://wirepusher.com
```

## Links

- **Documentation**: https://wirepusher.dev/help
- **Repository**: https://gitlab.com/wirepusher/shell-scripts
- **Issues**: https://gitlab.com/wirepusher/shell-scripts/-/issues
- **CLI (with encryption)**: https://gitlab.com/wirepusher/cli
- **Website**: https://wirepusher.dev

## License

MIT License - see [LICENSE](LICENSE) file for details.
