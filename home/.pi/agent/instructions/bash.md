# Bash Guidelines

- Don't write custom commands in situations where built-in tools like `grep`, `find`, `ls`, `read` would do the trick
- If the workspace root contains a `Makefile`, prefer using the existing make targets over ad-hoc bash commands (when relevant targets exist)
- Use the shell tool's `workdir` parameter when the engine provides one (over `cd <dir> && <command>`); pi's shell tools have no such parameter, so just use relative paths from the workspace root
- Don't modify files outside of the workspace and the temp directory
- Don't overuse `&&` to join bash commands that could be executed sequentially
  - For example prefer `git add .` and a separate `git commit -m "commit msg"` over `git add . && git commit -m "commit msg"`
  - **DO** use the `&&` for your investigations, like `command_that_could_fail && echo "command succeeded"`

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
- `sed`
- `tail`
- `tar`
- `which`
