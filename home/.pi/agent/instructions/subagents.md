# Subagent orchestration Guidelines

Conventions for working with `pi-subagents` in this setup. Deeper, source-verified
notes live in `~/obsidian/pi_knowledge/dotfiles/` (they decay on package updates —
re-verify before trusting specifics).

## Model policy
- Role→model tiers are set in `settings.json → subagents.agentOverrides`; the
  effective model must stay inside `subagents.modelScope` (enforce + strict).
  An out-of-scope per-run `model:` override aborts the run before any tokens
  are spent — that is the design, not a bug to work around.
- To run a role on a different model deliberately, edit `agentOverrides` +
  `modelScope` and reload pi. Check live state with `/subagents-models`.
- The watchdog is deliberately OFF. Its config belongs in Pi settings
  (`subagents.watchdog`), never in `extensions/subagent/config.json`; an invalid
  key there also silently disables launch rules.

## Orchestration
- One writer to the tree at a time even in async runs; declare sole-writer in
  the worker's task text. Reviewers/validators: `context: "fresh"`, pass them
  the explicit files/diff/plan paths.
- Canonical big-diff shape: planning fan-out → one worker → validation fan-out.
- Children do not manage loops — the parent orchestrates review rounds, capped
  (~3) and user-visible. Never sleep/poll a running child: async completion
  wakes this session natively; `bg_wait` only for non-notifying work.
- A child launched with explicit `async: true` returns a receipt with
  `ok: false` / `state: "running"` by design — `ok` confirms completion, not
  dispatch. Consume results before declaring work done.

## Script authoring (workflows/*.js)
- Statement body, explicit `return`, top-level await; NO nested async
  functions/arrows. `runs.all` resolves to an ordered ARRAY, not a keyed map.
- Keys are one-shot: reusing a key returns the cached receipt — vary per round
  (`impl-r2-a1`). `state` only exists with a mission (schedule-fired runs get
  none by default). Set `timeoutMs` on async composites — they have no default.
- `args` has no schema: keep a `// @args` header contract + early-throw guard;
  values persist as evidence — never secrets. Relative `workflowScriptPath`
  resolves against request cwd — prefer absolute.
- Run `action: "validate"` before first real execution.
- Launch every child that has an `outputSchema` with `acceptance: false`. If you leave it out, pi-subagents guesses an acceptance level and adds an "Acceptance Contract" asking for an `acceptanceReport`, which `structured_output` has no field for, so the child fails validation. Details: gotcha #30 in `Pi-subagents workflow authoring.md`.
- `toolBudget.block` only activates AFTER the hard budget is exceeded — it guards against overruns, not a standing deny-list. To keep a child read-only or no-edit for its whole run, use a custom agent whose `tools:` allowlist leaves out edit/write (ours: `verifier`, see gotcha #25).
- Prefer returned `output`/`structuredOutput` over shared files; `defaultReads`
  magic files (context.md/plan.md) are a chain-era vestige — solo runs do not
  auto-connect.

## Visibility & reporting
- Quote children's verdicts/summaries in the parent reply BEFORE calling
  ask_user_question; embed literal findings/diffs in option `preview`s.
- After the fact: `/subagent-outputs` (saved reports), `/subagents-fleet` (transcripts; **J/K (Shift+j/k) or PgUp/PgDn scroll the right-hand detail pane**; arrows and j/k only change the selected agent, and the status bar doesn't show the scroll keys), Ctrl+O (live card).

## Prompt templates (dual surface — decide intent when authoring)
- `/name` expands the body into the PARENT's prompt; `/prompt-workflow`
  compiles it into a CHILD's task. Wrong-surface use is silent.
- Parent-voice bodies (multi-step, coordinator prose, "ask me") and anything
  relying on `@file` mention expansion → parent-run only. Self-contained
  single-role tasks → safe for `/prompt-workflow` and chain steps.
- Encode intent in `description:` with `[parent-run]` / `[child task]` — the
  file format records nothing else.
- Chain wrappers: per-step config goes in step frontmatter, never
  `--subagent`/`--fork`/`--fresh` flags (those apply to every step).
