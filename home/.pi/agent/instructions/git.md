# `git` Guidelines

## Terminology and precedence

A repository has one **main worktree** (the original working tree created by
`git clone` or `git init`) and may have additional **linked worktrees** created
with `git worktree add`.

A **protected branch** is any of the following:

- `main` or `master`;
- the remote's default branch, whatever its name;
- a branch identified as protected by project or operator instructions.

Protected-branch restrictions take precedence over linked-worktree autonomy. A
linked worktree must not be used to bypass the restrictions on a protected
branch. Explicit read-only, no-commit, or no-push instructions also take
precedence over the defaults below.

When uncertain whether the current directory belongs to the main or a linked
worktree, run:

```bash
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != true ]; then
    printf '%s\n' not-a-worktree
elif [ "$(git rev-parse --path-format=absolute --git-dir)" = \
       "$(git rev-parse --path-format=absolute --git-common-dir)" ]; then
    printf '%s\n' main-worktree
else
    printf '%s\n' linked-worktree
fi
```

Do not infer the worktree type only from the current path or from whether
`.git` is a file or directory.

## Main worktree and protected branches

When working in the main worktree, on any branch:

- Do not create commits unless explicitly asked.
- Do not push commits unless explicitly asked. Permission to commit does not
  imply permission to push.
- The agent may create a new topic branch and its corresponding linked
  worktree without separate permission. Do so without changing the main
  worktree's checked-out branch, index, or uncommitted files.
- The agent may publish a newly created branch only when every commit reachable
  from it is already present in up-to-date remote-tracking refs. A useful check
  is `git rev-list <branch> --not --remotes`, which must produce no commits.

Apply the same commit and push restrictions when a protected branch is checked
out in a linked worktree. An implementation request by itself is not permission
to commit or push in either restricted context; those operations must be
requested explicitly.

Never stash, reset, relocate, or otherwise manipulate the operator's
uncommitted main-worktree changes merely to populate a linked worktree. If work
must continue elsewhere, create the new branch and worktree from an appropriate
committed base and leave the existing state untouched.

## Autonomous linked worktrees

In a linked worktree on an attached, non-protected topic branch, the agent may
commit and push autonomously unless instructed otherwise:

- Decide when to commit and choose commit messages, while following repository
  conventions.
- Create coherent commits after proportionate tests and validation; do not
  commit every intermediate edit merely to push it quickly.
- Before each commit, inspect the status, untracked files, and staged diff.
  Stage only intended changes and check for secrets, credentials, generated
  artifacts, and throwaway files.
- Inspect the resulting commit, then push it promptly rather than leaving
  checked work local unnecessarily.
- Push to the configured upstream. For an agent-created branch with no
  upstream, create a same-name branch on the unambiguous primary remote and set
  it as upstream. If the writable remote or destination is ambiguous, ask
  rather than guessing.

Do not commit from a detached `HEAD`; first create or select an appropriate
non-protected topic branch.

## Published history

Prefer append-only history. Except for the narrow latest-commit cleanup case
below, do not rewrite published history during autonomous work. If a cleaner
history would require a squash, rebase, amend, or other rewrite, continue the
task with follow-up commits instead of pausing to request permission. Once the
functional work is complete, report the optional cleanup and what rewrite it
would require. Perform it only if the operator subsequently requests it.

On an autonomous, non-protected topic branch, the agent may amend the latest
commit to remove files accidentally included in that commit. If it has already
been pushed, first verify that the remote branch has not advanced independently,
then update it with `--force-with-lease`. Never use unconditional `--force`.
Use follow-up commits for ordinary corrections outside this narrow case.

If a pushed commit exposed secrets or credentials, stop further pushes and
report the exposure. Removing the file in a later commit or force-pushing a
rewrite is not sufficient incident response; credential rotation and any
history cleanup must be coordinated with the operator.

## Branch and worktree conventions

Linked worktree directories should be siblings of the main worktree. Form the
worktree directory name from the main worktree's basename, a hyphen, and a
portable form of the branch name:

```text
main worktree: /some/path/some-project
branch:        important-feature
worktree:      /some/path/some-project-important-feature

main worktree: /some/path/some-project
branch:        feat/add-users
worktree:      /some/path/some-project-feat-add-users
```

Replace `/` and any other characters that are not portable in a sibling
directory name with `-`; collapse repeated replacement hyphens and trim leading
or trailing replacement hyphens. Do not overwrite or silently reuse an existing
path when the resulting name collides with another worktree or directory.

When choosing a branch name, use a short descriptive work slug of at most four
words, unless project or operator conventions say otherwise. Conventional
prefixes and issue identifiers do not count toward the slug length. Examples:

```text
add-auth0-authentication
issue-42-add-auth0-authentication
feat/add-auth0-authentication
```

Creating a branch or linked worktree does not imply permission to delete it
later. Do not delete branches, tags, or worktrees, discard changes, or perform
other destructive cleanup unless explicitly asked. Optional cleanup should be
reported after the work rather than interrupting an otherwise autonomous
workflow.
