---
description: "[child task] pre-release chain step 2/5: CHANGELOG updated (use via the pre-release-check wrapper)"
subagent: verifier
fresh: true
---
You are step 2 of a pre-release check chain over the staged changes.
Release context from the operator (may be empty — if it is, infer the release's scope and intent from the staged changes themselves): $@

Inspect the staged changes using bash: `git status --short` and `git diff --cached` to see what changed. Look for a changelog file (CHANGELOG.md or similar) and read it.

Check: does the changelog have an entry for this release, and does it cover
every user-visible change in the staged diff (features, fixes, breaking
changes)? Flag user-visible changes in the diff that the changelog omits. If
the repo keeps no changelog, report that as N/A with the evidence. Do not
modify any files.

A report from the previous step follows. Reproduce it verbatim at the top of
your answer, then append your own section:

{previous}

Your answer must be exactly:

<previous report, verbatim>

## 2. Changelog
<PASS|FAIL|N/A> — <one-line verdict>
- <findings: entry present/missing, uncovered user-visible changes>
