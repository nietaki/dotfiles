---
name: best-practices
description: Find best practices for a given tech stack when implementing new functionality.
---

## What to do

Use the search and documentation tools configured in this session (e.g. Brave, Exa, or other MCP servers — discover them with the MCP search tool if unsure) to research the best-practice approaches to solving the problem at hand. If external research is unavailable, state that limitation rather than guessing.

The best-practice might be a library to use, a standard way to achieve a given goal in the programming language, or a customary design pattern when there's more than way to achieve a given goal.

### Research protocol

Consult sources in this priority order:

1. The project's own conventions, docs, and existing code.
2. Official documentation, specifications, and maintained reference implementations of the stack in question.
3. Issue discussions and well-regarded open-source code for practical trade-offs.
4. StackOverflow threads, reddit threads, and engineering blog posts — supplemental evidence only, not authoritative defaults.

Bad sources are marketing materials and generic listicles aimed at inexperienced engineers.

**Stopping criterion:** Stop once you can name the realistic options, the constraints that separate them, and the decision criteria. Don't keep iterating for marginal detail.

### Presenting research results

After performing the research, describe the alternatives with their advantages and disadvantages, along with your suggestion. Cite the URL of every source that materially affected the recommendation, with a date for time-sensitive claims. If no reliable external source was found, say so. Prefer unordered lists over long paragraphs (whenever reasonable).

For small, easily-contained approaches provide example code snippets based on existing code - don't try to adapt them to the specifics of the current project (yet).

In some cases, the research results don't need to be long-winded - sometimes the user isn't very experienced
with a given library or programming language and just needs a simple example of how things are usually done, without
diving into alternatives and minute trade-offs.

If there are any important caveats to the proposed approaches that could impact the "right" decision - make sure to mention them. The caveats could be related to, for example, performance implications, causing tight coupling, ease of refactoring, vendor lock-in, or viral licensing implications.

## When to use the skill

Use when planning the implementation of distinctly new functionality/system in a given project.
Do not use when there's existing patterns in the repository that can be followed.

Also use when the user asks for you to research best practices.

