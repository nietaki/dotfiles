import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

/**
 * pi-mode-ux — glue between @pedro_klein/pi-modes and the rest of the stack.
 *
 * Why this exists (all verified against the INSTALLED pi-modes src/index.ts,
 * which lags behind GitHub main):
 *
 * 1. /mode — the published pi-modes registers NO slash commands; mode
 *    switching is only a Ctrl+Alt+M shortcut. Typing /build expands the
 *    package's bundled prompt template (package.json `pi.prompts`) instead.
 *    The extension DOES listen for the "pi-ask:mode-switch" event, so we
 *    register a non-colliding /mode command that emits it. (Side effect
 *    inherited from pi-modes: switching also injects a "Continue working"
 *    follow-up message and aborts any in-flight run.)
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

export default function (pi: ExtensionAPI): void {
	let ctx: ExtensionContext | null = null;
	let mode: Mode | null = null;

	function publishStatus(): void {
		if (ctx && mode) ctx.ui.setStatus("pi-modes", SEGMENTS[mode]);
	}

	// Keep a fresh ExtensionContext (for setStatus outside event handlers) and
	// re-publish every turn — covers session restores and any footer resets.
	pi.on("session_start", (_event, c) => {
		ctx = c;
		publishStatus();
	});
	pi.on("before_agent_start", (_event, c) => {
		ctx = c;
		publishStatus();
	});

	// pi-modes emits this synchronously inside applyMode, AFTER gating.
	pi.events.on("pi-modes:changed", (data: unknown) => {
		const next = (data as { mode?: Mode })?.mode;
		if (!next || !MODES.includes(next)) return;
		mode = next;

		if (next === "build" || next === "none") {
			// Re-expose the redundant-by-design read-only wrapper.
			pi.setActiveTools(pi.getAllTools().map((t) => t.name));
		}
		publishStatus();
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
			// Let pi-modes do the real work (gating, persistence, notify,
			// contract injection) through its one external switch hook.
			pi.events.emit("pi-ask:mode-switch", { mode: target });
		},
	});
}
