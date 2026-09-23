// sessions-retro — pi-subagents workflow script
// Saved-workflow registry copy: ~/.pi/agent/subagent-workflows/sessions-retro/script.js
// (pi-subagents-workflows package). Canonical repo path:
// home/.pi/agent/subagent-workflow_sources/sessions-retro/script.js
//
// Two-stage session retrospective for ONE working directory:
//   enumerate (scout) -> parallel per-session digests (scout, fresh context,
//   each writes a bounded JSON file to /tmp) -> one strong-model synthesis
//   (reviewer, reads the JSON files, returns a ranked proposal board).
// File handoff keeps giant transcript text out of task strings and receipts.
//
// @args
//   cwd       string  required — the project whose sessions to review.
//                     pi stores them under ~/.pi/agent/sessions/--<path>--/,
//                     i.e. the absolute path with '/' replaced by '-'
//                     (verified 2026-09-23: /Users/nietaki/repos/grr-fyi ->
//                     --Users-nietaki-repos-grr-fyi--)
//   maxSessions number optional (default 4, capped 6) — newest-N session files
//
// LAUNCH: /workflow run sessions-retro cwd=/path/to/project
//   (or pi_subagent_workflow action=run, name=sessions-retro). The registry
//   injects its own `cwd` = the pi run directory, which is NOT args.cwd — the
//   project to review must be passed explicitly. Its runner passes only
//   {workflowScript, cwd} to pi-subagents, so no outer timeoutMs/deadline and
//   no raised spawn budget; use subagent({workflowScriptPath}) when you need
//   either. Always detached async.
//
// Budget: 1 + maxSessions + 1 children (<= 8; run cap 24, global concurrency 4).
// No `state` (launch without a mission is fine). Launch it with an explicit
// timeoutMs (async composites have no default), e.g. 3_600_000.
// PERMISSION NOTE: plain `ls ~/.pi/agent/sessions/` works for agents, but
// tree-walking variants (find/du) were denied by pi-permission-system
// (external_directory). Children inherit the same rules — enumerate uses ls
// only; degrade to found=false if a rule still bites, then add a narrow read
// rule rather than broadening the agent's reach.

if (typeof args !== "object" || args === null ||
    typeof args.cwd !== "string" || args.cwd.trim() === "") {
  throw new Error("sessions-retro: args.cwd is required — the working directory to review, e.g. \"/Users/nietaki/repos/grr-fyi\"");
}
const targetCwd = args.cwd.trim();
const maxSessions = Math.min(Math.max(Number(args.maxSessions) || 4, 1), 6);

// Every schema-bound child gets acceptance disabled. OMITTING `acceptance`
// makes pi-subagents infer a level ("attested" for scout/reviewer, "checked"
// for the writer role), which injects an "## Acceptance Contract" telling the
// child to "end with a structured acceptance report" — a property the
// structured_output tool does not expose, so the model stuffs it into `value`
// and validation retries (6 of 8 children in the 2026-09-23 smoke test).
// `false` -> level "none" -> nothing injected. Full write-up:
// ../feature-dev/script.js.
const NO_ACCEPTANCE = { acceptance: false };

function digestTask(item, idx) {
  const outFile = "/tmp/pi-retro-digest-" + idx + "-" + item.tag + ".json";
  return [
    "You are one digest worker of a session retrospective. Stay strictly within YOUR session file.",
    "YOUR SESSION: " + item.path + " (~" + item.sizeKb + " KiB).",
    "",
    "STEP 0 — GO/NO-GO.",
    "Inspect the head and tail of the file (first and last few entries).",
    "Set greenlit=false (write NOTHING, empty outputFile) if ANY of:",
    "- the file is a near-duplicate/continuation of another transcript of the same session,",
    "- it is trivially short (< ~10 user-visible turns),",
    "- it contains no real work (purely meta/testing/abandoned).",
    "Prefer greenlit=false when in doubt — the operator launches retros on purpose.",
    "",
    "STEP 1 — DIGEST (only if greenlit=true).",
    "Read the transcript in bounded windows with your read tool (it truncates per call; use",
    "offsets). If large, skim structurally first: grep for user-message and tool-error markers,",
    "then deep-read only the passages those point to.",
    "Extract AT MOST 6 concrete, evidence-backed findings — real friction observed IN THIS",
    "SESSION, not hypothetical improvements: repeated corrections, denied/failed tool calls,",
    "wrong-model symptoms (verbosity, refusals, cheap-model errors), missing context the agent",
    "re-learned every turn, wasted tokens, missing or stale skills/instructions.",
    "For each: category (model-policy | agents-config | instructions-skills | permission-rules",
    "| operator-behavior | other), what happened, 2-4 sentence evidence, session path + position",
    "(timestamp/entry), proposed change (specific, file-level where possible: settings key,",
    "skill text, instruction line), expected gain, confidence (low|medium|high).",
    "WRITE ONLY to " + outFile + " (your write tool):",
    "JSON exactly {\"session\":\"" + item.path + "\",\"findings\":[{\"category\":\"...\",\"what\":\"...\",\"evidence\":\"...\",\"position\":\"...\",\"proposal\":\"...\",\"gain\":\"...\",\"confidence\":\"...\"}]}",
    "with AT MOST 6 findings. No other files. Nothing in the report may leak secrets.",
    "Return greenlit=true and the outputFile path. If the write failed, set greenlit=false."
  ].join("\n");
}

const listSpec = {
  type: "object",
  additionalProperties: false,
  required: ["found", "files"],
  properties: {
    found: { type: "boolean" },
    note: { type: "string", description: "what was inspected / why nothing was found" },
    files: {
      type: "array",
      maxItems: 40,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["path", "mtime", "sizeKb", "tag"],
        properties: {
          path: { type: "string" },
          mtime: { type: "string", description: "ISO-ish or epoch — whatever ls reports" },
          sizeKb: { type: "number" },
          tag: { type: "string", description: "short slug of the file name (timestamp_id prefix), unique per file" }
        }
      }
    }
  }
};

const digestSpec = {
  type: "object",
  additionalProperties: false,
  required: ["greenlit", "outputFile"],
  properties: {
    greenlit: { type: "boolean", description: "false => wrote nothing" },
    outputFile: { type: "string", description: "absolute /tmp path written (\"\" when greenlit=false)" },
    skippedReason: { type: "string" }
  }
};

const boardSpec = {
  type: "object",
  additionalProperties: false,
  required: ["proposals", "unproposedGaps"],
  properties: {
    proposals: {
      type: "array",
      maxItems: 12,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["surface", "title", "change", "addresses", "evidence", "confidence", "greenlit"],
        properties: {
          surface: { type: "string", description: "model-policy | agents-config | instructions-skills | permission-rules | operator-behavior | other" },
          title: { type: "string" },
          change: { type: "string", description: "file-level, apply-ready: which file, what edit" },
          addresses: { type: "string" },
          evidence: { type: "string", description: "grounded quote/pointer you actually opened" },
          confidence: { type: "string" },
          greenlit: { type: "boolean", description: "true only if you re-opened the cited evidence" }
        }
      }
    },
    unproposedGaps: { type: "array", maxItems: 12, items: { type: "string" } }
  }
};

// ---- stage 1: enumerate ------------------------------------------------------
// Encoding observed live 2026-09-23: /Users/nietaki/.homesick/repos/dotfiles ->
// "--Users-nietaki-.homesick-repos-dotfiles--" (leading slash dropped, each "/"
// becomes "-", dots kept, wrapped in "--"). Instructed, not computed — the scout
// verifies by listing.
const expectedDir = "--" + targetCwd.replace(/^\/+/, "").replace(/\//g, "-") + "--";

const list = await runs.run("enumerate", {
  agent: "scout",
  context: "fresh",
  // scout's `output: context.md` is routed into ~/.pi/agent/sessions/..., which
  // our permission policy write-denies (~/.pi/*). We consume structuredOutput,
  // so disable it rather than pay a denied write per child.
  output: false,
  task: [
    "Enumerate pi session transcripts stored for one project.",
    "Store root: ~/.pi/agent/sessions/ . Expected per-project directory for",
    targetCwd + ": " + expectedDir + " — but VERIFY by listing the root; if absent,",
    "pick the closest matching directory name. If listing is denied or nothing matches:",
    "found=false, explain in note, stop.",
    "List every *.jsonl inside, newest-first (mtime), max 40: absolute path, mtime,",
    "size in KiB, and tag = filename without extension, truncated to 40 chars, unique per row.",
    "READ-ONLY; never modify anything."
  ].join("\n"),
  outputSchema: listSpec,
  ...NO_ACCEPTANCE
});

const all = ((list && list.structuredOutput && list.structuredOutput.files) || []);
const files = all
  .filter(f => typeof f.path === "string" && Number(f.sizeKb) > 2)
  .slice(0, maxSessions);

if (files.length === 0) {
  return {
    status: "nothing-to-review",
    enumerateNote: (list && list.structuredOutput && list.structuredOutput.note) || "no structured list",
    hint: "If the note says permission-denied, add a pi-permission-system read rule for ~/.pi/agent/sessions/** first. Otherwise point args.cwd at a directory pi has actually been used in."
  };
}
emit("retro: digesting " + files.length + " of " + all.length + " session file(s) for " + targetCwd);

// ---- stage 2: parallel digests (file handoff) --------------------------------
const digests = await runs.all(files.map((item, idx) => ({
  key: "digest-" + (idx + 1),
  agent: "scout",
  context: "fresh",
  task: digestTask(item, idx),
  output: false,   // same ~/.pi write-deny; digests go to /tmp by task text
  outputSchema: digestSpec,
  ...NO_ACCEPTANCE
})));

const settled = digests
  .map((d, i) => ({ key: "digest-" + (i + 1), ok: Boolean(d && d.ok), s: d && d.structuredOutput, error: d && d.error ? String(d.error).slice(0, 200) : null }))
  .filter(d => d.ok && d.s && d.s.greenlit && typeof d.s.outputFile === "string" && d.s.outputFile !== "");
const skipped = digests
  .map((d, i) => ({ key: "digest-" + (i + 1), ok: Boolean(d && d.ok), s: d && d.structuredOutput, error: d && d.error ? String(d.error).slice(0, 200) : null }))
  .filter(d => !settled.some(x => x.key === d.key));

if (settled.length === 0) {
  return { status: "all-digests-skipped-or-failed", digests: skipped.map(s => ({ key: s.key, error: s.error, reason: s.s && s.s.skippedReason ? s.s.skippedReason : null })) };
}

// ---- stage 3: synthesis (strong model, grounded) ------------------------------
let board = null;
let boardError = null;
try {
  board = await runs.run("synthesize", {
    agent: "reviewer",
    context: "fresh",
    task: [
      "You are the synthesis judge of a pi session retrospective for " + targetCwd + ".",
      "Digest workers wrote per-session findings as JSON files. Files to read (use your read tool):",
      settled.map(d => "- " + d.s.outputFile + "  (from " + d.key + ")").join("\n"),
      "",
      "Merge duplicate findings across sessions. Rank by (confidence x expected gain) / effort.",
      "KEEP AT MOST 10 proposals total. Mark a proposal greenlit=true ONLY after you re-opened",
      "its digest file and confirmed the cited evidence is real (quote it in `evidence`).",
      "Drop or greenlit=false anything you cannot ground; record why in unproposedGaps.",
      "Group by surface: model-policy | agents-config | instructions-skills | permission-rules",
      "| operator-behavior | other. Proposals must be file-level and apply-ready.",
      "You are READ-ONLY: never edit dotfiles or project files — you propose, the parent",
      "session applies only what the user approves.",
      "",
      "Context also true (from the orchestration, not to be re-verified): " + skipped.length +
      " digest(s) were skipped or failed: " + (skipped.length ? skipped.map(s => s.key).join(", ") : "-") + "."
    ].join("\n"),
    outputSchema: boardSpec,
    ...NO_ACCEPTANCE
  });
} catch (e) {
  boardError = String(e && e.message ? e.message : e).slice(0, 300);
}

return {
  status: board && board.ok ? "completed" : "synthesize-failed",
  sessionsConsidered: files.length,
  digestsWritten: settled.map(d => ({ key: d.key, outputFile: d.s.outputFile })),
  digestsSkipped: skipped.map(s => ({ key: s.key, error: s.error, reason: s.s && s.s.skippedReason ? s.s.skippedReason : null })),
  board: board && board.ok ? board.structuredOutput : null,
  boardError,
  hint: board && board.ok
    ? "Present the board grouped by surface; embed each proposal's literal evidence in option previews; apply only user-approved edits; /reload, then re-verify with /subagents-doctor."
    : "Digest files remain under /tmp/pi-retro-digest-* — relaunch synthesis or read them directly."
};
