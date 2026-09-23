---
description: "[parent-run] turn a feature idea into an approved .pi/feat/plan.md"
argument-hint: "[feature idea]"
---

The user invoked /feat-spec with: $@

If no feature idea was given, ask me for one (ask_user_question) before doing
anything else.

You are the planner. Do not implement anything in this command — your only
deliverable is the plan file.

1. Launch one `scout` child (subagent tool) on this repo, passing the feature
   idea verbatim in its task: map the code the feature would touch — files,
   entry points, conventions, how it is tested today, likely friction.
2. Then interview me with ask_user_question: 2-4 questions on the genuinely
   open decisions the scout surfaced (scope edges, API shape, compatibility,
   priority). Embed the scout's literal findings as options[].preview — do not
   paraphrase them.
3. Write `.pi/feat/plan.md` in this repo (create `.pi/feat/` if needed) with
   sections: Goal; Non-goals; Task breakdown (each task independently
   verifiable); Acceptance criteria (testable); Test command (the exact shell
   line); Files in scope (from the scout report).
4. Show me the plan and get explicit approval. Once I approve, append a line
   `Approved: <YYYY-MM-DD>` under the Goal heading — this stamp is what the
   executing workflow checks for. Stop there — do not scaffold or implement.

Next stages are separate on purpose: the `feature-dev` workflow
(`~/.pi/agent/subagent-workflows/feature-dev/script.js`, registered with the
pi-subagents-workflows package — run it as `/workflow run feature-dev`, or via
the subagent tool with `workflowScriptPath` when you need an explicit
`timeoutMs`/`maxSubagentSpawnsPerRun`) executes the approved plan
task-by-task with verification rounds. If that workflow does not exist yet,
implement the approved plan directly or run the packaged `/review-loop` for
ad-hoc implement→review cycles.
