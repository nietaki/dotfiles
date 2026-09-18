/**
 * Append instruction files to the system prompt.
 *
 * Reads instruction directories, in this fixed order, each emitted as its
 * own top-level block:
 *
 *   ~/.pi/agent/instructions/*.md         → "# Pi Instructions"
 *
 * (The OpenCode-variant source below is commented out: pi instructions
 * now live independently in ~/.pi/agent/instructions/; the OpenCode files
 * remain untouched for OpenCode itself.)
 *
 * The blocks are built ONCE at extension load (per process), from files
 * sorted by name with fixed separators, so the emitted bytes are
 * deterministic and stable across turns and prompt-cache friendly. Edits to
 * instruction files take effect on restart or /reload, never mid-session.
 */
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? process.env.USERPROFILE ?? "";

const INSTRUCTION_SOURCES: Array<{ dir: string; header: string }> = [
	// {
	// 	dir: join(HOME, ".config", "opencode", "instructions"),
	// 	header: "# Additional Instructions",
	// },
	{
		dir: join(HOME, ".pi", "agent", "instructions"),
		header: "# Pi Instructions",
	},
];

function buildInstructionsBlock(dir: string, header: string): string | null {
	if (!existsSync(dir)) return null;

	// sort() is code-unit ordering: deterministic across platforms/runs.
	const files = readdirSync(dir)
		.filter((name) => name.endsWith(".md"))
		.sort();

	const sections: string[] = [];
	for (const file of files) {
		let content: string;
		try {
			content = readFileSync(join(dir, file), "utf-8");
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
	return [header, ...sections].join("\n\n");
}

export default function (pi: ExtensionAPI) {
	// Frozen for the lifetime of the process: every before_agent_start sees
	// the exact same string, keeping the system prompt byte-identical turn to
	// turn. (If no instructions changed, pi can also skip resending them.)
	const blocks = INSTRUCTION_SOURCES.map(({ dir, header }) =>
		buildInstructionsBlock(dir, header),
	).filter((block): block is string => block !== null);
	if (blocks.length === 0) return;
	const suffix = "\n\n" + blocks.join("\n\n");

	pi.on("before_agent_start", async (event) => {
		return { systemPrompt: `${event.systemPrompt}${suffix}` };
	});
}
