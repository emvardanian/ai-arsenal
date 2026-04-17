---
description: Full ceremony — scope L default, strict tier, every approval gate
argument-hint: <large feature description>
---

Invoke the Task skill with:

```
scope: l, tier: strict, task_type: feature, entry_point: /task-full
$ARGUMENTS
```

If `$ARGUMENTS` is empty, reply: "What large task? Describe it in one line; you'll refine in Spec.".

User preamble keys in `$ARGUMENTS` override command defaults. Strict tier can be switched mid-flight via "approve and switch to <tier>" at any gate.
