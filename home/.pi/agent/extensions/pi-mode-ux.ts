import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

/**
 * pi-mode-ux — glue between @pedro_klein/pi-modes and the rest of the stack.
 *
 * Why this exists (all verified against the INSTALLED pi-modes src/index.ts,
 * which lags behind GitHub main):
 *
 * 1. /mode — the published pi-modes registers NO slash commands; mode
 *    switching is only a Ctrl+Alt+M shortcut. Its bundled prompt templates
 *    (package.json `pi.prompts`) are OpenCode-flavored leftovers (they
 *    reference subagents pi does not have and an "ask_user" tool that
 *    doesn't exist here), so settings.json loads the package with
 *    "prompts": [] — they register nothing. The extension DOES listen for
 *    the "pi-ask:mode-switch" event, so we register a non-colliding /mode
 *    command that emits it. (Side effect inherited from pi-modes: switching
 *    also injects a "Continue working" follow-up message and aborts any
 *    in-flight run. Note pi-modes' optional mode-contract injection reads
 *    ~/.pi/agent/extensions/pi-modes/prompts/*.md, which we deliberately
 *    do NOT provide — the static instructions/modes.md is the only mode
 *    guidance in the system prompt.)
 *
 * 2. Footer status — pi core wires ctx.ui.setStatus(key, text) into the
 *    shared footerDataProvider; @henryqw/pi-footer renders ALL entries of
 *    data.getExtensionStatuses() (footer.ts:347), so one setStatus call per
 *    mode change makes the mode visible in the existing footer. No fork,
 *    no extra status package.
 *
 * 3. bash_readonly in build/none — installed pi-modes drops bash_readonly
 *    from the active tools in build AND none. We re-add it after every mode
 *    change: it is a read-only tool by construction, menshen does not gate
 *    it (gatedTools: ["bash"]), and gotgenes' shellTools alias applies the
 *    full bash path/external_directory policy to it — so exposing it in
 *    write-enabled modes is safe and saves reviewer-model round-trips for
 *    plain reads.
 *
 * 4. mode_status tool — pi-modes' /mode pipeline re-informs the model after
 *    a switch (abort + "Mode is now X" follow-up), but Ctrl+Alt+M cycling
 *    does neither: currentMode changes instantly while the run's system
 *    prompt stays frozen at its before_agent_start value. The tool is a
 *    zero-arg read-only projection of the mirrored event state plus LIVE
 *    pi.getActiveTools() facts, so it cannot disagree with the footer or
 *    the gating. It reports only — switching remains a human action (a
 *    switch tool would let the model escape the gates that exist to
 *    constrain it).
 *
 *    The write-gate answer is *sensed*: it dynamically imports
 *    WRITE_FILTERED_MODES from the installed pi-modes source (absolute
 *    path — relative specifiers would resolve against the repo through
 *    the homeshick symlink). If that import ever fails, the tool falls
 *    back to a hand-mirrored set and labels the line "(mirrored)", so
 *    a stale answer is always visible, never silent.
 */

const MODES = ["ask", "brainstorm", "plan", "build", "none"] as const;
type Mode = (typeof MODES)[number];

const SEGMENTS: Record<Mode, string> = {
	ask: "? ASK",
	brainstorm: "* BRAINSTORM",
	plan: "# PLAN",
	build: "+ BUILD",
	none: "- NONE",
};

// Sense pi-modes' actual write-gate set instead of hand-mirroring it.
// Absolute specifier: this file is a homeshick symlink, and jiti resolves
// relative specifiers against the realpath (inside the repo, where
// npm/node_modules does not exist). The target imports only
// @earendil-works/pi-tui (resolved via pi's own aliases) + node builtins;
// loading the module has no side effects beyond defining the extension fn.
const PI_MODES_SOURCE = join(
	process.env.HOME ?? process.env.USERPROFILE ?? "",
	".pi",
	"agent",
	"npm",
	"node_modules",
	"@pedro_klein",
	"pi-modes",
	"src",
	"index.ts",
);

let writeGateSense: Promise<Set<string> | null> | null = null;
function sensedWriteFilteredModes(): Promise<Set<string> | null> {
	writeGateSense ??= import(pathToFileURL(PI_MODES_SOURCE).href)
		.then((mod: unknown) => {
			const set = (mod as { WRITE_FILTERED_MODES?: unknown })
				?.WRITE_FILTERED_MODES;
			return set instanceof Set ? (set as Set<string>) : null;
		})
		.catch(() => null); // failure is surfaced as the "(mirrored)" label
	return writeGateSense;
}

// Hand-mirrored fallback for WRITE_FILTERED_MODES, used only when the
// dynamic import fails; the output then carries "(mirrored)" so a stale
// answer can never be mistaken for a sensed one.
function fallbackWriteFilteredModes(): Set<string> {
	return new Set(["ask", "brainstorm"]);
}

export default function (pi: ExtensionAPI): void {
	let ctx: ExtensionContext | null = null;
	let mode: Mode | null = null;
	let previousMode: Mode | null = null;
	let changedAt = 0;

	function publishStatus(): void {
		if (ctx && mode) ctx.ui.setStatus("pi-modes", SEGMENTS[mode]);
	}

	// Show the active model's provider in the footer, styled to match
	// pi-footer's model-name rendering (theme.fg("dim", ...)).
	// The theme's "dim" is a specific gray (#666666 dark / #767676 light),
	// not the ANSI dim attribute — so we use truecolor escapes to match.
	const DIM_FG = "\x1b[38;2;102;102;102m";
	const RESET_FG = "\x1b[39m";
	function publishProviderStatus(): void {
		if (!ctx) return;
		const provider = ctx.model?.provider;
		if (provider) {
			ctx.ui.setStatus("provider", `${DIM_FG}${provider}${RESET_FG}`);
		}
	}

	// Keep a fresh ExtensionContext (for setStatus outside event handlers) and
	// re-publish every turn — covers session restores and any footer resets.
	pi.on("session_start", (_event, c) => {
		ctx = c;
		publishStatus();
		publishProviderStatus();
	});
	pi.on("before_agent_start", (_event, c) => {
		ctx = c;
		publishStatus();
		publishProviderStatus();
	});

	// Update the provider label when the user switches models.
	pi.on("model_select", (_event, c) => {
		ctx = c;
		publishProviderStatus();
	});

	// pi-modes emits this synchronously inside applyMode, AFTER gating.
	pi.events.on("pi-modes:changed", (data: unknown) => {
		const payload = (data ?? {}) as { mode?: Mode; previousMode?: Mode };
		const next = payload.mode;
		if (!next || !MODES.includes(next)) return;
		previousMode = payload.previousMode ?? mode;
		mode = next;
		changedAt = Date.now();

		if (next === "build" || next === "none") {
			// Re-expose the redundant-by-design read-only wrapper.
			pi.setActiveTools(pi.getAllTools().map((t) => t.name));
		}
		publishStatus();
	});

	// Read-only projection of the mirrored mode state (see header note 4).
	// Denylist-based mode gating (pi-modes filters only bash/bash_readonly by
	// name) never removes this tool, so it answers in every mode — including
	// none, where pi-modes itself injects nothing.
	pi.registerTool({
		name: "mode_status",
		label: "Mode Status",
		description:
			"Report the active pi-modes workflow mode and live tool-gating state (read-only query).",
		promptSnippet: "Query the active workflow mode and its live tool gating",
		promptGuidelines: [
			"Use mode_status before starting implementation work, or whenever unsure which workflow mode is active right now (e.g. after a mid-run Ctrl+Alt+M cycle); it reflects live gating state, not a turn-start assumption.",
		],
		parameters: Type.Object({}),
		async execute() {
			const active = pi.getActiveTools();
			if (!mode) {
				return {
					content: [
						{
							type: "text",
							text: "mode: unknown (no pi-modes state in this process — e.g. subagent or pre-first-event)",
						},
					],
					details: { mode: null },
				};
			}
			const bash = active.includes("bash")
				? "bash (unrestricted)"
				: active.includes("bash_readonly")
					? "bash_readonly (restricted commands)"
					: "no shell tool";
			// Ask pi-modes' real WRITE_FILTERED_MODES (sensed, not mirrored);
			// fall back to a hand copy only if the import failed — visibly.
			const probed = await sensedWriteFilteredModes();
			const writeFiltered = probed ?? fallbackWriteFilteredModes();
			const writes = writeFiltered.has(mode)
				? "filtered (markdown in cwd, /tmp, ~/.pi)"
				: "unfiltered";
			const writesSuffix = probed ? "" : " (mirrored)";
			const secs = changedAt ? Math.max(0, Math.round((Date.now() - changedAt) / 1000)) : null;
			const lines = [
				`mode: ${mode}`,
				`footer: ${SEGMENTS[mode]}`,
				`previous: ${previousMode ?? "n/a"}`,
				`changed: ${secs === null ? "unknown" : `${secs}s ago`}`,
				`shell tool: ${bash}`,
				`writes: ${writes}${writesSuffix}`,
			];
			return {
				content: [{ type: "text", text: lines.join("\n") }],
				details: { mode, previousMode, bash },
			};
		},
	});

	pi.registerCommand("mode", {
		description: "Switch pi-modes workflow mode: /mode <ask|brainstorm|plan|build|none>",
		handler: async (args: string, c: ExtensionContext) => {
			ctx = c;
			const target = (args ?? "").trim().toLowerCase() as Mode;
			if (!target || !MODES.includes(target)) {
				c.ui.notify(`Usage: /mode <${MODES.join("|")}>`, "warning");
				return;
			}
			if (target === mode) {
				c.ui.notify(`Already in ${target} mode`, "info");
				return;
			}
			// Let pi-modes do the real work (gating, persistence,
			// notification) through its one external switch hook.
			pi.events.emit("pi-ask:mode-switch", { mode: target });
		},
	});
}
