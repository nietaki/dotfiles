// feature-dev — pi-subagents workflow script
// Saved-workflow registry copy: ~/.pi/agent/subagent-workflows/feature-dev/script.js
// (pi-subagents-workflows package). Canonical repo path:
// home/.pi/agent/subagent-workflow_sources/feature-dev/script.js
//
// Execute an APPROVED feature plan task-by-task with TDD discipline:
//   decompose (fresh scout, outputSchema: checks the 'Approved:' stamp and
//   that the working tree is clean)
//   -> per task, serially: a FRESH `worker` implements it (tdd skill, sole
//      writer, designs the interface sketch itself, RED = intended-reason
//      failure (assertion once the path is runnable)
//      evidence) -> fresh `verifier` (custom agent: bash + watchdog_diff, NO
//      edit/write tools) re-runs the suite and audits test honesty
//   -> FAIL resumes THAT task's worker with the literal findings (capped
//      rounds) -> still failing, worker blocked, or a child crashed: ABORT
//      with a full report
//   -> all green: closing fan-out, both schema-typed:
//        quality    — fresh `reviewer` (read-only, watchdog_diff, no bash)
//        acceptance — fresh `verifier` (runs the suite, checks every
//                     criterion in scope, cross-checks the plan for criteria
//                     the decomposition dropped)
//   -> final return with a machine-readable verdict.
//
// @args
//   planPath      string   optional (default ".pi/feat/plan.md") — the
//                          approved plan, relative to the workflow cwd
//   maxFixRounds  integer  optional (default 2, 0-5) — verifier-driven
//                          fix rounds per task before the workflow aborts
//   onlyTasks     int[]    optional — run only these task ids (continue after
//                          an abort, or split a plan that exceeds the spawn
//                          budget). The acceptance check is then scoped to
//                          the selected tasks' criteria. The registry manifest
//                          declares this as string[] (it has no number[]
//                          type), so numeric strings are accepted too.
//   allowDirty    boolean  optional (default false) — proceed even though the
//                          working tree has changes outside .pi/ when the run
//                          starts (e.g. an onlyTasks continuation). Those paths
//                          are passed to every auditor as "pre-existing".
//   spawnCap      integer  optional (default 24) — soft guard for the run fan-out
//                          budget. The script aborts cleanly with a report
//                          before exceeding this, rather than throwing mid-run.
//                          Resumes reuse the original claim, so they don't
//                          consume additional budget.
//
// LAUNCH — two surfaces, same script:
// 1. Saved registry (pi-subagents-workflows): /workflow run feature-dev
//      planPath=.pi/feat/plan.md   (or pi_subagent_workflow action=run)
//    Its runner passes ONLY {workflowScript, cwd} to pi-subagents, so it can
//    never raise maxSubagentSpawnsPerRun or set an outer timeoutMs, and it is
//    always detached async. Use it for plans of <=3 tasks (with the default
//    24-spawn cap); args are type-checked against workflow.json first.
// 2. Direct (needed for bigger plans / an explicit deadline):
//    subagent({ workflowScriptPath: "/Users/nietaki/.pi/agent/subagent-workflows/feature-dev/script.js",
//               args: { planPath: ".pi/feat/plan.md" }, cwd: "<target repo>",
//               timeoutMs: 14_400_000, maxSubagentSpawnsPerRun: 40 })
//    Async composites have no default deadline — always pass timeoutMs on the
//    OUTER call (each worker child may take up to 30 min, per round).
// The registry prepends `const args = …; const cwd = …` to this body; that
// shadows the sandbox `args` global, so the script must keep working with a
// plain object (it does).
//
// BUDGET (spawns): every runs.run claims one, resumes included (workflow
// fan-out budget claims per key). Per task 2 .. 2*(maxFixRounds+1); total
//   happy path  1 + 2*T + 2
//   worst case  1 + 2*(maxFixRounds+1)*T + 2
// With the default cap of 24 and 2 fix rounds the worst case fits only 3
// tasks — raise it per run with the top-level maxSubagentSpawnsPerRun (as
// above) or split via onlyTasks. The script emits the worst case up front.
// Exceeding the cap mid-run makes runs.run throw: no structured report.
//
// NOTES:
// - No commits anywhere: the tree is left dirty for the operator to review
//   (git diff) and commit. Verifiers audit the files the worker reported for
//   the task (all rounds merged) + the cumulative diff; that is why the run
//   requires a clean tree at start (see allowDirty).
// - worker is pinned by this setup's agentOverrides to qwen3.8-flash; the
//   verifier too (frontmatter). Retier by editing settings.json /
//   agents/verifier.md + reloading pi; modelScope must allow the target.
// - If a child detaches via supervisor contact the run stays paused until
//   it settles; that is expected.

if (args.planPath !== undefined && typeof args.planPath !== "string") {
  throw new Error("feature-dev: args.planPath must be a string (path to the approved plan)");
}
if (args.maxFixRounds !== undefined &&
    !(Number.isInteger(args.maxFixRounds) && args.maxFixRounds >= 0 && args.maxFixRounds <= 5)) {
  throw new Error("feature-dev: args.maxFixRounds must be an integer 0-5");
}
const isTaskId = (n) => (Number.isInteger(n) && n >= 1) ||
  (typeof n === "string" && /^[1-9][0-9]*$/.test(n.trim()));
if (args.onlyTasks !== undefined &&
    (!Array.isArray(args.onlyTasks) || args.onlyTasks.length === 0 ||
     !args.onlyTasks.every(isTaskId))) {
  throw new Error("feature-dev: args.onlyTasks must be a non-empty array of positive task ids (integers, or numeric strings via the saved-workflow registry)");
}
if (args.allowDirty !== undefined && typeof args.allowDirty !== "boolean") {
  throw new Error("feature-dev: args.allowDirty must be a boolean");
}
if (args.spawnCap !== undefined &&
    !(Number.isInteger(args.spawnCap) && args.spawnCap >= 1)) {
  throw new Error("feature-dev: args.spawnCap must be a positive integer");
}

const PLAN_PATH = (typeof args.planPath === "string" && args.planPath.trim()) ? args.planPath.trim() : ".pi/feat/plan.md";
const MAX_FIX_ROUNDS = Number.isInteger(args.maxFixRounds) ? args.maxFixRounds : 2;
const ONLY_TASKS = Array.isArray(args.onlyTasks) ? args.onlyTasks.map((n) => Number(n)) : null;
const ALLOW_DIRTY = args.allowDirty === true;
const SPAWN_CAP = Number.isInteger(args.spawnCap) ? args.spawnCap : 24;
let spawnsUsed = 0; // tracked for clean abort before exceeding SPAWN_CAP

const TIMEOUT = {
  decompose: 5 * 60 * 1000,
  worker: 30 * 60 * 1000,
  verifier: 15 * 60 * 1000,
  closing: 15 * 60 * 1000,
};

// EVERY schema-bound child must be launched with acceptance disabled.
// Omitting `acceptance` makes pi-subagents INFER a level (acceptance.js
// `inferLevel`): "checked" for agents declaring `acceptanceRole: writer` (the
// builtin worker), "attested" for everything else (scout, reviewer, our
// verifier — they declare no role). Any level but "none" injects a ~1.5 KB
// "## Acceptance Contract" section into the child's prompt that ends with:
//   "Completion is not accepted from prose alone. End with a structured
//    acceptance report."
// But the `structured_output` tool never exposes an `acceptanceReport`
// property: registerStructuredOutputTool passes `structured.acceptanceReport`,
// which createStructuredOutputRuntime does not set (it only sets
// acceptanceReportPath/Required). So the instruction is unsatisfiable through
// the tool — the model puts `acceptanceReport` INSIDE `value`, our schema's
// `additionalProperties: false` rejects it, and it retries. Observed on 6 of 8
// children in the 2026-09-23 smoke test (scout, both workers, both verifiers,
// closing reviewer), three error families. `acceptance: false` -> level "none"
// -> formatAcceptancePrompt returns "" (verified: 0 chars injected, was 1555
// for worker / 1516 for the others). We lose nothing: our evidence contract is
// the task text + these schemas, and we never read acceptance reports.
// Also cheaper per child — "checked" additionally demanded changed-files,
// tests-added, commands-run, residual-risks and no-staged-files evidence.
const NO_ACCEPTANCE = { acceptance: false };

// Only `approved`, `treeClean` and `blockers` are required so a missing or
// unapproved plan can return a clean NO-GO without inventing tasks; the
// remaining fields are checked in JS when approved.
const DECOMP_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["approved", "treeClean", "baselineGreen", "blockers"],
  properties: {
    approved: { type: "boolean" },
    treeClean: { type: "boolean" },
    baselineGreen: { type: "boolean" },
    dirtyPaths: { type: "array", items: { type: "string" } },
    goal: { type: "string" },
    nonGoals: { type: "array", items: { type: "string" } },
    testCommand: { type: "string" },
    context: { type: "string" },
    globalAcceptance: { type: "array", items: { type: "string" } },
    tasks: {
      type: "array",
      maxItems: 24,
      items: {
        type: "object",
        additionalProperties: false,
        required: ["id", "title", "acceptance"],
        properties: {
          id: { type: "integer" },
          title: { type: "string" },
          summary: { type: "string" },
          acceptance: { type: "array", minItems: 1, items: { type: "string" } },
          files: { type: "array", items: { type: "string" } },
        },
      },
    },
    blockers: { type: "array", items: { type: "string" } },
  },
};

const WORKER_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["status", "summary", "filesTouched", "behaviorsCovered", "redEvidence", "suiteOutput"],
  properties: {
    status: { enum: ["done", "blocked"] },
    summary: { type: "string" },
    filesTouched: { type: "array", items: { type: "string" } },
    behaviorsCovered: { type: "array", items: { type: "string" } },
    redEvidence: { type: "array", items: { type: "string" } },
    suiteOutput: { type: "string" },
    concerns: { type: "array", items: { type: "string" } },
  },
};

// Shared by the per-task verifier and the closing acceptance check (both run
// the `verifier` agent). Mirrors agents/verifier.md's output section.
const VERIFY_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["verdict", "testsRun", "findings", "acceptance", "summary"],
  properties: {
    verdict: { enum: ["PASS", "FAIL"] },
    testsRun: { type: "string" },
    diffTool: { type: "string" },
    findings: { type: "array", items: { type: "string" } },
    acceptance: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["criterion", "status", "evidence"],
        properties: {
          criterion: { type: "string" },
          status: { enum: ["covered", "partial", "missing", "unverifiable"] },
          evidence: { type: "string" },
        },
      },
    },
    summary: { type: "string" },
  },
};

const QUALITY_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["mergeVerdict", "findings", "summary"],
  properties: {
    mergeVerdict: { enum: ["BLOCK", "OK", "OK with notes"] },
    findings: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        required: ["severity", "finding"],
        properties: {
          severity: { enum: ["P0", "P1", "P2"] },
          location: { type: "string" },
          finding: { type: "string" },
        },
      },
    },
    summary: { type: "string" },
  },
};

function bullets(items, empty) {
  return items && items.length ? items.map((x) => "- " + x) : [empty];
}

function preexistingNote(dirty) {
  return dirty.length
    ? "PRE-EXISTING CHANGES (present before this workflow started; NOT part of this feature — ignore them in your audit): " + dirty.join(", ")
    : "";
}

function decomposeTask() {
  return [
    "You are the decomposition step of the feature-dev workflow. Read the plan file at " + PLAN_PATH + " (relative to your working directory). Do not edit anything.",
    "If the file is missing or unreadable, return approved=false with a blocker naming the path.",
    "The plan must carry an explicit approval stamp: a line starting with 'Approved:' (usually under the Goal heading). Missing stamp means the plan was never approved: return approved=false with that blocker. Do not proceed regardless of how good the plan looks.",
    "Working-tree check (always, even when not approved): run `git status --porcelain` via bash. Ignore entries under .pi/ (the plan and runtime state live there). treeClean = no remaining entries; dirtyPaths = the remaining paths (empty array when clean). Not a git repo: treeClean=false plus a blocker.",
    "Baseline test check (always, even when not approved): run the test command from the plan's 'Test command' section via bash. baselineGreen = true only if the suite passes with exit code 0. If the suite is red at baseline, return approved=false with a blocker saying 'baseline suite is red — fix before running feature-dev'.",
    "When approved, extract (verbatim wherever possible — do NOT paraphrase acceptance criteria):",
    "- goal: the Goal, condensed to 1-3 sentences",
    "- nonGoals: the Non-goals entries",
    "- testCommand: the exact shell line from the plan's Test command section",
    "- context: the Context section (scout's recon findings — key files, conventions, how tests are written). Empty string if the section is missing.",
    "- globalAcceptance: plan-level acceptance criteria from the 'Global acceptance' section (empty array if none)",
    "- tasks: the Task breakdown in order; id = task number starting at 1 (from '## Task N:' headings); title; summary (short, from the plan); acceptance = the testable criteria listed under that task's 'Acceptance criteria:' subsection (REQUIRED — if a task has no acceptance criteria of its own, return approved=false with a blocker naming the task; do NOT fall back to globalAcceptance); files = plan 'Files in scope' entries under that task (empty array if none)",
    "- blockers: anything that makes execution ambiguous (no runnable test command, criteria that cannot be verified, contradictory scope). Empty array if none.",
  ].join("\n");
}

function implTaskText(t, plan, dirty) {
  return [
    "You are the implementation worker for task " + t.id + " of the approved feature plan at " + PLAN_PATH + ". You are the ONLY writer in this workflow; every other child is read-only. The plan is the contract — follow it, do not renegotiate scope.",
    "GOAL: " + plan.goal,
    plan.context && plan.context.trim()
      ? "CONTEXT (from the scout's recon — read these files first to understand the codebase):\n" + plan.context
      : "",
    "NON-GOALS (do not build any of these):",
    ...bullets(plan.nonGoals, "- (none listed)"),
    "TASK " + t.id + ": " + t.title + (t.summary ? " — " + t.summary : ""),
    "ACCEPTANCE CRITERIA (all must be verifiably true when you finish):",
    ...bullets(t.acceptance),
    t.files && t.files.length
      ? "FILES IN SCOPE (from the plan; touch these plus whatever your tests need, staying inside the plan's declared scope): " + t.files.join(", ")
      : "",
    "FULL-SUITE TEST COMMAND: " + plan.testCommand,
    preexistingNote(dirty),
    "",
    "METHOD — strict test-driven development per your loaded tdd skill, with one override: the approved plan IS the skill's Planning step (step 1). Do NOT ask anyone to confirm the interface or which behaviors to test — the acceptance criteria above are the approved behaviors. Start at the Interface Sketch.",
    "1. Sketch the public interface this task needs first (signatures/types as declarations or fixtures so the test path resolves; production dummies only as a last resort, removed in GREEN). Keep the sketch provisional.",
    "2. Vertical slices: one behavior or one small cohesive cluster per cycle. RED: write the test(s), RUN them, observe each fail FOR ITS INTENDED REASON — an assertion failure once the path is runnable (a compile/import failure only counts while you are still establishing this test's interface sketch; extend it minimally, re-run, then require the assertion failure) — keep the exact failure output. GREEN: minimal code to pass. Never write all tests before all implementation.",
    "3. Refactor while staying green; when the task's behaviors are covered, run the FULL suite with the command above — it must pass.",
    "4. Do NOT commit anything. Leave the working tree dirty on purpose; a fresh-context verifier audits it next.",
    "Skill escape hatches: only 'pure config / glue code' may skip test-first here, and only for the part that genuinely has no testable behavior; spikes must be deleted before you finish. Every use must be reported as a concerns entry 'TDD-EXCEPTION: <file/part> — <why> — <how you verified it instead>'. Anything covered by an acceptance criterion always needs a test.",
    "",
    "EVIDENCE you must return in the structured output:",
    "- redEvidence: one entry per new-or-changed test, '<test name> — RED: <one-line real failure snippet you observed>', for tests you actually watched fail this task",
    "- behaviorsCovered: which acceptance criterion each covered behavior satisfies",
    "- filesTouched: every file you created or modified",
    "- suiteOutput: tail of the final full-suite run INCLUDING its exit code",
    "- concerns: TDD-EXCEPTION entries plus anything the verifier should know",
    "- status blocked (plus explanation in summary) only if the plan genuinely cannot answer a product decision; prefer contact_supervisor reason=need_decision for real ambiguity over guessing",
  ].filter((line) => line !== "").join("\n");
}

function fixTaskText(t, plan, verify, round) {
  const gaps = verify.acceptance.filter((a) => a.status !== "covered").map((a) => a.criterion + " -> " + a.status + " (" + a.evidence + ")");
  return [
    "The independent verifier REJECTED task " + t.id + " (entering fix round " + round + " of " + MAX_FIX_ROUNDS + "). Your prior implementation stands — address the findings below; do not redo the whole task.",
    "FINDINGS (fresh-context verifier that re-ran the suite and audited the diff itself):",
    ...bullets(verify.findings, "- (no findings listed; read the verifier summary)"),
    gaps.length ? "ACCEPTANCE GAPS:\n" + gaps.map((g) => "- " + g).join("\n") : "",
    "VERIFIER TEST RUN: " + verify.testsRun,
    "VERIFIER SUMMARY: " + verify.summary,
    "",
    "Fix TDD-style: when a finding is a weak/dishonest test, fix the TEST first — watch it fail for the right reason, then make it pass. Full suite command: " + plan.testCommand + " — it must pass when you finish. Do NOT commit.",
    "Return the same structured fields: status, summary, filesTouched (files changed THIS round), behaviorsCovered (the FULL list for the task, not just this round), redEvidence (ONLY newly observed RED failures from this round), suiteOutput, concerns (all TDD-EXCEPTION entries still in effect).",
  ].filter((line) => line !== "").join("\n");
}

function verifyTaskText(t, plan, impl, files, red, round, dirty) {
  return [
    "Independent verification of task " + t.id + " ('" + t.title + "') from the plan at " + PLAN_PATH + " (implementation round " + round + ").",
    "ACCEPTANCE CRITERIA (report one acceptance entry per criterion):",
    ...bullets(t.acceptance),
    "NON-GOALS (building any of these is a finding):",
    ...bullets(plan.nonGoals, "- (none listed)"),
    "TEST COMMAND: " + plan.testCommand,
    "WORKER-REPORTED FILES TOUCHED FOR THIS TASK (all rounds so far):",
    ...bullets(files, "- (none reported — treat that itself as a finding)"),
    "WORKER CLAIMS:",
    "- summary: " + impl.summary,
    "- behaviorsCovered: " + impl.behaviorsCovered.join(" | "),
    "- redEvidence (claims each of these was seen failing for its intended reason — assertion once runnable; prefix = round):",
    ...(red.length ? red.map((e) => "  - " + e) : ["  - (none claimed)"]),
    "- concerns: " + (impl.concerns && impl.concerns.length ? impl.concerns.join(" | ") : "(none)"),
    "- suiteOutput (claimed): " + impl.suiteOutput,
    preexistingNote(dirty),
    "",
    "The working tree accumulates ALL completed tasks of this plan (no per-task commits exist), so: run the full suite yourself; audit the reported files closely and the broader diff for weakened/deleted assertions; verify each claimed RED test exists and really asserts the claimed behavior. PASS only with your own observed evidence.",
    "TDD-EXCEPTION concerns: accept one only when the part is genuinely config/glue with no testable behavior AND the stated alternative verification is plausible; code that implements an acceptance criterion without a test is a FAIL.",
  ].filter((line) => line !== "").join("\n");
}

function closingQualityTask(plan, rows, dirty) {
  return [
    "Final closing review of a completed feature (all tasks passed their per-task verification gates). Whole feature, fresh eyes.",
    "GOAL: " + plan.goal,
    "NON-GOALS:",
    ...bullets(plan.nonGoals, "- (none listed)"),
    "TASKS SHIPPED IN THIS RUN: " + rows.map((r) => "#" + r.id + " " + r.title).join("; "),
    "FILES TOUCHED: " + [...new Set(rows.flatMap((r) => r.filesTouched))].join(", "),
    preexistingNote(dirty),
    "Read the plan at " + PLAN_PATH + " for Files-in-scope context, then review the CUMULATIVE working-tree diff with watchdog_diff (narrow it with a path when it truncates).",
    "Focus: code quality and design — coherence across tasks, duplication that crossed task boundaries, dead scaffolding left from interface sketches, naming vs the project's domain language, error handling, anything over-built relative to the Non-goals. Correctness against acceptance criteria is checked separately; do not duplicate it.",
    "Report concrete findings with severity P0 (blocks merge) / P1 (fix before release) / P2 (note), each with a file:line location. mergeVerdict: BLOCK if any P0, else 'OK with notes' if any findings, else OK. Do not edit anything.",
  ].filter((line) => line !== "").join("\n");
}

function closingAcceptanceTask(plan, selected, fullRun, dirty) {
  // On full runs, only check global acceptance criteria (per-task criteria already
  // passed their gates). On partial runs, check the selected tasks' criteria.
  const criteria = fullRun
    ? (plan.globalAcceptance || []).map((a) => "- [global] " + a)
    : selected.flatMap((t) => t.acceptance.map((a) => "- [task " + t.id + "] " + a));

  return [
    "Whole-feature ACCEPTANCE pass.",
    fullRun
      ? "Every task already passed its own per-task gate. This check focuses on GLOBAL acceptance criteria only (cross-cutting concerns like 'no regressions'). Per-task criteria are not re-checked."
      : "This run implemented only tasks " + selected.map((t) => t.id).join(", ") + " of the plan. Check their acceptance criteria.",
    "GOAL: " + plan.goal,
    "TEST COMMAND: " + plan.testCommand + " — run it yourself; the suite must pass on the final tree.",
    "CRITERIA IN SCOPE (report one acceptance entry per criterion, citing the proof you found: test name + file:line, or observed behavior):",
    ...criteria,
    fullRun
      ? "EXTRACTION CROSS-CHECK: these global criteria were extracted from the plan by another agent. Read " + PLAN_PATH + " and add an acceptance entry (status missing, evidence 'not in extracted list') plus a finding for every plan global acceptance criterion that is absent above or was materially paraphrased."
      : "",
    preexistingNote(dirty),
    "Mark a criterion unverifiable when no test or observable behavior can prove it — that is itself a finding. verdict PASS only if the suite passes and every entry is covered. Any partial, missing, or unverifiable -> FAIL. Do not edit anything.",
  ].filter((line) => line !== "").join("\n");
}

// ---------------------------------------------------------------- decompose

emit("feature-dev: reading and decomposing " + PLAN_PATH);
const dec = await runs.run("decompose", {
  agent: "scout",
  context: "fresh",
  label: "Decompose approved plan",
  task: decomposeTask(),
  // scout's frontmatter declares `output: context.md`, which a workflow child
  // gets routed into ~/.pi/agent/sessions/.../outputs/<runId>/ — inside our
  // permission policy's write-deny on ~/.pi/*. The child would burn a denied
  // write and leave a misleading artifact. This script consumes
  // structuredOutput, so disable the file output explicitly.
  output: false,
  outputSchema: DECOMP_SCHEMA,
  ...NO_ACCEPTANCE,
  timeoutMs: TIMEOUT.decompose,
});
if (!dec.ok || !dec.structuredOutput) {
  return { verdict: "NO-GO", stage: "decompose", reason: [dec.error || "decompose child returned no structured output"], output: dec.output };
}
const plan = dec.structuredOutput;
if (!plan.approved) {
  return {
    verdict: "NO-GO",
    stage: "decompose",
    reason: plan.blockers.length ? plan.blockers : ["plan missing or lacks the 'Approved:' stamp"],
    hint: "Produce/approve a plan first — e.g. run /feat-spec in the target repo and approve it.",
  };
}
const shapeErrors = [
  ...(plan.goal && plan.goal.trim() ? [] : ["no goal extracted"]),
  ...(plan.testCommand && plan.testCommand.trim() ? [] : ["no test command extracted"]),
  ...(plan.tasks && plan.tasks.length ? [] : ["no tasks extracted"]),
];
if (shapeErrors.length || plan.blockers.length) {
  return { verdict: "NO-GO", stage: "decompose", reason: [...shapeErrors, ...plan.blockers], hint: "Fix the plan at " + PLAN_PATH + " and relaunch." };
}
const dirty = plan.dirtyPaths || [];
if (!plan.treeClean && !ALLOW_DIRTY) {
  return {
    verdict: "NO-GO",
    stage: "preflight",
    reason: ["working tree has changes outside .pi/ — audits compare against HEAD, so they would be attributed to this feature"],
    dirtyPaths: dirty,
    hint: "Commit/stash them, or relaunch with args.allowDirty=true (e.g. continuing a previous run via onlyTasks).",
  };
}
if (plan.baselineGreen !== true) {
  return {
    verdict: "NO-GO",
    stage: "preflight",
    reason: ["baseline test suite is red — fix failing tests before running feature-dev"],
    hint: "Run '" + plan.testCommand + "' and fix any failures, then relaunch.",
  };
}

const tasks = ONLY_TASKS ? plan.tasks.filter((t) => ONLY_TASKS.includes(t.id)) : plan.tasks;
if (!tasks.length) {
  return { verdict: "NO-GO", stage: "select", reason: ["no plan tasks matched args.onlyTasks " + JSON.stringify(ONLY_TASKS) + " (plan task ids: " + plan.tasks.map((t) => t.id).join(", ") + ")"] };
}
const fullRun = tasks.length === plan.tasks.length;

emit("feature-dev: " + tasks.length + " task(s); spawn budget needed: " + (3 + 2 * tasks.length) +
  " happy path, " + (3 + 2 * (MAX_FIX_ROUNDS + 1) * tasks.length) + " worst case (spawnCap: " + SPAWN_CAP + ")");

// Helper to check spawn budget before launching
function checkSpawnBudget(needed) {
  if (spawnsUsed + needed > SPAWN_CAP) {
    return { ok: false, reason: "spawn budget exceeded: " + spawnsUsed + " used + " + needed + " needed > " + SPAWN_CAP + " cap" };
  }
  return { ok: true };
}

// ---------------------------------------------------------------- per task

const perTask = [];
try {
for (const [index, t] of tasks.entries()) {
  emit("feature-dev: task " + (index + 1) + "/" + tasks.length + " (#" + t.id + ") — " + t.title);
  const files = new Set();
  const red = [];
  let impl;
  let v;
  let runId;
  let round = 0;

  for (; round <= MAX_FIX_ROUNDS; round++) {
    if (round > 0) {
      emit("feature-dev: task #" + t.id + " rejected — fix round " + round + "/" + MAX_FIX_ROUNDS);
      // Resumes reuse the original claim, so they don't consume additional budget
    }
    impl = await runs.run("impl-t" + t.id + "-r" + round, round === 0
      ? { agent: "worker", context: "fresh", skill: "tdd", label: "Implement task " + t.id + ": " + t.title,
          task: implTaskText(t, plan, dirty), outputSchema: WORKER_SCHEMA, ...NO_ACCEPTANCE, timeoutMs: TIMEOUT.worker }
      : { resume: runId, skill: "tdd", label: "Fix task " + t.id + " round " + round,
          task: fixTaskText(t, plan, v.structuredOutput, round), outputSchema: WORKER_SCHEMA, ...NO_ACCEPTANCE, timeoutMs: TIMEOUT.worker });
    if (round === 0) spawnsUsed++; // only fresh launches count
    if (!impl.ok || !impl.structuredOutput || impl.structuredOutput.status === "blocked") break;
    // Guard: resume requires runId from the previous round
    if (round > 0 && !runId) {
      emit("feature-dev: ABORT — round 0 returned no runId, cannot resume");
      return {
        verdict: "ABORTED",
        stage: "WORKER_ERROR",
        failedTask: t.id,
        reason: "round 0 worker returned no runId — cannot resume for fix rounds",
        perTask,
        goal: plan.goal,
        testCommand: plan.testCommand,
        treeState: "partially implemented plan left UNCOMMITTED in the working tree",
      };
    }
    runId = impl.runId || runId; // each resume returns a new runId — follow the latest
    impl.structuredOutput.filesTouched.forEach((f) => files.add(f));
    red.push(...impl.structuredOutput.redEvidence.map((e) => "r" + round + ": " + e));

    // Check budget before launching verifier
    const budgetCheck = checkSpawnBudget(1);
    if (!budgetCheck.ok) {
      emit("feature-dev: ABORT — " + budgetCheck.reason);
      return {
        verdict: "ABORTED",
        stage: "BUDGET_EXCEEDED",
        failedTask: t.id,
        reason: budgetCheck.reason,
        perTask,
        goal: plan.goal,
        testCommand: plan.testCommand,
        hint: "Relaunch with args.spawnCap higher, or use args.onlyTasks to split the plan.",
        treeState: "partially implemented plan left UNCOMMITTED in the working tree",
      };
    }

    v = await runs.run("verify-t" + t.id + "-r" + round, {
      agent: "verifier",
      context: "fresh",
      label: "Verify task " + t.id + " round " + round,
      task: verifyTaskText(t, plan, impl.structuredOutput, [...files], red, round, dirty),
      outputSchema: VERIFY_SCHEMA,
      ...NO_ACCEPTANCE,
      timeoutMs: TIMEOUT.verifier,
    });
    spawnsUsed++;
    if (!v.ok || !v.structuredOutput || v.structuredOutput.verdict === "PASS") break;
  }

  const implOut = impl.ok ? impl.structuredOutput : undefined;
  const verOut = v && v.ok ? v.structuredOutput : undefined;
  const status = !implOut ? "WORKER_ERROR"
    : implOut.status === "blocked" ? "BLOCKED"
    : !verOut ? "VERIFIER_ERROR"
    : verOut.verdict === "PASS" ? "VERIFIED"
    : "FAILED";
  const row = {
    id: t.id,
    title: t.title,
    status,
    fixRoundsUsed: Math.min(round, MAX_FIX_ROUNDS),
    filesTouched: [...files],
    workerConcerns: implOut && implOut.concerns ? implOut.concerns : [],
    finalFindings: verOut ? verOut.findings : [],
    ...(status === "WORKER_ERROR" ? { error: impl.error || "worker returned no structured output" } : {}),
    ...(status === "VERIFIER_ERROR" ? { error: (v && v.error) || "verifier returned no structured output" } : {}),
    ...(status === "BLOCKED" ? { blockedSummary: implOut.summary } : {}),
  };
  perTask.push(row);

  if (status !== "VERIFIED") {
    emit("feature-dev: ABORT at task #" + t.id + " (" + status + ")");
    const reasons = {
      WORKER_ERROR: "worker child failed — infrastructure blocker; the tree may be partially modified",
      BLOCKED: "worker reported blocked (genuine plan ambiguity) — no further rounds spent",
      VERIFIER_ERROR: "verifier child failed — infrastructure blocker; the task's implementation is unverified",
      FAILED: "task still failing after " + MAX_FIX_ROUNDS + " fix round(s)",
    };
    return {
      verdict: "ABORTED",
      stage: status,
      failedTask: t.id,
      reason: reasons[status],
      perTask,
      goal: plan.goal,
      testCommand: plan.testCommand,
      treeState: "partially implemented plan left UNCOMMITTED in the working tree; inspect git diff, then continue with args.onlyTasks (+ allowDirty: true)",
    };
  }
}
} catch (err) {
  emit("feature-dev: ERROR — " + (err && err.message ? err.message : String(err)));
  return {
    verdict: "ABORTED",
    stage: "SCRIPT_ERROR",
    reason: "script threw: " + (err && err.message ? err.message : String(err)),
    perTask,
    goal: plan.goal,
    testCommand: plan.testCommand,
    treeState: "partially implemented plan left UNCOMMITTED in the working tree",
  };
}

// ---------------------------------------------------------------- closing

emit("feature-dev: all " + tasks.length + " task(s) verified — closing quality + acceptance checks");

// Check budget before closing fan-out (2 children)
const closingBudgetCheck = checkSpawnBudget(2);
if (!closingBudgetCheck.ok) {
  emit("feature-dev: ABORT — " + closingBudgetCheck.reason);
  return {
    verdict: "ABORTED",
    stage: "BUDGET_EXCEEDED",
    reason: closingBudgetCheck.reason,
    perTask,
    goal: plan.goal,
    testCommand: plan.testCommand,
    hint: "Relaunch with args.spawnCap higher, or use args.onlyTasks to split the plan.",
    treeState: "all tasks verified but closing checks could not run; tree is UNCOMMITTED",
  };
}

try {
const [quality, acceptance] = await runs.all([
  { key: "quality-final", agent: "reviewer", context: "fresh", label: "Closing code-quality review",
    model: "openrouter/openai/gpt-5.6-sol",
    task: closingQualityTask(plan, perTask, dirty), outputSchema: QUALITY_SCHEMA, ...NO_ACCEPTANCE, timeoutMs: TIMEOUT.closing },
  { key: "acceptance-final", agent: "verifier", context: "fresh", label: "Closing acceptance check",
    task: closingAcceptanceTask(plan, tasks, fullRun, dirty), outputSchema: VERIFY_SCHEMA, ...NO_ACCEPTANCE, timeoutMs: TIMEOUT.closing },
]);
spawnsUsed += 2;
const q = quality.ok ? quality.structuredOutput : undefined;
const a = acceptance.ok ? acceptance.structuredOutput : undefined;
const verdict = !q || !a ? "COMPLETE_REVIEW_INCOMPLETE"
  : q.mergeVerdict === "BLOCK" || a.verdict === "FAIL" ? "COMPLETE_WITH_BLOCKERS"
  : "COMPLETE";

return {
  verdict,
  scope: fullRun ? "full plan" : "tasks " + tasks.map((t) => t.id).join(", ") + " of " + plan.tasks.length,
  goal: plan.goal,
  testCommand: plan.testCommand,
  perTask: perTask.map((r) => ({ id: r.id, title: r.title, status: r.status, fixRoundsUsed: r.fixRoundsUsed, workerConcerns: r.workerConcerns })),
  closing: {
    quality: q || "quality reviewer failed: " + (quality.error || "no structured output"),
    acceptance: a || "acceptance check failed: " + (acceptance.error || "no structured output"),
  },
  treeState: "all changes left UNCOMMITTED for your review (git diff)",
};
} catch (err) {
  emit("feature-dev: ERROR in closing — " + (err && err.message ? err.message : String(err)));
  return {
    verdict: "COMPLETE_REVIEW_INCOMPLETE",
    stage: "CLOSING_ERROR",
    reason: "closing checks threw: " + (err && err.message ? err.message : String(err)),
    perTask: perTask.map((r) => ({ id: r.id, title: r.title, status: r.status, fixRoundsUsed: r.fixRoundsUsed, workerConcerns: r.workerConcerns })),
    goal: plan.goal,
    testCommand: plan.testCommand,
    treeState: "all tasks verified but closing checks failed; tree is UNCOMMITTED",
  };
}
