# WirePusher Shell Scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official shell script library for [WirePusher](https://wirepusher.dev) - Send push notifications from your shell scripts.

## Features

- **POSIX sh compatible** - Works on any Unix-like system (Linux, macOS, BSD, etc.)
- **Bash-enhanced version** - Optional version with advanced features
- **Zero dependencies** - Only requires `curl` (already installed on most systems)
- **Easy installation** - One-line installer
- **Comprehensive examples** - Ready-to-use scripts for common scenarios
- **Well tested** - Includes test suite

## Requirements

- POSIX sh or bash
- curl

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

## Quick Start

```bash
# Source the library
. /usr/local/lib/wirepusher/wirepusher.sh

# Set credentials
export WIREPUSHER_TOKEN="wpt_your_token"
export WIREPUSHER_ID="your_user_id"

# Send a notification
wirepusher_send "Hello" "World!"
```

## Usage

### Simple Notification

```bash
# Source the library
. /usr/local/lib/wirepusher/wirepusher.sh

# Send notification with positional arguments
wirepusher_send "Build Complete" "v1.2.3 deployed successfully"
```

### Advanced Notification

```bash
# Send notification with named arguments
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

Store credentials in environment variables:

```bash
export WIREPUSHER_TOKEN="wpt_your_token"
export WIREPUSHER_ID="your_user_id"

# Now you can send notifications without passing credentials
wirepusher_send "Test" "Message"
```

### Error Handling

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

## Examples

### Cron Job Monitoring

Monitor disk space and send alerts:

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -ge 80 ]; then
    wirepusher_send \
        --title "⚠️ Disk Space Alert" \
        --message "Disk usage is at ${DISK_USAGE}%" \
        --type "alert"
fi
```

### Git Hooks

Send notifications on push (post-receive hook):

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

while read oldrev newrev refname; do
    branch=$(echo "$refname" | sed 's|refs/heads/||')

    wirepusher_send \
        --title "🔄 Code Pushed" \
        --message "Branch: $branch\nRepository: $(basename $(pwd))" \
        --type "git-push"
done
```

### CI/CD Pipeline

Send build notifications:

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Build started
wirepusher_send --title "🔄 Build Started" --message "Branch: $CI_BRANCH"

# Run build
if make build; then
    wirepusher_send \
        --title "✅ Build Successful" \
        --message "Branch: $CI_BRANCH" \
        --type "ci-success"
else
    wirepusher_send \
        --title "❌ Build Failed" \
        --message "Branch: $CI_BRANCH" \
        --type "ci-failure"
    exit 1
fi
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
        --type "alert"
fi
```

### Website Availability

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

if ! curl -fsSL -o /dev/null --max-time 10 https://example.com; then
    wirepusher_send \
        --title "⚠️ Website Down" \
        --message "https://example.com is not accessible" \
        --type "alert"
fi
```

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
- `--id TEXT` - User ID (overrides `WIREPUSHER_ID`)

**Exit Codes:**

- `0` - Success
- `1` - Authentication error (401, 403)
- `2` - Validation error (400, 404)
- `3` - Rate limit error (429)
- `4` - Network or other error

### `wirepusher_version`

Print library version.

```bash
wirepusher_version
# Output: WirePusher Shell Script Library v1.0.0
```

### `wirepusher_check_dependencies`

Check if required commands (curl) are available.

```bash
if wirepusher_check_dependencies; then
    echo "All dependencies are installed"
fi
```

## Environment Variables

- `WIREPUSHER_TOKEN` - Your API token (required)
- `WIREPUSHER_ID` - Your user ID (required)
- `WIREPUSHER_URL` - API URL (default: `https://wirepusher.com/send`)

## POSIX sh vs Bash Version

### POSIX sh (wirepusher.sh)

- Works on all Unix-like systems
- Maximum compatibility
- Use this unless you need bash-specific features

### Bash (wirepusher-bash.sh)

- Requires Bash 4.0 or higher
- Better array handling for tags
- Cleaner string manipulation
- Use this if you're already using bash

**Switching to Bash version:**

```bash
. /usr/local/lib/wirepusher/wirepusher-bash.sh
```

## Complete Examples

See the [examples/](examples/) directory for complete, ready-to-use scripts:

- **simple.sh** - Basic usage examples
- **cron-job.sh** - Disk and memory monitoring for cron jobs
- **git-hook.sh** - Git post-receive hook for push notifications
- **monitoring.sh** - Comprehensive system health checks
- **ci-pipeline.sh** - CI/CD pipeline notifications

## Testing

Run the test suite:

```bash
cd tests
sh test.sh
```

## Best Practices

### Store Credentials Securely

```bash
# .env file
export WIREPUSHER_TOKEN="wpt_your_token"
export WIREPUSHER_ID="your_user_id"

# Source in your scripts
. .env
. /usr/local/lib/wirepusher/wirepusher.sh
```

### Error Handling

Always check exit codes:

```bash
if ! wirepusher_send "Title" "Message"; then
    echo "Failed to send notification" >&2
    # Log error, retry, or take other action
fi
```

### Quoting

Always quote variables:

```bash
# Good
wirepusher_send "$title" "$message"

# Bad (can break with spaces or special characters)
wirepusher_send $title $message
```

### Use set -e

Exit immediately on error:

```bash
#!/bin/sh
set -e

. /usr/local/lib/wirepusher/wirepusher.sh
# Script will exit if any command fails
```

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

## Development

### Building from Source

```bash
git clone https://gitlab.com/wirepusher/shell-scripts.git
cd shell-scripts
```

### Running Tests

```bash
cd tests
sh test.sh
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [WirePusher Website](https://wirepusher.dev)
- [API Documentation](https://wirepusher.dev/api)
- [GitLab Repository](https://gitlab.com/wirepusher/shell-scripts)
- [Issue Tracker](https://gitlab.com/wirepusher/shell-scripts/-/issues)

## Support

- Email: support@wirepusher.dev
- Issues: https://gitlab.com/wirepusher/shell-scripts/-/issues
