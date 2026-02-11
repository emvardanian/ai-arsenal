# Security Checklist (Fallback)

> Use this only when `security-scanning` plugin is unavailable.

## Input Validation
- [ ] SQL injection — parameterized queries, no string concatenation in queries
- [ ] NoSQL injection — sanitized MongoDB/Mongoose queries, no `$where`
- [ ] XSS — output encoding, no `dangerouslySetInnerHTML` without sanitization
- [ ] Command injection — no `exec()`, `eval()`, `child_process` with user input
- [ ] Path traversal — no `../` in file paths from user input
- [ ] SSRF — no user-controlled URLs in server-side requests without allowlist

## Authentication & Authorization
- [ ] Auth checks on every protected endpoint
- [ ] Role-based access control where needed
- [ ] Session/token expiration and refresh
- [ ] Password hashing (bcrypt/argon2, never MD5/SHA1)
- [ ] No auth bypass through parameter manipulation

## Data Protection
- [ ] No hardcoded secrets (API keys, passwords, tokens, connection strings)
- [ ] Sensitive data not logged
- [ ] PII handled according to requirements
- [ ] Proper error messages (no stack traces to client)

## Configuration
- [ ] CORS configured restrictively (not `*` in production)
- [ ] Rate limiting on public/auth endpoints
- [ ] HTTPS enforcement
- [ ] Security headers (CSP, X-Frame-Options, etc.)

## Dependencies
- [ ] Run `npm audit` / `pip audit` / equivalent
- [ ] No known vulnerable packages
- [ ] Lock file committed
- [ ] No unnecessary dependencies added
