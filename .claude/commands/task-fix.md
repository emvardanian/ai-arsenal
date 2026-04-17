---
description: Bugfix — task_type=bugfix, scope auto-classified, tier follows scope
argument-hint: <bug description>
---

Invoke the Task skill with:

```
task_type: bugfix, entry_point: /task-fix
$ARGUMENTS
```

If `$ARGUMENTS` is empty, reply: "What needs fixing?".

User preamble keys in `$ARGUMENTS` override the command defaults.
