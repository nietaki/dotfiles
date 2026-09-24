# Web Search & Page Access

Web access runs through the `pi-web-access` extension (not the old Brave/Exa
MCP servers). For current events, documentation, or any time-sensitive fact:
search the web instead of relying on training data. Cite the URL when results
inform an answer.

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
