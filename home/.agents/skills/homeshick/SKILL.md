---
name: homeshick
description: "Link, unlink, and troubleshoot dotfiles managed by homeshick in the nietaki dotfiles repo using hslink and hsunlink. Use when creating, editing, renaming, or deleting files under the repo's home/ tree, when a newly created config does not appear in $HOME, when $HOME dotfiles are broken or dangling symlinks, or whenever homeshick, dotfiles, hslink, or hsunlink are mentioned. Covers the git-staging requirement: homeshick only links git-tracked files, so new or renamed files must be staged before hslink."
---

# Homeshick Dotfiles Management

This skill covers linking and unlinking dotfiles managed by homeshick.

## Critical: Files Must Be Staged

**Homeshick only links files that are tracked by git.** Before running `hslink`, ensure your new or renamed files are staged:

```bash
git add home/path/to/file
```

Unstaged files will be silently skipped during linking.

## Link Dotfiles

Use `hslink` to create symlinks from the dotfiles castle into `$HOME`:

```bash
hslink
```

This runs `homeshick link dotfiles` and symlinks all git-tracked files from `home/` into your home directory.

**Common workflow:**
1. Edit or create files in `home/`
2. Stage them: `git add home/...`
3. Link them: `hslink`

## Unlink Broken Symlinks

Use `hsunlink` to find and remove dangling symlinks left behind when dotfiles are deleted or renamed from the repo:

```bash
hsunlink          # List broken links, then delete them
hsunlink -l       # List only, delete nothing (dry-run)
```

**When to use:**
- After deleting files from the dotfiles repo
- After renaming files in the repo
- When troubleshooting missing dotfiles

The command finds broken symlinks in `$HOME` that point to `*dotfiles*` paths and removes them. It excludes `.git`, `node_modules`, `.venv`, `target`, and `~/.homesick` directories.

## Implementation Details

Both commands are standalone bash scripts linked to `~/bin/`:
- `home/bin/hslink` - wraps `homeshick link dotfiles`
- `home/bin/hsunlink` - finds and removes broken symlinks

They're pure bash with no zsh dependencies, avoiding shell wrapper warnings.

## Symlinked Directories (directory-level linking)

Some tools discover config by scanning a directory in a way that **skips
symlinked files** — e.g. Node's `fs.readdirSync(dir, { withFileTypes: true })`
followed by `entry.isFile()` returns `false` for symlinks. homeshick's default
per-file linking then makes the whole directory invisible to such tools.
Observed with `pi-subagents`' `/prompt-workflow` prompt discovery
(`~/.pi/agent/prompts/`, 2026-09-23; the upstream `readPromptFiles` has the
same bug on main).

Fix: let git track a **symlink as a file object** (mode `120000`) so homeshick
links the *directory path* in one shot:

```bash
mkdir -p home/path/prompt_sources          # real dir, real files
git mv home/path/prompts/… home/path/prompt_sources/
rmdir home/path/prompts                    # now-empty original dir
ln -s prompt_sources home/path/prompts     # relative symlink, same parent
git add home/path/prompts                  # recorded as 120000 blob
git ls-files -s home/path/prompts          # verify mode is 120000
hslink                                     # $HOME/path/prompts -> repo symlink
```

Path resolution chains through both hops (`$HOME/...` → repo symlink → real
dir), so tools see regular files. Works on fresh clones identically: checkout
materializes the `120000` blob as a real symlink (macOS/Linux; Windows needs
`core.symlinks` + privileges).

Notes:

- If `$HOME` already holds the old per-file **directory** at that path,
  plain `hslink` conflicts; `hslink --force` replaces it with the single
  symlink. On a fresh machine it links in one step, no `--force`.
- homeshick still links every tracked file under `home/`, so it also creates
  a redundant `$HOME/path/prompt_sources/` of per-file symlinks. Harmless;
  to avoid it, keep the real directory outside `home/` (castle root) — the
  relative symlink still resolves through the repo checkout.
- In this repo today: `home/.pi/agent/prompts -> prompt_sources`.

## Performance Considerations

Both `hslink` and `hsunlink` take about a minute to run, so don't run it in situations where it's not needed.
