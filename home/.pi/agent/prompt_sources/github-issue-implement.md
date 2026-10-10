---
description: "[parent-run] Plan, implement, push, and open a draft PR for a GitHub issue"
argument-hint: "[issue-url-or-number]"
model: opencode-go/qwen3.8-flash
thinking: xhigh
skill:
  - github-issues
  - github-mcp
  - tdd
---

Implement one GitHub issue from its prepared linked worktree. Use a published
implementation plan when available or establish one in this session, then
complete its tasks sequentially.

This workflow authorizes coherent commits and pushes from the prepared attached,
non-protected issue branch under applicable git policy, followed by creation of
one draft pull request. It does not authorize writing to the GitHub issue,
merging, deleting a branch or worktree, or rewriting published history.

The optional issue selector is:

<issue-selector>
$@
</issue-selector>

## Require the prepared workspace

This prompt must run from somewhere inside the prepared linked worktree. Resolve
its repository root with `git rev-parse --show-toplevel` and use that root for
all repository operations. Read all applicable project instructions, especially
git policy, then verify from git metadata rather than path-shape guesses that:

- the checkout belongs to one unambiguous GitHub `owner/repo`;
- it is a registered linked worktree, not the main worktree;
- `HEAD` is attached to a non-protected branch named
  `issue-<positive-number>-<nonempty-slug>`; and
- its configured remote and any upstream refer to the selected repository and
  leave no ambiguous push destination.

On a failed precondition, stop without switching branches, creating replacement
git state, changing directories to another checkout, or modifying files. Do not
repair setup silently.

Capture the issue number encoded in the branch. Inspect the current status,
local and upstream tips, remotes, recent relevant commits, and worktree
registration. Fetch the unambiguous repository remote before relying on remote
branch state or attempting a future push. Do not stash, reset, clean, overwrite,
or otherwise discard existing work.

## Resolve the issue and choose a plan

Follow **Resolve an issue for a repository-centered workflow**, **Fetch the
complete issue**, and **Discover proposed implementation plans** in the loaded
`github-issues` skill. Resolution order for this workflow is:

1. the explicit selector, parsed under the skill's selector rules;
2. the issue number encoded in the current branch; and
3. the remaining skill fallbacks, which should be needed only if earlier
   evidence proves unusable.

An explicit selector must match both the branch issue number and checkout
repository exactly. On mismatch, report every conflicting identity and stop.
Do not reinterpret the branch, search for another checkout, or continue against
unrelated source.

Select a sole matching plan automatically. When several plans match, require an
operator selection and recommend the newest without choosing it implicitly.
Retain the selected comment's URL, author, creation time, and complete body.

If no plan exists, use `ask_user_question` to ask whether the operator wants to
brainstorm collaboratively now or have the agent create the plan autonomously.
Do not invoke the separate brainstorming prompt or publish a plan comment. For
collaborative planning, load and follow the `brainstorm` skill and settle
implementation-blocking choices. For autonomous planning, inspect the issue and
repository, make routine choices without an approval round, and ask only when a
consequential ambiguity cannot be resolved safely.

Create a session-local plan according to **Implementation plan contract** using
the current pre-mutation `HEAD` as its snapshot. Record plan provenance as a
published comment, collaborative session plan, or autonomous session plan.
For a published plan, normalize absent or out-of-order optional sections locally
when its intent remains clear. Require at least one understandable, verifiable
implementation task; stop only when substantive omissions or conflicts prevent
safe execution.

## Reconcile the plan with current evidence

Before file mutation:

1. If the plan supplies a repository snapshot, resolve it and compare it with
   current `HEAD`, inspecting relevant intervening commits and diffs. Fetch the
   repository remote when needed; do not silently substitute another commit.
   If no usable snapshot is available, record that limitation and compensate
   with a careful inspection of current repository state and later discussion.
2. Reconcile every issue comment later than a published plan as required by the
   shared plan contract. A session-local plan must already reflect the complete
   issue discussion.
3. Verify the plan's material paths, symbols, conventions, tests, and
   assumptions against the repository, and identify work that already satisfies
   a task.

Continue autonomously when current evidence remains compatible with the planned
outcome and record material adaptations. If unavailable provenance, unrelated
history, an incorrectly based worktree, or current evidence creates a material
conflict, explain it and ask when an operator decision can resolve it safely;
otherwise stop rather than improvising a different scope.

Inspect all tracked and untracked working-tree changes before implementation.
When any exist, summarize their paths and apparent overlap with the plan, then
use `ask_user_question` to ask whether they are intentional issue work to
resume, unrelated work to preserve under explicit instructions, or a reason to
stop. Do not proceed without an explicit choice. Never discard the changes or
stage unrelated files merely to obtain a clean tree.

## Create and execute the implementation TODOs

Create one session TODO from every numbered implementation task. Use its
imperative title as the subject; include its objective, affected areas, work,
and validation expectations in the description; preserve plan order and add
only real dependencies. Briefly state the resulting sequence.

For each task, reconcile the plan with the complete issue, current repository,
project instructions, and established patterns. Implement only its coherent
scope, follow the loaded `tdd` skill when behavior is testable, and run the
specific validation needed to establish completion. Verify rather than redo
work already present. Do not begin the next task while the current task or a
required publication checkpoint is unresolved.

Repository evidence may justify deviations that preserve the planned outcome
and scope, follow stronger project constraints, or avoid unnecessary work.
Record material deviations and ask when a consequential ambiguity cannot be
resolved from authoritative evidence.

Prefer the plan, project documentation, established patterns, and nearby
examples over external research. Load `best-practices` only when the operator or
plan requests research, or implementation exposes a consequential choice that
the plan and project evidence cannot responsibly resolve. Do not relitigate a
settled decision unless it proves infeasible, unsafe, or materially stale.

## Commit and push coherent checkpoints

Treat a substantive completed plan task as a normal checkpoint candidate.
Combine tiny adjacent tasks when separate commits would obscure the change, and
split large tasks only at independently understandable, validated milestones.
Follow the applicable git policy for staging, diff inspection, validation,
committing, published-history handling, and pushing. Do not create empty,
knowingly failing, or incidental checkpoints.

If checkpoint publication remains unresolved, record it as a blocker and do not
start the next task. Ensure all intended issue work is committed and pushed
before final validation and PR creation.

## Validate, create the draft PR, and report

After all plan tasks are complete, run the plan's overall validation plus
practical relevant repository-wide checks. Create ordered corrective TODOs for
failures and handle them sequentially under the same implementation and
publication rules. Do not claim completion while required checks fail.

Verify the issue branch, upstream relationship, pushed commit set, and final
working-tree status. Identify any explicitly preserved operator changes and do
not represent the worktree as clean when it is not.

As the final step, load and follow `github-prs` to create the authorized draft
PR using the issue and implementation record. Create it only after all intended
commits are pushed. If PR creation remains blocked, report the pushed
implementation accurately without claiming the workflow completed.

After successful PR creation, report:

- the issue identity and plan provenance;
- completed tasks and key changes;
- created commits and pushed branch;
- tests and checks with outcomes;
- material deviations, preserved changes, risks, and follow-up work; and
- the draft pull request URL.

Do not write progress or completion comments to the issue or merge the pull
request.
