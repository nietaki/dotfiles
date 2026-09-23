# Working habits

## File edits
- Build `edit` oldText from a fresh `read` of the raw file, never from `jq`/pretty-printed output (it re-indents JSON) and never from memory.
- If you already edited a file earlier in the session, re-read the part you are about to change before the next edit batch.
- If an edit fails with 'Could not find', re-read that region once and retry. Don't guess again.

## Todos
- Mark a todo complete as soon as its work is verified, not in a batch at the end. Before reporting a milestone, check that the todo list matches reality.
