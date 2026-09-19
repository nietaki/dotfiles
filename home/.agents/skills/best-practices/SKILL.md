---
name: best-practices
description: Find best practices when for a given tech stack when implementing new functionality.
---

## What to do

Use the websearch and webfetch tools (plus any relevant MCPs) to research the best-practice approaches to solving the problem at hand.

The best-practice might be a library to use, a standard way to achieve a given goal in the programming language, or a customary design pattern when there's more than way to achieve a given goal.

Iterate until you have a good idea about the range of available options.

Good sources of this type of information are specific StackOverflow threads, reddit threads, blog posts on software engineering blogs, and reference code in popular open-source GitHub repos. Bad sources are marketing materials and generic listicles aimed at inexperienced engineers.

### Presenting research results

After performing the research, describe the alternatives with their advantages and disadvantages, along with your suggestion. Prefer unordered lists over long paragraphs (whenever reasonable).

For small, easily-contained approaches provide example code snippets based on existing code - don't try to adapt them to the specifics of the current project (yet).

In some cases, the research results don't need to be long-winded - sometimes the user isn't very experienced
with a given library or programming language and just needs a simple example of how things are usually done, without
diving into alternatives and minute trade-offs.

If there are any important caveats to the proposed approaches that could impact the "right" decision - make sure to mention them. The caveats could be related to, for example, performance implications, causing tight coupling, ease of refactoring, vendor lock-in, or viral licensing implications.

## When to use the skill

Use when planning the implementation of distinctly new functionality/system in a given project.
Do not use when there's existing patterns in the repository that can be followed.

Also use when the user asks for you to research best practices.

