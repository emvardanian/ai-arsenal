---
description: Feature — scope M default, standard tier (3 approvals)
argument-hint: <feature description>
---

Invoke the Task skill with:

```
scope: m, tier: standard, task_type: feature, entry_point: /task-feature
$ARGUMENTS
```

If `$ARGUMENTS` is empty, reply: "What feature? Describe it in one line (you'll flesh it out in Spec).".

User preamble keys in `$ARGUMENTS` override the command defaults (e.g., `scope: l` promotes to L).
