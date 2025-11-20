# CLAUDE.md - WirePusher Shell Scripts

Context file for AI-powered development assistance on the WirePusher shell scripts project.

## Project Overview

**WirePusher Shell Scripts** are POSIX-compatible shell script libraries for sending push notifications via [WirePusher](https://wirepusher.dev).

- **Language**: POSIX sh (with Bash-enhanced variant)
- **Dependencies**: curl only
- **Purpose**: Send notifications from shell scripts, cron jobs, CI/CD pipelines, system automation
- **Philosophy**: Zero dependencies, maximum portability, simple integration

## Architecture

```
shell-scripts/
├── wirepusher.sh              # POSIX sh compatible (dash, ash, bash, zsh)
├── wirepusher-bash.sh         # Bash-enhanced version (4.0+)
├── install.sh                 # One-line installer
├── examples/                  # 6 usage examples
│   ├── README.md              # Example documentation
│   ├── simple.sh              # Basic usage
│   ├── notifai.sh             # AI-powered notifications
│   ├── cron-job.sh            # Cron monitoring
│   ├── monitoring.sh          # System health checks
│   ├── git-hook.sh            # Git integration
│   └── ci-pipeline.sh         # CI/CD integration
├── tests/
│   └── test.sh                # Test suite
├── docs/
│   ├── ADVANCED.md            # Advanced patterns
│   └── SECURITY.md            # Security best practices
├── README.md                  # Full documentation (623 lines)
├── CHANGELOG.md               # Version history
└── CONTRIBUTING.md            # Contribution guidelines
```

## Key Features

### 1. Dual Implementation Strategy

**wirepusher.sh** (POSIX sh):
- Maximum portability (dash, ash, bash, zsh, ksh)
- Works on all Unix-like systems (Linux, macOS, BSD, Alpine)
- Minimal shell features (no arrays, no ${var//pattern/})
- Target: System scripts, cron jobs, minimal containers

**wirepusher-bash.sh** (Bash 4.0+):
- Bash-specific optimizations (arrays, pattern replacement)
- More readable code
- Same API as POSIX version
- Target: Bash users preferring idiomatic code

**Design decision**: Maintain both versions to serve different use cases. POSIX version prioritizes portability; Bash version prioritizes readability.

### 2. API Functions

#### wirepusher_send()

Send notifications with full control:

```bash
# Positional arguments (token required)
wirepusher_send "Title" "Message" "$WIREPUSHER_TOKEN"

# Named arguments (reads token from environment)
wirepusher_send \
    --title "Deploy Complete" \
    --message "v1.2.3 deployed" \
    --type "deployment" \
    --tag "production" \
    --tag "release" \
    --image-url "https://example.com/image.png" \
    --action-url "https://example.com/dashboard"
```

**Exit codes**:
- `0` - Success
- `1` - Missing required parameters
- `2` - curl not found
- `3` - curl execution failed (network error)
- `4` - API returned error

#### wirepusher_notifai()

AI-powered notifications (NotifAI):

```bash
# Positional (token required)
wirepusher_notifai "deployment finished successfully" "$WIREPUSHER_TOKEN"

# Named (reads token from environment)
wirepusher_notifai \
    --text "the server restarted and all services are up" \
    --type "monitoring"
```

**Exit codes**: Same as `wirepusher_send()`

#### wirepusher_version()

Print library version:

```bash
wirepusher_version  # outputs: "2.0.0"
```

#### wirepusher_check_dependencies()

Check if curl is installed:

```bash
if wirepusher_check_dependencies; then
    echo "curl is available"
else
    echo "curl not found"
fi
```

### 3. Internal Functions (Private)

**_wirepusher_escape_json()**: JSON string escaping
- Escapes: `"` `\` `/` control characters
- Handles newlines, tabs, carriage returns
- POSIX-compatible (no bash-isms)

**_wirepusher_parse_error()**: Parse nested error responses
- Extracts error type, code, message from API responses
- Handles nested `{"status":"error","error":{...}}` format
- Falls back to entire response if parsing fails

### 4. Error Handling Pattern

The library uses exit codes instead of exceptions:

```bash
# Simple: Exit on error
set -e
wirepusher_send "Alert" "Message" "$TOKEN"

# Conditional: Check exit code
if wirepusher_send "Alert" "Message" "$TOKEN"; then
    echo "Success"
else
    exit_code=$?
    echo "Failed with exit code $exit_code"
fi

# Capture and handle
wirepusher_send "Alert" "Message" "$TOKEN"
case $? in
    0) echo "Success" ;;
    1) echo "Missing parameters" ;;
    2) echo "curl not found" ;;
    3) echo "Network error" ;;
    4) echo "API error" ;;
esac
```

### 5. Tag Normalization

Automatic validation (matches other SDKs):
- Lowercase conversion
- Whitespace trimming
- Character validation (alphanumeric, hyphens, underscores only)
- Invalid tags silently filtered

Implementation in both versions handles normalization differently:
- **POSIX**: Manual loop with `case` statements
- **Bash**: Array operations with pattern replacement

### 6. No Built-in Encryption

**Design decision**: Shell scripts do NOT support encryption (unlike other SDKs).

**Rationale**:
- OpenSSL/GPG dependencies would violate zero-dependency goal
- Complex crypto operations are error-prone in shell
- Users needing encryption should use Python/Go/JS SDKs

**Alternative**: Users can pre-encrypt message before sending:
```bash
# Manual encryption (requires openssl)
encrypted=$(echo "$message" | openssl enc -aes-128-cbc -base64 -pass pass:"$password")
wirepusher_send "Title" "$encrypted" "$TOKEN"
```

### 7. Environment Variable Support

All parameters support environment variables:

```bash
# Set defaults via environment
export WIREPUSHER_TOKEN="abc12345"
export WIREPUSHER_TYPE="production"
export WIREPUSHER_IMAGE_URL="https://example.com/logo.png"

# Use defaults
wirepusher_send "Alert" "Message"

# Override defaults
wirepusher_send --title "Alert" --message "Message" --type "critical"
```

## Testing Strategy

### test.sh Structure

1. **JSON Escaping Tests**: Verify `_wirepusher_escape_json()` handles special characters
2. **Validation Tests**: Check required parameters
3. **Argument Parsing**: Test positional vs named arguments
4. **Version Check**: Verify `wirepusher_version()` output

### Testing Limitations

- No actual API integration tests (would require real token)
- No mock HTTP responses (would require complex curl mocking)
- Focus on unit testing pure functions (escaping, parsing)

### Manual Testing

```bash
# Test against real API
export WIREPUSHER_TOKEN="your-token"
cd tests && sh test.sh

# Test with different shells
sh test.sh      # POSIX sh (dash on Debian/Ubuntu)
bash test.sh    # Bash
dash test.sh    # dash explicitly
zsh test.sh     # zsh
```

## POSIX vs Bash Differences

### String Operations

| Operation | POSIX | Bash |
|-----------|-------|------|
| Substring extraction | `${var#pattern}` | `${var:offset:length}` |
| Pattern replacement | Manual loop | `${var//pattern/replacement}` |
| Length | `${#var}` | `${#var}` (same) |

### Arrays

**POSIX**: No arrays - use space-separated strings or loops
```bash
tags=""
for tag in production release; do
    tags="$tags $tag"
done
```

**Bash**: Native array support
```bash
tags=(production release)
```

### Function Returns

**POSIX**: Only exit codes (0-255)
```bash
get_value() {
    echo "result"  # Return via stdout
    return 0       # Exit code
}
result=$(get_value)
```

**Bash**: Same pattern (no difference)

## Common Pitfalls

### 1. Quoting

**Always quote variables**:
```bash
# Bad: Unquoted (word splitting, globbing)
wirepusher_send $title $message $token

# Good: Quoted
wirepusher_send "$title" "$message" "$token"
```

### 2. Exit Codes

**Check exit codes properly**:
```bash
# Bad: Ignores exit code
wirepusher_send "Title" "Message" "$TOKEN"
echo "Done"  # Always executes

# Good: Check exit code
if ! wirepusher_send "Title" "Message" "$TOKEN"; then
    echo "Failed" >&2
    exit 1
fi
```

### 3. Environment Persistence

**Functions can't modify parent environment**:
```bash
# This does NOT work
set_token() {
    WIREPUSHER_TOKEN="abc12345"  # Only sets in function scope
}
set_token
echo "$WIREPUSHER_TOKEN"  # Empty

# Use export or eval pattern
export WIREPUSHER_TOKEN="abc12345"
```

### 4. curl Not Found

**Always check dependencies**:
```bash
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required" >&2
    exit 1
fi
```

Or use `wirepusher_check_dependencies`:
```bash
if ! wirepusher_check_dependencies; then
    exit 2
fi
```

## Development Patterns

### Adding a New Parameter

1. **Update both files**: `wirepusher.sh` AND `wirepusher-bash.sh`
2. **Parse in both positional and named modes**
3. **Add to JSON payload**
4. **Update README examples**
5. **Add test case**

Example:
```bash
# Parse named argument
while [ $# -gt 0 ]; do
    case "$1" in
        --new-param)
            new_param="$2"
            shift 2
            ;;
        # ...
    esac
done

# Add to JSON
json="$json,\"newParam\":\"$new_param\""
```

### Testing JSON Escaping

Add test case to `tests/test.sh`:
```bash
test_escape() {
    local input='Special "chars" \backslash'
    local expected='Special \"chars\" \\backslash'
    local result
    result=$(_wirepusher_escape_json "$input")

    if [ "$result" = "$expected" ]; then
        echo "✓ Escape test passed"
    else
        echo "✗ Escape test failed"
        return 1
    fi
}
```

### Shell Compatibility Testing

Test matrix:
- **sh** (POSIX): dash (Debian/Ubuntu), ash (Alpine), sh (BSD)
- **bash**: 4.0+ (macOS, Linux)
- **zsh**: 5.0+ (macOS default since Catalina)

```bash
# Quick compatibility check
for shell in sh bash dash zsh; do
    if command -v "$shell" >/dev/null 2>&1; then
        echo "Testing with $shell..."
        "$shell" test.sh || echo "Failed with $shell"
    fi
done
```

## Integration Patterns

### Cron Jobs

```bash
# crontab format
WIREPUSHER_TOKEN=abc12345
0 * * * * /path/to/script.sh  # Hourly
```

### Systemd Services

```ini
[Service]
Environment="WIREPUSHER_TOKEN=abc12345"
ExecStart=/path/to/script.sh
```

### GitLab CI

```yaml
script:
  - . ./wirepusher.sh
  - wirepusher_send "CI Success" "Build passed"
```

### Docker

```dockerfile
# Install curl in Alpine
RUN apk add --no-cache curl

# Copy script
COPY wirepusher.sh /usr/local/bin/

# Use in entrypoint
ENTRYPOINT ["/bin/sh", "-c", ". /usr/local/bin/wirepusher.sh && ..."]
```

## Design Decisions

### Why POSIX sh?

- **Maximum portability**: Works everywhere (Alpine, Debian, BSD, macOS)
- **Minimal containers**: Alpine Linux uses busybox ash (POSIX-only)
- **Cron compatibility**: Many cron implementations use `/bin/sh`
- **Legacy systems**: Old Unix systems may only have POSIX sh

### Why Bash Version?

- **User preference**: Many users prefer Bash and have it installed
- **Readability**: Bash arrays and string ops are more intuitive
- **Performance**: Native Bash operations can be faster

### Why Both?

- Different use cases: System scripts need POSIX; developer scripts prefer Bash
- Maintenance: Code is similar enough to maintain both
- Testing: Validates POSIX compatibility

### Why No Retry Logic?

**Design decision**: No automatic retries in shell scripts.

**Rationale**:
- Users can implement custom retry logic (see docs/ADVANCED.md)
- Shell script context varies (cron vs CI vs manual)
- Exit codes enable custom retry strategies

**Pattern**:
```bash
# User implements their own retry
for i in 1 2 3; do
    wirepusher_send "Title" "Message" "$TOKEN" && break
    sleep $((i * 2))
done
```

### Why No Rate Limit Tracking?

**Current limitation**: Shell scripts don't expose rate limit headers (yet).

**Planned feature**: Future versions will export rate limit info to environment variables:
```bash
# After send (future)
wirepusher_send "Title" "Message" "$TOKEN"
echo "Remaining: $WIREPUSHER_LAST_RATE_REMAINING"
```

**Workaround**: See docs/ADVANCED.md for manual rate limiting patterns.

## Version History

- **v2.0.0** (2025-11-15): Nested error format support, improved validation
- **v1.x**: Initial release with basic send functionality

## Related Projects

- **wirepusher-python**: Python 3.8+ library (async/sync, encryption, rate limits)
- **wirepusher-go**: Go library (context support, idiomatic Go)
- **wirepusher-js**: JavaScript/TypeScript library (ESM/CommonJS, encryption)
- **wirepusher-cli**: Command-line tool (binary distribution, no dependencies)

## Common Use Cases

1. **Cron job monitoring**: Alert when scheduled tasks fail
2. **Server health checks**: Monitor disk space, memory, services
3. **Deployment notifications**: Notify team on deploy success/failure
4. **Git hooks**: Notify on push, tag, merge
5. **CI/CD integration**: GitLab CI, GitHub Actions, Jenkins
6. **Log monitoring**: Tail logs and alert on patterns
7. **Backup completion**: Notify when backups complete or fail

## Getting Help

- **Documentation**: [README.md](README.md) for full documentation
- **Examples**: [examples/README.md](examples/README.md) for usage examples
- **Advanced usage**: [docs/ADVANCED.md](docs/ADVANCED.md) for patterns
- **Security**: [docs/SECURITY.md](docs/SECURITY.md) for best practices
- **Issues**: https://gitlab.com/wirepusher/shell-scripts/-/issues
- **Support**: support@wirepusher.dev

---

**Last updated**: 2025-11-20
