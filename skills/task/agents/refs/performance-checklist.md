# Performance Checklist

## Database
- [ ] No N+1 queries — use eager loading / populate / join
- [ ] Indexes exist for frequently queried fields
- [ ] No unbounded queries (missing LIMIT / pagination)
- [ ] Connection pooling configured

## Memory & Async
- [ ] No memory leaks (event listeners removed, streams closed, timers cleared)
- [ ] Async/await used correctly (no unhandled promises)
- [ ] No blocking operations on main thread / event loop
- [ ] Large data sets streamed, not loaded into memory

## Caching & Network
- [ ] Expensive operations cached where appropriate
- [ ] API responses paginated for list endpoints
- [ ] No redundant API calls
- [ ] Static assets optimized (images, bundles)

## Measurement
- [ ] Flag any endpoint likely to exceed 500ms response time
- [ ] Flag operations that scale poorly (O(n²) or worse)
