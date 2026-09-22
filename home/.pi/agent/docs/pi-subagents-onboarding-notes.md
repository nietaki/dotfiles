# pi-subagents onboarding — session notes (2026-09-22, complete)

Companion to `pi-subagents-decision.md`. Records where the interactive onboarding
reached and everything queued for a future session. Steps 1–5 done; steps 6–7
were later restructured into the revised plan at the end of this file (2026-09-23).
All work below is committed (through `5335fbb`).

## Done this session

- **Tour** — builtin agents, slash commands (`/subagents-doctor|fleet|guide|models|...`),
  packaged prompts (`/review-loop`, `/parallel-review`, ...), skills, FleetView.
- **Smoke test** — `scout` foreground run mapped the repo (worked; artifact + fan-out
  receipts explained).
- **Parallel review** — 6 `reviewer` children (two trios: staged diff + commit
  `a4e01fb`) via one `workflowScript` with `runs.all`. Found real drift (below).
- **Config built** (`settings.json → subagents.agentOverrides`):
  - judgment roles (reviewer, oracle, evidence-auditor) on the strong tier;
    work roles (scout, worker, researcher, delegate, doc-drift-sentinel) on the
    cheap tier. Exact models change — the non-decaying source of truth is
    `agentOverrides` in settings; live view via `/subagents-models`.
    (Snapshot 2026-09-23, commit `0c7e97b`: reviewer/oracle → claude-opus-5,
    evidence-auditor → gpt-5.6-sol, researcher → gemini-3.1-pro-preview,
    scout/doc-drift-sentinel → qwen3.7-plus, worker/delegate → qwen3.8-flash.)
  - 6 external-CLI builtins (`claude-code*`, `codex-exec*`, `cursor-agent*`) `disabled: true`
  - caps in `extensions/subagent/config.json`: `maxSubagentSpawnsPerRun: 24`, `globalConcurrencyLimit: 4`
- **Custom agent** `doc-drift-sentinel.md` (user-level, `agents/`) — verified live on
  `qwen3.8-max`; caps active (`1/24` receipt). First run: 6 findings incl. the
  AGENTS.md false-permission claim; second (verification) run confirmed fixes and
  caught 2 over-corrections in my own rewrite.
- **Drift fixes applied** to AGENTS.md, extensions/README.md, this decision doc,
  pi-permission-system config comments (values made non-decaying where asked).
- **`/subagent-outputs` extension command** (`extensions/subagent-outputs.ts`) —
  pure-TUI browser for child output artifacts: picker (newest first, optional
  filter arg) → scrollable markdown viewer. Scroll was broken in v1 because
  ui.custom() components mount inside pi's `editorContainer`, a plain Container
  invisible to the layout engine — a nested ScrollView never gets
  updateLayout(), so scrollBy() clamps to a no-op. Fix: manual windowing
  (render Markdown to lines, slice a `tui.terminal.rows`-height window, redraw
  via `tui.requestRender()`). Verified live working after the fix.

## Queued / open threads

1. ~~Step 6 — first saved workflow~~ — superseded 2026-09-23 by the revised plan
   below. The candidates listed here were quick associations, never examined;
   the brainstorm starts open-ended and must not anchor on them.
2. ~~Step 7 — field test~~ — folded into revised plan step (7), unchanged in
   substance, now sequenced after the workflows exist.
3. **Residual drift deliberately skipped** (sentinel round-2): README:172 still says
   `homeshick link` (→ `hslink`); "~125 allow rules" should be ~121 allow + 3 deny
   + 1 ask; decision-doc table could gain rows.
4. **Model-visibility mystery (downscoped 2026-09-23)** — `/model` showed 9
   opencode-go models vs 30 in `models-store.json` ∩ 28 bundled; plan dashboard
   lists 18. Since the re-pin (`0c7e97b`) the important half is not the *count*
   but whether pins take EFFECT: verify by Ctrl+O on a scout/worker run during
   the field test (revised plan step (7)). The `/model` picker-gating question
   only affects manual UX — bundle it with the artifact-stub bug (thread (6))
   for one upstream report if it still reproduces.
5. ~~Add OpenRouter provider → re-judge judgment tier~~ — **done 2026-09-23**:
   openrouter added; judgment tiers re-pinned in `0c7e97b`. The new pins are
   what the Config-built section snapshots and what modelScope now locks in.
6. **`a-validation` reviewer's report was lost** (artifact = one-line stub,
   "Saved output: unavailable"). Watch for recurrence → likely a
   retention/persist bug worth reporting upstream with run ids.
7. ~~Commit the staged config + agent + fixes~~ — **done 2026-09-22**: user
   committed everything (`36787f1` config/agents/docs, `5335fbb` the
   subagent-outputs scroll fix).

## Visibility fix (why questions felt context-free)

Child output lands in the *parent's* tool result, collapsed by default. Surfaces,
in order of preference:

1. **`/subagent-outputs`** (custom extension, committed) — the durable answer:
   browse any child's saved report after the fact, no model involvement.
2. **Ctrl+O** expands the live collapsed card during/after a run.
3. **`/subagents-fleet`** inspects running/recent children with transcripts.

Convention adopted: the parent quotes children's verdicts/summaries in its own
reply *before* calling ask_user_question — candidate to make permanent in
`~/.pi/agent/instructions/subagents.md`.

Update (same session): the ask_user_question tool supports `options[].preview`
(markdown, single-select) — future sessions should embed the literal child findings
/ diffs into previews rather than paraphrasing them.

## Operator preferences learned

- Use `ask_user_question` (not prose menus) for every decision point.
- Show literal before→after diffs and get approval before editing docs/configs.
- Prefer non-decaying wording for dynamic values in docs.

## Knowledge references (2026-09-23)

Source-verified deep notes (will decay on package update — re-verify before trusting):

- `~/obsidian/pi_knowledge/dotfiles/Pi-subagents workflow authoring.md` —
  surfaces × invocation matrix, state passing, fan-out, loops, args contract,
  23 numbered gotchas.
- `~/obsidian/pi_knowledge/dotfiles/Pi-subagents watchdog - purpose, gates and
  model policy.md` — triggers/routing, LSP pre-pass, launch rules vs modelScope.
  Watchdog stays OFF in this setup, deliberately.

Pinned gotchas: **watchdog config lives in Pi settings** (`subagents.watchdog` in
`settings.json`), NOT in `extensions/subagent/config.json` (spawn/concurrency caps
only). And any *invalid* key inside `subagents.watchdog` flips config resolution to
not-ok and silently drops launch rules with it.

## Revised onboarding plan (2026-09-23)

Supersedes threads (1) and (2).

1. These notes updated; stale model section fixed; threads (4) downscoped, (5) closed.
2. `subagents.modelScope` (enforce + strict, per-role allow lists) closes the
   per-run `model:` escape from the `agentOverrides` pins.
3. Create `home/.pi/agent/instructions/subagents.md`: script-authoring checklist
   (no nested async helpers; `runs.all` = ordered array; unique per-round keys;
   explicit child `async:true` receipts carry `ok:false` by design; set
   `timeoutMs` on async composites; `state` requires a mission; args header
   comment + early-throw guard; absolute `workflowScriptPath`), async etiquette
   (never sleep/poll — completion wakes natively; `bg_wait` only for
   non-notifying work), one-writer rule, quote children's verdicts before
   ask_user_question (embed literal findings in option `preview`s).
4. Prompt-template voice pass: classify the bodies of `continue/fix/explain_line/
   find_typos` as parent-voice vs child-voice; stamp `description:` with
   `[parent-run]` / `[child task]` — wrong-surface invocation is silent, so the
   file must carry its own intent.
5. Brainstorm session, OPEN-ENDED: decide which workflows we actually want,
   then assign one each to parent-recipe / chain-wrapper / script based on the
   style's strengths; small + educational scope.
6. Author the three chosen workflows (`action:"validate"` first for the script).
7. Field test in a real project: handoff markdown; absorbs the pin-effectiveness
   verification from thread (4); watch for the lost-artifact recurrence (6).
