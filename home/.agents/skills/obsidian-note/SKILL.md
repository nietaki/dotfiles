---
name: obsidian-note
description: "Create or update knowledge notes in the user's Obsidian vault at ~/obsidian/pi_knowledge/. Use when the user says to make a note, document this, save this for future reference, write this up in Obsidian, or capture session knowledge into the vault. Notes must be self-contained because the conversation transcript will not be available to readers. Only invoked on explicit user requests - never write notes unprompted."
---

# Obsidian Knowledge Notes

Capture what a session uncovered into the user's Obsidian vault for future reference by the user or by agents.

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
- Wikilinks resolve by filename vault-wide, so filenames must stay unique across all subfolders. Check with `ls ~/obsidian/pi_knowledge/*/ | grep -i "<key phrase>"` before inventing a title.

## Note template

```markdown
---
title: "Short descriptive title"
date: 2026-09-22
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

`status` values: `active` (working doc), `done` (plan executed), `stale` (needs re-verification).

## Content rules

**Self-contained test:** a reader with zero access to the conversation must be able to act on the note. State the original problem, the constraints that mattered, what was verified vs assumed, and what to do next.

**Document, don't research:** the note records what the session already uncovered. Never do new web searches, tool calls for discovery, or codebase exploration *for the note itself*. Re-verify a fact only if it is trivial and cheap (one `dig`, one `ls`). Found a gap while writing? Add it to `Open questions` and move on.

Include whatever fits the note's type:

| Note type | Must include |
|---|---|
| Decision / tool choice | Alternatives considered with pros & cons, justifications for each choice made, what was rejected and why |
| Workflow / how-to | Exact tools and commands as used, example usage where relevant, pitfalls hit during the session |
| Plan / implementation | Ordered steps with timeline, the effect each change causes (good and bad), a task checklist with `- [ ]` items to tick off later |
| Troubleshooting / incident | Symptoms, root cause, fix, how it was confirmed working |
| Reference | Verified date for every fact, authoritative online sources |

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

## Procedure for adding a new note

1. Derive target folder (basename of cwd; user overrides win); `mkdir -p` if needed.
2. Check the folder + vault-wide filename uniqueness; update an existing note instead of duplicating.
3. Write the note with the `write` tool, following the template and type checklist.
4. Verify the write (`head` the file or read it back) and report the full path to the user.
5. If updating an existing note, preserve its structure and frontmatter date semantics (keep original `date`, add an `updated:` key).

## Never

- Write outside `~/obsidian/pi_knowledge/`.
- Delete or restructure other notes unless explicitly asked.
- Trigger this skill for note-taking destinations other than this vault (repo-local docs/READMEs are ordinary file edits, not skill work).
- Pad notes with unverified filler to match a template — omit sections that don't apply.
