# Contributing to Pincho Shell Scripts

Thank you for your interest in contributing to the Pincho shell scripts! This document outlines the process and requirements for contributing to this project.

## Pull Request / Merge Request Requirements

**REQUIRED**: Documentation must be updated before merging any PR. This ensures documentation stays in sync with code changes.

## Documentation Update Checklist

When making code changes, ALWAYS check if these documentation files need updating:

### Core Documentation

- [ ] **CHANGELOG.md** - Add entry under `[Unreleased]` section
  - Use categories: Added, Changed, Fixed, Deprecated, Removed, Security
  - Include issue/MR number reference
  - Example: `- Fixed JSON escaping for special characters (#15)`

- [ ] **README.md** - Update if:
  - New features or flags added
  - Usage examples changed
  - Installation instructions changed
  - API endpoints or authentication changed
  - New dependencies or requirements

## When to Update Documentation

### ALWAYS update docs for:

- ✅ New command-line flags or options
- ✅ Changes to script behavior or output
- ✅ New features or functionality
- ✅ Breaking changes or deprecations
- ✅ Changes to authentication or API usage
- ✅ Installation or setup process changes
- ✅ Security-related changes

### Usually should update docs for:

- 🔍 Bug fixes that affect documented behavior
- 🔍 Changes to error handling or validation
- 🔍 Platform-specific behavior changes

### Generally don't need docs updates for:

- ❌ Internal refactoring with no external impact
- ❌ Code cleanup or formatting
- ❌ Comment improvements
- ❌ Test additions without behavior changes

## Shell Script Standards

### POSIX Compliance

The main `pincho.sh` script must remain POSIX sh-compliant for maximum portability:

- **DO NOT** use bash-specific features (`[[`, `$()`, arrays, etc.)
- Use `sh` shebang: `#!/bin/sh`
- Test with multiple shells: `sh`, `dash`, `ash`, `bash`

### Bash Version

The `pincho-bash.sh` script can use bash-specific features but must:

- Use `#!/usr/bin/env bash` shebang
- Work with bash 3.2+ (macOS default)
- Clearly document any bash-specific requirements

### Code Style

- Use 2-space indentation
- Quote all variables: `"$variable"`
- Use `${variable}` for clarity in strings
- Add comments for complex logic
- Keep lines under 80 characters when possible

### Security Best Practices

- Always validate user input
- Use `printf` instead of `echo` for user data
- Quote all file paths and variables
- Avoid `eval` and command substitution of user input
- Sanitize data before passing to JSON

### Testing

All changes must include or update tests:

```bash
# Run tests
cd tests && ./test.sh

# Test POSIX compliance
sh tests/test.sh

# Test with different shells
dash tests/test.sh
bash tests/test.sh
```

## CHANGELOG.md Format

Always add entries to the `[Unreleased]` section at the top:

```markdown
## [Unreleased]

### Added
- New feature description (#issue)

### Changed
- Modified behavior description (#issue)

### Fixed
- Bug fix description (#issue)

### Deprecated
- Deprecated feature notice (#issue)
```

When a release is made, the `[Unreleased]` section will be converted to a version number.

## PR/MR Description Template

Include in your PR/MR description:

```markdown
## Changes Made
- Brief description of changes

## Testing
- [ ] Tested with sh
- [ ] Tested with bash
- [ ] Tested with dash (if POSIX script)
- [ ] All existing tests pass
- [ ] New tests added (if applicable)

## Documentation Updates
- [x] CHANGELOG.md updated
- [x] README.md updated (if needed)
- [ ] No documentation updates needed (explain why)

## Breaking Changes
- [ ] None
- [ ] Yes (describe and document migration)
```

## Issue Template

**IMPORTANT**: Always use the issue template when creating issues via GitLab UI or structure your issue following this format.

### Required Sections

- **Problem/Motivation** - The "why" - what problem does this solve?
- **Current vs Expected Behavior** - Clear description of the gap
- **Impact Analysis** - Who is affected and severity level
- **Environment Details** - OS, shell version, related configuration
- **Reproduction Steps** - Exact commands to reproduce the issue
- **Proposed Solution** (Optional) - If you have implementation ideas
- **Success Criteria** - How to know when it's done

### Creating Issues via glab CLI

```bash
glab issue create --title "Issue title" --description "$(cat <<'EOF'
## Problem / Motivation
[Describe why this issue exists]

## Current Behavior
[What happens now]

## Expected Behavior
[What should happen]

## Environment Details
- OS: [e.g., macOS 14.0, Ubuntu 22.04, Alpine Linux]
- Shell: [e.g., bash 5.2, sh (dash), busybox ash]
- Script Version: [e.g., pincho.sh v1.0.0]

## Reproduction Steps
1. Run command: `./pincho.sh ...`
2. Observe: [what happens]
3. Expected: [what should happen]

## Impact Analysis
**Severity:**
- [ ] Critical (script fails/data loss)
- [ ] Medium (affects functionality)
- [ ] Low (minor issue/enhancement)

**Affected Users:**
[Who is affected: all users, specific platforms, specific use cases]

## Proposed Solution (Optional)
[If you have implementation ideas]

## Success Criteria
- [ ] First criteria
- [ ] Second criteria
EOF
)"
```

## GitLab Workflow

### Default Settings

- MRs default to "squash commits" and "delete source branch" enabled
- These settings help keep the main branch clean and linear

### Starting New Work

When starting new work:
1. Delete local feature branch
2. Check out main branch
3. Pull latest changes
4. Create a new branch for the new task

### Command Reference

```bash
# View and manage issues
glab issue list
glab issue view <issue-number>
glab issue close <issue-number>

# Create and manage merge requests
glab mr create
glab mr list
glab mr view <mr-number>
```

## Platform-Specific Considerations

### macOS

- Default `sh` is bash 3.2 (in POSIX mode)
- Test with both `sh` and `bash`
- Note: Some GNU utilities behave differently (date, sed, etc.)

### Linux

- Common shells: bash, dash, ash (Alpine/BusyBox)
- Test with `dash` for POSIX compliance verification
- Consider container/minimal environments

### Windows

- Git Bash, WSL, Cygwin support
- Test path handling (forward vs backslash)
- Be aware of line ending differences (CRLF vs LF)

## Questions?

If you have questions about contributing, please:
- Review the [README.md](README.md) for usage and architecture
- Check existing issues and merge requests for examples
- Reach out to the maintainers

Thank you for contributing to Pincho Shell Scripts!
