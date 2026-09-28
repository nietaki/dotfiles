# Working habits

## File edits
- Build `edit` oldText from a fresh `read` of the raw file, never from `jq`/pretty-printed output (it re-indents JSON) and never from memory.
- If you already edited a file earlier in the session, re-read the part you are about to change before the next edit batch.
- If an edit fails with 'Could not find', re-read that region once and retry. Don't guess again.

## Todo tool calls
The `todo` tool has a call contract that is not obvious from its name. Getting it wrong wastes turns on validation errors and silent wrong-task mutations.
- `create` REQUIRES a non-empty `subject`. Omitting it returns `Error: subject required for create`. Supply `subject` (short, imperative), plus `description` (long-form detail) and `activeForm` (present-continuous label) at creation so you do not have to patch them later.
- Before updating a task by numeric `id`, call `todo list` and copy the exact id from the output. Ids are assigned per create call and are not predictable from ordering — updating the wrong id silently mutates a different task (e.g. `#3` when you meant `#4`).
- Send exactly ONE status transition per `update`. Duplicate or replayed updates return `No change: #N already matches the requested values` — harmless but wasted. An `update` with no mutable field (only `id`) is rejected.
- When marking a task `completed`, change only its `status`. Do not piggyback `description`, `blockedBy`, `owner`, or `activeForm` edits for a DIFFERENT task onto a status update — each edit targets the task named by `id`.
- Use `addBlockedBy` / `removeBlockedBy` (additive merge) on `update`; do not resend the whole `blockedBy` array. Cycles are rejected.

## ask_user_question calls
- Each question `header` is a short chip/tag and is HARD-LIMITED to 16 characters — longer labels fail validation (`questions.N.header: must not have more than 16 characters`). Keep it to 1–2 words.
- Every question needs 2–4 options, each with a concise label and a description of the trade-off. Never author reserved labels (`Other`, `Type something.`) — they are appended automatically and rejected if typed.
- Batch up to 4 independent questions in one call; keep dependent questions sequential (one call after the previous answer is known).

## Todos
- Mark a todo complete as soon as its work is verified, not in a batch at the end. Before reporting a milestone, check that the todo list matches reality.
