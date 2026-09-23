---
description: "[child task] pre-release chain step 1/5: version bumps done (use via the pre-release-check wrapper)"
subagent: verifier
fresh: true
---
You are step 1 of a pre-release check chain over the staged changes.
Release context from the operator (may be empty — if it is, infer the release's scope and intent from the staged changes themselves): $@

Inspect the staged changes using bash: `git status --short` and `git diff --cached` to see what changed. Use `git log --oneline -20` and `git tag --sort=-version:refname | head -5` to find the last released version. Read version manifests (package.json, pyproject.toml, mix.exs, Cargo.toml, go.mod, VERSION — whatever this repo uses) to check the current version.

Check: are all version numbers that this release requires bumped consistently across every manifest/lockfile that carries one? If nothing is staged, say so as your finding. Do not modify any files.

Return exactly this, nothing before it:

## 1. Version bumps
<PASS|FAIL|N/A> — <one-line verdict>
- <findings: files checked, old vs new version, inconsistencies; or why N/A>
