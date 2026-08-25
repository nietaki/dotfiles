---
description: Creates TASKS.md template in project root if it doesn't exist. Does not ask questions or modify existing files.
mode: subagent
model: opencode-go/qwen3.7-plus
steps: 5
color: secondary
permission:
  edit: allow
  read: allow
  glob: allow
  bash: deny
  question: deny
  task: deny
  todowrite: deny
  todoread: deny
  lsp: deny
  dash: deny
  github-readonly: deny
  webfetch: deny
  websearch: deny
  codesearch: deny
  trmnl-plugin: deny
  github-notifications: deny
---

Check if TASKS.md exists in the project root using `glob` or `read`.

If it exists, report "TASKS.md already exists" and stop.

If it does not exist, create it with this exact content:

```markdown
# Tasks

## [Task title]

[Freeform description of what needs to be done]

### Acceptance Criteria

- [Criterion 1]
- [Criterion 2]

### Dependencies

- [Prerequisite work or libraries to integrate, or "None"]

## Notes
```

Do not ask questions. Do not modify existing content. Do not explore the codebase. Only check for the file and create the template if missing.
