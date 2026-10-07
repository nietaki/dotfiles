---
name: brainstorm
description: Collaboratively explore and refine ideas, plans, designs, or approaches. Use when the operator wants to brainstorm alternatives, clarify a topic, examine trade-offs, or develop a shared understanding.
---

# Brainstorm

## Purpose

A brainstorming session should help the operator and assistant:

- develop a shared understanding of the topic, its goals, and its boundaries
- establish shared, consistently used terminology for important concepts, entities, and processes
- uncover assumptions, unknowns, challenges, and risks, along with possible mitigations
- explore alternatives, their strengths and weaknesses, and the trade-offs between them
- reach actionable clarity while explicitly retaining questions that do not need to be resolved yet

## Process

Use the following phases adaptively rather than as a mandatory checklist. Shorten, revisit, or skip phases when the discussion calls for it.

### 1. Frame

Start at a high level. Restate your understanding of the topic and establish the relevant goals, scope, constraints, and level of abstraction. Do not interrogate the operator about information that is already clear or immaterial.

Before asking questions that available evidence can answer, inspect relevant sources such as the codebase, documentation, history, configuration, or authoritative external sources. Run small, safe experiments when they can efficiently verify uncertain behaviour.

Distinguish verified facts, assumptions, tentative ideas, and agreed conclusions.

### 2. Explore

Work through the topic from a top-down perspective, tackling one important theme at a time. Make the discussion collaborative: contribute ideas, alternatives, implications, and recommendations instead of only asking questions.

For consequential choices, explain the viable alternatives and give your recommended option with its rationale. Explore details when they materially affect the goals, risks, feasibility, or trade-offs, or when the operator asks to go deeper.

### 3. Converge

Identify where the discussion supports a conclusion, decision, or narrower set of options, without forcing every open question to be resolved.

When an explicit decision, preference, or clarification from the operator is needed to proceed, **use the `ask_user_question` tool** instead of ending a message with a plain-text question. Provide enough context before invoking the tool, make the options and trade-offs clear, and use answer descriptions or previews when useful. Do not batch dependent questions. Ordinary conversational prompts are fine when inviting open-ended contributions and no explicit choice is required.

During longer sessions, periodically restate the conclusions reached, important trade-offs, and remaining open questions so that the discussion maintains continuity.

### 4. Synthesize

When the important themes appear sufficiently explored, say so and offer to:

- summarise the shared understanding
- continue exploring a remaining theme
- identify follow-up tasks

Do not force closure if the operator wants to continue. When a summary is requested, include the relevant conclusions or decisions, their rationale, major trade-offs, acknowledged risks, unresolved questions, and possible next steps.

## What not to do

- Do not assume the operator's goals or intentions; present your understanding and ask for clarification when a mistaken assumption would matter.
- Do not try to specify every detail or resolve every unlikely edge case; stay at the operator's chosen level of abstraction unless a detail is crucial.
- Do not make unsubstantiated guesses when a reasonable source of truth is available; research or test the behaviour when doing so is relevant and proportionate.
- Do not try to establish everything at once through wall-of-text messages; work through one important theme at a time.
- Do not manufacture answers for every question; explicitly leaving some questions open is a valid outcome.

## Situation-specific prompts

Select only the prompts relevant to the topic. These examples are a menu, not a required checklist, and the same process applies to technical and non-technical discussions.

### A proposed software feature

- goals, non-goals, and acceptance criteria
- constraints that any acceptable approach must fulfil
- integration points and the complexity of those integrations
- useful libraries, established patterns, and applicable best practices
- security, compatibility, migration, operational, and maintenance implications
- implementation effort and the trade-off between an exploratory prototype and a production-grade solution

### A Pi extension, tool, skill, prompt, or workflow

- goals, non-goals, and priorities
- relevant Pi guidance and established best practices
- integration points with the rest of the harness
- interaction and failure modes
- optional configuration and appropriate defaults

### A strategy, process, or non-technical plan

- desired outcomes, non-goals, stakeholders, and audience
- assumptions, constraints, values, time, and financial cost
- available approaches and their likely benefits, drawbacks, and robustness
- reversibility and the cost of changing direction
- risks, evidence that could reduce uncertainty, and indicators of success
