# Web Search & Page Access

Web access runs through the `pi-web-access` extension (not the parked Brave/Exa
MCP servers). For current events, documentation, or any time-sensitive fact:
search the web instead of relying on training data. Cite the URL when results
inform an answer.

MCP servers themselves run through Pi's **built-in** MCP support
(`~/.pi/agent/mcp.json`, `/mcp`, `pi mcp list`). Their tools are registered as
`mcp__<server>__<tool>` with the server/tool hyphens kept
(`mcp__github-readonly__list_issues`); inside codemode the same tools appear
under the underscore identifier form (`mcp__github_readonly__list_issues`) and
either spelling resolves when called. Reach them through the `codemode` tool,
which this setup enables permanently (`defaultTools: ["+codemode"]`). Only a
slice is declared — measured 13 of 68 MCP tools with all five servers connected
— so find the rest with `searchTools()` (its `namespace:` filter takes the
hyphen form) or by filtering `ALL_TOOLS`. Registered names over 64 characters
get an 8-hex suffix, so never type a long name from memory.

## Tools

- `web_search` — search the web; returns bounded, source-linked results and
  names the provider used. Prefer 2–4 varied query angles over one query for
  research. Full results are stored for later retrieval.
- `get_search_content` — fetch the full stored content of a prior search
  result by its `responseId` when the inline snippet is not enough.
- `fetch_content` — fetch a URL as readable markdown/text (and GitHub repo
  content, see below). Use it to read a specific page directly.
- `source_check` — cross-check a claim/question against live sources.

Search providers are constrained to **Exa and Brave** (configured in
`~/.pi/agent/web-search.json`, credentials from the `EXA_API_KEY` /
`BRAVE_API_KEY` env vars). Automatic routing tries Exa first and falls back to
Brave. Brave's free tier is ~2k queries/month — prefer few well-formed queries
over many similar ones, and reuse cached results rather than re-searching.

## Activation

The four tools above are registered eagerly and are available immediately in
every session — call `web_search` / `fetch_content` / `source_check` /
`get_search_content` directly. (On a Pi build where the package can resolve
Pi's version at startup it may instead advertise a single `web_enable` loader
tool to call first, with the real tools appearing on the following request; if
a `web_enable` call is ever reported as “not found”, the tools are simply
eagerly available and you can use them.)

## GitHub — division of responsibility

- `pi-web-access` (`fetch_content`): given a **public** GitHub repository,
  file, or tree **URL**, it clones into `/tmp/pi-github-repos` (bounded, wiped
  per session) and returns real file contents plus a local path to explore with
  `read`/`bash`. Public repos only here — `gh` is not installed, so private
  clones are not available through this path.
- `github-readonly` MCP: use for GitHub **context, repository API operations,
  issues, and pull requests**. The extension's URL/clone path and this MCP are
  complementary, not interchangeable — do not assume one replaces the other.
- `github-personal-engineering` MCP: write-capable sibling entry over the same
  binary, for the issue→PR loop on repositories owned by the personal account
  (issue/PR creation, comments, reviews, CI inspection, label reads). Narrowed
  by `--exclude-tools` (no merges, no remote contents writes, no label
  vocabulary admin). `actions_run_trigger` (workflow dispatch) is callable and
  is **not** approval-gated — built-in MCP has no `approveTools`; a gate would
  be a `pi-permission-system` rule (shape in `extensions/README.md`). Use this
  entry only when a write is actually needed; `github-readonly` covers looking.
- `github-readonly` search size limits: `search_issues`, `search_pull_requests`,
  `search_code`, and `search_repositories` accept `perPage` (up to 100). Start
  with `perPage <= 10` and narrow the query instead of paging wide — a
  `perPage: 100` result can be a 300 KB payload. Direct tool results over 20 KB
  reach the model with the middle cut out and the full text saved to a
  `pi-mcp-<hex>.txt` file under `$TMPDIR`, whose path the result names (readable:
  the permission policy carves `/private/var/folders/*/pi-mcp-*` out read-only).
  Prefer filtering inside a `codemode` script — scripts always receive the
  complete `CallToolResult` — and inspect the spill file with `read`/`grep` only
  when a direct call already produced one. Never re-run the same search just to
  see what was truncated. For repository discovery, `search_repositories` also
  supports `minimal_output: true`.
