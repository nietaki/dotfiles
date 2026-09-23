---
description: "[parent-run] turn a feature idea into an approved .pi/feat/plan.md"
argument-hint: "[feature idea]"
---

The user invoked /feat-spec with: $@

If no feature idea was given, ask me for one (ask_user_question) before doing
anything else.

You are the planner. Do not implement anything in this command — your only
deliverable is the plan file.

1. Launch one `scout` child (subagent tool) on this repo with `output: false`,
   passing the feature idea verbatim in its task: map the code the feature
   would touch — files with line ranges, entry points, conventions, how it is
   tested today, likely friction. Return the scout's findings in full.
2. Run the test command (once you know it from the scout) to confirm the suite
   is currently green. If it's red, stop and report — do not proceed until the
   baseline is green.
3. Interview me with ask_user_question: 2-4 questions on the genuinely open
   decisions the scout surfaced (scope edges, API shape, compatibility,
   priority). Embed the scout's literal findings as options[].preview — do not
   paraphrase them.
4. Write `.pi/feat/plan.md` in this repo (create `.pi/feat/` if needed) with
   this structure:

   ```markdown
   # Feature: [name]

   ## Goal
   [1-3 sentences]

   ## Non-goals
   - [item 1]
   - [item 2]

   ## Context
   [Scout's recon findings: key files with line ranges, conventions, how tests
   are written, known friction. This is what workers will read before starting.]

   ## Task 1: [title]
   [description of what this task does]

   **Acceptance criteria:**
   - [criterion 1 — must be testable]
   - [criterion 2]

   **Files in scope:**
   - [file 1]
   - [file 2]

   ## Task 2: [title]
   [description]

   **Acceptance criteria:**
   - [criterion 1]

   **Files in scope:**
   - [file 1]

   ## Global acceptance
   [Criteria that apply across all tasks, not tied to a single task — e.g.
   "no regressions in existing tests"]

   ## Test command
   [exact shell line to run the full suite]
   ```

   Aim for **2-4 tasks**, each being one coherent vertical slice a single
   worker can finish in one session. Prefer fewer larger tasks over many small
   ones — each task pays for a fresh worker starting from scratch, a verifier,
   and 2-4 full suite runs. A task should be substantial enough that the
   overhead is justified.

   Each task must have its own acceptance criteria (testable, verifiable).
   Tasks are numbered (Task 1, Task 2, …) for stable IDs across re-runs.

5. Show me the plan and get explicit approval. Once I approve, append a line
   `Approved: <YYYY-MM-DD>` under the Goal heading — this stamp is what the
   executing workflow checks for. Stop there — do not scaffold or implement.

Next stages are separate on purpose: the `feature-dev` workflow executes the
approved plan task-by-task with verification rounds. Run it as `/workflow run
feature-dev`, or via the subagent tool with `workflowScriptPath` when you need
an explicit `timeoutMs`/`maxSubagentSpawnsPerRun`.
