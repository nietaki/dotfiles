# sessions-retro

Reviews pi session transcripts scoped to **one** working directory and turns
them into a ranked proposal board for this setup (model policy, agents config,
instructions/skills, permission rules, operator behaviour). Two-stage on
purpose: cheap models extract, one strong model judges. All children are
read-only; a human decides what to apply.

```
enumerate (scout: ls ~/.pi/agent/sessions/--<cwd>--/)
  -> digest-N in parallel (scout, fresh context; go/no-go first, then a bounded
     JSON file written to /tmp — keeps transcript text out of task strings)
  -> synthesize (reviewer on the strong tier: merges duplicates, ranks by
     confidence x expected gain / effort)
```

## Arguments

- `cwd` (required) — the project to review. Session dirs are the absolute path
  with `/` → `-`, wrapped in `--`, e.g. `/Users/nietaki/repos/grr-fyi` →
  `--Users-nietaki-repos-grr-fyi--` (verified 2026-09-23). The registry injects
  its own `cwd` = the pi run directory, which is **not** `args.cwd`; pass the
  target explicitly.
- `maxSessions` (default 6, capped at 16) — newest-N transcripts.

Budget: `1 + maxSessions + 1` children (≤ 18), inside the default 24-spawn cap.

## Model tiers

- **Digest workers** (scout): `opencode-go/qwen3.7-plus` — cheap extraction
- **Synthesis judge** (reviewer): `openrouter/anthropic/claude-opus-5.5` — strong judgment for merging duplicates, ranking by confidence × gain / effort, grounding proposals in evidence

The model override is per-launch, not global — it doesn't change the reviewer tier for other workflows.

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
           timeoutMs: 3_600_000 })
```

## Permissions

Reading `~/.pi/agent/sessions/**` needs a `path_read` entry (our policy denies
`~/.pi/*` by default and restores reads selectively). Plain `ls` works for
children; tree-walking variants (`find`, `du`) were denied — enumerate uses `ls`
only and degrades to `nothing-to-review` with a hint if a rule still bites.

Both scout launches pass `output: false`: scout's `output: context.md`
frontmatter would route an artifact write into `~/.pi/agent/sessions/…`, inside
the write-deny.
