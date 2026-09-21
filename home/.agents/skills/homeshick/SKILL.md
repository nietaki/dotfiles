---
name: homeshick
description: Link, unlink, and troubleshoot dotfiles managed by homeshick in the nietaki dotfiles repo using hslink and hsunlink. Use when creating, editing, renaming, or deleting files under the repo's home/ tree, when a newly created config does not appear in $HOME, when $HOME dotfiles are broken or dangling symlinks, or whenever homeshick, dotfiles, hslink, or hsunlink are mentioned. Covers the git-staging requirement: homeshick only links git-tracked files, so new or renamed files must be staged before hslink.
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
