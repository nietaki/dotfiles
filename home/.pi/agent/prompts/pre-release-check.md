---
description: "[chain wrapper — invoke as /prompt-workflow pre-release-check <release context>] staged-change release gate: versions, changelog, docs, compat, verdict"
argument-hint: "[optional short release hint, e.g. 'v1.2.0 bugfix release']"
chain: pre-release-version -> pre-release-changelog -> pre-release-docs -> pre-release-compat -> pre-release-verdict
---
This file is a chain wrapper: its `chain:` frontmatter is the whole definition
and this body is never sent to a child. It is meant for
`/prompt-workflow pre-release-check`, which runs the five
steps strictly sequentially, splicing each step's output into the next, and
returns the final report with a GO/NO-GO verdict. Args are optional: a short
release hint (version, intent) sharpens the checks, but with none the steps
infer scope from the staged changes themselves.

(Parent: if you are reading this because the operator typed
`/pre-release-check` natively — do not act on this body. Run
`/prompt-workflow pre-release-check` with the operator's release context
instead, or, if they want judgment applied between checks, run the five
`pre-release-*` steps yourself as fresh-context reviewer children and
synthesize.)

Known chain limitation, accepted by design: failures are unguarded — if a step
fails, later steps run on its empty output. The verdict step is instructed to
return NO-GO — INCOMPLETE REPORT in that case rather than fabricate a result.
