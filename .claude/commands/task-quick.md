---
description: Quick task — scope XS/S, express tier (1 approval at commit)
argument-hint: <task description>
---

Invoke the Task skill with the following preamble to set express-tier small-scope defaults:

```
scope: s, tier: express, entry_point: /task-quick
$ARGUMENTS
```

If `$ARGUMENTS` is empty, reply: "What's the quick task? (e.g., 'rename getUserById to fetchUserById')".

The user may override the defaults by including their own preamble keys in `$ARGUMENTS` — user preamble wins over command defaults.
