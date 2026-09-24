---
description: "[parent-run] Implement the approved project plan sequentially using tracked TODOs"
argument-hint: "[extra-guidance]"
model: opencode-go/qwen3.8-flash, opencode-go/deepseek-v4.1-flash
thinking: medium
skill:
  - tdd
  - best-practices
---

Implement the approved plan for the current project. Coordinate the work in this
session and complete the plan's tasks sequentially; do not delegate or work on
multiple plan tasks in parallel.

Optional guidance from the operator is:

<extra-guidance>
$@
</extra-guidance>

Treat empty or whitespace-only guidance as no additional constraints. Treat
non-empty guidance as applying to this implementation run, but do not let it
silently override the plan's goals or non-goals when the two conflict.

## Establish the work

1. Read the applicable project instructions and `.pi/feat/plan.md` in the
   current project directory. If the plan does not exist, stop without changing
   project files and tell the operator to run `/plan` first.
2. Read the plan in full, then inspect enough of the repository and current
   working tree to understand its present state, conventions, and any work that
   may already satisfy part of the plan. Do not discard or overwrite unrelated
   operator changes.
3. Extract the plan's ordered implementation tasks into the session TODO list.
   Create one TODO per plan task, preserving sequencing with dependencies when
   applicable. Include validation expectations in each TODO's description.
4. Briefly state the task sequence before implementation begins. If the plan is
   internally contradictory or cannot be implemented responsibly, explain the
   blocker and stop rather than inventing a replacement plan.

## Implement sequentially

Work through the TODOs one at a time. Exactly one plan task may be in progress:

1. Mark the next unblocked task in progress before beginning it.
2. Reconcile that task with the current repository state. If it is already
   implemented, verify it instead of redoing it.
3. Implement the task following the plan, project instructions, loaded skills,
   and established repository patterns. Use test-driven development where the
   task is testable. Do not commit changes unless the operator explicitly asks.
4. Run the task-specific tests and checks needed to establish completion. Mark
   the TODO complete immediately after it is verified, never before.
5. Only after completing the current TODO, mark the next unblocked task in
   progress and continue.

Never begin another plan task while the current one is unresolved. If a task is
blocked, keep it in progress, record the blocker, and stop unless the blocker
can be resolved as part of that same task without expanding scope.

Repository evidence may justify reasonable implementation deviations. Make
those deviations autonomously when they preserve the approved outcome and
non-goals, follow stronger project constraints, and avoid unnecessary scope.
Record each material deviation and its rationale. Ask the operator only when a
consequential ambiguity cannot be resolved responsibly from the plan,
additional guidance, project instructions, or repository evidence.

## Validate and report

After all implementation TODOs are complete, run the plan's broader validation
strategy plus any relevant repository-wide checks that are practical. Do not
claim completion while required checks fail. If validation exposes more work,
create an ordered TODO for it and handle it under the same one-at-a-time rule.

Finish with a concise report containing:

- the completed tasks and key changes;
- tests and checks run, with their outcomes;
- material deviations from the plan and why they were necessary;
- remaining blockers, risks, or follow-up work, or `None` when there are none.
