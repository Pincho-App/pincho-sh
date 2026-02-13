# CLAUDE.md - Pincho Shell Scripts

Context file for AI-powered development assistance on the Pincho shell scripts project.

## Project Overview

**Pincho Shell Scripts** are POSIX-compatible shell script libraries for sending push notifications via [Pincho](https://pincho.app).

- **Language**: POSIX sh (with Bash-enhanced variant)
- **Dependencies**: curl only
- **Purpose**: Send notifications from shell scripts, cron jobs, CI/CD pipelines, system automation
- **Philosophy**: Zero dependencies, maximum portability, simple integration

## Architecture

```
pincho-sh/
├── pincho.sh                  # POSIX sh compatible (dash, ash, bash, zsh)
├── pincho-bash.sh             # Bash-enhanced version (4.0+)
├── install.sh                 # One-line installer
├── examples/                  # Usage examples
├── tests/
│   └── test.sh                # Test suite
├── docs/
│   ├── ADVANCED.md            # Advanced patterns
│   └── SECURITY.md            # Security best practices
└── README.md                  # Documentation
```

## Key Features

### Dual Implementation Strategy

**pincho.sh** (POSIX sh):
- Maximum portability (dash, ash, bash, zsh, ksh)
- Works on all Unix-like systems (Linux, macOS, BSD, Alpine)
- Minimal shell features (no arrays, no ${var//pattern/})
- Target: System scripts, cron jobs, minimal containers

**pincho-bash.sh** (Bash 4.0+):
- Bash-specific optimizations (arrays, pattern replacement)
- More readable code
- Same API as POSIX version
- Target: Bash users preferring idiomatic code

### API Functions

#### pincho_send()

Send notifications with full control:

```bash
# Positional arguments
pincho_send "Title" "Message"

# Named arguments
pincho_send \
    --title "Deploy Complete" \
    --message "v1.2.3 deployed" \
    --type "deployment" \
    --tag "production" \
    --tag "release" \
    --image "https://example.com/image.png" \
    --action "https://example.com/dashboard"
```

**Exit codes**:
- `0` - Success
- `1` - Authentication error (401, 403)
- `2` - Validation error (400, 404)
- `3` - Rate limit error (429)
- `4` - Network or other error

#### pincho_notifai()

AI-powered notifications:

```bash
pincho_notifai "deployment finished successfully"
pincho_notifai --text "the server restarted" --type "monitoring"
```

#### pincho_version()

Print library version.

#### pincho_check_dependencies()

Check if curl is installed.

### Environment Variables

- `PINCHO_TOKEN` - API token (required)
- `PINCHO_URL` - API endpoint (default: https://api.pincho.app/send)
- `PINCHO_LAST_RATE_LIMIT` - Rate limit info (exported after requests)
- `PINCHO_LAST_RATE_REMAINING` - Requests remaining
- `PINCHO_LAST_RATE_RESET` - Reset timestamp

### No Built-in Encryption

**Design decision**: Shell scripts do NOT support encryption (unlike other SDKs).

**Rationale**:
- OpenSSL/GPG dependencies would violate zero-dependency goal
- Complex crypto operations are error-prone in shell
- Users needing encryption should use Python/Go/JS/C#/Rust SDKs

## Testing

```bash
# Run tests
sh tests/test.sh

# Test with different shells
dash tests/test.sh
bash tests/test.sh
zsh tests/test.sh
```

## Development

### Adding a New Parameter

1. **Update both files**: `pincho.sh` AND `pincho-bash.sh`
2. **Parse in both positional and named modes**
3. **Add to JSON payload**
4. **Update README examples**
5. **Add test case**

### Shell Compatibility Testing

Test matrix:
- **sh** (POSIX): dash (Debian/Ubuntu), ash (Alpine), sh (BSD)
- **bash**: 4.0+ (macOS, Linux)
- **zsh**: 5.0+ (macOS default since Catalina)

## Common Pitfalls

### Always Quote Variables
```bash
# Bad
pincho_send $title $message

# Good
pincho_send "$title" "$message"
```

### Check Exit Codes
```bash
if ! pincho_send "Title" "Message"; then
    echo "Failed" >&2
    exit 1
fi
```

## Links

- **Website**: https://pincho.app
- **Repository**: https://github.com/Pincho-App/pincho-sh
- **CLI Tool**: https://github.com/Pincho-App/pincho-cli
