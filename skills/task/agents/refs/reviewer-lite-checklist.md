# Reviewer-Lite Checklist

**Purpose**: Pattern-matchable critical-issue checklist for haiku-tier per-module review. Loaded on demand by `agents/reviewer-lite.md`.

**Scope**: 5 categories. Each category has (a) trigger patterns the agent can detect via grep/regex/simple AST, (b) default severity, (c) deduplication rule against test failures.

**Out of scope**: semantic cross-file analysis, circular-dependency detection, race-condition inference. Those require final Reviewer (sonnet).

## Category 1: Hardcoded Secrets

**Severity**: Critical (always)

**Patterns**:

| Pattern | Example | Tool |
|---|---|---|
| AWS access key | `AKIA[0-9A-Z]{16}` | grep |
| GitHub PAT | `ghp_[A-Za-z0-9]{36}` | grep |
| OpenAI API key | `sk-[A-Za-z0-9]{48}` | grep |
| Anthropic API key | `sk-ant-[A-Za-z0-9_-]{40,}` | grep |
| Private key header | `-----BEGIN .+PRIVATE KEY` | grep |
| JWT/session secret string literals | `(SECRET\|TOKEN\|KEY)\s*=\s*["'][A-Za-z0-9+/=]{20,}["']` in code files | grep |
| .env file committed | any file `.env` not in `.gitignore` | filesystem |

**Finding format**: `Hardcoded <type> in <file>:<line>. Pattern matched: <pattern>.`

## Category 2: N+1 Queries

**Severity**: Critical if in hot path (route handler, request middleware); else Minor.

**Patterns**:

| Pattern | Example | Notes |
|---|---|---|
| ORM `.findOne`/`.get`/`.fetch` inside loop | `for (u of users) { const x = await User.findOne({ id: u.parentId }) }` | detect loop + async call + model method |
| Raw SQL in loop | `for ... { await db.query("SELECT ...") }` | same structural pattern |
| `.map(async ...)` with DB call | `users.map(async u => db.fetch(u.id))` | Promise.all allowed; naked map not |

**Detection**: look for `for`/`while`/`forEach`/`.map`/`.filter` containing `await`, DB method, or known ORM call.

**Severity upgrade**: if loop iterates over `req.body` or unbounded input → Critical regardless of hot-path.

## Category 3: SQL Injection Patterns

**Severity**: Critical (always)

**Patterns**:

| Pattern | Example |
|---|---|
| String concatenation in query | `db.query("SELECT * FROM users WHERE id = " + userId)` |
| Template literal with unsanitized vars | `` db.query(`SELECT * FROM t WHERE x = ${input}`) `` without known-safe `input` |
| `%s`-style string formatting into raw query | `cursor.execute("SELECT * FROM t WHERE x = %s" % value)` (Python) |
| Missing parameterization for known libs | `.query()` / `.execute()` / `.raw()` with non-literal string, no parameter array |

**Detection**: grep for `query(`, `execute(`, `raw(`, `.find(` (when first arg looks concatenated).

**Allowlist**: parameterized queries (`db.query("... WHERE x = ?", [value])`), ORM builders (`where({id})`), well-known safe builders.

## Category 4: Unhandled External-Call Failures

**Severity**: Critical for payment/auth/data-loss paths; else Minor.

**Patterns**:

| Pattern | Example |
|---|---|
| `await fetch(...)` without `.catch` or `try/catch` | `const r = await fetch(url); return r.json();` |
| `axios(...)` without error handling | same |
| `http.get(url, callback)` with single-arg callback | `http.get(url, r => ...)` — no err arg |
| Promise without rejection handler | `doStuff().then(...)` no `.catch` |
| External API call in async fn with no try/catch wrapping | any |

**Detection**: look for known HTTP clients + examine enclosing control flow.

**Hot-path upgrade**: if call is in `POST /checkout`, `POST /auth`, `DELETE /...` handlers → Critical.

## Category 5: Unbounded Loops

**Severity**: Critical if no break condition visible; Minor if bounded but verbose.

**Patterns**:

| Pattern | Example |
|---|---|
| `while(true)` without visible `break` in body | `while (true) { if (cond) continue; doThing(); }` — no break |
| `for(;;)` (C-style infinite) | any |
| Recursion without base case check | function calls itself unconditionally |
| `setInterval` without `clearInterval` reference | potential runaway |

**Detection**: grep for `while(true)`, `while (true)`, `for(;;)`. For recursion, look for function definitions calling themselves without an early `return` before the call.

**Note**: intentionally-infinite event loops (e.g., main daemon loop) should be whitelisted via comment `// eslint-disable-line` or explicit pattern. If Review-Lite flags, user can fix or dismiss via final Reviewer.

## Deduplication Rules

Before reporting a finding, check `.task/07-tests-{N}-{C}.md` Brief section:

- If a test failure already mentions the same file:line → skip (deduplication).
- If the test failure's error message contains the same pattern term → skip.

This prevents double-reporting issues the Tester already caught.

## Output Format

Review-Lite agent emits findings to `.task/09.5-review-lite-{N}.md` per the schema in `specs/task-cycle2-integration/contracts/reviewer-lite-output.md`.

Per finding row:
```
| <#> | <severity> | <file>:<line> | <category> | <description> | <pattern_matched> |
```

## Verdict Rules

- **PASS**: zero findings.
- **PASS_WITH_MINOR**: only Minor findings.
- **FAIL_CRITICAL**: one or more Critical findings → routes to Debugger (max 2 cycles per Test/Debug rule).

## Haiku Constraints

Review-Lite runs on haiku. Haiku handles:
- grep/regex pattern matching ✓
- simple AST walking (loops, conditionals) ✓
- file:line reporting ✓

Haiku does NOT handle:
- cross-file reasoning ✗ (defer to final Reviewer)
- semantic control-flow analysis ✗
- type inference ✗
- data-flow tracking across functions ✗

If a category requires capabilities haiku lacks, leave it to the final Reviewer. Review-Lite's value is speed + early catch, not depth.
