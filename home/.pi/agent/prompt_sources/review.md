---
description: "[child task] Review current project changes or a specified project aspect and return prioritized, evidence-backed improvement suggestions without modifying project files."
argument-hint: "[focus]"
model: openrouter/openai/gpt-5.6-luna-pro, openrouter/openai/gpt-6-luna
thinking: high
subagent: custom-reviewer
inheritContext: false
---

Review this project without modifying project files.

The operator's optional review focus is:

<review-focus>
$@
</review-focus>

If the review focus is empty after trimming whitespace, review all current uncommitted changes, including staged, unstaged, and relevant untracked files, and assess how they integrate with the existing codebase. If a focus is present, treat the complete text as one freeform scope description and inspect enough surrounding code and project context to evaluate it properly.

Review the applicable range of concerns rather than stopping at surface-level style comments:

- correctness, edge cases, failure handling, security, and regressions;
- whether the general approach is sound and fits the existing architecture;
- opportunities to simplify or remove unnecessary abstraction and duplication;
- adherence to project conventions and relevant best practices;
- code organization, how functionality is split between functions / modules;
- bespoke functionality that maintained existing libraries or platform features could replace;
- compatibility, performance, operability, and maintainability implications;
- test quality, assertion strength, meaningful coverage, and missing cases;
- documentation or migration work required by the change.

Read the relevant project instructions, diff, implementation, tests, dependency manifests, and nearby patterns. Run safe targeted checks and, when useful and proportionate, broader tests, lint, typecheck, or build commands and non-mutating experiments. Base recommendations on repository evidence and documented local conventions; do not claim external research or force generic conventions over deliberate local constraints.

Return a prioritized list of suggestions for the operator to decide on. Support every finding with concrete evidence and include its severity, location, impact, smallest recommended change, and meaningful alternatives or trade-offs. Separate issues introduced or exposed by the reviewed work from unrelated pre-existing concerns. Also state what was reviewed, which validation commands ran and their outcomes, what already looks sound, and any testing gaps or limitations. Do not invent findings; if no actionable issue qualifies, say exactly `No issues found.`
