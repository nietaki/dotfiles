---
name: apify-job-search
description: Search recent English- or Polish-language backend, SRE, and DevOps postings with the Apify Fantastic.jobs Career Site Job Listing API. Use when the user asks to find, query, or summarize job openings using the configured apify-job-listings MCP server.
---

# Apify Job Search

Use the configured `apify-job-listings` MCP server and its Fantastic.jobs
Career Site Job Listing API Actor tool to find jobs from company career sites.
Return source postings, not invented or inferred job details.

## Invoking through codemode

The server connects automatically at session start under Pi's built-in MCP
support; call its tools from a `codemode` script. Registered tool names keep the
server and tool hyphens (`mcp__apify-job-listings__get-dataset-items`); codemode
lists them under an underscore identifier
(`mcp__apify_job_listings__get_dataset_items`) and both spellings resolve when
called. The Actor tool's registered name is **hashed** because
`mcp__apify-job-listings__fantastic-jobs--career-site-job-listing-api` exceeds
Pi's 64-character limit — the real names are
`mcp__apify-job-listings__fantastic-jobs--career-site-jo_dba742b8` (registered)
and `mcp__apify_job_listings__fantastic_jobs__career_site_jo_dba742b8`
(`ALL_TOOLS`). Discover it instead of typing either from memory — note the
`namespace:` filter takes the hyphen form:

```js
const found = await searchTools("career site job listing", { namespace: "mcp__apify-job-listings", limit: 5 });
const runTool = found.map(t => t.name).find(n => n.includes("career_site_jo"));
const result = await tools[runTool]({ /* Actor input below */ });
return { runTool, isError: result.isError, content: result.content, structuredContent: result.structuredContent };
```

The management tools are short enough to name directly:
`mcp__apify-job-listings__get-dataset-items`,
`mcp__apify-job-listings__fetch-actor-details`,
`mcp__apify-job-listings__get-actor-run`. Codemode receives the whole
`CallToolResult`; check `isError` before using the payload, and read the JSON out
of the text content blocks (or `structuredContent` when the server supplies it)
rather than assuming an adapter-normalized shape. A server-level error result
resolves in the script, but a call the permission gate blocks **throws** — so
wrap gated calls in `try/catch` if one branch failing must not abort the script.
The two location branches are independent, so run them concurrently with
`Promise.allSettled`.

The Actor is pay-per-event; see the pricing note below. Never run it as a
connectivity or migration smoke-test — use
`mcp__apify-job-listings__fetch-actor-details` for that.

## Search profile

Default profile:

- **Roles:** backend engineering, SRE/site reliability, and DevOps.
- **Technology:** Elixir or Go (including Golang), with Go matches kept specific to the programming language.
- **Language:** English or Polish, using `aiLanguageFilter: ["English", "Polish"]` and checking the returned `ai_job_language`.
- **Time window:** `timeRange: "7d"` for an on-demand search.
- **Maximum results:** `limit: 10` per Actor run by default. The Actor requires a minimum limit of 10. Ask before increasing the cap.
- **Description:** request plain text with `descriptionType: "text"` and include the full `description_text` for each returned posting.

The Actor is pay-per-event. Its Store page lists a starting price of $4 per 1,000 jobs; state that runs may incur charges before running it, especially when doing multiple searches. `descriptionSearch` is unsupported for the `6m` time range; use `7d` by default.

## Search terms

### Role titles

Start with this tested `titleSearch` array:

```json
["backend:*", "back-end:*", "SRE", "DevOps:*"]
```

The array entries are alternatives (OR). A 7-day test with these four terms returned Backend, Back-End, SRE, and DevOps titles. If recall is too low, ask whether to broaden with unverified adjacent titles such as `site reliability engineer`, `platform engineer:*`, `infrastructure engineer:*`, `cloud engineer:*`, or `production engineer:*`. Avoid adding a generic `software engineer` term without the user's agreement; it substantially broadens the role set.

The Actor's `:*` suffix means prefix matching. Use it for word forms where useful; it is not a free-form wildcard and does not replace spelling variants (for example, keep both `backend:*` and `back-end:*`). Stable acronyms such as `SRE` can be used without it.

### Technologies in descriptions

Keep technology matching in `descriptionSearch`, not `titleSearch`, so roles are not discarded just because a technology is absent from the title. Start with:

```json
["elixir", "golang", "go programming", "go language", "go developer", "go engineer"]
```

`descriptionSearch` array entries are alternatives (OR); a test of `["elixir", "golang"]` returned postings whose descriptions contained `golang` but not `elixir`. The tool's `descriptionSearch` includes both title and description, so **verify the body**: after retrieving results, retain only postings whose `description_text` contains Elixir/Golang or a Go-language-context match. Do not count a title-only match. Reject generic uses of `go` (the ordinary verb); do not search bare `go` by default because it is noisy. If the contextual Go phrases miss relevant jobs, ask before trying a bare `go` search, and then validate each hit against its description.

Multiple search parameters are intended to narrow together: matching a role title, a technology, language, and location/work-arrangement branch should all be required. Check the returned fields before presenting results rather than assuming every filter worked.

## Run two location branches

Run separate searches because remote work and a Poland-based location are alternative cases, not simultaneous requirements. Apply the same role, technology, language, time-window, result-cap, and description parameters to each branch.

### Remote

Add:

```json
"aiWorkArrangementFilter": ["Remote OK", "Remote Solely"]
```

Use `ai_remote_location`, `ai_remote_location_derived`, `ai_work_arrangement`, and `locations_derived` to assess eligibility. The user's preference is to **rank** explicitly US-only remote jobs below worldwide, Europe-wide, or Poland-eligible remote roles, not to exclude them.

### Poland-local

Add:

```json
"locationSearch": ["Poland"]
```

Do not set `aiWorkArrangementFilter` on this branch; keep onsite, hybrid, and remote-in-Poland jobs eligible.

Do **not** use the city-level form `locationSearch: ["Warsaw, Poland"]`: a verified 2026-09-29 7-day run with the full profile (roles, Go/Elixir description terms, English/Polish) returned **0 items**, while the same run with `"Poland"` returned 5. The city string is apparently matched too literally against derived location values. Country-wide matching still surfaces Warsaw jobs — check `locations_derived` / `ai_remote_location_derived` per posting (e.g. Atos "Senior Devops Engineer with Golang" listed Warszawa among its hybrid sites).

Deduplicate results across the two branches by normalized posting URL. Preserve the source URL and do not merge distinct listings solely because their titles are similar.

## Example inputs

Remote branch:

```json
{
  "timeRange": "7d",
  "limit": 10,
  "descriptionType": "text",
  "titleSearch": ["backend:*", "back-end:*", "SRE", "DevOps:*"],
  "descriptionSearch": ["elixir", "golang", "go programming", "go language", "go developer", "go engineer"],
  "aiLanguageFilter": ["English", "Polish"],
  "aiWorkArrangementFilter": ["Remote OK", "Remote Solely"]
}
```

Poland branch: same input, replacing `aiWorkArrangementFilter` with `locationSearch: ["Poland"]`.

## Read and present results

After each successful Actor run, read only the default dataset created by that
run using `mcp__apify-job-listings__get-dataset-items`, with a limit no larger
than the requested Actor limit. Parse the returned content blocks (or
`structuredContent`) to get the items; `itemCount` on the run is not the item
list.

A run response is **not** proof the Actor finished. The Actor tool self-caps its
own wait ("max seconds 0–45, default 30… for long-running Actors the response
returns at the cap with the current run status"), so read the returned status
and follow its `nextStep`, polling
`mcp__apify-job-listings__get-actor-run`, before reading the dataset —
otherwise you are querying a run that is still open. Select at least these fields:

- `date_posted` — preserve the posting timestamp (ISO format; don't invent a timezone if absent)
- `organization`
- `url`
- `title`
- `description_text`

Also retain `ai_job_language`, `ai_work_arrangement`, `ai_remote_location`, `ai_remote_location_derived`, `locations_derived`, and `domain_derived` as useful validation/ranking context and for the required table columns. Use the original full description text; do not summarize it in place of the requested description. If there are no results, report that this search returned none in the selected window—not that no such jobs exist.

**`timeRange` does not bound `date_posted`.** Verified 2026-09-29: a `7d` run returned postings whose `date_posted` was two and four months old (long-lived Lever listings recrawled this week). The window filters on ingestion/validity, not the original posting date. Always compare `date_posted` against the requested window and flag stale postings rather than presenting them as new; also watch for non-open-req titles (e.g. "Talent Pool") surfacing this way.

## Present results as a table

Present combined results (both branches, deduplicated by normalized URL) as one markdown table with exactly these columns, in order:

| Column | Rule |
|---|---|
| Title | Link to the job posting `url`. |
| Company | Link to the company website: `https://<domain_derived>`. Do **not** use `organization_url` as the primary source — it is frequently null or points at the ATS board (verified 2026-09-29 samples). `domain_derived` was populated on every item and is ~98% accurate per the Actor README; do not enable `includeCompanyDetails` just for the website. |
| Posted | `date_posted`, date-only (YYYY-MM-DD). |
| Remote locations | `ai_remote_location_derived` (fallback `ai_remote_location`), plus `locations_derived` when they disagree — a disagreement is itself a Notes item (AI eligibility parse vs source location). |
| Lang | `ai_job_language`. |
| Notes | Plain-text caveats. **Every emoji in Assessment must also be explained here in words** — the table must stay readable without knowing the legend. Include duplicates/variants, Go-vs-Elixir evidence quality, hybrid/onsite arrangements, and data contradictions. |
| Assessment | Emoji flags, one or more per row (see below). |

### Assessment emojis

- 🎯 good fit — role, verified body-text Elixir/Go requirement, and Poland/EU-eligible location all hold.
- 📍 likely location-incompatible — remote eligibility excludes Poland/EU (e.g. US-only, LATAM-only). This is the operator's chosen rule: not-Poland/EU-eligible → 📍; explicitly-PL/EU/worldwide-eligible → no flag. Consistent with ranking US-only remote below worldwide/Europe/Poland-eligible roles rather than dropping it. Note: `ai_remote_location` is output-only — no server-side filter for eligibility exists in this Actor (verified 2026-09-29; `locationExclusionSearch` matches `locations_derived` only and misfires in both directions), so this must be assessed after retrieval.
- 🧂 tech is only seasoning — the posting matches on Elixir/Go but treats it as "nice to have" rather than a core requirement.
- ⚠️ weak description match — body text matches the profile poorly for reasons other than tech seasoning (e.g. junior-level when senior was implied, adjacent-but-different role, noisy bare-"go" style matches).
- 🦖 stale — `date_posted` falls outside the requested window (recrawled listing).
- ♻️ duplicate/variant — regional or slug variant of another row in the table (URLs differ, role does not; do not merge rows, flag them).
- 🧊 talent pool / evergreen — not an open req ("Talent Pool", standing pipeline listings).

Rows meeting none of the negative flags still carry 🎯 only if the body-text technology verification passed; a title-only match never earns 🎯.

## Validation notes

The individual `titleSearch` and `descriptionSearch` array OR behavior has been demonstrated with successful 7-day test runs. The specific base role terms above were tested. The `elixir`/`golang` description OR test produced only Golang matches in its 10-result sample; it did not establish that Elixir has matches in every time window. The Go-context phrases, the language filter, and the combined multi-filter behavior have not been individually test-run. The remote `aiWorkArrangementFilter` branch and the `locationSearch: ["Poland"]` branch were test-run successfully on 2026-09-29 (10 and 5 items respectively, all Golang matches, no Elixir); the city-level `"Warsaw, Poland"` form was test-run and returned 0 — use `"Poland"`. Verify actual result fields and descriptions on each run.
