---
description: "[child task] find typos in changed files"
argument-hint: "[dir]"
subagent: scout
fresh: true
---

Find and report typos in the files affected by current git changes.

First, list the changed files yourself: run `git changed` in `${1:-.}` (fall back to `git status --porcelain` if that alias is unavailable).

Then scan the whole of each changed file, not just the changed code.

Return only a terse list — file, line, misspelling, correction. No prose, no fixes applied.
