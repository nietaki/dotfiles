---
description: "[parent-run] Search recent Go/Elixir backend, SRE, and DevOps jobs in remote and Poland branches, present assessed results, and save a dated Obsidian summary."
argument-hint: "[process overrides, e.g. limit 40; also search Rust and Kubernetes]"
model: "opencode-go/qwen3.8-flash, openrouter/openai/gpt-6-luna"
skill:
  - obsidian-note
  - apify-job-search
---
Run the complete job-hunt workflow: execute the remote and Poland-local searches, validate and assess every result, present the combined batch as the table prescribed by the loaded `apify-job-search` skill, and write a self-contained dated summary note using the loaded `obsidian-note` skill.

The operator's optional process overrides are:

<process-overrides>
$@
</process-overrides>

Treat empty or whitespace-only overrides as no changes. Otherwise interpret them as freeform adjustments to this run. Supported adjustments include:

- a different Actor `limit` (applied to each branch unless the operator says otherwise); and
- additional role-title terms, description keywords, or technologies to search **in addition to** the established profile.

Do not silently replace the established role or technology terms unless the operator explicitly asks. If an override is materially ambiguous, ask before starting the paid Actor runs. Reject limits outside the Actor's supported 10–5,000 range. The limits in this template are run-specific and do not change either loaded skill's defaults.

## 1. Establish the effective query

Use this base input for both branches:

```json
{
  "timeRange": "7d",
  "limit": 25,
  "descriptionType": "text",
  "titleSearch": ["backend:*", "back-end:*", "SRE", "DevOps:*"],
  "descriptionSearch": ["elixir", "golang", "go programming", "go language", "go developer", "go engineer"],
  "aiLanguageFilter": ["English", "Polish"],
  "populateAiRemoteLocation": true,
  "populateAiRemoteLocationDerived": true
}
```

Apply clear overrides before either run. Additional search terms extend the relevant arrays. Preserve Go-language specificity: do not add bare `go` unless the operator explicitly requests it, and then validate every hit against the description body.

Briefly state that the Apify Actor is pay-per-event (the Store page listed approximately $4 per 1,000 jobs when this template was authored) and that two runs of up to the effective per-branch limit may incur charges. Invocation of this command authorizes both runs at the template's limit or a clearly supplied override; do not ask for a second confirmation solely because the default here is 25.

## 2. Run the two branches

Use `fantastic-jobs/career-site-job-listing-api` through the configured `apify-job-listings` MCP server.

1. **Remote branch:** base input plus:
   ```json
   "aiWorkArrangementFilter": ["Remote OK", "Remote Solely"]
   ```
2. **Poland branch:** base input plus:
   ```json
   "locationSearch": ["Poland"]
   ```
   Do not set `aiWorkArrangementFilter` on this branch; onsite, hybrid, and remote-in-Poland roles are all eligible. Do not narrow this to `"Warsaw, Poland"` unless explicitly instructed — that city-level form was verified to miss relevant listings.

The branches are independent and may run in parallel. After each successful run, read only that run's default dataset with `get-dataset-items`; never infer results from the immediate `itemCount`, which may lag. Do not fetch more rows than the effective Actor limit.

Retrieve at least:

- `date_posted`, `organization`, `domain_derived`, `url`, `title`, `description_text`;
- `ai_job_language`, `ai_work_arrangement`, `ai_remote_location`, `ai_remote_location_derived`; and
- `locations_derived`.

## 3. Validate, combine, and assess

Follow the loaded `apify-job-search` skill exactly:

- Retain only postings whose body text genuinely contains Elixir, Golang, or an unambiguous Go-programming-context match. A title-only match does not qualify.
- If the operator added technologies, validate those against the body as well and say which technology caused each match.
- Deduplicate across branches by normalized posting URL. Keep distinct regional/slug variants, but mark them as variants rather than pretending they are distinct roles.
- Compare `date_posted` to the requested window and flag stale/re-crawled listings.
- Assess Poland/EU eligibility after retrieval using `ai_remote_location_derived` (fallback `ai_remote_location`) and cross-check `locations_derived`. The Actor cannot reliably filter US-only eligibility server-side.
- Use `https://<domain_derived>` for the company link; do not enable `includeCompanyDetails` merely to obtain a website.
- Never invent or infer missing posting facts. Make contradictions explicit.

## 4. Present the batch

Present one combined markdown table with exactly these columns and order:

| Title | Company | Posted | Remote locations | Lang | Notes | Assessment |
|---|---|---|---|---|---|---|

- Link **Title** to the posting URL.
- Link **Company** to `https://<domain_derived>`.
- Use date-only `YYYY-MM-DD` under **Posted**.
- Put AI-derived eligibility in **Remote locations**, including source-location disagreement when relevant.
- Explain every assessment emoji in plain English under **Notes**.
- Use the skill's expressive assessment legend: 🎯 good fit, 📍 likely location-incompatible, 🧂 technology only nice-to-have, ⚠️ other weak description match, 🦖 stale, ♻️ duplicate/variant, 🧊 talent pool/evergreen.
- Rank strong Poland/EU-eligible fits first and likely location-incompatible roles below them; do not silently discard the latter.

If a branch returns no validated results, state that this search returned none under the effective filters and time window — not that no such jobs exist.

## 5. Write the Obsidian note

Always write or update a note after presenting the table. The operator explicitly sets the vault-root destination to:

```text
~/obsidian/pi_knowledge/job-postings/
```

This replaces the `obsidian-note` skill's cwd-derived folder. Follow the skill's deduplication and safe-write procedure. The filename is an explicitly requested dated snapshot exception and must begin with the current local date:

```text
YYYY-MM-DD Job search batch - <concise effective scope>.md
```

Use a concise, filename-safe scope derived from the effective technologies/roles and the remote + Poland branches. Before writing, inspect the target folder and search the vault for a near-duplicate. Update the same batch note when appropriate; if a substantively different query already has a same-date note, distinguish the filename by effective scope rather than overwriting it.

The note must be self-contained and start, after frontmatter and H1, with an executive summary covering:

- total validated results and approximate distinct-role count;
- standout options and why they stand out; and
- visible trends such as technology mix, location restrictions, stale listings, or ATS duplicates.

Then include the assessment legend, the complete results table (all retained URLs, including marked variants), effective search parameters and branch differences, verified data-quality caveats, open questions that were not researched further, and sources actually used. Use `status: active` and relevant tags. Do not expose credentials or include irrelevant session history.

Read the completed note back and verify its frontmatter, executive summary, row count, and links.

## 6. Finish

Report:

1. remote-branch and Poland-branch raw and validated counts;
2. the combined retained and approximate distinct-role counts;
3. the full path of the Obsidian note; and
4. any important limitations or unresolved data contradictions.
