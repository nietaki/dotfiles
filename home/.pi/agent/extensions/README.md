# Pi permission stack — 3-layer prototype

> Status: **prototype** (2026-09-11). Goal: replace the deny-by-default
> bash whitelist with semantic classification, keep fine-grained file
> denies, and add workflow modes. Design driven by three needs:
>
> 1. **Modes** (plan/build/…) with different permissions per mode
> 2. **Semantic bash gating** — classify read-only / writing / dangerous
>    instead of maintaining a ~150-line glob whitelist
> 3. **Fine-grained file rules** — hard denies like `*.envrc-priv`, `~/.ssh/*`

## The layers

| Layer | Package | Question it answers | Mechanism |
|---|---|---|---|
| Modes | `@pedro_klein/pi-modes` (+ `pi-readonly-bash`) | *Which tools exist right now?* | Tool substitution: Ask/Brainstorm/Plan lose `bash`, get `bash_readonly`; Ask/Brainstorm restrict `write`/`edit` to markdown-in-project + temp + `~/.pi` |
| Judgment | `@shinynito/pi-menshen` (`gatedTools: ["bash"]`) | *Is this command safe, given what it does?* | tree-sitter-bash AST → rule engine → ~200-command read-only registry fast-path → Guardian reviewer model → manual prompt |
| Boundaries | `@gotgenes/pi-permission-system` | *May anything touch this path/tool AT ALL?* | Deterministic surfaces, most-restrictive-wins: `path` → `external_directory` → per-tool → `bash`; symlink-aware; MCP/skill gating; wrapper flooring (`bash -c`/`eval`/`sudo`/unparseable → ask) |

**Why this composes safely:** pi's `tool_call` handlers can only *block* —
an "allow" is silence, not a grant. Multiple gate extensions therefore
compose as an **intersection**: an action survives only if every engine
declines to block it. No layer can open a hole in another. Worst case of
a layer misbehaving is an extra prompt (never a silent pass), and handler
order affects only which engine prompts first.

## Files

- `pi-permission-system/config.json` — boundaries (need 3). The bash
  whitelist is collapsed to `{"*": "allow"}` **except two deterministic
  backstop denies** (`git push`/`git reset`) that hold even if menshen is
  disabled. `shellTools` aliases `bash_readonly` so path/external gates
  fire on its commands too (without it, `bash_readonly cat ~/.ssh/id_rsa`
  would bypass the path denies).
- `~/.pi/pi-menshen.json` → repo `home/.pi/pi-menshen.json` — judgment
  (need 2). `gatedTools: ["bash"]` only; rules encode the old policy for
  the non-read-only long tail; `sensitivePaths` mirrors hard-denied names
  so even read-only commands touching them go to review. **Strict JSON**
  (`JSON.parse`) — reasoning in `_comment*` keys. Menshen rewrites this
  file when you use `/perm allow|deny …` or deny-&-remember — new rules
  land here and become part of dotfiles, which is a feature (`git diff`
  reviews the growth of your own policy).
- This README — architecture + reasoning.

## Daily use

- `/build` `/plan` `/ask` `/brainstorm` `/none`, or `Ctrl+Alt+M` to cycle.
  **New sessions default to `ask`** (read-only) — press `Ctrl+Alt+M` or
  `/build` to get a writable session.
- Read-only commands (`cat`, `ls`, `git log`, …) run silently anywhere in
  the stack now — that was the whole point of deleting the whitelist.
- Novel/mutating commands get a reviewer-model verdict (session model;
  set a cheap `classifierModel` in `pi-menshen.json` to save main-model
  context). The reviewer denial feedback + `deny & remember` let rules
  accrue from *actual friction* instead of anticipatory globs.
- `gotgenes` prompts (`s` = approve pattern for session) still exist for
  wrapper/`bash -c`/unparseable commands — that floor is independent of
  the bash map and stays on purpose.

## Deliberate behavior changes vs the old whitelist

1. `rm *.go` → no longer an allow rule; goes to the reviewer.
2. `npm install`, `ssh`, `brew`, `bash -c`, … → no longer silent denies;
   they reach the reviewer model (or gotgenes' wrapper floor).
3. `git commit` stays **ask** (your last manual edit), `git push` /
   `git reset` stay **deny** — in BOTH menshen rules and gotgenes as a
   deterministic backstop.
4. `docker *`/`curl *` kept as allow for parity — flag for tightening
   once the reviewer proves the noise level acceptable.

## Known rough edges (prototype caveats)

- **Two configs, one truth:** `sensitivePaths` (menshen, routes to
  review) vs `path` denies (gotgenes, hard). Keep gotgenes as source of
  truth for *denies*; menshen's list is only "review these names too".
- **Double prompts** are possible when both engines want to ask (e.g.
  `bash -c` inside a complex pipeline). gotgenes' `permissions:ui_prompt`
  bus and menshen's relay are independent today; if annoying, file
  against whichever owns the noisier half.
- **Maturity:** menshen is 1★ (Aug 2026, single author, WASM grammar);
  pedro packages ~1★. gotgenes ships breaking changes regularly — read
  its migration notes on version bumps. `pi update --extensions` can
  change any of these behaviors underneath you; pin versions if a setup
  works.
- **Modes are tool-level, not policy-level:** plan mode = no mutating
  tools; you cannot (yet) express "plan mode may run `kubectl get` but
  build mode runs `kubectl apply` with ask" per mode. If that becomes a
  real need, the seam is menshen's project rules or a thin authorizer
  chain link in gotgenes.
- **No OS sandbox / network control** in this prototype — every layer
  above is a decision, not containment. `carderne/pi-sandbox` or
  `pi-landstrip` can be added later without touching this design.

## Test results (verified live, 2026-09-11)

Run as agent probes in a real session; each denial/block attributed to its layer:

| Probe | Layer proven | Result |
|---|---|---|
| ask-mode: `bash` absent, only `bash_readonly` | pi-modes tool gating | ✅ new sessions default to ask |
| `seq 3` (never in old whitelist) via `bash_readonly` | readonly policy | ✅ silent pass |
| `cat ~/.ssh/config` via `bash_readonly` | **shellTools alias** → gotgenes `path_read` deny | ✅ `(rule '~/.ssh/*')` |
| `ls ~/.pi` via `bash_readonly` | gotgenes `external_directory` | ✅ denied, `~` resolved first |
| `git push --dry-run` via `bash_readonly` | gotgenes bash-backstop through alias | ✅ `"invoked as 'bash_readonly'"` |
| `touch /tmp/x` in ask mode | mode-layer mutation block | ✅ `Readonly bash blocked` |
| build mode (Ctrl+Alt+M ×3, ask→…→build): `seq 3` | menshen registry / long tail | ✅ silent |
| `mkdir -p /tmp/… && touch … && ls` | menshen segment rules | ✅ silent |
| `cat ~/.ssh/config` under full `bash` | intersection (menshen allow ≠ grant) | ✅ gotgenes denies |
| `kubectl version --client` | **menshen `ask` rule** | ✅ manual dialog appeared (only menshen can ask — gotgenes has no ask rules now) |
| `python3 -c 'print(1)'` | menshen Guardian reviewer | ✅ auto-verdict, no human prompt |
| `env whoami` | gotgenes wrapper floor | ✅ dialog `(rule '<indirection-bash-wrapper>')`, denial reason echoed back |

Unverified: menshen `deny & remember` persistence; `git commit` ask rule (same code path as kubectl's); only ONE prompt appeared for `env whoami` (gotgenes asked, menshen seemingly deferred — the feared double-prompt didn't materialize here); pi-status footer mode indicator (package not installed).

Caveat found: **modes are invisible in the TUI by default** — pi-modes publishes its status segment via `pi-status:register`, which requires `@pedro_klein/pi-status`; without it the only feedback is a transient notification on *change* (and `Ctrl+Alt+M` only notifies when the mode actually differs — cycling ask→brainstorm→plan produces near-identical toolsets). Consider installing pi-status.

## Activation / rollback

Activate: restart `pi` (package list in `settings.json` changed — new
packages load at startup, not via `/reload`).

Test after restart:
- `cat` some file → silent ✓ (registry)
- `cat ~/.ssh/config` → denied by gotgenes `path` ✓
- `touch /tmp/x && rm /tmp/x` → allow rules ✓; `echo hi > ~/x` → external_directory deny ✓
- `ls ~/notes` → denied: `ls` is read-only-classified by menshen but gotgenes external gate blocks ✓ (the intersection in action)
- `/plan` then ask for a file write → tool-level block ✓; `/build` → works
- `git push origin main` → denied by BOTH layers ✓

Rollback: `git checkout home/.pi/agent/settings.json home/.pi/agent/extensions/pi-permission-system/config.json && rm home/.pi/pi-menshen.json && homesick link dotfiles && pi remove npm:@shinynito/pi-menshen npm:@pedro_klein/pi-modes npm:@pedro_klein/pi-readonly-bash`
(the old whitelist returns via git history in config.json)
