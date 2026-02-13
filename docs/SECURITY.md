# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 2.x     | :white_check_mark: |
| 1.x     | :x:                |

## Reporting a Vulnerability

The Pincho team takes security bugs seriously. We appreciate your efforts to responsibly disclose your findings.

### How to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by:

1. **Opening a security advisory** on GitHub:
   - Go to https://github.com/Pincho-App/pincho-sh/security/advisories/new
   - Provide detailed information about the vulnerability

2. **Include the following information**:
   - Type of vulnerability (e.g., command injection, authentication bypass, etc.)
   - Full paths of source file(s) related to the vulnerability
   - Location of affected source code (tag/branch/commit or direct URL)
   - Step-by-step instructions to reproduce the issue
   - Proof-of-concept or exploit code (if possible)
   - Impact of the vulnerability (what an attacker could do)
   - Suggested fix (if you have one)

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours
- **Updates**: We will send you regular updates about our progress (at least every 5 business days)
- **Validation**: We will work to validate the vulnerability and determine its impact
- **Fix**: We will work on a fix and prepare a security release
- **Disclosure**: We will coordinate with you on the disclosure timeline

### Disclosure Policy

- **Coordinated disclosure**: We prefer coordinated disclosure and will work with you on timing
- **Security advisories**: We will publish security advisories for confirmed vulnerabilities
- **Credit**: We will credit you in the security advisory (unless you prefer to remain anonymous)

## Security Best Practices for Users

When using the Pincho shell scripts:

### 1. Protect Your API Tokens

**Never hardcode tokens in scripts**:
```bash
# Bad: Hardcoded token (anyone with file access can see it)
pincho_send "Title" "Message" "abc12345"

# Good: Use environment variable
export PINCHO_TOKEN="abc12345"
pincho_send "Title" "Message" "$PINCHO_TOKEN"

# Better: Load from secure location
PINCHO_TOKEN=$(cat ~/.pincho/token)
pincho_send "Title" "Message" "$PINCHO_TOKEN"

# Best: Use secret manager (GCP example)
PINCHO_TOKEN=$(gcloud secrets versions access latest --secret="pincho-token")
pincho_send "Title" "Message" "$PINCHO_TOKEN"
```

### 2. Protect Script Files

Set restrictive permissions on scripts containing tokens:
```bash
# Only owner can read/write/execute
chmod 700 my-notification-script.sh

# For token files
chmod 600 ~/.pincho/token
```

### 3. Never Commit Tokens to Version Control

Use `.gitignore` to exclude sensitive files:
```bash
# .gitignore
.env
*.token
secrets/
```

### 4. Validate Input

If your script accepts user input, validate and sanitize it:
```bash
# Good: Validate input before sending
validate_message() {
    local msg="$1"
    if [ ${#msg} -gt 10000 ]; then
        echo "Error: Message too long" >&2
        exit 1
    fi
    if ! echo "$msg" | grep -q '^[[:print:][:space:]]*$'; then
        echo "Error: Invalid characters in message" >&2
        exit 1
    fi
}

read -r message
validate_message "$message"
pincho_send "Alert" "$message" "$PINCHO_TOKEN"
```

### 5. Use Secure curl

The library uses `curl` with secure defaults:
- HTTPS only (no HTTP fallback)
- Certificate verification enabled
- No insecure options

If you modify the scripts, **never** disable certificate verification:
```bash
# Bad: Insecure (disables certificate verification)
curl -k https://...

# Good: Secure (default behavior)
curl https://...
```

### 6. Review Script Dependencies

The shell scripts require only `curl`:
- Ensure `curl` is installed and up-to-date
- On systems with package managers, regularly update:
  ```bash
  # Debian/Ubuntu
  sudo apt update && sudo apt upgrade curl

  # macOS
  brew upgrade curl

  # RHEL/CentOS
  sudo yum update curl
  ```

### 7. Principle of Least Privilege

- Use API tokens with minimal required permissions
- Create separate tokens for different automation tasks
- Rotate tokens regularly
- Revoke tokens immediately if compromised

### 8. Audit Script Execution

Log notification sends for security monitoring:
```bash
# Example: Log to syslog
send_with_logging() {
    local title="$1"
    local result
    result=$(pincho_send "$title" "$2" "$3" 2>&1)
    local exit_code=$?
    logger -t pincho "Sent: title=\"$title\" status=$exit_code"
    return $exit_code
}
```

### 9. Secure Cron Jobs

When using cron, ensure:
- Crontab files have restrictive permissions (600)
- Environment variables are set securely
- Output is logged securely

```bash
# crontab -e
# Load token from secure location, not in crontab
0 * * * * PINCHO_TOKEN=$(cat ~/.pincho/token) /path/to/script.sh
```

## Known Security Considerations

### Command Injection

The library uses proper quoting and escaping for JSON values. **Do not** modify the internal `_pincho_escape_json()` function without careful review.

If you extend the scripts, always quote variables:
```bash
# Good: Quoted variables
title="$USER_INPUT"
pincho_send "$title" "message" "$token"

# Bad: Unquoted (vulnerable to injection)
pincho_send $title message $token
```

### No Built-in Encryption

Unlike other Pincho SDKs, the shell scripts **do not** support message encryption. If you need encrypted notifications:
- Use a different SDK (Python, Go, JavaScript, etc.)
- Or manually implement encryption before sending

### Token Exposure in Process List

When passing tokens as arguments, they may be visible in process listings (`ps aux`):
```bash
# Potentially visible in ps output
pincho_send "Title" "Message" "abc12345"
```

**Mitigation**: Use environment variables instead:
```bash
# Not visible in ps output
export PINCHO_TOKEN="abc12345"
pincho_send "Title" "Message" "$PINCHO_TOKEN"
```

### Shell History

Tokens typed in shell may be stored in history files (`.bash_history`, `.zsh_history`):
```bash
# Bad: Token visible in history
export PINCHO_TOKEN="abc12345"

# Good: Prepend with space (in bash/zsh with HISTCONTROL=ignorespace)
 export PINCHO_TOKEN="abc12345"

# Better: Don't type it at all - load from file
export PINCHO_TOKEN=$(cat ~/.pincho/token)
```

### Network Security

- The library communicates over HTTPS with TLS encryption
- Ensure your system's CA certificates are up-to-date
- Test connectivity: `curl -v https://api.pincho.app`

### POSIX Compliance

Both `pincho.sh` (POSIX sh) and `pincho-bash.sh` (Bash) are audited for security. Use the appropriate version for your shell.

## Security Updates

Security updates will be released as:
- **Patch versions** (e.g., 2.0.1) for security fixes
- Tagged releases on GitHub
- Announcements in `CHANGELOG.md`

Security releases will:
- Be clearly marked with `[SECURITY]` in release notes
- Describe the vulnerability and impact
- Provide upgrade instructions
- Include a security advisory for critical issues

## Hall of Fame

We recognize security researchers who responsibly disclose vulnerabilities:

<!-- Security researchers will be listed here after coordinated disclosure -->

## Questions?

If you have questions about this security policy, please:
- Open a public issue for general security questions
- Contact us at **support@pincho.app** for private inquiries

---

**Last updated**: 2025-11-20
