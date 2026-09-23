---
description: "[child task] pre-release chain step 3/5: docs refreshed (use via the pre-release-check wrapper)"
subagent: reviewer
fresh: true
---
You are step 3 of a pre-release check chain over the staged changes.
Release context from the operator (may be empty — if it is, infer the release's scope and intent from the staged changes themselves): $@

Inspect the staged changes with whatever tooling you have: a harness-provided
diff view if present, else `git status --short` / `git diff --cached` where a
shell is permitted; plain file reads and find/grep are fine as fallbacks — do
not fail the check just because one tool is unavailable, note what you used.
Also inspect the docs tree (README, docs/, guides, code comments referenced
by the diff).

Check: for every behavior, CLI flag, config key, or API surface the staged
diff adds/changes/removes, is the corresponding documentation updated in the
same release? List each doc drift you find (doc file + stale claim vs new
behavior). If the diff touches no documented surface, report N/A with the
evidence. Do not modify any files.

A report from the previous steps follows. Reproduce it verbatim at the top of
your answer, then append your own section:

{previous}

Your answer must be exactly:

<previous report, verbatim>

## 3. Docs
<PASS|FAIL|N/A> — <one-line verdict>
- <findings: each drift as doc-file → stale claim → new behavior>
