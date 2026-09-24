# Pi permissions

> Status: single-layer since 2026-09-21 (was a three-layer stack since 2026-09-11).
> One question this answers: *may anything touch this path, tool, or command at
> all?* — deterministically, with no model in the loop.

## The layer

`@gotgenes/pi-permission-system` is the whole gate. pi's `tool_call` handlers
can only **block** — an "allow" is silence, not a grant — so the surfaces in
`config.json` compose as an **intersection**: an action survives only if every
surface declines to block it, most-restrictive-wins, and handler order affects
only which rule prompts first.

Matching is symlink-aware, so a symlink alias cannot evade a `path` deny.

Surfaces, in the order they are consulted:

| Surface | Question |
|---|---|
| `path` / `path_read` / `path_write` | may this file be read / written at all? (cross-cutting: read/write/edit, MCP + extension tools, and path tokens inside bash commands) |
| `external_directory` / `external_directory_read` | may anything reach outside the working directory? |
| `mcp`, `skill`, per-tool | may this server / skill / tool be used? |
| `bash` | is this exact command denied? |

**How to read a deny vs. a read-only rule.** Bare `path` is sugar: its entries
expand into `path_read` *and* `path_write`, placed FIRST. A later explicit
`path_read` entry therefore wins for reads while the write denial stands — that
is how the entire `~/.pi` tree is inspectable but immutable. Adding a read-only
surface = `path` deny + `path_read` allow (and drop it from
`external_directory`, add it to `external_directory_read`).

## Files

- `pi-permission-system/config.json` — the policy.
  - **`authorizerChain: ["session-yolo"]`** (added 2026-09-24) is the opt-in
    activation for the `session-yolo.ts` ask switch (see *Session-scoped ask
    switch* below). Naming a link is the only thing that gives it authority; a
    link that is registered but not named here decides nothing, and a named link
    that never registered is skipped fail-safe (asks still prompt).
  - **Hard denies** for secrets: `*.env`, `*.env.*` (with `*.env.example`
    allowed back), `*.envrc-priv`, `~/.ssh/*`.
  - **`~/.pi` is read-only, wholesale** (flipped from a broad `allow` + four
    named denies, 2026-09-21). Everything under it is loaded on every future
    startup, so a write there is self-modification with a delay:
    `extensions/*.ts` is arbitrary code that runs at next start in *every*
    project; `instructions/*.md` is injected into every future system prompt;
    `mcp.json` is commands the adapter spawns; `models.json` defines providers
    including `baseUrl`, so it can redirect API traffic; `npm/` is what gets
    installed. The old shape allowed all of that and carved out only
    `auth.json`, `sessions/*`, `settings.json` and this config file.
  - **`path_read` allows `~/.pi/*` back for reads** — config, extension source,
    prompts, and the multi-MB history of past transcripts is auditable. Writes stay
    denied by `path` *and* by the `external_directory` boundary, so no single
    layer's relaxation reopens the tree. `auth.json` is the one path denied in
    **both** directions (provider API keys); it must stay listed after the
    broad read allow, since last match wins. Now that transcripts are readable,
    a readable `auth.json` would make "quote the secret into the next request"
    one step instead of several.
  - **CWD boundary**: `external_directory` is `deny` by default; writable
    carve-outs are `~/.agents/skills`, `~/.local/share/mise`, `~/.betterwright`,
    the bun-installed betterwright CLI, and the temp dirs (`/tmp`,
    `/private/tmp`, `${TMPDIR}`). `external_directory_read` adds read-only reach
    for `~/.pi`, `~/repos/**` and the Go module cache (`~/go/pkg/mod/**`);
    writes there stay denied.
  - **`bash`**: `"*": "allow"` plus `"git push *"` and `"git reset *"` denies.
    Trailing-` *` is optional-suffix in the matcher, so bare `git push` is
    covered (verified in the source).
  - `~/.betterwright` was opened as a deliberate whole-tree decision
    (2026-09): the `browser` tool already attaches its own screenshots, so
    gating the tree blocked only path-based debugging of artifacts and profile
    locks. **Consequence:** `vault.enc`, `master-key.json`, and browser
    profiles are reachable by path-aware tools. The "never reveal stored
    secrets" rule in the browser skill is behavioural for this tree, not
    policy-enforced.
- `footer-provider.ts` — publishes the active model's provider into the
  `@henryqw/pi-footer` status line via `ctx.ui.setStatus`. Purely cosmetic; it
  survived the mode-stack removal because it was never part of it.
- `instructions.ts` — appends `~/.pi/agent/instructions/*.md` to the system
  prompt as one `# Pi Instructions` block, built once at extension load in
  filename order so the bytes are stable across turns (prompt-cache friendly).
  Edits to instruction files need a restart or `/reload`.
- `subagent-outputs.ts` — `/subagent-outputs [filter]`: TUI browser over
  pi-subagents child output artifacts (picker, then a manual-windowed
  markdown scroller: a nested ScrollView never works inside pi's
  `editorContainer` — it's invisible to the layout engine, so `updateLayout()`
  is never called and `scrollBy()` clamps to a no-op; hence render-to-lines,
  slice a `tui.terminal.rows`-height window, redraw via `tui.requestRender()`).
  Reads files only — never invokes the model.
- `session-yolo.ts` — a **per-session operator switch for `ask` decisions**
  (prompt / allow / deny), registered as a `pi-permission-system` authorizer
  link. `/yolo [on|off|allow|deny|toggle|status]` or **Ctrl+Alt+Y** change it; a
  read-only `session_yolo_status` tool lets the *agent report* the mode (to
  propose enabling it before a long autonomous run) but never change it; the
  footer shows the current mode (`ask:prompt` / `ask:auto-allow` /
  `ask:auto-deny`). Full writeup in *Session-scoped ask switch* below.
- This README — the reasoning.

## Session-scoped ask switch (`session-yolo.ts`)

The package's built-in `yoloMode` auto-approves every ask, but it is a
*persisted* config knob — the `/permission-system` modal / `save()` writes
`~/.pi/.../config.json` and it is re-read from disk — so it is neither ephemeral
nor reliably session-scoped. `session-yolo.ts` adds an in-memory, per-session
equivalent that **only bypasses the interactive prompt, never the rule engine**.

**Why it can't touch the rules.** `policy/permission-gate.ts::applyPermissionGate`
escalates to the live-authority chain *only when the deterministic rule resolves
to `ask`*. A rule `allow` is granted and a rule `deny` blocks with the chain never
consulted. So registering this link cannot weaken any `allow`/`deny` in
`config.json`: the `~/.pi` write-deny, the `.env`/`~/.ssh` denies, and the
`git push`/`git reset` denies all still hold, ask or not. The chain owner also
wraps the link in a **bounded-delegation envelope**
(`authority/delegation-envelope.ts`): a link's `allow` on the `path` /
`external_directory` surface families is downgraded to `defer`. **Consequence:**
with the current policy (which has zero `ask` rules), the only asks you actually
hit are the *synthetic bash floors* — `sudo`, `env`, `xargs`, `find -exec`,
`bash -c`, `eval`, and unparseable commands — and those gate on the `bash`
surface, which is **not** excluded, so `allow` mode covers exactly the
autonomous-run pain. A hypothetical future `ask` on a path surface would still
prompt in `allow` mode; that is a package guardrail we do not defeat.

**Modes** (in-memory; reset to `prompt` whenever the session id changes):
`prompt` (defer → normal dialog, default) · `allow` (approve permitted asks) ·
`deny` (reject asks with a teaching reason — a strict/headless posture).

**Service access without importing the package.** The extension reaches the
session's `PermissionsService` through the documented process-global map keyed by
`Symbol.for("@gotgenes/pi-permission-system:session-services")` — the same slot
`getPermissionsService(sessionId)` reads. It does *not* `import` the package:
`@gotgenes/pi-permission-system` installs under `~/.pi/agent/npm/node_modules`,
which is **off Node's upward resolution path from `~/.pi/agent/extensions/`**
(pi-tui / pi-coding-agent / typebox only resolve there because Pi's jiti loader
*aliases* them; the permission package is not in that alias map). Registration is
on `permissions:ready` (fires ≥ once per session and repeats; the handler is
idempotent) with a `before_agent_start` retry. Subagent asks are adjudicated by
the **serving parent's** mode, so enable it in the interactive session that
answers prompts.

**Caveat — config.json symlink integrity.** `authorizerChain` lives in
`config.json`, which must be the homeshick **symlink** into this repo for edits
here to reach a running agent. The package's own `save()` path does
`rename(tmp, configPath)`, which **detaches a symlink** and replaces it with a
regular file — so a `/permission-system` save silently un-tracks this file. Verify
with `ls -l ~/.pi/agent/extensions/pi-permission-system/config.json` (should be a
`->` symlink); relink with `hslink` (manual `~/.pi` surgery is blocked by this very
policy). This was observed broken on 2026-09-24.

**Activate:** `git add home/.pi/agent/extensions/session-yolo.ts`, `hslink` to
link it, then `/reload` (loads the new `.ts`). The `authorizerChain` config edit is
picked up on the next config refresh once the symlink points back at the repo.

- `settings.json` optionally pins packages to their installed version
  (`npm:name@ver`) — pinned specs are skipped by `pi update --extensions`.
  Unpin with `pi install npm:<pkg>` (no version) when you deliberately want an
  update. Currently floating on purpose: `rpiv-ask-user-question`,
  `betterwright`, `pi-subagents`, `@juicesharp/rpiv-todo`.
- `@juicesharp/rpiv-todo` — "A todo list for the model, rendered as a live
  overlay that survives /reload and conversation compaction." Added 2026-09-23
  for model-side task tracking with persistent visibility.
- Skills live in `~/.agents/skills/` (repo-tracked, the harness-neutral Agent
  Skills location pi auto-discovers) — no settings entry needed.

## Daily use

- Read-only commands anywhere inside the boundary run silently.
- A blocked call prompts through gotgenes (`s` = approve the pattern for the
  session), or fails silently when a `deny` rule matches. Denies on
  `git push` / `git reset` are silent by design.
- **Session-scoped ask switch** (`session-yolo.ts`): `/yolo` (or Ctrl+Alt+Y)
  flips how `ask` decisions are handled for this session only — `prompt` is
  normal, `allow` auto-approves permitted asks, `deny` auto-rejects them. It
  never changes the rule engine; hard `deny`s still block silently even in
  `allow` mode. See *Session-scoped ask switch* below.
- Commands that reach outside the working tree, or touch a denied path token
  however they spell it (`cat ~/.ssh/id_rsa`, `> foo.env`), are blocked.
- **The agent cannot change its own pi configuration.** Anything under `~/.pi`
  is read-only to tool calls: to add an extension or tweak a policy, edit (or
  ask to edit) the repo copy under `home/.pi/...` and relink. Direct state
  surgery in `~/.pi` — clearing a stale cache, pruning `npm/` — is a manual
  step, by design.

## What we gave up (2026-09-21)

Removed: `@pedro_klein/pi-modes` + `@pedro_klein/pi-readonly-bash` (mode tool
substitution: ask/brainstorm/plan lost `bash`, gained a whitelisted
`bash_readonly`; ask/brainstorm restricted `write`/`edit` to markdown + temp +
`~/.pi`) and `@shinynito/pi-menshen` (tree-sitter bash AST → read-only registry
→ reviewer model). They were partially working — menshen shipped
`"enabled": false` — and the modes were enforced by filtering tool *names*, which
is a speed bump rather than a boundary: an allowed command can still write files.

What is gone with them:

1. **No semantic judgment of commands.** `bash` is allow-all except two denies.
   Novel or mutating commands are no longer reviewed. `rm -rf` inside the
   workspace passes silently — the only remaining protection there is your own
   care plus `git`.
2. **No read-only modes.** Nothing stops a write or a build in a session that
   was meant to be read-only. The `/mode` command, the `Ctrl+Alt+M` cycle, the
   footer mode segment, the `mode_status` tool, and `instructions/modes.md`
   (the mode text in the system prompt) are all deleted.
3. **`git commit` is no longer gated.** It was `ask` in menshen's rules; gotgenes
   does not mention it. The "don't commit unless asked" rule now lives only in
   `instructions/git.md`.
4. **Sensitive-path routing is gone** — menshen's `sensitivePaths` sent a
   read-only command touching e.g. `package-lock.json` to review. Reads are
   plainly allowed now; only the hard denies remain.

Deliberate: a deterministic layer you can read in one screen over a probabilistic
one you cannot predict. If the permissiveness ever bites, the old per-command
whitelist is this file at commit `5643577` (~125 allow rules under
`"bash": {"*": "deny"}`).

## Known rough edges

- **Path-shaped, not intent-shaped.** Every guard answers *where* a call goes,
  not *what* it does. `curl -o script.sh && sh script.sh` is one allow and one
  allow; the file it then writes is subject to the path rules, but nothing
  reviews the command pair.
- **The gate sees tool calls, not syscalls.** It inspects the paths a call
  *names*, so a child process writing wherever it likes is invisible: `npm`,
  `pi install`, and `homeshick link` all write into `~/.pi` and are not blocked
  by the read-only rule. That is load-bearing, not a bug — the repo-first
  workflow depends on `homeshick link` working — but it means the rule stops
  the agent *editing its own configuration*, not the agent *causing* an edit
  (any command with a `--prefix`/`--force` can be coerced into that). Genuine
  containment needs `carderne/pi-sandbox` or `pi-landstrip`.
- **Maturity:** gotgenes ships breaking changes regularly — read migration
  notes when you deliberately unpin and update.
- **No OS sandbox / network control** — every rule above is a decision, not
  containment. `carderne/pi-sandbox` or `pi-landstrip` would add the missing
  axis without touching this design.
- The read-only tree matches the `~/.pi/...` side of the homeshick symlinks.
  Inside *this* dotfiles repo the realpaths sit in the workspace, so policy
  edits go through `home/.pi/...` — which `AGENTS.md` requires anyway (verified:
  with the `~/.pi` write deny in place, editing `config.json` via its repo path
  still works, because the deny resolves the symlink's own path, not its
  target). In any other project both routes are blocked.

## Activation / rollback

Activate: restart `pi`. The package list loads at startup, not via `/reload`;
gotgenes hot-reloads `config.json` mid-session.

Rollback: `git revert` the change, or `git checkout <pre-change-commit> -- home/.pi`
then `hslink` and `pi install` the three packages at
their old pins (`npm:@shinynito/pi-menshen@2.1.0`,
`npm:@pedro_klein/pi-modes@0.2.0`, `npm:@pedro_klein/pi-readonly-bash@0.2.0`).
`pi-menshen.json` returns via `git checkout <pre-change-commit> -- home/.pi/pi-menshen.json`;
`homeshick link` will relink it.
