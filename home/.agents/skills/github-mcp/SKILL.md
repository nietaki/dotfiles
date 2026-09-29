---
name: github-mcp
description: "Work with GitHub through the two local github-mcp-server entries configured in ~/.pi/agent/mcp.json: `github-readonly` (reads only) and `github-personal-engineering` (the write-capable issue-to-PR surface). Use when reading or searching issues, pull requests, reviews, labels, repository source, or GitHub Actions CI, or when creating, commenting on, updating, or triaging issues and pull requests in repositories owned by the personal GitHub account. Both entries start disconnected and must be connected before any tool call, and several capabilities (pull request merges, remote file writes, label administration, workflow dispatch and cancellation) are deliberately excluded and must not be worked around."
---

# GitHub MCP — local `github-mcp-server` entries

Both entries run the same binary (`~/repos/github-mcp-server/github-mcp-server`)
with different tokens and toolsets.

## Connect before calling anything

The adapter registers these servers lazily. Until connected, the namespace tool
is absent and calls fail — `mcp({})` showing `not listening; disconnected` is
the normal starting state, not an error.

```
mcp({ connect: "github-personal-engineering" })   # 35 tools
mcp({ connect: "github-readonly" })               # 22 tools
```

Both entries advertise the **same tool names**, so with the `mcp` gateway always
pass `server:` explicitly — `mcp({ server: "github-personal-engineering", tool:
"list_issues", args: {...} })` — or use the prefixed name directly (`tool:
"github-personal-engineering_list_issues"`). Verified: a bare `get_me` with no
`server:` returns `not found` plus prefixed candidates from both entries, so the
gateway refuses to guess rather than picking one silently.

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

`github-personal-engineering` is narrowed by `--exclude-tools`. These are absent
from the advertised surface and there is no alternative name for them
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
  string, no `/reload` needed). A **new token value** requires `/reload`, because
  the server process captured the environment at spawn.
