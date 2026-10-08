---
name: best-practices
description: Conditionally research current best practices when project evidence cannot resolve a consequential technical choice or the operator explicitly requests research.
---

# Best-practices research

## Decide whether research is warranted

Loading this skill provides a research procedure. It does not by itself mean
that external research is required.

Use the procedure when:

- the operator explicitly asks for best-practice research;
- distinctly new functionality lacks a suitable project precedent;
- a consequential implementation choice cannot be resolved from the approved
  plan, project documentation, existing code, or other authoritative local
  evidence; or
- current external facts could materially change the choice.

Do not perform external research when:

- an approved plan already resolves the decision and no contrary evidence has
  appeared;
- the repository contains a clear, applicable pattern;
- the question is a routine implementation detail; or
- research would merely validate an approach that is already adequately
  established.

When research is not warranted, continue the parent task without producing a
best-practices report. Do not use research to relitigate an approved decision
unless current evidence shows that it is infeasible, unsafe, or materially
stale.

## Research procedure

When the activation criteria above are met, use the search and documentation
tools configured in this session: the `pi-web-access` tools plus any applicable
MCP server tools available through the built-in `codemode` tool. List the
callable set with `ALL_TOOLS` or find a tool with `searchTools()` inside a
codemode script when necessary. If warranted external research is unavailable,
state that limitation rather than guessing.

The relevant practice might be a library to use, a standard facility of the
language or platform, or a customary design pattern for the problem.

Consult sources in this priority order:

1. The project's own conventions, documentation, and existing code.
2. Official documentation, specifications, and maintained reference
   implementations for the stack in question.
3. Issue discussions and well-regarded open-source code that illuminate
   practical trade-offs.
4. Stack Overflow or Reddit discussions and engineering blog posts as
   supplemental evidence only, not authoritative defaults.

Avoid marketing materials and generic listicles aimed at inexperienced
practitioners.

**Stopping criterion:** stop once the realistic options, the constraints that
separate them, and the decision criteria are clear. Do not keep researching for
marginal detail.

## Present the results

Describe the realistic alternatives, their advantages and disadvantages, and
your recommendation. Cite the URL of every source that materially affects the
recommendation, including a date for time-sensitive claims. If no reliable
external source was found, say so. Prefer concise unordered lists over long
paragraphs when reasonable.

For a small, self-contained approach, an illustrative code snippet based on the
project's style may be useful, but do not prematurely adapt it into the project
or begin implementation merely because research was requested.

Scale the explanation to the decision. A straightforward library or language
idiom may need only a short example, while a consequential choice should make
its trade-offs explicit. Call out caveats that could change the decision, such
as performance, coupling, migration cost, maintainability, vendor lock-in, or
licensing implications.
