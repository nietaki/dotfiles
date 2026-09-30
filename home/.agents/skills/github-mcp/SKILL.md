---
name: github-mcp
description: "Work with GitHub through the two local github-mcp-server entries configured in ~/.pi/agent/mcp.json under Pi's built-in MCP support: `github-readonly` (reads only) and `github-personal-engineering` (the write-capable issue-to-PR surface). Use when reading or searching issues, pull requests, reviews, labels, repository source, or GitHub Actions CI, or when creating, commenting on, updating, or triaging issues and pull requests in repositories owned by the personal GitHub account. Both entries connect automatically at session start, are reached through the built-in `codemode` tool as `mcp__<server>__<tool>`, and several capabilities (pull request merges, remote file writes, label administration, workflow cancellation) are deliberately excluded and must not be worked around."
---

# GitHub MCP — local `github-mcp-server` entries (built-in Pi MCP)

Both entries run the same binary (`~/repos/github-mcp-server/github-mcp-server`)
with different tokens and toolsets. They are plain `mcpServers` entries in
`~/.pi/agent/mcp.json`, served by Pi's built-in MCP support (no adapter
extension).

## Connection model

Pi connects every enabled server when a session starts; the first prompt waits
up to 10 seconds, and a slow server's tools appear once it connects. There is
nothing to open or connect by hand — the old "start disconnected, then
`mcp({ connect: ... })`" workflow is gone.

- `/mcp` — server manager: state, tool list, exposure, the full connection
  error (including the tail of a stdio server's stderr), reconnect, enable/disable.
- `/mcp reconnect <server>`, `/mcp login <server>`, `/mcp logout <server>` — one-off actions.
- `pi mcp list --json` (bash) — the same view from a shell; exits 1 when an
  enabled server is not connected or an entry is invalid.
- `~/.pi/agent/mcp.log` — MCP logging notifications from servers, rotated at 5 MB.

A server that drops its connection shows as disconnected and is reconnected on
the next call.

## Calling the tools

Reach the tools through the built-in `codemode` tool, which this setup enables
permanently with `"defaultTools": ["+codemode"]` in `~/.pi/agent/settings.json`;
`"autoEnableCodemode": true` in `mcp.json` also activates it when a codemode
server connects. Tools are registered as `mcp__<server>__<tool>`, hyphens
included. Because the server name is part
of the tool name, the two GitHub entries advertising the same base names
(`get_me`, `issue_read`, …) no longer collide — there is no "pass `server:`
explicitly" rule any more.

```js
// @options: {"max_output_tokens": 4000}
const result = await tools["mcp__github-readonly__search_issues"]({
  query: "repo:owner/project is:open label:bug",
  perPage: 10,
});
if (result.isError) return result;
return result.structuredContent ?? result.content;
```

A codemode script receives the server's whole `CallToolResult` — `content`
blocks as sent, `structuredContent`, and `isError` — so filter inside the script
and return only the part you need. `isError` resolves in the script instead of
throwing; check it before using the payload. A call the permission gate blocks is
the opposite case: it **throws**, so wrap a gated write in `try/catch` when one
denied branch must not abort the rest of the script.

### Two spellings of one name

Verified against this build:

| Context | Spelling |
|---|---|
| Registered pi tool name — permission surfaces and the nested-call log | **hyphens kept**: `mcp__github-readonly__get_me`, `mcp__apify-job-listings__get-dataset-items` |
| `/mcp` and `pi mcp list` tool listings | the server's own **unprefixed** names (`get_me`, `get-dataset-items`) |
| `ALL_TOOLS` / `searchTools()` **results**, and `tools.<name>` property access | **codemode identifier**: every non-`[A-Za-z0-9_$]` char becomes `_`, e.g. `mcp__github_readonly__get_me` |
| `searchTools(..., { namespace })` filter | **hyphen form** — it is matched exactly against the namespace name `mcp__<server>` |

Both spellings resolve when called: `tools["mcp__github-readonly__get_me"]` and
`tools["mcp__github_readonly__get_me"]` both succeed (verified against the same
tool, which returned identical output either way). Use the hyphen form for
`namespace:` filters and for permission rules — a `_`-spelled surface key matches
nothing and silently falls through to the `"*"` allow (verified by temporarily
denying both spellings).

### Do not invent the long names — look them up

Pi sanitizes and caps the *registered* name at 64 characters, replacing the tail
with an 8-character hash. Verified on this setup, exactly two MCP tools are
hashed:

| Registered name | Codemode identifier |
|---|---|
| `mcp__github-personal-engineering__add_reply_to_pull_req_fe1189df` | `mcp__github_personal_engineering__add_reply_to_pull_req_fe1189df` |
| `mcp__apify-job-listings__fantastic-jobs--career-site-jo_dba742b8` | `mcp__apify_job_listings__fantastic_jobs__career_site_jo_dba742b8` |

Everything else keeps its plain name. When a tool is not visible in the
`codemode` declaration list, discover it rather than guessing:

```js
return await searchTools("reply to pull request comment",
  { namespace: "mcp__github-personal-engineering", limit: 5 });
// or, matching on the identifier form that ALL_TOOLS reports:
return ALL_TOOLS.map(t => t.name).filter(n => n.startsWith("mcp__github_personal_engineering"));
```

`describeTool(name)` accepts either spelling. **The declaration list is trimmed.**
Measured in a session with all five enabled servers connected: 68 MCP tools are
callable, but the `codemode` description declares only 13 of them — 10 MCP plus
the 3 resource tools — because declarations share `codemode.inlineBudget`
(default 3000 estimated tokens). Per-namespace it reported
`github-readonly (22 tools, 2 shown)`, `github-personal-engineering (35 tools,
2 shown)`, `apify-job-listings (6, 2 shown)`, `dash (4, 3 shown)`, `github-grep
(1)`. So most GitHub tools are **not** in the description: expect to find them
with `searchTools()` or by filtering `ALL_TOOLS`, and never guess a name.
Raising `codemode.inlineBudget` in `~/.pi/agent/settings.json` widens the
declared slice; it is left at the default here on purpose.

## Large output

The 20 KB middle-truncation applies to **direct** model-facing MCP calls
(`pi-mcp-<random>.txt` holds the full text). With every server on
`exposure: "codemode"` here, you normally never hit it: a codemode script
receives the complete result — verified with a 49.5 KB
`search_repositories` (`perPage: 100`) payload, 2.4× the cap, arriving whole.
Filter in the script and return only what you need. Keep `perPage <= 10` on the
search tools and narrow the query instead of paging wide — a `perPage: 100`
result costs a round trip of tens of KB inside the script.

## Which entry

| | `github-readonly` | `github-personal-engineering` |
|---|---|---|
| Writes | none (`--read-only` strips them from the schema) | issues, PR discussion, PR metadata |
| Reach | its own token's repos | **personal-account repos only** |
| Use for | looking, searching, reading source/CI | the issue→PR loop |

Org-owned repositories and repos where the account is an outside collaborator are
out of reach of the engineering token — a fine-grained PAT has one resource
owner. A 403/404 there is scope, not a bug; do not retry or switch tools.

## Deliberate boundaries — do not route around them

`github-personal-engineering` is narrowed by the server binary's own
`--exclude-tools` argument, so these are absent from the advertised surface
(deprecated aliases like `merge_pr` or `rerun_failed_jobs` are not registered
either, so finding nothing means nothing, not a naming problem):

- **`merge_pull_request`** — merges are a human decision. If a task needs one,
  stop and hand it back.
- **`push_files`, `create_or_update_file`, `delete_file`, `create_branch`,
  `fork_repository`, `create_repository`** — implementation and pushes are local
  git's job, not this server's.
- **`update_pull_request_branch`** — it writes a merge-upstream commit, i.e. a
  contents write. Sync the branch locally and push instead.
- **`label_write`** — repository label vocabulary is read-only. Apply existing
  labels through `issue_write` with `labels: [...]`; create/rename/delete a
  shared label is not available by design.

`actions_run_trigger` (workflow dispatch) is **callable**: it was never actually
gated by the old `approveTools` entry (the list held only a commented-out item),
and built-in MCP has no `approveTools`. Approval for it would come from
`pi-permission-system`; see `home/.pi/agent/extensions/README.md` for the
rule shape.

Local git is also how you read source in bulk: `get_file_contents` is fine for
one file, but use the working tree when exploring a repo you already have.

## Verified quirks of this build

- **Inconsistent parameter names:** issues use `issue_number`, pull requests use
  `pullNumber` (camelCase).
- `issue_read` label shape depends on `method`: `get` returns label name strings,
  `get_labels` returns objects with `color`/`description`/`id`. Mapping `.name`
  over the `get` form silently yields nothing — a false "labels missing".
- `pull_request_read` rejects `method: "get_commits"` as unknown. Valid: `get`,
  `get_diff`, `get_files`, `get_comments`, `get_reviews`, `get_review_comments`,
  `get_status`, `get_check_runs`.
- `get_check_runs` works on a public repo's PR; treat it as best-effort on
  private ones (fine-grained tokens have a documented Checks API gap). CI status
  is more reliable through Actions reads and `get_status`.
- `actions_list` / `actions_get` take `resource_id` as a **string**; `get_job_logs`
  takes numeric `run_id` / `job_id`.
- `create_pull_request` with `head == base` returns `422 No commits between ...`.
  That is the cleanest way to prove the write path is authorized without
  creating anything, and a useful substitute for a real PR test.
- **Public repositories are readable by any token.** A contents or metadata read
  that succeeds on a public repo proves nothing about permissions — always probe
  a private repo inside the token's scope when checking whether a grant is live.
- Fine-grained PAT permission *changes* take effect immediately (same token
  string, no restart needed). A **new token value** does not: `${VAR}` is read
  from the Pi process environment when the server is spawned, so update the
  environment and restart pi (or re-export and restart the session) before
  expecting the new credential.

## Resources and parked servers

Both GitHub entries advertise 5 resource URI templates and no concrete
resources, which registers the read-only resource tools
`list_mcp_resources`, `list_mcp_resource_templates`, `read_mcp_resource`
(verified present). `searchTools`-style discovery covers them too.

Verified from a live session: a server with `"enabled": false` registers **no**
tool names at all — `trmnl`, `betterwright`, `brave`, `exa`, `openzim`, and
`github-notifications` contribute zero entries to `ALL_TOOLS` (68 MCP names,
five enabled servers only). Disabling in `mcp.json` is therefore real
containment for path-aware tools, and `"exposure": "hidden"` additionally
registers-but-blocks if the server is ever enabled.

## PAT creation URL for the engineering entry

`https://github.com/settings/personal-access-tokens/new?name=github-personal-engineering&description=pi%20MCP%20issue%E2%86%92PR%20engineering%20surface%20(personal%20repos%2C%20no%20merge%2C%20no%20contents%20write)&expires_in=90&metadata=read&contents=read&issues=write&pull_requests=write&actions=write&statuses=read`
