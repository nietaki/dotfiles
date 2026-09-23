---
description: "[parent-run] create or improve a pi-prompt-template-model prompt template via guided interview"
argument-hint: "<template-name> [notes]"
model: openrouter/openai/gpt-5.6-sol, openrouter/openai/gpt-5.6-luna-pro, opencode-go/deepseek-v4.1-flash
skill: prompt-template-authoring
---

You are authoring or revising one Pi prompt template for the
`pi-prompt-template-model` extension. Target template name: `$1`

Any extra freeform notes from the operator (may be empty): ${@:2}

If the name did not come through (empty, or left as a literal placeholder), ask
for it before anything else. Before any file access, require the supplied name to
match `^[a-z0-9]+(?:-[a-z0-9]+)*$`; reject slashes, `..`, file extensions, and
leading or trailing hyphens. The filename becomes the slash command
(`foo-bar.md` → `/foo-bar`). Check the installed package's current
`RESERVED_COMMAND_NAMES` in `pi-prompt-template-model/prompt-loader.ts`, plus
existing Pi commands and templates, rather than relying on a short hardcoded
reserved-name list.

## 1. Establish the mode

User templates live in `~/.pi/agent/prompts/`. In this setup that path is a
homeshick-managed symlink into the dotfiles repo, so resolve it before touching
anything:

```bash
ls -la ~/.pi/agent/prompts
readlink -f ~/.pi/agent/prompts
```

- Template file already exists → **improvement mode** (skip to §5).
- No such file → **creation mode** (§2–§4).
- Never write into a project's `.pi/prompts/` from this command, and never
  create, replace, or rename anything directly under `$HOME` — write only at the
  repo path the symlink resolves to. If a same-named template exists in the
  current project, say so and confirm the operator wants the user-level file.

## 2. Interview the operator

Be conversational. Use `ask_user_question` in focused rounds rather than one
monologue, and never fill a gap by guessing. Do not stack questionnaires: after
each structured round, summarize what the answers established and discuss the
next recommendation before asking again. Recommendations are welcome — put the
recommended option first with "(Recommended)" — but every decision needs the
operator's confirmation. Fold the operator's opening notes into the interview:
ask about a topic only when it is genuinely still open.

Cover these topics, in this order:

1. **Scope.** What the template must do, what it must not do, the concrete
   deliverable, who consumes the output, and how much latitude the agent gets.
   Distill this into the one-sentence purpose that becomes `description:`.
2. **Model.** Read `enabledModels` from `~/.pi/agent/settings.json` live with
   the read tool (the dotfiles repo copy at
   `~/.homesick/repos/dotfiles/home/.pi/agent/settings.json` is the same file) —
   do not rely on a memorised list. Suggest the model that fits the work and say
   why: capability, context, and thinking budget. Discuss subscription or
   pay-as-you-go trade-offs only when the current configuration or operator
   provides verified billing information; never infer billing from a provider
   name alone. Offer a comma-separated fallback chain when availability matters.
   Models are tried in order when switching, but if the session is already on
   any listed candidate the extension retains that model. Always write explicit
   `provider/model-id` pairs — bare ids resolve through an unrelated provider
   priority list and can land on the wrong account. Then ask whether `thinking:`
   should be pinned (`off`, `minimal`, `low`, `medium`, `high`, `xhigh`, `max`);
   omit the key to inherit the session level. Mention `restore: false` only if
   the operator wants the switch to stick. If §2.4 selects delegation, revalidate
   every candidate against strict `subagents.modelScope`: it must satisfy both
   the global `allow` list and the selected role's `agents.<role>.allow` list.
   Never suggest a delegated role/model pairing that would be rejected before
   execution.
3. **Invocation contract.** How they will actually type the command. Decide
   whether all arguments pass through as one blob, or whether positional
   placeholders and slices are needed, whether shell-style quoting matters, and
   which arguments deserve defaults. Set `argument-hint:` to match: `<angle
   brackets>` for required, `[square brackets]` for optional. Confirm the
   behaviour when an expected argument is absent — ask, fall back to a default,
   or refuse.
4. **Execution shape.** Default is inline: no `subagent:` key, the template runs
   in the current session. Ask whether it should delegate. If yes:
   - which agent — derive the live roster from enabled (not `disabled: true`)
     `subagents.agentOverrides`, `subagents.modelScope.agents`, and custom files
     in `~/.pi/agent/agents/`; verify the role exists and its model scope before
     referencing it;
   - `inheritContext: true` (child gets a fork of this conversation) versus
     independent context (`inheritContext` omitted/false). Independent context
     is right for review, scans, and validation; inheritance is right when the
     child needs this session's history. Do not add `fresh:` for this choice —
     `fresh` is a separate loop context-collapse setting;
   - whether `cwd:` (absolute path) or `parallel: N` (N ≥ 2) apply.
   Say plainly that a delegated template cannot ask the operator questions
   mid-run, so anything still needing an interview belongs inline.
5. **Skills — always ask.** If the work needs domain instructions (browser
   driving, TDD, homeshick, subagent authoring, etc.), set `skill:` instead of
   hoping the agent selects it. Inline runs inject each resolved skill body
   before the task; delegated runs bind resolved skill names to the outbound
   subagent request rather than prepending their bodies. Confirm every name
   resolves in the real skill directories (`~/.agents/skills/`,
   `~/.pi/agent/skills/`, project `.pi/skills/`, package-provided skills); an
   unresolvable skill name fails the whole command.

Then apply judgement about the extension's remaining features and raise only the
ones this template actually benefits from — never add machinery just because it
is available:

- Deterministic pre-steps (`run:` shorthand or the nested `deterministic:` block
  with `handoff:`) for establishing repo state before the model turn. Mutually
  exclusive with `subagent`, `chain`, `loop`, and `parallel`.
- `loop:` with `rotate:`, `converge:`, `fresh:` for iterative passes.
- `chain:` pipelines (`a -> b`, `parallel(a, b)`, `chainContext: summary`) for
  reusable multi-step flows. Chain templates ignore the body and `model:`; steps
  must not reference other chains.
- `bestOfN:` compare blocks (workers/reviewers/`finalApplier`; `finalApplier`
  requires `worktree: true`).
- `<if-model is="...">` conditionals for genuinely model-specific prose.
- `boomerang: true` to collapse context after a review-style prompt.

## 3. Recap, then get approval

Before writing anything, restate the spec compactly: filename and command name,
`description:`, `argument-hint:`, model / thinking / restore choices, two or
three concrete example invocations with real arguments, execution shape (inline
vs delegated, and why), skills, and any extra features with the reason each one
is justified. Ask the operator to confirm or amend. Do not create or modify the
file until they approve.

## 4. Write the template

Write at the resolved repo path under `prompt_sources/<name>.md`. Rules:

- Frontmatter carries only the fields this template uses, plus `description:`
  always. Tag the description with its surface — `[parent-run]` for
  coordinator/parent-voice bodies that ask questions or use `@file` mentions,
  `[child task]` for self-contained single-role bodies.
- The body is instructions to whoever runs the template, using exactly the
  argument placeholders agreed in §2.3, and stating what to do when an argument
  is missing.
- No `@file` mentions in a body intended for delegated or child runs — mention
  expansion only happens in the parent prompt.
- Nested YAML blocks keep valid indentation; the frontmatter must sit between
  two `---` lines.
- After writing, re-read the file and verify the frontmatter parses and the
  placeholders match the agreed contract.

## 5. Improvement mode (template already exists)

Read the existing template in full first. Then review it against the
`prompt-template-authoring` skill and report concrete findings, each with a
proposed edit:

- Model choice vs the live `enabledModels` list; for delegated templates, model
  compatibility with global and per-role `subagents.modelScope`; missing
  provider prefix; misunderstood active-model fallback semantics; no fallback
  where availability matters; unpinned `thinking:`.
- Missing or vague `description:` / absent `argument-hint:` / wrong bracket
  convention; unsafe or colliding command name; argument slots that silently
  drop input or lack defaults.
- Execution shape problems: undelegated heavy work, `subagent` without a
  deliberate inherited-vs-independent context choice, misuse of `fresh:` for
  subagent context, references to missing or disabled agents, missing
  `[parent-run]` / `[child task]` tag, `@file` mentions in a child-task body.
- Missing `skill:` where domain instructions would clearly help, unresolved
  skill names, or claims that delegated runs prepend skill bodies.
- Feature misuse: deterministic steps combined with `subagent`/`chain`/`loop`,
  `worktree` without a `parallel()` step, `body` or `model:` on a chain template,
  per-step `--loop` inside a parallel group.
- Body quality: assumptions, missing failure handling, unclear deliverable.

Present the findings, then explicitly ask whether the operator has specific
problems in mind that should take priority. Quote what you propose to change
before and after. Apply only approved edits and leave the rest of the file
untouched.

## 6. Hand it back

Show the finished file contents and ask for feedback; revise if asked. Then
offer to make it live and run these only on approval:

```bash
git -C ~/.homesick/repos/dotfiles add home/.pi/agent/prompt_sources/<name>.md
hslink
```

homeshick links only git-tracked files, so an unstaged new template is silently
skipped. Finish by telling the operator to run `/reload` in active sessions, and
to smoke-test the command with a realistic argument set (`pi -p "/<name> …"`
works for print-mode checks).
