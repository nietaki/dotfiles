# sessions-retro

Reviews pi session transcripts scoped to **one** working directory and turns
them into a ranked proposal board for this setup (model policy, agents config,
instructions/skills, permission rules, operator behaviour). Two-stage on
purpose: cheap models extract, one strong model judges. All children are
read-only; a human decides what to apply.

```
enumerate (retro-scout: one pi_sessions_list tool call, JSON transcribed verbatim —
   newest-N parent sessions, each with its nested child/subagent transcripts)
  -> digest-N in parallel (retro-scout, fresh context; ONE parent + its children
     per worker; go/no-go first, then a bounded JSON file written to /tmp —
     keeps transcript text out of task strings)
  -> synthesize (retro-judge on the strong tier: merges duplicates, ranks by
     confidence x expected gain / effort, re-verifies evidence against the
     exact transcript each finding's sourcePath names, THEN WRITES THE REPORT
     NOTE to the obsidian vault and returns notePath for the chat report)
```

## Arguments

- `cwd` (required) — the project to review. Session dirs are the absolute path
  with `/` → `-`, wrapped in `--`, e.g. `/Users/nietaki/repos/grr-fyi` →
  `--Users-nietaki-repos-grr-fyi--` (verified 2026-09-23). The registry injects
  its own `cwd` = the pi run directory, which is **not** `args.cwd`; pass the
  target explicitly.
- `maxSessions` (default 6, capped at 16) — newest-N **parent** sessions.
  Children (subagent transcripts) are not counted: they ride along with their
  parent's digest worker. The tool caps children at 12 newest per parent and
  flags >1 MiB as `oversized` (head/tail sample + grep only).
- `noteDir` (optional) — vault directory for the report note; default
  `/Users/nietaki/obsidian/pi_knowledge/sessions-retro`.

Budget: `1 + maxSessions + 1` children (≤ 18), inside the default 24-spawn cap.

## Session layout (verified 2026-09-23)

pi stores session transcripts in `~/.pi/agent/sessions/--<cwd-slug>--/` with this structure:

- **Parent sessions**: `<project-dir>/<timestamp>_<uuid>.jsonl` (top-level `.jsonl` files)
- **Child sessions**: `<project-dir>/<parent-stem>/<launch-uuid>/run-<n>/session.jsonl`
  - `<parent-stem>` = parent filename minus `.jsonl` (a directory)
  - `<launch-uuid>` = random per-launch UUID (NOT the async runId)
  - `run-0`, `run-1`, ... = resume attempts

Children are **nested under their parent's directory**, not at the top level.
The `pi_sessions_list` tool (extension `pi-sessions.ts`) resolves the slug dir,
walks the nesting, and tags each child with its agent / runId / runIndex
(parsed from the transcript's `session_info` line — the intermediate launch
UUID is random and is never the runId). One digest worker per **parent**, with
that parent's children attached.

For full details, see `~/obsidian/pi_knowledge/dotfiles/Pi-subagents session layout - where child sessions live.md`.

## Report note (the durable output)

The judge writes the finished board to
`~/obsidian/pi_knowledge/sessions-retro/retro-<ISO-minute>-<project>.md`
(frontmatter + summary + proposals-by-surface with quoted evidence + rejected
claims audit trail + method footer with the /tmp digest paths and run nonce),
and returns it as `reportNote` in the workflow result so the launching session
quotes the path in chat. The `sessions-retro` directory does not need to
pre-exist — pi's `write` creates parents. This is the ONLY file any retro
child may write outside /tmp digests; the vault is read+write in the
permission policy, dotfiles stay propose-only.

## Model tiers

- **Enumerate + digest workers** (retro-scout): `opencode-go/qwen3.7-plus`, pinned in the agent's frontmatter — cheap extraction
- **Synthesis judge** (retro-judge): `openrouter/anthropic/claude-opus-5.5`, pinned in the agent's frontmatter (and passed per-launch) — strong judgment for merging duplicates, ranking by confidence × gain / effort, grounding proposals in evidence

`retro-judge` is the builtin reviewer's discipline + `write`, scoped to the
report note — kept a dedicated user agent so the builtin reviewer (code/plan
review everywhere else) stays read-only. The model override is per-launch, not
global — it doesn't change the judge tier for other workflows.

## Timeouts

- **Per digest**: 5 minutes (`timeoutMs: 300_000`)
- **Synthesis**: 20 minutes (`timeoutMs: 1_200_000`)
- **Outer deadline**: pass `timeoutMs` at launch (e.g. `3_600_000` for 1 hour) — async composites have no default

## Limits of the `/workflow run` surface

The registry passes only `{workflowScript, cwd}`, so there is **no outer
`timeoutMs`** (async composites have no default deadline) and no raised spawn
budget. For an explicit deadline use the direct surface:

```js
subagent({ workflowScriptPath: "/Users/nietaki/.pi/agent/subagent-workflows/sessions-retro/script.js",
           args: { cwd: "/Users/nietaki/repos/grr-fyi", maxSessions: 6 },
           async: true, timeoutMs: 3_600_000 })
```

## Permissions

Enumeration is one `pi_sessions_list` call — an extension tool with no `path`
arg, so the gates extract nothing (pi-permission-system routes unregistered
extension tools by the `input.path` convention only; verified in source
2026-09-23). The tool's own reads are confined to `~/.pi/agent/sessions/` by
construction. Digest workers read transcripts with `read`/`grep`, allowed via
`path_read` + `external_directory_read` for `~/.pi/*`. bash tree-walks (`find`,
`du`) over the sessions store stay denied — never reintroduce them in task
text.

Both scout launches pass `output: false`: `retro-scout` already sets it in its
frontmatter, and an artifact write routed into `~/.pi/agent/sessions/…` would
hit the write-deny — belt and braces.

**Requirements:** the `pi-sessions` extension must be loaded (restart pi after
installing/editing it) and the `retro-scout` + `retro-judge` agents must be
linked (`home/.pi/agent/agents/` via hslink). Without the tool, enumeration
degrades to `found=false` and the workflow returns `nothing-to-review` with a
hint; without the judge's write grant, the board still returns with
`notePath` empty and the failure recorded in `unproposedGaps`.
