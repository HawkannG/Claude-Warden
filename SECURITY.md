# Security Policy

## Threat Model

⚠️ **Critical Understanding:** Warden is designed to prevent **unintentional** governance violations by Claude Code, not to defend against a **deliberately adversarial** AI agent. The hooks are security controls for workflow enforcement, **not a sandbox**.

### What Warden Protects Against ✅

- Accidental edits to governance files (CLAUDE.md, WARDEN-POLICY.md)
- Workflow drift (Claude skipping phases or ignoring instructions)
- Project structure violations (temp/ directories, excessive nesting)
- Unintended modifications to hooks and configuration

### What Warden Does NOT Protect Against ❌

- **Adversarial AI**: An AI agent actively attempting to bypass hooks
- **Filesystem access outside Claude Code**: Manual edits or other tools
- **Compromised hooks**: Maliciously modified hook scripts
- **Privilege escalation**: Hooks run with the same privileges as Claude Code
- **Race conditions**: TOCTOU attacks or rapid filesystem changes
- **Encoded payloads**: Heavily obfuscated or encoded bypass attempts

### Architectural Constraints

- Hooks run in the **same process space** as Claude Code
- No **cryptographic verification** of governance files
- **Audit logs are not tamper-proof**
- **Path validation is heuristic-based**, not exhaustive

For high-security environments, combine Warden with:
- File integrity monitoring (AIDE, Tripwire)
- Immutable file flags (`chattr +i` on Linux)
- Separate access control (filesystem permissions, SELinux)
- Code review of all AI-generated code before execution

## Supported Versions

| Version | Supported          | Status |
| ------- | ------------------ | ------ |
| 6.0.x   | :white_check_mark: | Secure |
| < 6.0   | :x:                | Upgrade required |

## Reporting a Vulnerability

**DO NOT** open public GitHub issues for security vulnerabilities.

### How to Report

Use GitHub's private security advisory:
- https://github.com/HawkannG/Warden-AI-Governance-Framework/security/advisories/new

Or contact the maintainer directly (see README).

### What to Include

- Clear description of the vulnerability
- Steps to reproduce
- Impact and affected versions
- Suggested fix (optional)

## Security Fixes in v6.0

Version 6.0 addresses 9 security vulnerabilities:

1. **Symlink Attack Protection** - Hooks now resolve symlinks before path validation
2. **Path Traversal Prevention** - Canonical path validation prevents `../` bypasses
3. **Command Injection Hardening** - Removed unsafe grep fallback, jq now required
4. **Exit Code Standardization** - Correct exit codes (0=allow, 1=block, 2=error)
5. **Dependency Validation** - jq is required, no unsafe fallbacks
6. **Git Command Injection Fix** - Sanitized paths before git operations
7. **Hook Tampering Protection** - Hooks protected from modification
8. **Error Handling** - All hooks have `set -euo pipefail`
9. **Log Injection Mitigation** - Resilient log format with error handling

## Security Testing

Run the comprehensive test suite:
```bash
bash tests/run-tests.sh
```

Includes 400+ tests covering all vulnerability types with regression testing.

## Best Practices

- Don't run Claude Code as root
- Review `.claude/audit.log` periodically
- Use version 6.0 or later
- Keep hooks executable and unmodified

---

**Last Updated:** February 2026
**Security Version:** 6.0
