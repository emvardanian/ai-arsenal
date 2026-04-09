# Commit Conventions Reference

Comprehensive reference for writing conventional commit messages in the SDLC pipeline.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

## Type Values

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature or capability | `feat(auth): add JWT refresh token rotation` |
| `fix` | Bug fix | `fix(api): handle null response from payment gateway` |
| `refactor` | Code restructuring without behavior change | `refactor(cart): extract price calculation into service` |
| `docs` | Documentation only changes | `docs: update API endpoint reference` |
| `test` | Adding or updating tests | `test(auth): add integration tests for login flow` |
| `chore` | Maintenance, dependencies, config | `chore: upgrade axios to 1.6.0` |
| `perf` | Performance improvement | `perf(db): add index on users.email column` |
| `ci` | CI/CD pipeline changes | `ci: add staging deploy step to GitHub Actions` |

## Scope Naming

- Lowercase, kebab-case
- Use module or feature name, not file names
- Scope is optional but recommended for `feat` and `fix`
- Omit scope for cross-cutting changes

Good scopes: `auth`, `api`, `user-profile`, `payment-gateway`, `cart`, `notifications`

Bad scopes: `utils.js`, `UserService`, `src/lib`, `index`

## Description Rules

- Imperative mood: "add", "fix", "update" -- not "added", "fixed", "updated"
- Lowercase first letter
- No period at end
- Target length: 50 characters or fewer
- Hard limit: 72 characters
- Complete the sentence: "This commit will ___"

## Body Rules

- Separated from description by one blank line
- Explain WHY, not WHAT (the diff shows what changed)
- Wrap at 72 characters per line
- Can use bullet points (prefixed with `-`)
- Optional for small, self-explanatory changes

## Footer Rules

- `Closes #N` or `Fixes #N` for issue references
- `BREAKING CHANGE: description` for breaking changes (must be uppercase)
- Multiple footers allowed, one per line
- Separated from body by one blank line

## Breaking Change Notation

Two ways to denote a breaking change (use both together):

1. Append `!` after type/scope in the subject line:
   ```
   feat(api)!: change response envelope format
   ```

2. Add a `BREAKING CHANGE:` footer explaining the migration:
   ```
   feat(api)!: change response envelope format

   All endpoints now return { data, meta, error } instead of raw payloads.

   BREAKING CHANGE: API consumers must unwrap the data field from responses.
   Migrate by accessing response.data instead of response directly.
   ```

When using `!`, always include the `BREAKING CHANGE:` footer with migration details.

## Good Examples

### Simple feature
```
feat(auth): add JWT-based user authentication
```

### Feature with body
```
feat(notifications): add email digest for weekly activity

Users receive a summary of unread notifications every Monday.
Digest is skipped if the user has no activity in the past week.
```

### Bug fix with issue reference
```
fix(api): handle null response from payment gateway

The gateway returns null instead of an error object when the
merchant account is suspended. Guard against this to prevent
unhandled TypeError in checkout flow.

Fixes #342
```

### Refactor
```
refactor(cart): extract price calculation into dedicated service

Price logic was duplicated across CartController and OrderController.
Centralizing it reduces drift and simplifies tax rule changes.
```

### Performance improvement
```
perf(search): add trigram index for fuzzy name matching

Query time drops from ~800ms to ~40ms on the users table
for LIKE queries with leading wildcards.
```

### Documentation
```
docs: update README and CHANGELOG for auth feature
```

### Chore with dependency update
```
chore: upgrade axios to 1.6.0

Addresses CVE-2023-45857 (CSRF token leakage via cookies).
```

### Test addition
```
test(payment): add integration tests for refund flow

Covers full refund, partial refund, and refund on expired
transactions. Uses Stripe test mode fixtures.
```

### CI change
```
ci: add staging deploy step to GitHub Actions

Staging auto-deploys on merge to develop branch.
Production still requires manual approval.
```

### Breaking change
```
feat(api)!: require API key header on all endpoints

Previously, read-only endpoints were unauthenticated.
All requests now require the X-API-Key header.

BREAKING CHANGE: clients must include X-API-Key header.
Unauthenticated requests return 401 instead of 200.
```

### Multi-line body with bullets
```
fix(auth): prevent session fixation on login

- Regenerate session ID after successful authentication
- Clear stale session data before creating new session
- Add session fingerprint check against user-agent

Fixes #218
```

## Bad Examples

| Message | Problem |
|---------|---------|
| `feat(auth): Added JWT-based authentication.` | Past tense ("Added"), trailing period |
| `fix: fixed the bug` | Vague description, past tense ("fixed") |
| `update stuff` | No type, no scope, no meaningful description |
| `feat(auth): Add JWT-based authentication` | Capitalized first letter in description |
| `fix(src/utils/helpers.js): handle edge case` | File path as scope instead of feature name |
| `feat: add auth and update docs and fix tests` | Multiple unrelated changes in one commit |
| `wip` | No type, meaningless description, not a valid commit |
| `fix(api): Fix the issue where the payment gateway returns null when the merchant account is suspended` | Description exceeds 72 characters |
| `FEAT(AUTH): ADD JWT` | All caps type and scope |
| `feat(auth): add authentication\n\nAdded JWT tokens` | Body restates what instead of why; past tense in body |

## Multi-Plan Commit Strategy

When a feature spans multiple plans or modules:

- One commit per plan or module boundary
- Each commit should be independently valid (builds, tests pass)
- Documentation can be a separate `docs:` commit or included with the feature commit
- Order: implementation commits first, docs commit last

Example sequence for an authentication feature:
```
feat(auth): add JWT token generation and validation
feat(auth): add login and registration endpoints
feat(auth): add password reset flow
test(auth): add integration tests for auth endpoints
docs: add authentication API reference
```

Avoid squashing unrelated modules into a single commit. Each commit should tell a clear, single-purpose story in the git log.
