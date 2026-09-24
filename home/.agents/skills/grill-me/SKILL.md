---
name: grill-me
description: Interview the user about a proposed plan or design until reaching shared understanding.
---

## What to do

Interview me about the plan until we reach shared understanding — but only about **material** decisions. A question is material when the answer changes product scope, behavior, compatibility, security, migration, operations, or an irreversible architectural choice.

Walk the design tree branch by branch, resolving dependencies between decisions, asking no more than 3 questions at a time. For each question, provide your recommended answer.

Before asking anything, explore the codebase (and docs, history, config): if repository evidence or a sensible default can answer it, resolve it yourself and state what you found instead of asking.

**Record every decision** as you go: the choice made, its rationale, and the rejected alternatives worth remembering.

### Stopping rule

Stop the interview once all of these are agreed:

- [ ] Goals and non-goals
- [ ] Acceptance criteria (how we'll know it works)
- [ ] Major trade-offs and their rationale
- [ ] Remaining risks acknowledged

When I can't answer a low-level implementation question, don't grind — mark it as an open question for the implementer with your recommendation, and move on. List unresolved questions explicitly at the end rather than inventing answers.

## When to use the skill

Use when user wants to stress-test a plan, get grilled on some design choice, or mentions "grill me".
