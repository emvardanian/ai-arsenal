# Architecture Checklist

## Code Quality
- [ ] Single Responsibility — each function/class does one thing
- [ ] DRY — no duplicated logic (but don't over-abstract)
- [ ] KISS — no unnecessary complexity or premature optimization
- [ ] Consistent naming conventions across the codebase
- [ ] Error handling — proper try/catch, custom error classes, error boundaries

## Design
- [ ] Loose coupling — modules don't reach into each other's internals
- [ ] Clean API contracts — interfaces between modules are clear
- [ ] Consistent patterns — follows existing codebase conventions
- [ ] No circular dependencies

## Edge Cases
- [ ] Empty input / null / undefined handling
- [ ] Large input / boundary values
- [ ] Concurrent requests / race conditions
- [ ] External service failures (timeouts, retries, circuit breakers)
- [ ] Partial failures in multi-step operations
