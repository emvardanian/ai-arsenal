# Commit Message Template

## Format

```
<type>(<scope>): <description>

<body>

<footer>
```

## Good Examples

```
feat(auth): add JWT-based user authentication

Implement JWT token generation and validation for the auth module.
Add middleware for protected routes and token refresh logic.
Update user model with token-related fields.

Closes #42
```

```
fix(api): handle null response from payment gateway

Payment gateway occasionally returns null on timeout.
Added null check with graceful fallback and retry logic.
```

```
docs: update README and CHANGELOG for auth feature

Add authentication section to README with setup instructions.
Add CHANGELOG entry for v1.2.0 auth feature.
```

## Bad Examples

- ❌ `feat(auth): Added JWT-based authentication.` (past tense, period)
- ❌ `fix: fixed the bug` (vague, past tense)
- ❌ `update stuff` (no type, no scope, no description)

## Quick Copy Format

```bash
cd /path/to/repo

# Commit 1
git add src/auth/jwt.ts src/auth/middleware.ts src/models/user.ts
git commit -m "feat(auth): add JWT-based user authentication

Implement JWT token generation and validation for the auth module.
Add middleware for protected routes and token refresh logic.

Closes #42"
```
