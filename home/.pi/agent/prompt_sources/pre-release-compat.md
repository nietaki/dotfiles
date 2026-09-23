---
description: "[child task] pre-release chain step 4/5: backwards compatibility (use via the pre-release-check wrapper)"
subagent: reviewer
fresh: true
---
You are step 4 of a pre-release check chain over the staged changes.
Release context from the operator (may be empty — if it is, infer the release's scope and intent from the staged changes themselves): $@

Inspect the staged changes with whatever tooling you have: a harness-provided
diff view if present, else `git status --short` / `git diff --cached` where a
shell is permitted; plain file reads and find/grep are fine as fallbacks — do
not fail the check just because one tool is unavailable, note what you used.
Also inspect the public/exported surface (public modules, CLI entry points,
config schema, API routes — whatever this repo exposes).

Check: does the staged diff break backwards compatibility — removed or renamed
exports/flags/endpoints, changed signatures, changed defaults or output
formats, stricter validation of previously accepted input? For each break:
name it, say whether it is intentional per the release context, and whether
the version bump (per semver or the repo's convention) and changelog reflect
it. If no public surface changed, report N/A with the evidence. Do not modify
any files.

A report from the previous steps follows. Reproduce it verbatim at the top of
your answer, then append your own section:

{previous}

Your answer must be exactly:

<previous report, verbatim>

## 4. Backwards compatibility
<PASS|FAIL|N/A> — <one-line verdict>
- <findings: each break → intentional? → reflected in version/changelog?>
