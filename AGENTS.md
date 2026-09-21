# AGENTS.md

## Dotfiles managed with homeshick

This repo is the **source of truth** for user `nietaki`'s dotfiles. It is a [homeshick](https://github.com/andsens/homeshick) dotfiles repo (a shell-native port of [homesick](https://github.com/rails/homesick) — the `~/.homesick/` directory name is historical): files under `home/` get symlinked into `$HOME` by `hslink` (a plain-bash wrapper around `homeshick link dotfiles`). The full workflow is documented in the homeshick skill at `home/.agents/skills/homeshick/SKILL.md`.

**Always edit the files in this repo, never the dotfiles directly.** The entries in `$HOME` (e.g. `~/.pi/`, `~/.config/`) are symlinks pointing back into this repo's `home/` tree — editing them edits the repo file *through* the symlink, but creating or replacing files at those locations (editors that write-and-rename, tools that overwrite configs) can silently break the symlink and detach the file from version control. If a file does not exist here yet, create it under `home/` in the corresponding path here, stage it, and relink — do not create it in `$HOME`. (Verified 2026-09-22: `pi install npm:<pkg>` edits `~/.pi/agent/settings.json` *through* the symlink and preserves it — but keep checking `ls -la` on any config a tool rewrites.)

**Important: `homeshick link` only links files that are tracked by git (staged or committed), and it links files individually** (there is no top-level `~/.pi` → repo directory symlink). Any new or renamed file must at least be staged before linking:

```bash
git add home/path/to/new-file      # or commit it
hslink                             # now the new file gets symlinked into $HOME
```

Untracked files are silently skipped — so if a newly created config doesn't show up in `~`, check `git status` first.

Guidelines:

- Always `git add` newly created files under `home/` as part of finishing a config change (do not commit unless asked).
- After staging, run `hslink` to apply.
- `homeshick` itself is a shell function loaded by the interactive rc files (`~/.zshrc`, `~/.bashrc`), so it does not exist in an agent's shell. Do **not** reach for `zsh -ic 'homeshick link dotfiles'` — this repo's pi permission system denies opaque shell wrappers (`zsh -ic`, `bash -c`) and steers you to the wrappers instead. Use:
  - `hslink` — `home/bin/hslink`, symlinked to `~/bin/hslink` (on PATH); execs homeshick's binary directly, no shell sourcing needed.
  - `hsunlink` — finds and removes dangling `*dotfiles*` symlinks in `$HOME` (dry-run with `hsunlink -l`); use it after deleting or renaming tracked files.
- To add an entire new directory of config, stage the directory: `git add home/.foo/`.
