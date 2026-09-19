# Pi permission stack

> Status: in daily use since 2026-09-11 (prototype hardened 2026-09 review).
> Design driven by three needs: (1) **modes** (ask/brainstorm/plan/build/none)
> with different permissions per mode, (2) **semantic bash gating** — classify
> commands read-only / writing / dangerous instead of maintaining a glob
> whitelist, (3) **fine-grained file rules** — hard denies (`*.envrc-priv`,
> `~/.ssh/*`, credential stores) that no other layer can open.

## The layers

| Layer | Package | Question it answers | Mechanism |
|---|---|---|---|
| Modes | `@pedro_klein/pi-modes` (+ `pi-readonly-bash`) | *Which tools exist right now?* | Tool substitution: ask/brainstorm/plan lose `bash`, get `bash_readonly`; ask/brainstorm restrict `write`/`edit` to markdown-in-project + temp + `~/.pi` |
| Judgment | `@shinynito/pi-menshen` (`gatedTools: ["bash"]`) | *Is this command safe, given what it does?* | tree-sitter-bash AST → rule engine → read-only registry fast-path → Guardian reviewer model → manual prompt |
| Boundaries | `@gotgenes/pi-permission-system` | *May anything touch this path/tool AT ALL?* | Deterministic surfaces, most-restrictive-wins: `path` → `external_directory` → per-tool → `bash`; symlink-aware; MCP/skill gating; wrapper flooring (`bash -c`/`eval`/`sudo`/unparseable → ask) |

**Why this composes safely:** pi's `tool_call` handlers can only *block* — an
"allow" is silence, not a grant. Gates therefore compose as an **intersection**:
an action survives only if every engine declines to block it, and handler order
affects only which engine prompts first. Worst case of a layer misbehaving is
an extra prompt, never a silent pass.

## Files

- `pi-permission-system/config.json` — boundaries. Bash is `allow` except two
  deterministic backstop denies (`git push`, `git reset`) that hold even if
  menshen is disabled; trailing-` *` patterns are optional-suffix, so bare
  `git push` is covered too (verified in the matcher source). `shellTools`
  aliases `bash_readonly` to full bash parity on these gates. Hard denies for
  secrets (`*.env*`, `~/.ssh/*`) and for the permission stack's own state +
  `~/.pi/agent/auth.json`/`sessions` (anti self-modification; managed sessions
  edit these files through the repo path instead).
- `~/.pi/pi-menshen.json` → repo `home/.pi/pi-menshen.json` — judgment.
  Gated on `bash` only. Rules encode the non-read-only long tail; broad
  `docker`/`curl`/`pi` allows were narrowed to read-only subcommand prefixes
  (2026-09), everything else goes to the reviewer model. Strict JSON
  (`JSON.parse`) — reasoning lives in `_comment*` keys. `/perm allow|deny …`
  rewrites this file, so policy growth shows up as `git diff`.
- `pi-mode-ux.ts` — glue extension (no forks): `/mode` command, footer mode
  segment, `bash_readonly` re-exposure in build/none, and the `mode_status`
  tool. Rationale and verified package internals are documented in the file's
  own header comments — read those before touching it. One doc-relevant note:
  pi-modes' optional per-mode contract injection reads
  `~/.pi/agent/extensions/pi-modes/prompts/*.md`, which we deliberately do
  not provide; `instructions/modes.md` is the only mode text in the system
  prompt.
- This README — architecture + reasoning.

## Settings notes

- `settings.json` pins every package to its installed version (`npm:name@ver`
  — pinned specs are skipped by `pi update --extensions`). Unpin with
  `pi install npm:<pkg>` (no version) when you deliberately want updates.
- pi-modes is loaded in object form with `"prompts": []`: its bundled
  `/build` `/plan` … slash templates are OpenCode-flavored leftovers
  (they reference subagents pi does not have and an `ask_user` tool that
  does not exist here) and are therefore not registered. Switch modes with
  `/mode` or Ctrl+Alt+M only.
- Skills live in `~/.agents/skills/` (repo-tracked, the harness-neutral
  Agent Skills location pi auto-discovers) — no settings entry needed.
- `pi-menshen.json`'s `classifierModel` pins the reviewer to a cheap
  opencode-go model; keep the exact `opencode-go/<id>` format — an
  unresolvable string silently falls back to the session model.

## Daily use

- `/mode <ask|brainstorm|plan|build|none>` or Ctrl+Alt+M to cycle
  (ask→brainstorm→plan→build→none). New sessions default to **ask**
  (read-only). `/mode` additionally aborts any in-flight run and injects a
  "Continue working. Mode is now …" follow-up ~150 ms later — that's the
  pi-modes switch pipeline working, not a bug.
- Read-only commands (`cat`, `ls`, `git log`, …) run silently anywhere in the
  stack. Novel/mutating commands get a reviewer-model verdict; repeated
  friction is converted into narrow rules via `deny & remember` / session
  approvals.
- gotgenes prompts (`s` = approve pattern for session) still exist for
  wrapper/`bash -c`/unparseable commands — that floor is independent of the
  bash map and stays on purpose.
- `pi-modes` emits `pi-status:register` events for a status package we do
  not use; the footer mode segment works through `ctx.ui.setStatus` +
  `@henryqw/pi-footer` instead. The dead events are noise, not breakage.

## Deliberate behavior changes vs the old whitelist

1. `rm *.go` → no longer an allow rule; goes to the reviewer.
2. `npm install`, `ssh`, `brew`, `bash -c`, … → no longer silent denies; they
   reach the reviewer model (or gotgenes' wrapper floor).
3. `git commit` stays **ask** (last manual edit), `git push` / `git reset`
   stay **deny** — in BOTH menshen rules and gotgenes as a deterministic
   backstop. Bare `git push`/`git reset` included (verified: both matchers
   treat a bare command as a prefix-rule match).
4. `docker`, `curl`, `pi` broad allows removed 2026-09 — see the menshen
   `_comment_allow`. `docker run`-style escapes and nested `pi` sessions now
   hit the reviewer instead of passing silently.

## Known rough edges

- **Two configs, one truth:** `sensitivePaths` (menshen, routes to review) vs
  `path` denies (gotgenes, hard). Keep gotgenes as source of truth for denies.
- **Double prompts** are possible when both engines want to ask. Observed once
  in testing; if it gets annoying, tune the noisier half.
- **Maturity:** menshen and the pedro packages are young; gotgenes ships
  breaking changes regularly — read migration notes when you deliberately
  unpin and update.
- **Modes are tool-level, not policy-level:** you cannot express
  per-mode command policies (`kubectl get` free in plan, `kubectl apply` ask
  in build). The seam for that would be menshen project rules or a gotgenes
  authorizer link.
- **No OS sandbox / network control** — every layer above is a decision, not
  containment. `carderne/pi-sandbox` or `pi-landstrip` could be added without
  touching this design.
- The gotgenes self-protection denies match the `~/.pi/...` side of the
  homeshick symlinks; inside *this* dotfiles repo the realpaths sit in the
  workspace, so policy edits go through `home/.pi/...` (which AGENTS.md
  requires anyway). In any other project both routes are blocked.

## Activation / rollback

Activate: restart `pi` (package list changed — new packages/pins load at
startup, not via `/reload`). The gotgenes `config.json` and
`pi-menshen.json` are picked up on restart too (gotgenes itself
hot-reloads config changes mid-session).

Rollback: `git checkout home/.pi/agent/settings.json home/.pi/agent/extensions/pi-permission-system/config.json home/.pi/pi-menshen.json && zsh -ic 'homeshick link dotfiles' && pi remove npm:@shinynito/pi-menshen npm:@pedro_klein/pi-modes npm:@pedro_klein/pi-readonly-bash`
(the old bash whitelist returns via git history in config.json).
