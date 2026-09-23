---
description: "[parent-run] Create a polished, shareable Obsidian note from the current session, guided by optional focus and must-include context."
argument-hint: "[focus and must-include guidance]"
model: "openrouter/openai/gpt-5.6-luna-pro, opencode-go/qwen3.8-flash"
thinking: medium
skill: obsidian-note
---
Create or update an Obsidian knowledge note that captures the reusable learnings from this session. Produce a self-contained, polished document suitable for sharing; do not write a chronological summary of the conversation.

The operator's optional focus and must-include guidance is:

$@

If the guidance above is empty, ask whether to proceed with the suggested default: capture the session's reusable learnings using your judgment about what will remain valuable. Do not write the note until the operator answers.

If guidance is present, treat it as emphasis and required coverage, not as a scope restriction unless the operator explicitly narrows the scope. Use the session as the source of truth and follow the loaded `obsidian-note` skill. Do not perform new research merely to enrich the note; record unresolved gaps as open questions.

Write or update the primary note. You may make small edits to related index or linking notes only when they materially improve discoverability; do not reorganize, rename, or broadly revise the vault. When finished, verify the written files and report the full path of the primary note plus any related notes changed.
