# WirePusher Shell Scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official shell script library for [WirePusher](https://wirepusher.dev) - Send push notifications from shell scripts, cron jobs, and automation workflows.

## Features

- **POSIX sh Compatible** - Works on any Unix-like system (Linux, macOS, BSD, Alpine)
- **Zero Dependencies** - Only requires curl (pre-installed on most systems)
- **Production Ready** - Comprehensive error handling and exit codes
- **CI/CD Ready** - Perfect for GitLab CI, GitHub Actions, Jenkins, cron jobs

## Installation

```bash
curl -sL https://gitlab.com/wirepusher/wirepusher-sh/-/raw/main/install.sh | sh
```

Or with sudo for system-wide installation:

```bash
curl -sL https://gitlab.com/wirepusher/wirepusher-sh/-/raw/main/install.sh | sudo sh
```

**Get your token:** Open app → Settings → Help → copy token

## Quick Start

```bash
# Source the library
. /usr/local/lib/wirepusher/wirepusher.sh

# Set your token
export WIREPUSHER_TOKEN="wpt_your_token"

# Send a notification
wirepusher_send "Deploy Complete" "Version 1.2.3 deployed to production"
```

## Usage

### Basic Notification

```bash
#!/bin/sh
. /usr/local/lib/wirepusher/wirepusher.sh

# Simple notification
wirepusher_send "Build Complete" "v1.2.3 deployed successfully"
```

### With Options

```bash
# Full-featured notification
wirepusher_send \
  --title "Deploy Complete" \
  --message "Version 1.2.3 deployed to production" \
  --type "deployment" \
  --tag "prod" \
  --tag "release" \
  --image "https://example.com/success.png" \
  --action "https://example.com/deployment/123"
```

### Error Handling

```bash
if wirepusher_send "Deploy Complete" "Version 1.2.3 deployed"; then
    echo "✅ Notification sent successfully"
else
    exit_code=$?
    case $exit_code in
        1) echo "❌ Authentication failed" ;;
        2) echo "❌ Validation error" ;;
        3) echo "⚠️  Rate limit exceeded" ;;
        4) echo "❌ Network error" ;;
    esac
fi
```

## API Reference

### `wirepusher_send`

Send a notification to WirePusher.

**Arguments:**

- `--title TEXT` - Notification title (required, max 256 chars)
- `--message TEXT` - Notification message (required, max 4096 chars)
- `--type TEXT` - Notification type for categorization
- `--tag TEXT` - Add a tag (can be repeated, max 10 tags)
- `--image URL` - Image URL to display
- `--action URL` - Action URL to open when tapped
- `--token TEXT` - API token (overrides `WIREPUSHER_TOKEN`)

**Exit Codes:**

- `0` - Success
- `1` - Authentication error (401, 403)
- `2` - Validation error (400, 404)
- `3` - Rate limit error (429)
- `4` - Network or other error

**Shorthand (positional arguments):**

```bash
wirepusher_send "Title" "Message"
```

### Other Functions

- `wirepusher_version` - Print library version
- `wirepusher_check_dependencies` - Check if curl is installed

## Environment Variables

- `WIREPUSHER_TOKEN` - Your API token (required)
- `WIREPUSHER_URL` - API endpoint (default: https://wirepusher.com/send)

Rate limit info (exported after each request):
- `WIREPUSHER_LAST_RATE_LIMIT` - Total requests allowed per hour
- `WIREPUSHER_LAST_RATE_REMAINING` - Requests remaining
- `WIREPUSHER_LAST_RATE_RESET` - Unix timestamp when limit resets

## Bash Version

For bash-specific features (better array handling):

```bash
#!/usr/bin/env bash
. /usr/local/lib/wirepusher/wirepusher-bash.sh

wirepusher_send --title "Test" --message "Message" --tag "tag1" --tag "tag2"
```

Requires Bash 3.2+ (pre-installed on macOS and most Linux systems).

## Encryption

⚠️ **Encryption not supported** in shell scripts due to OpenSSL dependency requirements.

For encryption support, use:
- [CLI tool](https://gitlab.com/wirepusher/cli) - Shell-friendly with encryption
- Language SDKs (Go, Python, PHP) - Native encryption support

## Examples

See [examples/](examples/) directory for complete scripts:

- `simple.sh` - Basic usage
- `cron-job.sh` - System monitoring
- `git-hook.sh` - Git push notifications
- `ci-pipeline.sh` - CI/CD workflows
- `monitoring.sh` - Health checks
- `error-handling.sh` - Retry logic and error handling
- `rate-limits.sh` - Rate limit tracking

## Documentation

- [Advanced Usage](docs/ADVANCED.md) - Patterns, best practices, troubleshooting
- [Examples Guide](examples/README.md) - Detailed examples and use cases
- [Security](docs/SECURITY.md) - Security best practices
- [Contributing](docs/CONTRIBUTING.md) - Development guide

## Requirements

- POSIX sh or Bash 3.2+
- curl (pre-installed on most systems)

## Links

- **Website**: https://wirepusher.dev
- **Documentation**: https://wirepusher.dev/help
- **Repository**: https://gitlab.com/wirepusher/wirepusher-sh
- **Issues**: https://gitlab.com/wirepusher/wirepusher-sh/-/issues
- **CLI Tool**: https://gitlab.com/wirepusher/cli

## License

MIT License - see [LICENSE](LICENSE) file for details.
