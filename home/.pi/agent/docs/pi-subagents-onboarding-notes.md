# pi-subagents onboarding — session notes (2026-09-22, partial)

Companion to `pi-subagents-decision.md`. Records where the interactive onboarding
stopped and everything queued for a future session. Steps 1–5 done, 6–7 deferred.

## Done this session

- **Tour** — builtin agents, slash commands (`/subagents-doctor|fleet|guide|models|...`),
  packaged prompts (`/review-loop`, `/parallel-review`, ...), skills, FleetView.
- **Smoke test** — `scout` foreground run mapped the repo (worked; artifact + fan-out
  receipts explained).
- **Parallel review** — 6 `reviewer` children (two trios: staged diff + commit
  `a4e01fb`) via one `workflowScript` with `runs.all`. Found real drift (below).
- **Config built** (`settings.json → subagents.agentOverrides`, staged):
  - judgment (reviewer, oracle, evidence-auditor) + `doc-drift-sentinel` → `opencode-go/qwen3.8-max`
  - work (scout, worker, researcher, delegate) → `opencode-go/qwen3.7-plus`
  - 6 external-CLI builtins (`claude-code*`, `codex-exec*`, `cursor-agent*`) `disabled: true`
  - caps in `extensions/subagent/config.json`: `maxSubagentSpawnsPerRun: 24`, `globalConcurrencyLimit: 4`
- **Custom agent** `doc-drift-sentinel.md` (user-level, `agents/`) — verified live on
  `qwen3.8-max`; caps active (`1/24` receipt). First run: 6 findings incl. the
  AGENTS.md false-permission claim; second (verification) run confirmed fixes and
  caught 2 over-corrections in my own rewrite.
- **Drift fixes applied** to AGENTS.md, extensions/README.md, this decision doc,
  pi-permission-system config comments (values made non-decaying where asked).

## Queued / open threads

1. **Step 6 — first saved workflow script** (`home/.pi/agent/workflows/*.js` →
   `workflowScriptPath` + `args`, `action:"validate"` first). Candidates:
   ship-check chain (scout→sentinel→reviewer), drift-triage with `outputSchema`
   branching, parallel sweep, or the decision-doc feature-dev loop.
2. **Step 7 — field test** in a real project: write a handoff markdown the user
   copies to the target repo root and starts a pi session from there.
3. **Residual drift deliberately skipped** (sentinel round-2): README:172 still says
   `homeshick link` (→ `hslink`); "~125 allow rules" should be ~121 allow + 3 deny
   + 1 ask; decision-doc table could gain rows.
4. **Model-visibility mystery (unsolved)** — `/model` showed 9 opencode-go models vs
   30 in `models-store.json` ∩ 28 bundled; plan dashboard lists 18. Gating cause
   never pinned down; verify the pinned tiers actually launch in a fresh session
   (Ctrl+O a scout run and watch the model line).
5. **Add OpenRouter provider** later → then re-judge judgment-tier model.
6. **`a-validation` reviewer's report was lost** (artifact = one-line stub,
   "Saved output: unavailable"). Watch for recurrence → likely a
   retention/persist bug worth reporting upstream with run ids.
7. **Commit the staged config + agent + fixes** (deliberately uncommitted per AGENTS.md).

## Visibility fix (why questions felt context-free)

Child output lands in the *parent's* tool result, collapsed by default; expand with
**Ctrl+O**, inspect transcripts via **`/subagents-fleet`**, or read the quoted
artifact path. Convention adopted: the parent quotes children's verdicts/summaries
in its own reply *before* calling ask_user_question — candidate to make permanent in
`~/.pi/agent/instructions/subagents.md`.

Update (same session): the ask_user_question tool supports `options[].preview`
(markdown, single-select) — future sessions should embed the literal child findings
/ diffs into previews rather than paraphrasing them.

## Operator preferences learned

- Use `ask_user_question` (not prose menus) for every decision point.
- Show literal before→after diffs and get approval before editing docs/configs.
- Prefer non-decaying wording for dynamic values in docs.
