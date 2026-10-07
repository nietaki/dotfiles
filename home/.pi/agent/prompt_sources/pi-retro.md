---
description: "[parent-run] Review recent Pi sessions and report evidence-grounded improvements to the harness"
argument-hint: "[cwd, time period, and additional issues]"
model: openrouter/openai/gpt-5.6-sol
thinking: max
skill:
  - pi-retrospect
  - obsidian-note
---
Conduct a retrospective of recorded Pi sessions to identify weaknesses in the
harness and concrete ways to improve it. This is an inline, single-agent task:
do not launch subagents or invoke a subagent workflow.

The operator's free-form scope and emphasis is:

<operator-guidance>
$@
</operator-guidance>

Interpret that guidance as natural language. It may specify one or more working
directories, a time period, and additional issues or hypotheses to investigate.
When a field is omitted, use these defaults:

- working directories: all;
- time period: the previous seven days through now, using the host timezone;
- additional issues: none beyond the standard investigation below;
- current session: exclude it;
- named working directories: use `cwdMatch: "sibling-prefix"` so adjacent
  worktree-shaped directories are included.

Treat additional issues as hypotheses and prioritisation guidance, not evidence
and not a reason to suppress unrelated findings. If the guidance is materially
ambiguous in a way that changes which sessions would be included, ask one
focused clarification before investigating. Otherwise proceed without an
interview. State the interpreted scope in the report.

## Guardrails

- The investigation is read-only. Do not edit harness configuration, project
  files, skills, prompts, tools, packages, or permission rules.
- The only permitted write is the final report note under
  `~/obsidian/pi_knowledge/sessions-retro/`.
- Do not launch subagents, saved workflows, chains, or parallel agents.
- Do not expose secrets or reproduce irrelevant private transcript content.
- A user hint, a single awkward interaction, or the old workflow's assumptions
  are not sufficient evidence of a systemic weakness.

## Investigation procedure

1. Use the injected `pi-retrospect` skill and its codemode-only tools. Call
   `list_sessions` with the interpreted timestamp bounds, omit `cwds` when the
   scope is all working directories, and otherwise pass the named absolute CWDs
   with `cwdMatch: "sibling-prefix"`. Keep `includeCurrentSession: false`.
   Inspect and report discovery warnings; an empty result with warnings does
   not prove there is no history.
2. Build a compact inventory of matching parent sessions and their nested
   `subagentSessions`. Triage before reading deeply. Use `session_entries` and
   return only the fields needed for analysis—normally transcript path,
   physical `lineNo`, role, timestamp, and bounded text. Inspect `raw` only for
   details omitted from text, such as tool-call arguments/results, model state,
   or permission failures. Never return whole transcripts to model context.
3. Look across sessions for repeated or high-impact evidence, including:
   - marked `STEERING: ` corrections and unmarked user corrections;
   - misunderstandings, repeated clarification, and their likely causes;
   - failed, denied, redundant, or awkward tool operations;
   - ineffective or conflicting system-prompt components and files under
     `~/.pi/agent/instructions/`;
   - relevant project `AGENTS.md` omissions, ambiguity, or stale guidance;
   - Pi settings, package configuration, and `pi-permission-system` friction;
   - model/task mismatch, including capability, context, latency, cost, and
     thinking-level symptoms where the transcript actually supports them;
   - delegation or workflow overhead, missing workflow steps, and needless
     manual repetition;
   - recurring operations that a custom tool, skill, or prompt could simplify;
   - any other harness-level cause supported by the sessions.
4. For plausible findings, inspect the current source-of-truth configuration
   before recommending a change. In the dotfiles setup, read repo files under
   `~/.homesick/repos/dotfiles/home/` rather than treating symlinked files under
   `$HOME` as editable sources. Read relevant project instructions when the
   finding concerns a particular project. Check whether the problem has already
   been fixed or whether current instructions contradict the initial theory.
5. When an observed gap might be solved by a published Pi package, perform
   focused, current web/package research rather than relying on memory. Cite the
   URLs actually used and explain fit, maintenance/security considerations, and
   why adoption is preferable—or not preferable—to a local prompt, skill, or
   custom tool. Do not perform an unfocused package survey.
6. Corroborate recurring claims across sessions where possible. A single event
   may still justify a finding when its impact is high, but label it as such.
   Separate verified observations, causal inference, and recommendations.

## Report

Follow the injected `obsidian-note` skill, with the operator's explicit folder
override `sessions-retro`. Create or update an appropriate dated retrospective
snapshot in `~/obsidian/pi_knowledge/sessions-retro/`; check for a same-scope
same-period note first so the vault does not accumulate near-duplicates. The
note must be self-contained and useful without access to this conversation.
Verify the written note by reading it back.

Include:

1. **Scope and method** — interpreted CWD and time bounds, whether worktree
   siblings were included, number of parent and nested sessions considered,
   selection/triage method, and all completeness warnings.
2. **Executive summary** — the most important harness weaknesses and the
   highest-value next actions.
3. **Evidence-backed findings** — for each finding:
   - affected surface and observed behavior;
   - quoted or tightly paraphrased evidence with transcript path and physical
     line number(s), without unnecessary private detail;
   - frequency/impact and whether it is isolated or recurring;
   - likely cause, clearly labelled when inferential;
   - current configuration inspected;
   - a specific proposed change naming the exact file, setting, workflow,
     package, prompt, skill, or tool surface;
   - expected gain, effort, risk/trade-offs, and confidence.
4. **Ranked proposal board** — deduplicate related changes and rank them by
   expected benefit, confidence, effort, and risk. Distinguish quick wins from
   larger experiments. Do not apply any proposal.
5. **Published-package opportunities** — only evidence-triggered candidates,
   with source links and build-vs-adopt reasoning.
6. **Rejected hypotheses and unchanged areas** — important possibilities that
   were investigated but not supported, including why they were rejected.
7. **Open questions and suggested follow-up evidence** — gaps that prevent a
   confident recommendation.

When finished, report the full note path in chat followed by a concise summary
of the top recommendations and any limitations. Do not make configuration
changes unless the operator later requests them in a separate turn.
