# Decision: `pi-subagents` for subagents & workflow orchestration

- **Status:** adopted (installed 2026-09-22)
- **Package:** [`pi-subagents`](https://github.com/nicobailon/pi-subagents) — `pi install npm:pi-subagents`
- **Scope:** user-level (`~/.pi/agent/settings.json` → this repo)

## Problem

We want multi-step feature-development workflows in pi — a loop of
requirement gathering → TDD implementation → review — executed by focused
subagents with deterministic orchestration, good onboarding/debugging, and
usage examples.

pi core ships only a *example* `subagent` extension; real orchestration comes
from community packages (`pi install npm:…`, keyword `pi-package`). An npm
registry + GitHub sweep surfaced **443 candidate packages**; ~15 are
substantive.

## Shortlist & comparison

| Package | Stars | Approach | Why not chosen |
|---|---|---|---|
| **`pi-subagents`** (nicobailon) ✅ | 3721 | Isolated child sessions + sandboxed-JS `workflowScript` (`runs.run/all/lanes`), typed gates, budgets, worktree lanes, fleet inspector | — chosen |
| `@tintinweb/pi-subagents` | 1201 | Claude-Code-compatible `Agent`/`SubagentWorkflow`, `agent()/phase()/pipeline()` scripts | Solid and API-rich, but smaller community; nicobailon's docs, validation, budgets, supervisor channel, and observability are deeper. Many ecosystem tools target nicobailon's event contract. |
| `@quintinshaw/pi-dynamic-workflows` | 532 | Strongest determinism: `vm` sandbox (no clock/random/fs), journaled edit-and-resume, `loopUntilDry`/`verify`/`gate`/`checkpoint` quality patterns | Best "workflow-as-artifact" engine after osolmaz; but keyword auto-trigger, larger surface, and it replaces (rather than layers on) the delegation substrate. Runner-up if we later need replayable/auditable runs. |
| `@osolmaz/pi-workflows` | 303 | Declarative typed TS graphs (`defineWorkflow` nodes/edges), SQLite event-sourced durable runs, protected `humanDecision` gates | Deepest *structural* determinism (graph validated, gates the model cannot answer, crash-safe effects) — but no parallel agent fan-out (one node at a time), agent steps run in the origin session's context/model, one active run per session, steep authoring curve, fast-moving API. In-depth comparison in this doc's appendix. |
| `pi-gauntlet` (+`pi-cohort`) | 14 | Pre-built gated pipeline: brainstorm → plan → TDD-locked subagent implementation → verify → ship, machine-enforced phase gates | Exactly our target flow *out of the box* — but opinionated whole-workflow adoption, hard peer dep, tiny community. Re-evaluate if we want the methodology wholesale instead of assembling it. |
| `obra/superpowers` + `@teelicht/pi-superagents` | 289k / 61 | Methodology-as-skills (brainstorm→plan→TDD→review) with opt-in slash commands | Proven content, but flow adherence is model/skill-driven — weakest determinism fit for our criteria. Skills can be layered onto pi-subagents later if desired. |
| `@mjasnikovs/pi-task` | 128 | Fixed deterministic spec pipeline (refine→research→grill→compose→critique), crash-safe md files | Spec generator for local models, not an implementation/review loop engine. |
| `@gotgenes/pi-subagents` | 228 | In-process subagent *core* + typed API (tintinweb fork) | Library for building other extensions; not needed standalone. |

## Why `pi-subagents` won

1. **Ease of onboarding** — install and ask in plain English ("Use reviewer to
   review this diff"). Builtin roles (`scout`, `worker`, `reviewer`, `oracle`,
   `researcher`, `delegate`) with recommended model tiering; custom roles are
   markdown + YAML frontmatter at `~/.pi/agent/agents/`. No config required.
2. **Ease of debugging** — FleetView under the editor; `/subagents-fleet` live
   inspector (read child transcripts, **steer or stop running children**);
   `/subagents-doctor`; `/subagents-guide <topic>`; machine-readable run
   artifacts and workflow receipts on disk.
3. **Deterministic-enough workflow definitions** — `workflowScript` /
   `workflowScriptPath` run plain-JS orchestration in a sandbox (no fs/shell/
   host globals; frozen JSON `args`); `action:"validate"` statically checks
   syntax + literal child keys *before* any child launches; per-workflow
   `timeoutMs`, `toolBudget`, `usageBudget`; **typed gates** run a command
   after a child finishes and feed its JSON stdout into JS branching;
   `runs.lanes` for parallel sequential chains with per-lane failure blocking.
4. **Usage examples** — ~320KB of docs (`workflows.md`, `agents.md`,
   `tool-reference.md`, `observability.md`, …), packaged prompt shortcuts
   (`/review-loop`, `/parallel-review`, `/gather-context-and-clarify`,
   `/council`), and `examples/typed-gate/workflow.js`.
5. **Popularity / ecosystem** — most-installed pi subagent package by a wide
   margin (3.7k★ vs 1.2k next); interop adapters from other packages key off
   its event contract, and the repo is very active (daily commits).
6. **Fit for the feature loop** — the documented recommended loop
   `clarify → scout → worker → fresh reviewers → worker` *is* our use case;
   red/green discipline is enforced by the deterministic test gate, review
   rounds are capped, and one writer touches the tree at a time (worktree
   isolation available per child when we want parallel writers).

## What was created in this repo

| Repo path | Links to | Purpose |
|---|---|---|
| `home/.pi/agent/settings.json` | `~/.pi/agent/settings.json` | added `"npm:pi-subagents"` to `packages`; later also `subagents.agentOverrides` (role→model tiers, 6 disabled external-CLI builtins) and `subagents.modelScope` (enforce+strict guard: keeps launched models inside the pinned tiers, rejects per-run `model:` escapes) |
| `home/.pi/agent/docs/pi-subagents-decision.md` | `~/.pi/agent/docs/pi-subagents-decision.md` | this document |
| `home/.pi/agent/docs/pi-subagents-onboarding-notes.md` | `~/.pi/agent/docs/pi-subagents-onboarding-notes.md` | onboarding session notes + queued steps (workflows, field test) |
| `home/.pi/agent/agents/doc-drift-sentinel.md` | `~/.pi/agent/agents/doc-drift-sentinel.md` | first custom role (read-only doc-drift auditor) |
| `home/.pi/agent/extensions/subagent/config.json` | `~/.pi/agent/extensions/subagent/config.json` | behavioral caps (`maxSubagentSpawnsPerRun: 24`, `globalConcurrencyLimit: 4`) |
| `home/.pi/agent/extensions/subagent-outputs.ts` | `~/.pi/agent/extensions/subagent-outputs.ts` | `/subagent-outputs` command — TUI browser (picker + scrollable markdown viewer) for child output artifacts |

Not added yet: custom workflow scripts and launcher prompts.
Added 2026-09-22: the `doc-drift-sentinel` custom role (`agents/`), role→model
tiers plus six disabled external-CLI builtins
(`settings.json → subagents.agentOverrides`), and spawn/concurrency caps
(`extensions/subagent/config.json`). Same day, post-review fixes: the
`/subagent-outputs` viewer command (`extensions/subagent-outputs.ts`) —
manual-windowed markdown scroller, because ui.custom() mounts inside a
layout-blind container (see onboarding notes for the full story).

Where future pieces go:

- custom roles → `home/.pi/agent/agents/**/*.md` (→ `~/.pi/agent/agents/`)
- reusable scripts → e.g. `home/.pi/agent/workflows/*.js`, launched via
  `subagent({ workflowScriptPath: "<abs path>", args: {...}, async: true })`
- option overrides → `~/.pi/agent/extensions/subagent/config.json` (see
  [configuration.md](https://github.com/nicobailon/pi-subagents/blob/main/docs/configuration.md))

## Install / link procedure used

```bash
pi install npm:pi-subagents   # edits ~/.pi/agent/settings.json through the homeshick symlink (verified intact)
git add home/.pi/agent/docs/pi-subagents-decision.md home/.pi/agent/settings.json
hslink                        # = homeshick link dotfiles (see skills/homeshick)
```

Verify in a fresh pi session: `/subagents-doctor`, then "Show me the available
subagents." Day-to-day use needs no further setup — e.g. "Use reviewer to
review this diff", `/review-loop`, `/parallel-review`.

## Sample workflow (reference — not yet added to this repo)

Sketch of the requirement-gathering → TDD → review-loop orchestration script
we would add later as `workflows/feature-dev.js`:

```js
const spec = await runs.run("spec", { agent: "worker", task: …gather requirements from args.feature… });
const impl = await runs.run("tdd",  { agent: "worker", task: "…test-first…",
                                      gate: { command: "<sh wrapper running args.testCommand → {verdict:green|red}>" } });
while (round < maxRounds && verdict === "BLOCK") {
  const reviews = await runs.all([correctness, tests, simplicity]);   // fresh-context reviewers in parallel
  … synthesize → runs.run(fix-N, gated by the same test command) …
}
return { rounds, merged, spec };
```

## Appendix: the two serious alternatives, in one paragraph each

- **`@quintinshaw/pi-dynamic-workflows`**: same delegation substrate but the
  orchestration runs in a stricter `vm` (determinism enables **journal
  replay/edit-and-resume**), ships quality-loop helpers (`loopUntilDry`,
  `verify`, `judgePanel`, `checkpoint`) and per-agent model tiers/worktrees.
  Chose it over if runs must survive interruption token-cheaply and be
  re-executed from journal.
- **`@osolmaz/pi-workflows`**: a durable state machine (SQLite event log,
  effect receipts, protected human-decision gates, `controlLoop()` bounded
  branching, typed workflow composition with named exits). Highest structural
  determinism and best crash semantics; least parallel, highest onboarding
  cost (TS graph authoring, engine/server vocabulary, one interactive run per
  session). Good long-term fit for *auditable org processes*, heavier than we
  need for personal feature loops.

## References

- https://github.com/nicobailon/pi-subagents (+ `docs/workflows.md`, `docs/agents.md`, `examples/typed-gate/`)
- https://github.com/tintinweb/pi-subagents
- https://github.com/QuintinShaw/pi-dynamic-workflows
- https://github.com/osolmaz/pi-workflows (`docs/DESIGN_PHILOSOPHY.md`, `docs/CONTROL_LOOPS.md`)
- https://github.com/jjuraszek/pi-gauntlet · https://github.com/obra/superpowers
- pi package docs: `<pi-install>/docs/packages.md`
