# Debug Examples

## Clustering Example

```
Cluster 1: "Authentication failures" (tests 3, 7, 12)
  - All fail with "401 Unauthorized"
  - All hit /api/protected/* endpoints

Cluster 2: "Validation errors" (test 5)
  - Returns 400 instead of expected 200
  - Only on POST /api/users with valid payload
```

## Hypothesis Example

```
Cluster 1: "Authentication failures"

  Hypothesis A: Token validation middleware rejects valid tokens
    - Where to look: middleware/auth.ts, verifyToken function
    - What would confirm: incorrect secret, wrong algorithm

  Hypothesis B: Token not being sent in request headers
    - Where to look: test setup, API client configuration
    - What would confirm: missing Authorization header

  Hypothesis C: User role mismatch
    - Where to look: middleware/roles.ts, route-level requirements
    - What would confirm: test user has 'user' role but endpoint requires 'admin'
```

## Investigation Example

```
Hypothesis A: Token validation middleware
  Evidence FOR:
    ✓ auth.ts line 23: uses process.env.JWT_SECRET but .env.test has different value
    ✓ Token generated with 'test-secret' but validated against 'production-secret'
  Evidence AGAINST:
    ✗ Algorithm matches (HS256 in both)
  Confidence: 85%
```

## Fix Instruction Example

```
Fix for Cluster 1:
  File: middleware/auth.ts
  Line: ~23
  Current: const secret = process.env.JWT_SECRET
  Change to: const secret = process.env.JWT_SECRET || 'test-secret-fallback'

  AND

  File: .env.test
  Add: JWT_SECRET=test-secret-used-in-fixtures

  Why: Token generation in test fixtures uses 'test-secret' but
  the middleware reads from .env which has a different value in test.
```
