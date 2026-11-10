---
name: status
description: Show where the project stands in the plumbline workflow - which deliverables are approved, what is still open, and the next command to run.
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/scripts/plumbline.sh *)
---

Current state, computed from git:

```
!`"${CLAUDE_PLUGIN_ROOT}"/scripts/plumbline.sh status 2>&1 || true`
```

Show the user this state as it is. Then add one or two lines saying what they
should do next, in plain words. Do not run the next command for them.
