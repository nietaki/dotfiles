# AGENTS.md

## Dotfiles managed with homesick

This repo is the **source of truth** for user `nietaki`'s dotfiles. It is a [homesick](https://github.com/rails/homesick) dotfiles repo: files under `home/` get symlinked into `$HOME` by `homesick link dotfiles`.

**Always edit the files in this repo, never the dotfiles directly.** The entries in `$HOME` (e.g. `~/.pi/`, `~/.config/`) are symlinks pointing back into this repo's `home/` tree — editing them edits the repo file *through* the symlink, but creating or replacing files at those locations (editors that write-and-rename, tools that overwrite configs) can silently break the symlink and detach the file from version control. If a file does not exist here yet, create it under `home/` in the corresponding path here, stage it, and relink — do not create it in `$HOME`.

**Important: `homesick link` only links files that are tracked by git (staged or committed).** Any new or renamed file must at least be staged before linking:

```bash
git add home/path/to/new-file      # or commit it
homesick link dotfiles             # now the new file gets symlinked into $HOME
```

Untracked files are silently skipped — so if a newly created config doesn't show up in `~`, check `git status` first.

Guidelines:

- Always `git add` newly created files under `home/` as part of finishing a config change (do not commit unless asked).
- After staging, run `homesick link dotfiles` to apply.
- To add an entire new directory of config, stage the directory: `git add home/.foo/`.
