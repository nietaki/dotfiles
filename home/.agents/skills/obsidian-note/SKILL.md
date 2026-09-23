---
name: obsidian-note
description: "Create or update knowledge notes in the user's Obsidian vault at ~/obsidian/pi_knowledge/. Use when the user says to make a note, document this, save this for future reference, write this up in Obsidian, or capture session knowledge into the vault. Notes must be self-contained because the conversation transcript will not be available to readers. Only invoked on explicit user requests - never write notes unprompted."
---

# Obsidian Knowledge Notes

Capture what a session uncovered into the user's Obsidian vault for future reference by the user or by agents.

The invoking prompt decides why the note is being created, what session material to emphasize, and whether clarification is needed. This skill governs vault safety, placement, deduplication, Obsidian formatting, and verified writes. Do not repeat an interview already completed by the invoking prompt.

## Vault location & access rules

- Vault root: `~/obsidian/pi_knowledge/` — the **only** part of the vault the agent may read or write.
- `~/obsidian` itself and `$HOME` broadly are blocked by the permission policy (`external_directory_read`). Never run `ls ~/obsidian`, `cd ~` + relative paths, or any command that touches paths above the vault root — it wastes a turn on a denial.
- Always use full paths rooted at the vault: `read ~/obsidian/pi_knowledge/dotfiles/Some note.md`, `ls ~/obsidian/pi_knowledge/dotfiles/`.
- `~/obsidian/pi_knowledge/Pi knowledge.md` explains the folder scheme: one subdirectory per source repo.

## Placement

- Subfolder = **basename of the current working directory** (the repo pi is run in). Create it if missing: `mkdir -p ~/obsidian/pi_knowledge/<basename>/`.
- An explicit folder named by the user overrides this default (e.g. "put it in dotfiles/").
- Before writing, list the target subfolder and reuse or update an existing note that covers the same topic instead of creating a near-duplicate.

## Filename

- Descriptive Title Case, **no date prefix**: `DMARC policy graduation - nietaki.com.md`. The date lives in frontmatter.
- Avoid `# ^ [ ] | " \ : / < >` in filenames — they break wikilinks. Spaces and hyphens are fine.
- Wikilinks resolve by filename vault-wide, so filenames must stay unique across all subfolders. Search recursively with `find ~/obsidian/pi_knowledge/ -type f -name '*.md' -print | rg -i -- '<key phrase>'`, then read plausible matches before deciding whether to update or create.

## Note template

```markdown
---
title: "Short descriptive title"
date: YYYY-MM-DD
tags: [topic/subtopic, another-tag]
status: active
---

# Short descriptive title

> [!abstract] One-line summary
> The entire point of the note in a single sentence.

## Context — why this exists
The triggering problem/question and what was being worked on.

## Current state / findings
Verified facts, with a date for anything time-sensitive.

## (body sections depend on note type — see below)

## Open questions
Gaps noticed while writing. Do NOT go research them.

## References
Links actually used during the session.
```

Replace `YYYY-MM-DD` with the current local date. `status` values: `active` (working doc), `done` (plan executed), `stale` (needs re-verification).

## Content rules

**Self-contained test:** a reader with zero access to the conversation must be able to act on the note. State the original problem, the constraints that mattered, what was verified vs assumed, and what to do next.

**Shared-reader test:** remove conversational shorthand such as “as discussed,” “above,” or unexplained “we.” Expand project-specific acronyms on first use, separate verified facts from recommendations, and omit secrets or irrelevant private session details.

**Document, don't research:** the note records what the session already uncovered. Never do new web searches, tool calls for discovery, or codebase exploration *for the note itself*. Re-verify a fact only if it is trivial and cheap (one `dig`, one `ls`). Found a gap while writing? Add it to `Open questions` and move on.

Include whatever fits the note's type:

| Note type | Must include |
|---|---|
| Decision / tool choice | Alternatives considered with pros & cons, justifications for each choice made, what was rejected and why |
| Workflow / how-to | Exact tools and commands as used, example usage where relevant, pitfalls hit during the session |
| Plan / implementation | Ordered steps with timeline, the effect each change causes (good and bad), a task checklist with `- [ ]` items to tick off later |
| Troubleshooting / incident | Symptoms, root cause, fix, how it was confirmed working |
| Reference | Dates for time-sensitive claims, authoritative sources actually used during the session, and unverified gaps under Open questions |

## Obsidian syntax guide

- **Frontmatter:** YAML between `---` lines. `title`, `date`, `tags`, `status` are the standard keys. `tags` is reserved — it must be a YAML list (`[a, b]` or `- a` lines), never a bare space-separated string (Obsidian silently splits it into word-tags). Links in frontmatter are inert strings for graph/backlinks — put links in the body.
- **Callouts** (the idiomatic scannable block):
  ```markdown
  > [!abstract] Summary          > [!note] Neutral aside
  > [!warning] Heads-up          > [!example] Sample
  > [!tip] Recommendation        > [!question] Open item
  ```
  Append `-` after the type (`[!note]-`) to make it collapsed by default.
- **Wikilinks:** `[[Other Note]]`, `[[Other Note#Section]]` (no `.md` suffix). Embeds: `![[image.png]]`. External links: standard `[text](url)`.
- **Tags:** lowercase, hyphenated, hierarchical with `/` — `email/dmarc`, `pi/skills`. Folders carry repo context; tags carry topic. Don't invent a tag that duplicates a folder's meaning (`dotfiles`).
- **Formatting:** tables for comparisons, fenced code blocks with language hints (```` ```bash ````), task lists `- [x]` / `- [ ]` for checklists, `##`-headed sections (never skip H1).
- No HTML, no Dataview inline fields (`key:: value`) unless the user asks — plugin-dependent.

## Procedure for adding or updating a note

1. Derive target folder (basename of cwd; user overrides win); `mkdir -p` if needed.
2. Check the folder and vault-wide filename uniqueness; read plausible matches and update an existing note instead of duplicating.
3. For a new note, use `write` and follow the template and type checklist.
4. For an existing note, read it in full and make targeted changes with `edit`. Never overwrite existing content wholesale unless the operator explicitly requests a rewrite. Preserve its structure and frontmatter date semantics: keep the original `date` and add or update an `updated:` key.
5. Default to changing only the primary note. Edit a related index or linking note only when the operator or invoking prompt authorizes it and the change materially improves discoverability. Read it first and keep the edit minimal.
6. Verify every written file by reading it back. Report the full path of the primary note and every additional path changed.

## Never

- Write outside `~/obsidian/pi_knowledge/`.
- Edit related notes without authorization from the operator or invoking prompt.
- Delete or restructure other notes unless explicitly asked.
- Trigger this skill for note-taking destinations other than this vault (repo-local docs/READMEs are ordinary file edits, not skill work).
- Pad notes with unverified filler to match a template — omit sections that don't apply.
