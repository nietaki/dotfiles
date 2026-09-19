/**
 * Append instruction files to the system prompt.
 *
 * Reads ~/.pi/agent/instructions/*.md and emits it as one top-level
 * "# Pi Instructions" block. (OpenCode's instructions under
 * ~/.config/opencode/instructions/ are its own; pi keeps a separate,
 * deliberately duplicated copy here — see dotfiles repo.)
 *
 * The block is built ONCE at extension load (per process), from files
 * sorted by name with fixed separators, so the emitted bytes are
 * deterministic and stable across turns and prompt-cache friendly. Edits to
 * instruction files take effect on restart or /reload, never mid-session.
 */
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? process.env.USERPROFILE ?? "";
const INSTRUCTIONS_DIR = join(HOME, ".pi", "agent", "instructions");
const HEADER = "# Pi Instructions";

function buildInstructionsBlock(): string | null {
	if (!existsSync(INSTRUCTIONS_DIR)) return null;

	// sort() is code-unit ordering: deterministic across platforms/runs.
	const files = readdirSync(INSTRUCTIONS_DIR)
		.filter((name) => name.endsWith(".md"))
		.sort();

	const sections: string[] = [];
	for (const file of files) {
		let content: string;
		try {
			content = readFileSync(join(INSTRUCTIONS_DIR, file), "utf-8");
		} catch {
			continue; // unreadable file: skip deterministically (no timestamped warning)
		}
		// Normalize line endings and trim trailing whitespace so the bytes
		// depend only on content, not on editor quirks.
		content = content.replace(/\r\n/g, "\n").trimEnd();
		if (content.length === 0) continue;
		sections.push(content);
	}

	if (sections.length === 0) return null;
	return [HEADER, ...sections].join("\n\n");
}

export default function (pi: ExtensionAPI) {
	const block = buildInstructionsBlock();
	if (block === null) return;
	const suffix = "\n\n" + block;

	// Frozen for the lifetime of the process: every before_agent_start sees
	// the exact same string, keeping the system prompt byte-identical turn to
	// turn. (If no instructions changed, pi can also skip resending them.)
	pi.on("before_agent_start", async (event) => {
		return { systemPrompt: `${event.systemPrompt}${suffix}` };
	});
}
