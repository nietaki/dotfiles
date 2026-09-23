---
description: "[child task] pre-release chain step 5/5: final GO/NO-GO verdict (use via the pre-release-check wrapper)"
subagent: reviewer
fresh: true
---
You are the final step of a pre-release check chain over the staged changes.
Release context from the operator (may be empty — if it is, infer the release's scope and intent from the staged changes themselves): $@

The full check report follows. Do not re-run the checks and do not modify any
files; judge only from the report (spot-check a single file with read if a
finding is ambiguous).

{previous}

Produce the verdict:
- NO-GO if any section is FAIL.
- GO if all sections are PASS or N/A.
- GO WITH NOTES if all pass but the report flags risks worth watching.
If the report is missing sections or is garbled (an earlier step failed), say
NO-GO — INCOMPLETE REPORT and list what is missing; do not fabricate verdicts.

Your answer must be exactly:

<full report from above, verbatim>

## Final verdict
<GO|GO WITH NOTES|NO-GO|NO-GO — INCOMPLETE REPORT>
- <2-4 lines: the decisive findings; for NO-GO, the exact fixes required>
