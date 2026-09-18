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
- `pi-mode-ux.ts` — glue extension (no forks), four jobs, all verified
  against the **installed** pi-modes `src/index.ts` (published npm code
  lags behind GitHub main — analyze what is actually running, not main):
  1. **`/mode <ask|brainstorm|plan|build|none>`** — published pi-modes
     registers *zero* slash commands (only a shortcut). Typing `/build`
     expands the package's bundled `prompts/build.md` template
     (`pi.prompts` in its package.json) — that is the `[MODE: BUILD …]`
     text, not a mode switch. `/mode` is a unique name; it emits
     `pi-ask:mode-switch`, the event pi-modes already listens for, and
     pi-modes then runs its real switch pipeline (gating, persistence,
     notification, contract injection). Known inherited side effect: the
     switch aborts any in-flight run and injects a "Continue working.
     Mode is now …" follow-up ~150 ms later (visible to the user as two
     extra messages — that is the plumbing working, not a bug).
  2. **Footer mode segment** — `ctx.ui.setStatus("pi-modes", …)` on every
     `pi-modes:changed`. pi core wires setStatus into the shared
     `footerDataProvider`, and `@henryqw/pi-footer` renders *all* entries
     of `getExtensionStatuses()` (footer.ts:347). No fork, no extra
     status package. Re-published on `before_agent_start` as a safety net.
  3. **`bash_readonly` kept in build/none** — installed pi-modes filters
     it out in those modes ("redundant"); we re-add it after each switch
     (`setActiveTools(getAllTools())`). Safe: it is read-only by
     construction, menshen does not gate it (`gatedTools: ["bash"]`), and
     gotgenes' `shellTools` alias applies the full bash path/external
     policy to it — proven by the `cat ~/.ssh/config` deny routed
     through `bash_readonly`. Benefit: plain reads in build mode skip
     menshen's reviewer round-trips.
  4. **`mode_status` tool** — zero-arg read-only query returning the
     mirrored mode (same state the footer renders) plus LIVE
     `pi.getActiveTools()` facts (which shell tool exists right now).
     Fills the gap where `/mode` re-informs the model (abort + follow-up
     message) but Ctrl+Alt+M mid-run does not. Reports only; switching
     stays a human action. Allowed by menshen/gotgenes default-allow
     (no paths, no args); survives mode gating because pi-modes filters
     by denylist name only.
- This README — architecture + reasoning.

## Daily use

- **`/mode` (our shim) or `Ctrl+Alt+M` to switch modes — do NOT use
  `/build` `/plan` `/ask` `/brainstorm` `/none`: the published pi-modes
  has no slash commands and those names expand the bundled contract
  templates as plain messages (see Files: pi-mode-ux).** Cycling with the
  shortcut goes ask→brainstorm→plan→build→none and only notifies on
  actual change; from a fresh (ask) session it takes 3 presses to build.
  **New sessions default to `ask`** (read-only).
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
- **gotgenes hot-reloads `config.json`** (verified 2026-09-11: a grep at
  `~/.pi/agent/npm/...` was denied, the config was edited, and the next
  call passed — no restart). Also note `path` and `external_directory`
  are separate surfaces: `allow` entries must be in *both* for bash
  reads outside the workspace (`~/.pi`, `~/.local/share/mise`, and
  `~/.config/opencode/skills` are in both; the skills dir is the one from
  settings.json `skills` — its SKILL.md files load via `read` through the
  default-allow `path` surface, but bash must reach it to run skill
  scripts).
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

Unverified: menshen `deny & remember` persistence; `git commit` ask rule (same code path as kubectl's); only ONE prompt appeared for `env whoami` (gotgenes asked, menshen seemingly deferred — the feared double-prompt didn't materialize here).

**pi-mode-ux.ts verified after restart (2026-09-11):** `/mode plan` → `/mode build` switched modes end-to-end (the two "Continue working. Mode is now …" messages in the transcript are pi-modes' own switch-pipeline side effect), and in build mode both `bash` and `bash_readonly` answered probes — proving the re-exposure. Footer confirmed: `+ BUILD` segment renders in `@henryqw/pi-footer` (user-eyeballed ✓).

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
- `/mode build` in a fresh session → toast + bash returns ✓ (verified)

Rollback: `git checkout home/.pi/agent/settings.json home/.pi/agent/extensions/pi-permission-system/config.json && rm home/.pi/pi-menshen.json && homesick link dotfiles && pi remove npm:@shinynito/pi-menshen npm:@pedro_klein/pi-modes npm:@pedro_klein/pi-readonly-bash`
(the old whitelist returns via git history in config.json)
