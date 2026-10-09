# Bash Guidelines

- This machine is macOS with BSD command-line tools: GNU-only flags fail (`cat -A`, `grep -P`, `sed -i` without a suffix argument, `readlink -f` on old systems). Use `od -c`/`xxd` for invisible characters, `rg` for PCRE, and `sed -i ''` for in-place edits.
- Outside the cwd, bash only gets the read carve-outs (`~/.pi`, `~/repos`, `~/go/pkg/mod`, `~/bin`), and only for commands the gate can prove are reads. `ls`, `ls -la` (use it to see symlink targets), `cat` and `head` work. Commands it can't prove are reads are denied under `path` (rule `~/.pi/*`) or `external_directory` (rule `*`). Seen denied: `jq <file>`, `readlink`, `test -r`, and unknown scripts given a path argument. One such token denies the whole compound command, so split it. For file contents prefer the `read`/`grep`/`find` tools or the repo path `home/.pi/...`. Run `~/bin` scripts by bare name, not by full path.

- Don't write custom commands in situations where built-in tools like `grep`, `find`, `ls`, `read` would do the trick
- `find` joins predicates with `-o` at LOW precedence: a bare `expr1 -o expr2` applies `expr2` to the whole tree, not just `expr1`'s scope. Parenthesize the disjunction (`\( ... -o ... \)`), keep shared filters outside it, and PRUNE heavy dirs — `-not -path '*/.venv/*'` only suppresses output while `find` still walks every file in it; `-prune` stops the traversal. Seen bad → noisy: `find home -path '*/.pi/*' -o -iname '*pi*'` returned `home/.agents/skills/pdf-reader/.venv/bin/pip`, `pip3`, `site-packages/pip`. Good:
  ```bash
  find home \( -path '*/.git' -o -path '*/.venv' -o -path '*/node_modules' \) -prune -o \
    \( -path '*/.pi/*' -o -iname '*pi*' \) -print
  ```
  For repo filename discovery prefer `rg --files home | rg 'PATTERN'` — it respects ignore files and needs no pruning flags.
- If the workspace root contains a `Makefile`, prefer using the existing make targets over ad-hoc bash commands (when relevant targets exist)
- Prefer relative paths from the workspace root over equivalent absolute paths
- Don't modify files outside of the workspace and the temp directory
- Don't overuse `&&` to join bash commands that could be executed sequentially
  - For example prefer `git add .` and a separate `git commit -m "commit msg"` over `git add . && git commit -m "commit msg"`
  - **DO** use the `&&` for your investigations, like `command_that_could_fail && echo "command succeeded"`
- Always set (sensible) timeouts in the `bash` tool. Use 300 seconds by default and only set longer timeouts for operations that you expect to be long-running.

## Standard programs

Prefer using the standard set of programs over equivalent alternatives.

Standard programs:

- `cat`
- `cp`
- `docker`
- `echo`
- `find`
- `head`
- `git`
- `go`
- `grep`
- `jq`
- `ls`
- `make`
- `mix`
- `mkdir`
- `rg`
- `tail`
- `tar`
- `which`

Prefer `grep` over `sed` when usable, as `sed` might be blocked by the permission system in siutations where `grep` wouldn't
