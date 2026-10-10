---
name: github-mcp
description: "Work with GitHub through the two local github-mcp-server entries configured in ~/.pi/agent/mcp.json under Pi's built-in MCP support: `github-readonly` for reads and `github-personal-engineering` for the write-capable issue-to-PR workflow. Use when reading or searching issues, pull requests, reviews, repository source, or GitHub Actions CI, or when creating, commenting on, updating, or triaging issues and pull requests in repositories owned by the personal GitHub account."
---

# GitHub MCP

The two GitHub entries use Pi's built-in MCP support and expose their tools
through `codemode`. They run the same server with different tokens and tool
surfaces.

## Discover and call tools

MCP tools are registered as `mcp__<server>__<tool>`. Discover the current tool
and schema with `searchTools()` and `describeTool()` rather than guessing names
or parameters. Use the hyphenated namespace form, such as
`mcp__github-personal-engineering`, for discovery and permission rules. Within
codemode, either the hyphenated registered name or sanitized underscore
identifier resolves.

```js
const matches = await searchTools("search GitHub issues", {
  namespace: "mcp__github-readonly",
  limit: 5,
});
return matches;
```

A codemode script receives the complete MCP `CallToolResult`. Check `isError`
before consuming `structuredContent` or `content`. A permission-gated call may
throw instead, so use `try/catch` when a denied write needs explicit handling.
Filter large results inside codemode and return only the fields needed by the
workflow. Keep search pages small and narrow the query rather than requesting a
large payload by default.

Use the local working tree for bulk source exploration when the repository is
already checked out; reserve GitHub content reads for remote-only evidence or
small targeted files.

## Trust successful writes

When a GitHub write returns a non-error result reporting success, treat the
operation as complete and use identifiers and URLs from that result. Do not read
the entity back merely to verify a successful write. Reads required before a
safe read-modify-write operation are unaffected.

After a timeout or otherwise ambiguous failure, inspect the relevant remote
state before retrying so a completed write is not duplicated. A permission
rejection, `isError` result, or thrown call is not success.

## Choose the correct entry

- Use `github-readonly` for general GitHub reads, source inspection, searches,
  and CI investigation.
- Use `github-personal-engineering` for the personal-account issue-to-PR
  workflow, including its reads. Do not silently switch entries after an error.

The engineering token covers personal-account repositories only. A 403 or 404
for an organization-owned repository or outside collaboration is a scope
failure, not a reason to retry through another entry.

## Respect the server boundary

The engineering entry intentionally excludes operations that must remain human
or local-git responsibilities. Do not route around a missing tool:

- Pull-request merges remain a human decision.
- Repository-content writes, branch creation, forks, and repository creation
  belong to local git or an explicitly different workflow.
- Updating a PR branch through GitHub is unavailable; synchronize locally and
  push under the applicable git policy.

Workflow dispatch is callable when its discovered tool is present, but it still
requires authority from the operator or calling workflow and any applicable
permission-system approval.
