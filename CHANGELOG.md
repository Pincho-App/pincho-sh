# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-10-26

### Added
- Initial release of WirePusher Shell Scripts Library
- `wirepusher.sh` - POSIX sh compatible library
- `wirepusher-bash.sh` - Bash-enhanced version with better array handling
- `wirepusher_send()` function with:
  - Positional arguments support (title, message)
  - Named arguments support (--title, --message, --type, --tag, --image, --action)
  - Environment variable configuration (WIREPUSHER_TOKEN, WIREPUSHER_ID)
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
- **Environment configuration** - WIREPUSHER_TOKEN, WIREPUSHER_ID, WIREPUSHER_URL

[Unreleased]: https://gitlab.com/wirepusher/shell-scripts/-/compare/v1.0.0...main
[1.0.0]: https://gitlab.com/wirepusher/shell-scripts/-/tags/v1.0.0
