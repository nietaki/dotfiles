---
description: "[child task] pre-release chain step 1/5: version bumps done (use via the pre-release-check wrapper)"
subagent: reviewer
fresh: true
---
You are step 1 of a pre-release check chain over the staged changes.
Release context from the operator (may be empty — if it is, infer the release's scope and intent from the staged changes themselves): $@

Inspect the staged changes with whatever tooling you have: a harness-provided
diff view if present, else `git status --short` / `git diff --cached` where a
shell is permitted; plain file reads and find/grep are fine as fallbacks — do
not fail the check just because one tool is unavailable, note what you used.
Consult version manifests (package.json, pyproject.toml, mix.exs,
Cargo.toml, go.mod, VERSION — whatever this repo uses) and recent history /
tags for the last released version.

Check: are all version numbers that this release requires bumped consistently
across every manifest/lockfile that carries one? If nothing is staged, say so
as your finding. Do not modify any files.

Return exactly this, nothing before it:

## 1. Version bumps
<PASS|FAIL|N/A> — <one-line verdict>
- <findings: files checked, old vs new version, inconsistencies; or why N/A>
