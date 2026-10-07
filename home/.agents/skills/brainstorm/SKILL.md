---
name: brainstorm
description: How to engage in brainstorming session with the operator about a proposed plan/idea/design/approach until a shared understanding is reached.
---

## Purpose of the brainstorm

The goal of a brainstorming session is to:
- iron out any potential misunderstandings about the given idea to produce a clear picture
- highlight potential unknowns, challenges or risks and potentially establish mitigation options
- establish "ubiquitous language" for the key concepts/entities/processes
- find potential strong and weak points of the idea
- establish potential trade-offs of different approaches
- end up with a clear, actionable understanding of the topic

## How to brainstorm

Start at a high level, making sure you understand the general idea.
Afterwards discuss relevant subtopics, providing alternatives and your recommendations for key decisions.

Make it interactive, conversation-like - the goal is for both sides to contribute in reaching the understanding.

When the operator's decision or opinion is needed **Use the `ask_user_question` tool** instead of asking the questions in a message and ending your turn. Provide enough context before asking the question and use the `description` and `preview` fields for the answers when useful.

Signal when you think all key topics are covered and specified well enough to summarise the conclusions or decide on follow-up tasks, but remain open to more discussion based on the operator's suggestions.

## What not to do

- do not make assumptions about the operator's goals or intentions
  - instead, present your understanding, provide suggestions or list alternatives
- do not try to specify every single detail or resolve every unlikely edge-case
  - instead, stick to the level of abstraction provided by the operator, dig into specifics only when they seem crucial or if asked by the operator
- do not make unsubstantiated guesses when some source of truth is available
  - instead, use the web search and github search tools when relevant
  - run small script experiments when some behaviour can be safely verified this way without wasting too many turns
- do not try to establish everything at once with wall-of-text-type messages
  - instead go through the topics in a top-down perspective, tackling
- do not try to establish answers for all possible questions - some things can be left highlighted as open questions

## Situation-specific topics

Based on the subject of the brainstorming session, different topics might need to be covered. Here's some common examples:

### A proposed feature in the project

- goals and non-goals of the feature
- constraints - requirements an acceptable approach must fulfill
- integration points with the rest of the project and complexity of that integration
- libraries that could be helpful in the implementation
- efforts that might help maintaining best practices when building the feature
- complexity estimation of different approaches and sub-tasks

### A `pi` extension, tool, skill, prompt, workflow

- goals and non-goals, priorities
- what best practices suggest
- integration points with the rest of the harness
- optional configuration options

### A general approach to achieving a certain goal

- existing solutions, their popularity, complexity, robustness and financial cost
- different trade-offs and our priorities within these
  - that includes professional approach <-> quick-and-dirty spectrum

## When to use the skill

When a user wants to brainstorm or discuss a specific topic/feature/plan/approach.

