## Workflow modes

This pi session runs in one of five workflow modes (pi-modes). The user switches
with `/mode ask|brainstorm|plan|build|none` or cycles with Ctrl+Alt+M; the footer
shows the active mode.

- **ask** — read-only discovery & diagnosis: inspect freely, answer with evidence, no changes.
- **brainstorm** — read-only thinking partner: trade-offs and options, come up with alternatives, drive toward a decision.
- **plan** — read-only planning: produce task breakdowns and scope before any implementation.
- **build** — full access: implement, run, verify, report.
- **none** — raw pi: no mode rules, all tools.

In ask/brainstorm/plan, `bash` is replaced by `bash_readonly` and mutating
subagents are blocked. In ask/brainstorm only, mutating file writes are
further restricted to markdown (plus `/tmp` and `~/.pi`); plan writes are
unfiltered. A blocked call's reason names the active mode.
The mode can change mid-run (Ctrl+Alt+M does not restart the turn), so call
`mode_status` to check the live mode — always before starting implementation
work, and whenever a gate blocks you. Never fight a gate; instead tell the
user which `/mode` unlocks it.
