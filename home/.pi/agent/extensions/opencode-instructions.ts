/**
 * Append opencode-style instruction files to the system prompt.
 *
 * Reads ~/.config/opencode/instructions/*.md and appends them as a single
 * block. The block is built ONCE at extension load (per process), from files
 * sorted by name with fixed separators, so the emitted bytes are
 * deterministic and stable across turns and prompt-cache friendly. Edits to
 * instruction files take effect on restart or /reload, never mid-session.
 */
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const INSTRUCTIONS_DIR = join(
	process.env.HOME ?? process.env.USERPROFILE ?? "",
	".config",
	"opencode",
	"instructions",
);

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
	return ["# Additional Instructions", ...sections].join("\n\n");
}

export default function (pi: ExtensionAPI) {
	// Frozen for the lifetime of the process: every before_agent_start sees
	// the exact same string, keeping the system prompt byte-identical turn to
	// turn. (If no instructions changed, pi can also skip resending them.)
	const block = buildInstructionsBlock();
	if (block === null) return;

	pi.on("before_agent_start", async (event) => {
		return { systemPrompt: `${event.systemPrompt}\n\n${block}` };
	});
}
