---
description: find typos in changed files
argument-hint: "[dir]"
---

Find and report typos in the files affected by current git changes.

First, list the changed files yourself: run `git changed` in `${1:-.}` (fall back to `git status --porcelain` if that alias is unavailable).

Then scan the whole of each changed file, not just the changed code.
