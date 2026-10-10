# feature-dev

Executes an **approved** `.pi/feat/plan.md` (produced by `/feat-spec`) task by
task, with an independent verification gate per task. Nothing is committed —
the tree is left dirty for the operator to review and commit.

## Plan format

The plan must follow the structure produced by `/feat-spec`:
- Numbered tasks (`## Task 1: …`, `## Task 2: …`) with stable IDs
- Each task has its own **Acceptance criteria** subsection (REQUIRED — plans
  with flat acceptance criteria are rejected)
- A **Context** section with the scout's recon findings (key files, conventions,
  how tests are written) — passed to every worker
- A **Global acceptance** section for cross-cutting criteria
- A **Test command** that must be green at baseline

## Shape

```
decompose (fresh scout, outputSchema; checks 'Approved:' stamp + clean tree +
           baseline test suite green)
per task, serially:
  fresh worker (skill: tdd, sole writer; reads Context section first)
      -> blocked/crash? ABORT
  fresh verifier (bash + watchdog_diff, NO edit/write)
      -> PASS: next task | crash: ABORT | FAIL: resume the worker, capped rounds
closing fan-out (both schema-typed):
  reviewer (opus-5.5) -> code quality (P0/P1/P2 + merge verdict)
  verifier -> acceptance (on full runs: global criteria only + cross-check;
                          on partial runs: selected tasks' criteria)
verdict: COMPLETE | COMPLETE_WITH_BLOCKERS | COMPLETE_REVIEW_INCOMPLETE
         | ABORTED | NO-GO
```

## Spawn budget

The script tracks spawns and aborts cleanly with a report before exceeding
`args.spawnCap` (default 24). Resumes reuse the original claim, so they don't
consume additional budget.

| tasks | maxFixRounds=2 worst case | fits default cap? |
|---|---|---|
| 3 | 3 + 6·3 = 21 | yes |
| 4 | 3 + 6·4 = 27 | **no** |

Beyond ~3 tasks (or with a higher `maxFixRounds`), either:
- Pass `args.spawnCap` higher via the direct launch surface
- Use `args.onlyTasks` to split the plan

## Limits of the `/workflow run` surface

The registry hands pi-subagents only `{workflowScript, cwd}`, always detached
async, so it can set **no outer `timeoutMs`**. Beyond ~3 tasks, launch the
same script directly so the deadline can be set:

```js
subagent({ workflowScriptPath: "/Users/nietaki/.pi/agent/subagent-workflows/feature-dev/script.js",
           args: { planPath: ".pi/feat/plan.md", spawnCap: 40 }, cwd: "<target repo>",
           timeoutMs: 14_400_000, maxSubagentSpawnsPerRun: 40 })
```

## Notes

- `onlyTasks` is `string[]` because the registry has no `number[]` type; the
  script normalises numeric strings. It also scopes the closing acceptance
  check to the selected tasks.
- `allowDirty` exists for continuations: the tree is dirty from the previous
  run, and those paths are passed to every auditor as pre-existing.
- Model tiers: `worker` and `verifier` are both pinned to
  `opencode-go/qwen3.8-flash` (settings `agentOverrides` / `agents/verifier.md`
  frontmatter); `scout` is `opencode-go/deepseek-v4.1-flash`; closing `reviewer`
  is overridden to `openrouter/openai/gpt-5.6-sol` for stronger cross-task
  judgment (fallback if sol is rate-limited: `openrouter/openai/gpt-5.6-luna-pro`).
- The decompose child passes `output: false`: scout's `output: context.md`
  frontmatter would route an artifact write into `~/.pi/agent/sessions/…`,
  which our permission policy write-denies (`~/.pi/*`).
- The script wraps the main execution in try/catch to return a structured
  report on errors, rather than throwing mid-run.
