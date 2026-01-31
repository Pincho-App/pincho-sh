# Pincho Shell Scripts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Official shell script library for [Pincho](https://pincho.app) - Send push notifications from shell scripts, cron jobs, and automation workflows. POSIX sh compatible, zero dependencies (only curl).

## Installation

```bash
curl -sL https://gitlab.com/pincho-app/pincho-sh/-/raw/main/install.sh | sh
```

**Get your token:** Open app → Settings → Help → copy token

## Quick Start

```bash
# Source the library
. /usr/local/lib/pincho/pincho.sh

# Set your token
export PINCHO_TOKEN="your_token"

# Send a notification
pincho_send "Deploy Complete" "Version 1.2.3 deployed to production"
```

## Usage

```bash
#!/bin/sh
. /usr/local/lib/pincho/pincho.sh

# Basic notification
pincho_send "Title" "Message"

# With all options
pincho_send \
  --title "Deploy Complete" \
  --message "Version 1.2.3 deployed" \
  --type "deployment" \
  --tag "prod" \
  --tag "release" \
  --image "https://example.com/image.png" \
  --action "https://example.com/dashboard"
```

## API Reference

### `pincho_send`

**Arguments:**
- `--title TEXT` - Title (required, max 256 chars)
- `--message TEXT` - Message (required, max 4096 chars)
- `--type TEXT` - Type for categorization
- `--tag TEXT` - Tag (repeatable, max 10)
- `--image URL` - Image URL
- `--action URL` - Action URL
- `--token TEXT` - API token (overrides `PINCHO_TOKEN` env var)

**Exit codes:** 0=success, 1=auth error, 2=validation error, 3=rate limit, 4=network error

**Shorthand:** `pincho_send "Title" "Message"`

**Environment variables:**
- `PINCHO_TOKEN` (required) - Your API token
- `PINCHO_URL` (optional) - API endpoint (default: https://api.pincho.app/send)
- `PINCHO_LAST_RATE_*` (exported) - Rate limit info after each request

### `pincho_notifai`

Convert text to notifications using AI. Useful for automation workflows where you have free-form text that should become a structured notification.

**Arguments:**
- `--text TEXT` - Text to convert (required, 5-2500 chars)
- `--type TEXT` - Type for categorization
- `--token TEXT` - API token (overrides `PINCHO_TOKEN` env var)

**Exit codes:** Same as `pincho_send`

**Shorthand:** `pincho_notifai "Deploy server and restart services"`

**Example:**
```bash
pincho_notifai "SSL cert expires in 7 days - renew now"
pincho_notifai --text "Build failed with 3 errors" --type "ci-cd"
```

## Bash Version

For better array handling: `. /usr/local/lib/pincho/pincho-bash.sh` (requires Bash 4.0+)

## Encryption

Not supported in shell scripts. Use [CLI tool](https://gitlab.com/pincho-app/pincho-cli) or language SDKs (Go, Python, JS, PHP, C#, Rust) for encryption.

## Examples

See [examples/](examples/) directory for complete scripts: cron jobs, git hooks, CI/CD, monitoring, error handling, rate limits, parallel sending.

## Documentation

- [Advanced Usage](docs/ADVANCED.md) - Error handling, integrations, best practices
- [Examples Guide](examples/README.md) - Detailed example walkthrough
- [Security](docs/SECURITY.md) - Security best practices

## Links

- **Website**: https://pincho.app
- **Repository**: https://gitlab.com/pincho-app/pincho-sh
- **CLI Tool**: https://gitlab.com/pincho-app/pincho-cli

## License

MIT License - see [LICENSE](LICENSE) file for details.
