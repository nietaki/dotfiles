# feature-dev

Executes an **approved** `.pi/feat/plan.md` (produced by `/feat-spec`) task by
task, with an independent verification gate per task. Nothing is committed —
the tree is left dirty for the operator to review and commit.

## Shape

```
decompose (fresh scout, outputSchema; checks the 'Approved:' stamp + clean tree)
per task, serially:
  fresh worker (skill: tdd, sole writer)  -> blocked/crash? ABORT
  fresh verifier (bash + watchdog_diff, NO edit/write)
      -> PASS: next task | crash: ABORT | FAIL: resume the worker, capped rounds
closing fan-out (both schema-typed):
  reviewer  -> code quality (P0/P1/P2 + merge verdict)
  verifier  -> acceptance (runs the suite; on a full run also cross-checks the
               plan for criteria the decomposition dropped)
verdict: COMPLETE | COMPLETE_WITH_BLOCKERS | COMPLETE_REVIEW_INCOMPLETE
         | ABORTED | NO-GO
```

## Limits of the `/workflow run` surface

The registry hands pi-subagents only `{workflowScript, cwd}`, always detached
async, so it can set **no outer `timeoutMs`** and **no raised
`maxSubagentSpawnsPerRun`**. Resumed children claim a spawn slot too, so with
the default cap of 24:

| tasks | maxFixRounds=2 worst case | fits default cap? |
|---|---|---|
| 3 | 3 + 6·3 = 21 | yes |
| 4 | 3 + 6·4 = 27 | **no** |

Beyond ~3 tasks (or with a higher `maxFixRounds`), launch the same script
directly so the budget and deadline can be set:

```js
subagent({ workflowScriptPath: "/Users/nietaki/.pi/agent/subagent-workflows/feature-dev/script.js",
           args: { planPath: ".pi/feat/plan.md" }, cwd: "<target repo>",
           timeoutMs: 14_400_000, maxSubagentSpawnsPerRun: 40 })
```

Exceeding the cap mid-run makes `runs.run` throw — no structured report.

## Notes

- `onlyTasks` is `string[]` because the registry has no `number[]` type; the
  script normalises numeric strings. It also scopes the closing acceptance
  check to the selected tasks.
- `allowDirty` exists for continuations: the tree is dirty from the previous
  run, and those paths are passed to every auditor as pre-existing.
- Model tiers: `worker` and `verifier` are both pinned to
  `opencode-go/qwen3.8-flash` (settings `agentOverrides` / `agents/verifier.md`
  frontmatter); `scout` is `qwen3.7-plus`; closing `reviewer` is `qwen3.8-flash`.
- The decompose child passes `output: false`: scout's `output: context.md`
  frontmatter would route an artifact write into `~/.pi/agent/sessions/…`,
  which our permission policy write-denies (`~/.pi/*`).
