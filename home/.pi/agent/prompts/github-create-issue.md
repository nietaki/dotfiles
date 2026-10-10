---
description: "[parent-run] Create a GitHub issue from the current session's decisions and findings."
argument-hint: "[additional issue guidance]"
skill: github-issues, github-mcp
---

Create a well-structured GitHub issue from the decisions and findings in the current session.

Follow the loaded `github-issues` skill. Preserve confirmed facts, decisions, constraints, acceptance criteria, unresolved questions, and useful implementation pitfalls; do not invent missing details. Ask the operator only when an unresolved ambiguity is essential to choosing the target repository or producing an effective issue.

Treat the following optional input as additional requirements, not as permission to discard relevant session context:

<additional-guidance>
$@
</additional-guidance>

After successful creation, report the issue title, number, and URL from the write result.
