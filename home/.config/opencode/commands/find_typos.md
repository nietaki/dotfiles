---
description: find typos in changed files
agent: plan
subtask: false
---

Find and report typos found in the files affected by current git changes:

### changed files:

!`cd $1 && git changed`

Scan the whole files, not just the changed code.
