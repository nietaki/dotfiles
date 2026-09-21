import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

/**
 * footer-provider — show the active model's provider in the pi footer.
 *
 * Extracted from the old `pi-mode-ux.ts` glue extension when the workflow-mode
 * stack (@pedro_klein/pi-modes + @shinynito/pi-menshen + pi-readonly-bash) was
 * removed. It is the one feature in that file that had nothing to do with modes.
 *
 * Mechanism: pi core wires `ctx.ui.setStatus(key, text)` into the shared
 * footerDataProvider, and `@henryqw/pi-footer` renders every entry of
 * `data.getExtensionStatuses()` — so a single `setStatus` call per relevant
 * event is all this needs. No fork, no extra status package.
 *
 * Styling: the theme's "dim" is a specific gray (#666666 dark / #767676 light),
 * not the ANSI dim attribute, so we emit truecolor escapes to match pi-footer's
 * own model-name rendering.
 */

const DIM_FG = "\x1b[38;2;102;102;102m";
const RESET_FG = "\x1b[39m";

export default function (pi: ExtensionAPI): void {
	let ctx: ExtensionContext | null = null;

	function publishProviderStatus(): void {
		if (!ctx) return;
		const provider = ctx.model?.provider;
		if (provider) {
			ctx.ui.setStatus("provider", `${DIM_FG}${provider}${RESET_FG}`);
		}
	}

	// Keep a fresh ExtensionContext and re-publish at turn boundaries — covers
	// session restores and any footer resets.
	pi.on("session_start", (_event, c) => {
		ctx = c;
		publishProviderStatus();
	});
	pi.on("before_agent_start", (_event, c) => {
		ctx = c;
		publishProviderStatus();
	});

	// Update the label when the user switches models.
	pi.on("model_select", (_event, c) => {
		ctx = c;
		publishProviderStatus();
	});
}
