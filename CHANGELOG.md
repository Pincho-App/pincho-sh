# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **NotifAI endpoint support** - AI-powered text-to-notification conversion
  - `pincho_notifai()` function in both `pincho.sh` and `pincho-bash.sh`
  - Converts free-form text (5-2500 chars) into structured notifications using AI
  - Supports optional `--type` parameter for categorization
  - Same error handling and rate limiting as `pincho_send()`
  - Rate limit: 50 requests/hour per token
  - `examples/notifai.sh` - Comprehensive example with 5 use cases
  - Documentation in `README.md`, `docs/ADVANCED.md`, and `examples/README.md`

### Changed
- **Documentation overhaul** - Complete redesign and streamlining of documentation (35% reduction overall)
  - **PINCHO_ID removed** - Eliminated all references to deprecated v1 API user ID parameter (27 occurrences across 9 files)
  - `README.md` - Redesigned from 572 to 184 lines (68% reduction) following SDK best practices
  - `docs/ADVANCED.md` - Streamlined from 762 to 650 lines (15% reduction) with improved organization
  - `examples/README.md` - Condensed from 479 to 182 lines (62% reduction) focusing on practical examples
  - Improved navigation and cross-linking between documentation files
  - Better separation of concerns (basic → README, advanced → ADVANCED.md, security → SECURITY.md)
- **Rate limit monitoring** - Automatic parsing and export of rate limit headers after each API call
  - `PINCHO_LAST_RATE_LIMIT` - Total requests allowed per hour
  - `PINCHO_LAST_RATE_REMAINING` - Requests remaining in current window
  - `PINCHO_LAST_RATE_RESET` - Unix timestamp when rate limit resets
- `examples/rate-limits.sh` - Comprehensive example demonstrating rate limit monitoring and batch sending with rate limit awareness
- `examples/error-handling.sh` - Comprehensive error handling patterns with retry logic, exponential backoff, and error-specific recovery strategies
- `examples/parallel-send.sh` - Parallel notification sending using xargs and GNU parallel with performance comparison and rate limit awareness
- **CI/CD automation** - Added `cloudbuild.yaml` with comprehensive testing pipeline:
  - ShellCheck linting for POSIX, Bash, and example scripts
  - Multi-shell compatibility testing (sh/dash, bash)
  - Automated test suite execution
  - Release artifact generation (tarball)
  - Automatic release notifications via Pincho
- **Documentation** - Added comprehensive documentation:
  - `docs/SECURITY.md` - Security best practices for shell script users (225 lines)
  - `docs/ADVANCED.md` - Advanced usage patterns and integrations (675 lines)
  - `docs/CODE_OF_CONDUCT.md` - Community guidelines based on Contributor Covenant 2.1
  - `examples/README.md` - Complete documentation for all 6 examples (480 lines)
  - `CLAUDE.md` - AI assistant context with architecture and design decisions (390 lines)

### Changed
- **Repository renamed** from `shell-scripts` to `pincho-sh` to align with SDK naming convention (`pincho-{language}`)
  - All documentation and URLs updated
  - GitLab automatically redirects old URLs to new repository name
- Updated header comments in both `pincho.sh` and `pincho-bash.sh` to document rate limit environment variables

## [1.0.0] - 2025-10-26

### Added
- Initial release of Pincho Shell Scripts Library
- `pincho.sh` - POSIX sh compatible library
- `pincho-bash.sh` - Bash-enhanced version with better array handling
- `pincho_send()` function with:
  - Positional arguments support (title, message)
  - Named arguments support (--title, --message, --type, --tag, --image, --action)
  - Environment variable configuration (PINCHO_TOKEN)
  - Comprehensive error handling with specific exit codes
  - JSON escaping for special characters
  - curl-based HTTP client with proper error handling
  - Support for all v1 API parameters
- Comprehensive examples:
  - `examples/simple.sh` - Basic usage
  - `examples/cron-job.sh` - Disk and memory monitoring
  - `examples/git-hook.sh` - Git post-receive hook
  - `examples/monitoring.sh` - System health checks (services, SSL, websites)
  - `examples/ci-pipeline.sh` - CI/CD pipeline notifications
- `install.sh` - One-line installer script
- `tests/test.sh` - Test suite with 11 test cases
- Complete documentation:
  - README with usage examples and API reference
  - MIT License
  - Changelog

### Features
- **POSIX sh compatibility** - Works on all Unix-like systems
- **Zero dependencies** - Only requires curl (standard on most systems)
- **Error codes** - Specific exit codes for different error types:
  - 0: Success
  - 1: Authentication error (401, 403)
  - 2: Validation error (400, 404)
  - 3: Rate limit error (429)
  - 4: Network or other error
- **JSON escaping** - Proper handling of quotes, backslashes, newlines, tabs
- **Validation** - Title/message length, required fields, tag count
- **Multiple tags** - Support for up to 10 tags
- **Optional fields** - Type, tags, image URL, action URL
- **Environment configuration** - PINCHO_TOKEN, PINCHO_URL

[Unreleased]: https://github.com/Pincho-App/pincho-sh/compare/v1.0.0...main
[1.0.0]: https://github.com/Pincho-App/pincho-sh/releases/tag/v1.0.0
