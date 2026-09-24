---
description: "[parent-run] Interactively research and write an implementation plan for a feature or change"
argument-hint: "<feature-or-change>"
model: openrouter/openai/gpt-5.6-luna-pro, openrouter/openai/gpt-6-luna
thinking: high
skill:
  - grill-me
  - best-practices
---

Create an implementation plan for a feature or change in the current project.
Do not implement the change. You may inspect files, history, configuration, and
other available evidence and run safe read-only research or validation commands,
but the only project file you may create or modify is `.pi/feat/plan.md`.

The operator's initial brief is:

<feature-or-change>
$@
</feature-or-change>

If the brief is empty after trimming whitespace, ask the operator what feature
or change they want to plan before doing anything else. Treat a non-empty brief
as the complete freeform starting point, not as positional arguments.

## Reach shared understanding

Planning must be interactive and conversational. Do not silently guess through
material ambiguity.

1. Read the applicable project instructions and inspect the repository enough
   to understand the current architecture, conventions, constraints, and nearby
   implementation patterns.
2. If `.pi/feat/plan.md` already exists, read it as context, but do not assume
   its scope or decisions remain valid. Tell the operator it will be replaced
   only after the new plan is agreed.
3. Restate the requested outcome and boundaries in your own words. Identify the
   intended user or system impact and what a future implementer must deliver.
4. List your current assumptions explicitly and ask the operator to confirm or
   correct them. Use focused rounds of questions, include a recommended answer
   with rationale where useful, and summarize what each round established
   before moving on. Ask the repository, documentation, or authoritative
   sources questions they can answer instead of asking the operator.
5. Research the gaps that could materially affect the implementation plan.
   Prefer established project patterns. When the change is genuinely new and
   local evidence is insufficient, research relevant libraries, platform
   capabilities, and current best practices. Distinguish verified facts from
   recommendations and cite external sources that influence a decision.
6. Recommend technical choices, alternatives, and trade-offs, but obtain the
   operator's confirmation for consequential product, scope, architecture,
   dependency, compatibility, migration, security, or operational decisions.
   You may settle routine details only when they follow clearly from confirmed
   intent and project conventions.

Continue until the implementation-relevant intent is understood and no material
assumption is awaiting confirmation. Do not prolong the interview over details
that repository evidence or an implementer can safely resolve later.

## Agree the plan before writing

Before modifying `.pi/feat/plan.md`, recap the proposed plan in the conversation:

- the outcome and scope;
- explicit non-goals;
- key technical decisions, tools, and libraries;
- important assumptions, constraints, risks, and unresolved questions;
- the proposed task breakdown and ordering.

Ask the operator to approve or amend that recap. Do not write a speculative plan
while material ambiguity remains. If research is blocked, explain the blockage
and either resolve it with the operator or preserve the uncertainty explicitly
as an open question with its implementation impact.

## Write the deliverable

After approval, create the `.pi/feat/` directory if needed and write
`.pi/feat/plan.md`. Replace an existing plan rather than appending to it. Make
the document self-contained for a future implementer who does not have access
to this conversation.

Use headings appropriate to the change and include at least:

1. **Summary** — what will change, why, and the intended outcome.
2. **Goals and scope** — concrete behavior and deliverables covered by the plan.
3. **Non-goals** — related work explicitly outside this implementation.
4. **Project context** — relevant architecture, existing behavior, conventions,
   constraints, and likely files or components, with paths when known.
5. **Tools and libraries** — dependencies, platform features, or internal
   utilities to use, including whether each is existing or new and why it fits.
6. **Key decisions and rationale** — important choices, rejected alternatives,
   trade-offs, and how the approach fits the larger system.
7. **Implementation tasks** — an ordered list of independently understandable
   work items. Usually provide 2–6 tasks; use fewer or more only when the
   change's real complexity warrants it, and explain unusual granularity. For
   each task, state its objective, affected areas, concrete work, dependencies
   or sequencing, edge cases, and how to validate completion.
8. **Validation strategy** — tests, checks, migration verification, observability,
   or manual validation needed across the plan.
9. **Risks and open questions** — only genuine remaining uncertainties, each
   with its impact and the decision or evidence needed to close it. Say `None`
   when everything material is resolved.

Keep the plan implementation-oriented without inventing exact APIs, filenames,
or behavior that research did not establish. Record enough reasoning for a
future implementer to make consistent decisions when details arise.

After writing, re-read `.pi/feat/plan.md` and verify that it matches the approved
scope, contains explicit non-goals, preserves confirmed decisions and rationale,
and has a coherent task sequence. Report the path written and briefly summarize
what the plan contains. Do not begin implementation.
