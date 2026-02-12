# Changelog

All notable changes to the Claude Warden AI Governance Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Fixed stdin pipe issue: redirect all read commands to /dev/tty in hooks

### Added
- Added SESSION-LOG.md for persistent memory across sessions

## [1.0.0] - 2026-02-11

### Added
- Initial release of Claude Warden framework
- Self-protection hooks preventing Claude from editing governance files
- Five core hooks:
  - `warden-guard.sh` - Blocks edits to protected governance files
  - `warden-bash-guard.sh` - Filters unsafe bash commands
  - `warden-post-check.sh` - Validates changes after tool execution
  - `warden-session-end.sh` - Generates session handoff documentation
  - `warden-audit.sh` - Calculates drift score across 8 dimensions
- Governance file structure:
  - `.claude/CLAUDE.md` - Operating instructions
  - `.claude/rules/policy.md` - Constitution (highest governance authority)
  - `.claude/rules/workflow.md` - Development workflow protocol
  - `.claude/rules/architecture.md` - Project structure template
  - `.claude/rules/feedback.md` - Feedback loop for governance improvements
- Automated installer (`install.sh`) with dependency checks
- Automated uninstaller (`uninstall.sh`) with cleanup verification
- File protection utility (`lockdown.sh`) using immutable flags
- Migration script (`migrate-from-prefect.sh`) for legacy installations
- Comprehensive test suite (300+ test cases):
  - Path traversal protection tests
  - Symlink resolution tests
  - Directory depth enforcement tests
  - Protected file validation tests
- Documentation:
  - README.md with Quick Demo and security model
  - SECURITY.md with threat model and limitations
  - LICENSE (MIT)

### Security
- Path traversal protection with canonical path validation
- Symlink resolution to prevent directory escape
- Protected file allowlist enforcement
- Audit logging for all hook actions
- Human-only edit enforcement for governance files

[Unreleased]: https://github.com/yourusername/claude-warden/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/claude-warden/releases/tag/v1.0.0
