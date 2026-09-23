# pi-subagents workflow lineup — decisions & justification

Status: agreed (2026-09-23). One workflow authored at a time, review between each.

## W1 — `feat-spec.md` — parent-recipe (prompt template, invoked `/feat-spec`)

**What:** turns a feature idea into an approved `.pi/feat/plan.md` (goal,
non-goals, task breakdown, acceptance criteria, test command, files in scope).
Scout child does repo recon; the parent session interviews the user and writes
the plan. Stops there — no code.

**Why this style:** requirements gathering is judgment work — deciding when
recon is sufficient, what to probe, how to split tasks, when to stop for
approval. The library deliberately keeps loop/clarification judgment
parent-side; a script or chain cannot ask the user questions.

## W2 — pre-release-check — chain wrapper (`/prompt-workflow`)

Status: shipped 2026-09-23 — 6 files in `prompt_sources/` (5 steps + wrapper),
smoke-tested end-to-end; verdict NO-GO on first live use was correct (caught
real doc drift, since fixed).

**What:** a fixed linear pre-release check over the staged changes: version
bumps done, `CHANGELOG.md` updated, docs refreshed, backwards-compatibility
verified — then a 5th `pre-release-verdict` step that judges only from the
cumulative report. The chain is a cumulative-report pipeline: each step
reproduces the prior report verbatim and appends its section, because
`{previous}` carries only the immediate predecessor and the chain result is
the last step's output alone. Unguarded-failure mitigation: the verdict step
returns `NO-GO — INCOMPLETE REPORT` on garbled/missing sections instead of
fabricating.

**Why this style:** the check sequence is always the same, with no branching
between stages — the canonical use of `chain: a -> b -> c`. It gains the one
thing scripts lack: operator-invocable slash-command UX from a discovered
template. Its known weakness (unguarded failure propagation) is acceptable:
a step running on garbage input fails visibly, not dangerously.
(Design brainstorm still open; it replaced the original `feat-scaffold`
chain proposal, which the user dropped.)

## W3 — `feature-dev.js` — script workflow

**Status:** authored 2026-09-23 (`home/.pi/agent/subagent-workflow_sources/feature-dev/`,
symlinked into `~/.pi/agent/subagent-workflows/feature-dev/` via a tracked
`120000` dir-symlink for the registry's realpath check). Ships with a new
custom agent `home/.pi/agent/agents/verifier.md` (bash + watchdog_diff, NO
edit/write) and a relaxed `home/.agents/skills/tdd/SKILL.md` (behavior-cluster
cycles, assertion-level RED, interface-sketch-not-a-phase, bugfix loop, escape
hatches). Registered with the `pi-subagents-workflows` package
(`npm:pi-subagents-workflows@0.2.1`, pinned) — `/workflow run feature-dev`
works from any session whose cwd is the target repo, but that surface can't
raise `maxSubagentSpawnsPerRun` or set an outer `timeoutMs`, so plans above
~3 tasks use the direct `workflowScriptPath` launch (same script file). Smoke
test 2026-09-23: `/workflow run feature-dev` in an empty scratch repo returned
`verdict: NO-GO, stage: decompose` with a blocker naming `.pi/feat/plan.md`,
as expected.
assertion-level RED, interface-sketch-not-a-phase, bugfix loop, escape hatches).

**What:** executes an approved W1 plan: decompose tasks via `outputSchema`
(fresh scout, enforces the `Approved:` stamp and a clean working tree),
serially implement each task with a fresh `worker` (sole writer,
`skill: "tdd"`, designs the interface sketch itself; the approved plan stands
in for the skill's Planning step), resumed only for that task's fix rounds —
verify each task with a fresh-context `verifier` that re-runs the suite and
audits test honesty, capped fix rounds (default 2, findings threaded back
verbatim), abort-with-full-report on persistent FAIL, worker-blocked, or any
child crash, closing schema-typed fan-out (fresh `reviewer` for code quality
+ fresh `verifier` for acceptance, since only it can run the suite), explicit
return of per-task status + a machine-readable verdict.

**Why this style:** this is the shape templates structurally cannot express —
data-driven decomposition, a bounded loop, branching on machine-readable
results, and resume-key threading through rounds. Gates/loops live in
deterministic JavaScript; the LLM only does the tasks. Serial one-writer keeps
the write path safe; parallel worktree lanes are a later lesson, not this trio.

**Design decisions (from the W3 conversation):** the red-green-refactor loop
lives INSIDE the per-task worker — splitting test-author/implementer across
children forces the horizontal slicing the tdd skill forbids; independence
comes from the fresh verifier instead. No commits anywhere — verifiers audit
worker-reported filesTouched (merged across fix rounds) + the cumulative diff
instead of per-task baselines, hence the clean-tree preflight (`allowDirty`
opt-out passes pre-existing paths to every auditor). Spawn budget: resumes
claim a slot too, so worst case is 3 + 2·(maxFixRounds+1)·T — raise
`maxSubagentSpawnsPerRun` on the launch call beyond ~3 tasks. `toolBudget.block` turned out to be budget-triggered, not
persistent — the only durable no-edit guarantee is the custom agent's `tools:`
allowlist. Verifier tiered at qwen3.8-flash per operator call (author/judge
same-tier risk accepted; closing reviews + operator as backstop);
`qwen3.8-max` added to the global modelScope allowlist for future retiering.

## Follow-up — `sessions-retro` — script workflow

**Status:** authored 2026-09-23 (`home/.pi/agent/subagent-workflow_sources/sessions-retro/`, same registry layout as feature-dev). Registered with `pi-subagents-workflows`.

**What:** reviews pi session transcripts scoped to one working directory
(`~/.pi/agent/sessions/--<path>--/*.jsonl`): enumerate → capped parallel
cheap-model per-session digests (go/no-go first; write bounded JSON) → one
strong-model synthesis producing a grounded, ranked proposal board for the
setup surfaces (model policy, agents config, instructions/skills, permission
rules, operator behavior). Markdown report; the operator picks it up and
applies only what they approve.

**Why this style:** dynamic fan-out over discovered files plus budget control
— script-only again. Deliberately sequenced AFTER the three main workflows:
it is uniquely ours (nothing ships like it), high-value dogfooding, and it
reuses every lesson the trio teaches. Strong model judges, cheap models
extract (two-stage cost discipline). Read-only children; humans gate changes.
