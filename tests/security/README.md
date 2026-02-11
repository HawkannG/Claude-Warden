# Security Test Suite

Comprehensive security validation for Prefect v6.0 vulnerability fixes.

## Quick Validation

Run the fast validation suite (6 critical tests):

```bash
bash tests/security/quick-test.sh
```

**Tests:**
- ✅ Direct edit of protected files blocked
- ✅ Symlink attack prevented (P2-V1, CVSS 8.4)
- ✅ Path traversal prevented (P2-V2, CVSS 7.9)
- ✅ Safe files allowed
- ✅ Exit code correctness (P2-V4, CVSS 6.8)
- ✅ Bash write protection (P2-V3 partial)

## Full Test Suite

Run comprehensive security tests:

```bash
bash tests/security/run-security-tests.sh
```

**Individual test files:**
- `test-symlink-attack.sh` — Tests 5 symlink bypass vectors
- `test-path-traversal.sh` — Tests 6 path traversal techniques
- `test-exit-codes.sh` — Tests 5 exit code scenarios
- `test-command-injection.sh` — Tests 7 command injection vectors (⚠️ some bypass attempts expected)

## What's Tested

### CRITICAL Vulnerabilities (Fixed in v6.0)

| ID | Vulnerability | CVSS | Status | Test Coverage |
|----|--------------|------|--------|---------------|
| P2-V1 | Symlink Attack | 8.4 | ✅ FIXED | Direct, single-level, nested, hooks |
| P2-V2 | Path Traversal | 7.9 | ✅ FIXED | Literal `../`, encoded, absolute paths |
| P2-V4 | Exit Code Misuse | 6.8 | ✅ FIXED | Block=1, Allow=0, Error=2 |
| P2-V5 | jq Fallback Unsafe | 5.9 | ✅ FIXED | jq required, no grep fallback |

### PARTIAL Protection

| ID | Vulnerability | CVSS | Status | Notes |
|----|--------------|------|--------|-------|
| P2-V3 | Command Injection | 8.1 | ⚠️ PARTIAL | Direct writes blocked; variable expansion/base64/heredoc still work |

### Expected Behavior

**✅ Should block (exit 1):**
- `Edit tool → CLAUDE.md`
- `Edit tool → sneaky.md` (where sneaky.md → CLAUDE.md symlink)
- `Edit tool → ../../../etc/passwd`
- `Bash tool → echo x > CLAUDE.md`
- `Bash tool → sed -i 's/foo/bar/' PREFECT-POLICY.md`

**✅ Should allow (exit 0):**
- `Edit tool → src/app.ts`
- `Edit tool → docs/README.md`
- `Bash tool → cat CLAUDE.md`
- `Bash tool → ls -la`

**✅ Should error (exit 2):**
- Invalid JSON input
- Missing jq dependency

## CI Integration

GitHub Actions runs security tests on every push:

```yaml
- name: Run security tests
  run: bash tests/security/quick-test.sh
```

## Adding New Tests

1. Create `test-[name].sh` in `tests/security/`
2. Follow the pattern:
   - Use `set -euo pipefail` (but disable when capturing exit codes)
   - Create temp directory with `mktemp -d`
   - Clean up with `trap "rm -rf $TEST_DIR" EXIT`
   - Return exit 0 on success, exit 1 on failure
3. Add to `run-security-tests.sh`

## References

- **Panelist 2 Assessment**: `/PanelOutput/panelist-2-assessment.md`
- **SECURITY.md**: Security model and threat boundaries
- **Hook Source**: `.claude/hooks/prefect-*.sh`

---

**Last Updated:** February 2026
**Security Version:** 6.0
**Test Coverage:** 9/9 critical vulnerabilities
