// sessions-retro — pi-subagents workflow script
// Saved-workflow registry copy: ~/.pi/agent/subagent-workflows/sessions-retro/script.js
// (pi-subagents-workflows package). Canonical repo path:
// home/.pi/agent/subagent-workflow_sources/sessions-retro/script.js
//
// Two-stage session retrospective for ONE working directory:
//   enumerate (retro-scout -> pass-through of the pi_sessions_list tool) ->
//   parallel per-PARENT digests (retro-scout, fresh context; each parent
//   digest also mines its nested child transcripts for evidence; each writes
//   a bounded JSON file to /tmp) -> one strong-model synthesis (retro-judge:
//   grounds every proposal against the raw transcripts, merges + ranks, then
//   WRITES THE REPORT NOTE into the obsidian vault under
//   ~/obsidian/pi_knowledge/sessions-retro/ and returns board + notePath so
//   the launching session can quote the file location).
// File handoff keeps giant transcript text out of task strings and receipts.
//
// @args
//   cwd       string  required — the project whose sessions to review.
//                     pi stores them under ~/.pi/agent/sessions/--<path>--/,
//                     i.e. the absolute path with '/' replaced by '-'
//                     (verified 2026-09-23: /Users/nietaki/repos/grr-fyi ->
//                     --Users-nietaki-repos-grr-fyi--)
//   maxSessions number optional (default 6, capped 16) — newest-N PARENT
//                     sessions; each parent's child (subagent) transcripts
//                     ride along in its digest worker (tool caps children at
//                     12 newest per parent, flags >1 MiB as oversized)
//   noteDir   string  optional — vault dir for the report note; default
//                     /Users/nietaki/obsidian/pi_knowledge/sessions-retro
//
// LAUNCH: /workflow run sessions-retro cwd=/path/to/project
//   (or pi_subagent_workflow action=run, name=sessions-retro). The registry
//   injects its own `cwd` = the pi run directory, which is NOT args.cwd — the
//   project to review must be passed explicitly. Its runner passes only
//   {workflowScript, cwd} to pi-subagents, so no outer timeoutMs/deadline and
//   no raised spawn budget; use subagent({workflowScriptPath}) when you need
//   either. Always detached async.
//
// Budget: 1 + maxSessions + 1 children (<= 18; run cap 24, global concurrency 4).
// No `state` (launch without a mission is fine). Launch it with an explicit
// timeoutMs (async composites have no default), e.g. 3_600_000.
// PERMISSION NOTE (verified 2026-09-23 against pi-permission-system source):
// enumeration goes through the pi_sessions_list EXTENSION tool — unregistered
// extension tools expose only an `input.path` arg to the path gates, and this
// tool's params are named cwd/maxParents, so no gate fires; its reads are
// confined to ~/.pi/agent/sessions/ by construction. bash tree-walks (find/du)
// over the sessions store stay denied — do NOT re-add them. Digest workers
// read transcripts with read/grep (~/.pi/* is allowed on path_read +
// external_directory_read).

if (typeof args !== "object" || args === null ||
    typeof args.cwd !== "string" || args.cwd.trim() === "") {
  throw new Error("sessions-retro: args.cwd is required — the working directory to review, e.g. \"/Users/nietaki/repos/grr-fyi\"");
}
const targetCwd = args.cwd.trim();
const maxSessions = Math.min(Math.max(Number(args.maxSessions) || 6, 1), 16);

// ---- vault report note -------------------------------------------------------
// The synthesize judge writes the final report here and echoes the path back
// via boardSpec.notePath; the launching session quotes it to the operator.
// pi's write tool creates parent dirs, so the dir need not exist yet. The
// obsidian vault is opened read+write in the permission policy (path +
// external_directory allows), so a child with `write` can land the note from
// any cwd.
const VAULT_DEFAULT = "/Users/nietaki/obsidian/pi_knowledge/sessions-retro";
const vaultDir = typeof args.noteDir === "string" && args.noteDir.trim() !== ""
  ? args.noteDir.trim().replace(/\/+$/, "")
  : VAULT_DEFAULT;
const reportStamp = new Date().toISOString().slice(0, 16).replace(/[T:]/g, "-");
const projectName = targetCwd.replace(/\/+$/, "").split("/").pop() || "project";
const REPORT_PATH = vaultDir + "/retro-" + reportStamp + "-" + projectName + ".md";

// Every schema-bound child gets acceptance disabled. OMITTING `acceptance`
// makes pi-subagents infer a level ("attested" for scout/reviewer, "checked"
// for the writer role), which injects an "## Acceptance Contract" telling the
// child to "end with a structured acceptance report" — a property the
// structured_output tool does not expose, so the model stuffs it into `value`
// and validation retries (6 of 8 children in the 2026-09-23 smoke test).
// `false` -> level "none" -> nothing injected. Full write-up:
// ../feature-dev/script.js.
const NO_ACCEPTANCE = { acceptance: false };

// Run nonce to avoid collisions with stale digest files from prior runs
const RUN_NONCE = Date.now().toString(36);

function digestTask(item, idx) {
  const outFile = "/tmp/pi-retro-digest-" + RUN_NONCE + "-" + idx + "-" + item.tag + ".json";
  const kids = Array.isArray(item.children) ? item.children : [];
  const kidLines = kids.length
    ? kids.map(c =>
        "- " + c.path + " (agent=" + (c.agent || "?") +
        " runId=" + String(c.runId || "?").slice(0, 8) +
        " run-" + (c.runIndex == null ? "?" : c.runIndex) +
        " " + c.sizeKb + " KiB" + (c.oversized ? " OVERSIZED" : "") + ")").join("\n")
    : "- none recorded";
  return [
    "You are one digest worker of a session retrospective. Your unit is ONE parent pi session",
    "plus its child (subagent) transcripts — they are all parts of the same session's story.",
    "YOUR SESSION: " + item.path + " (~" + item.sizeKb + " KiB).",
    "CHILD TRANSCRIPTS (same session, nested under the parent's directory):",
    kidLines,
    "",
    "STEP 0 — GO/NO-GO.",
    "Inspect the head and tail of the PARENT file (first and last few entries).",
    "Set greenlit=false (write NOTHING, empty outputFile) if ANY of:",
    "- it is trivially short (< ~5 user-visible turns with no friction),",
    "- it contains no real work (purely meta/testing/abandoned with no actionable findings).",
    "Prefer greenlit=true when in doubt — the operator launched this retro to find friction, and even short sessions may contain valuable signals.",
    "",
    "STEP 1 — DIGEST THE PARENT (only if greenlit=true).",
    "Read the transcript in bounded windows with your read tool (it truncates per call; use",
    "offsets). If large, skim structurally first: grep for user-message and tool-error markers,",
    "then deep-read only the passages those point to.",
    "",
    "STEP 2 — MINE CHILDREN (only ones the parent implicates).",
    "Children extend the parent session: a denied tool call, a wasted retry, or missing",
    "context may live only in a child transcript. For each candidate child: grep FIRST for",
    "friction markers (\"Denied by policy\", \"isError\", repeated near-identical commands,",
    "correction language), then read bounded windows around the hits only. Never full-read a",
    "child above ~200 KiB; OVERSIZED children are head/tail sample + grep ONLY. For the same",
    "runId, the highest run-N is the fullest record; earlier runs mainly explain WHY the",
    "resume happened. Skip children with no plausible link to friction visible in the parent.",
    "",
    "STEP 3 — WRITE.",
    "Extract AT MOST 6 concrete, evidence-backed findings — real friction observed IN THIS",
    "SESSION (parent or its children), not hypothetical improvements: repeated corrections,",
    "denied/failed tool calls,",
    "wrong-model symptoms (verbosity, refusals, cheap-model errors), missing context the agent",
    "re-learned every turn, wasted tokens, missing or stale skills/instructions.",
    "For each: category (model-policy | agents-config | instructions-skills | permission-rules",
    "| operator-behavior | other), what happened, 2-4 sentence evidence, sourcePath = the exact",
    "transcript the evidence came from (the parent path or one child path listed above),",
    "position (timestamp/entry WITHIN THAT FILE), proposed change (specific, file-level where",
    "possible: settings key, skill text, instruction line), expected gain, confidence",
    "(low|medium|high).",
    "WRITE ONLY to " + outFile + " (your write tool):",
    "JSON exactly {\"session\":\"" + item.path + "\",\"findings\":[{\"category\":\"...\",\"what\":\"...\",\"evidence\":\"...\",\"sourcePath\":\"...\",\"position\":\"...\",\"proposal\":\"...\",\"gain\":\"...\",\"confidence\":\"...\"}]}",
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
          tag: { type: "string", description: "short slug of the file name (timestamp_id prefix), unique per file" },
          children: {
            type: "array",
            maxItems: 12,
            description: "nested child (subagent) transcripts of this parent, newest-first; [] when none",
            items: {
              type: "object",
              additionalProperties: false,
              required: ["path", "sizeKb"],
              properties: {
                path: { type: "string" },
                mtime: { type: "string" },
                sizeKb: { type: "number" },
                agent: { type: ["string", "null"], description: "subagent role from session_info; null when unparseable" },
                runId: { type: ["string", "null"] },
                runIndex: { type: ["integer", "null"], description: "resume attempt count (run-<n> directory)" },
                oversized: { type: "boolean", description: ">1 MiB — head/tail sample + grep only" }
              }
            }
          }
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
  required: ["proposals", "unproposedGaps", "notePath"],
  properties: {
    notePath: {
      type: "string",
      description: "absolute path of the vault report note you wrote; empty string if the write failed"
    },
    proposals: {
      type: "array",
      maxItems: 12,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["surface", "title", "change", "addresses", "evidence", "confidence", "effort", "greenlit"],
        properties: {
          surface: { type: "string", description: "model-policy | agents-config | instructions-skills | permission-rules | operator-behavior | other" },
          title: { type: "string" },
          change: { type: "string", description: "file-level, apply-ready: which file, what edit" },
          addresses: { type: "string" },
          evidence: { type: "string", description: "grounded quote from the actual transcript" },
          confidence: { type: "string" },
          effort: { type: "string", description: "low | medium | high — estimated effort to implement" },
          greenlit: { type: "boolean", description: "true only if you opened the transcript and quoted the evidence" }
        }
      }
    },
    unproposedGaps: { type: "array", maxItems: 12, items: { type: "string" } }
  }
};

// ---- stage 1: enumerate ------------------------------------------------------
// The retro-scout agent exposes pi_sessions_list, which computes the
// --<cwd-slug>-- directory itself and returns listSpec-shaped JSON, so this
// stage is a transcription pass-through — no manual encoding knowledge needed.
const list = await runs.run("enumerate", {
  agent: "retro-scout",
  context: "fresh",
  // retro-scout pins output:false in its frontmatter; explicit false also
  // guards against a future frontmatter drift writing into ~/.pi/agent/sessions.
  output: false,
  task: [
    "Enumerate pi session transcripts for one project so digest workers can be assigned.",
    "Call your pi_sessions_list tool with exactly:",
    "  cwd: " + targetCwd,
    "  maxParents: " + maxSessions,
    "It returns JSON {found, note, files:[{path, mtime, sizeKb, tag, children:[...]}]} —",
    "newest-first parent sessions of that project, each with its nested child (subagent)",
    "transcripts (absolute path, agent, runId, runIndex, sizeKb, oversized flag).",
    "Return that JSON UNCHANGED as your structuredOutput: same field names and values; do",
    "not add, drop, rename, reorder, or reformat entries. If the tool reports found=false,",
    "return found=false, copy its note, files=[].",
    "Do not read, list, or explore anything else — the tool output is the whole job.",
    "READ-ONLY; never modify anything."
  ].join("\n"),
  outputSchema: listSpec,
  timeoutMs: 90_000,  // 1.5 min for enumeration (one tool call + transcription)
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
    hint: "If the note says the sessions dir is missing, point args.cwd at a directory pi has actually been used in. If pi_sessions_list itself was unavailable to the scout, the extension did not load (restart pi)."
  };
}
emit("retro: digesting " + files.length + " of " + all.length + " parent session(s) (children ride along) for " + targetCwd);

// ---- stage 2: parallel digests (file handoff) --------------------------------
const digests = await runs.all(files.map((item, idx) => ({
  key: "digest-" + (idx + 1),
  agent: "retro-scout",
  context: "fresh",
  task: digestTask(item, idx),
  output: false,   // same ~/.pi write-deny; digests go to /tmp by task text
  outputSchema: digestSpec,
  timeoutMs: 300_000,  // 5 min per digest — prevent hangs
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
    agent: "retro-judge",
    context: "fresh",
    model: "openrouter/anthropic/claude-opus-5.5",  // strong model for synthesis judgment
    task: [
      "You are the synthesis judge of a pi session retrospective for " + targetCwd + ".",
      "Digest workers wrote per-session findings as JSON files. Files to read (use your read tool):",
      settled.map(d => "- " + d.s.outputFile + "  (from " + d.key + ")").join("\n"),
      "",
      "GROUNDING: For each proposal you consider, open the ACTUAL transcript at the position cited — the finding's `sourcePath` (a parent or one of its child transcripts), falling back to the digest's `session` field when a finding omits it. Quote the literal text from that transcript in your `evidence` field. Do not just re-check the digest — verify against the source.",
      "",
      "Merge duplicate findings across sessions. Rank by (confidence x expected gain) / effort.",
      "KEEP AT MOST 10 proposals total. Mark a proposal greenlit=true ONLY after you opened the transcript and quoted the evidence.",
      "Drop or greenlit=false anything you cannot ground in the actual transcript; record why in unproposedGaps.",
      "Group by surface: model-policy | agents-config | instructions-skills | permission-rules",
      "| operator-behavior | other. Proposals must be file-level and apply-ready.",
      "",
      "DOTFILES REPO: The setup files live in the dotfiles repo at ~/.homesick/repos/dotfiles/home/.pi/agent/. When proposing edits, read the current file content first (via read tool) to ensure your proposal is not stale or already done. Propose edits to the repo paths (e.g. ~/.homesick/repos/dotfiles/home/.pi/agent/settings.json), NOT the symlinked $HOME paths (e.g. ~/.pi/agent/settings.json).",
      "",
      "You are otherwise READ-ONLY: the ONLY file you may write is the report note named below. Never edit dotfiles or project files — you propose, the operator applies only what they approve.",
      "",
      "FINAL STEP — WRITE THE REPORT NOTE (exactly one file, your write tool):", REPORT_PATH,
      "The obsidian vault is the report's destination; write no other file.",
      "Note structure: YAML frontmatter (title, date, tags: [pi/sessions-retro], project: " + targetCwd + ", status: active), then: Summary (parents digested + children mined, digests written/skipped, headline proposals); Proposals grouped by surface, each with the literal change, what it addresses, the quoted evidence as a blockquote naming its transcript + position, confidence/effort/greenlit; Rejected findings & unproposed gaps (every claim you dropped and why — the audit trail matters); Method footer listing the digest files above and this run's nonce (" + RUN_NONCE + ").",
      "Nothing in the note may leak secrets. Return notePath = " + REPORT_PATH + " (empty string + an unproposedGaps entry if the write failed).",
      "",
      "Context also true (from the orchestration, not to be re-verified): " + skipped.length +
      " digest(s) were skipped or failed: " + (skipped.length ? skipped.map(s => s.key).join(", ") : "-") + "."
    ].join("\n"),
    outputSchema: boardSpec,
    timeoutMs: 1_200_000,  // 20 min for synthesis — complex merge + rank
    ...NO_ACCEPTANCE
  });
} catch (e) {
  boardError = String(e && e.message ? e.message : e).slice(0, 300);
}

return {
  status: board && board.ok ? "completed" : "synthesize-failed",
  sessionsConsidered: files.length,
  reportNote: board && board.ok
    ? (String((board.structuredOutput && board.structuredOutput.notePath) || "") || "WARNING: judge echoed no notePath — expected " + REPORT_PATH)
    : null,
  digestsWritten: settled.map(d => ({ key: d.key, outputFile: d.s.outputFile })),
  digestsSkipped: skipped.map(s => ({ key: s.key, error: s.error, reason: s.s && s.s.skippedReason ? s.s.skippedReason : null })),
  board: board && board.ok ? board.structuredOutput : null,
  boardError,
  hint: board && board.ok
    ? "Report the vault note file path (reportNote above) verbatim to the operator first, then present the board grouped by surface; embed each proposal's literal evidence in option previews; apply only user-approved edits; /reload, then re-verify with /subagents-doctor."
    : "Digest files remain under /tmp/pi-retro-digest-* — relaunch synthesis or read them directly."
};
