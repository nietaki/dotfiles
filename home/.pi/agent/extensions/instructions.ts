/**
 * Inject instruction files into the system prompt as structured context files.
 *
 * Reads ~/.pi/agent/instructions/*.md and adds each one to
 * `event.systemPromptOptions.contextFiles` in `before_agent_start`, so Pi
 * renders them inside its `<project_context>` section as
 * `<project_instructions path="...">` blocks. (OpenCode's instructions under
 * ~/.config/opencode/instructions/ are its own; pi keeps a separate,
 * deliberately duplicated copy here — see dotfiles repo.)
 *
 * Why contextFiles and not a returned `systemPrompt`: returning
 * `systemPrompt` sets `forceSystemPrompt`, which makes the whole prompt an
 * opaque, unstructured replacement. Pi then cannot diff it into the
 * transcript's structured sections, and tools that inspect the prompt — e.g.
 * `pi-context-view`, which reads the section layout and the `contextFiles`
 * paths it is given — cannot tell that the trailing text came from
 * instruction files, so it shows up as unattributed prompt prose. Injecting
 * through the structured option keeps Pi's delta/diff path intact and gives
 * the files a real provenance label. The cost: these global files render
 * under the "Project-specific instructions and guidelines:" heading, which is
 * semantically slightly off but is the native surface Pi exposes for
 * file-backed prompt instructions.
 *
 * Files are read ONCE at extension load (per process) and sorted by name, so
 * the injected bytes are deterministic and stable across turns
 * (prompt-cache friendly). Edits to instruction files take effect on restart
 * or /reload, never mid-session.
 *
 * Pi normalizes `before_agent_start` options from the base loadout on every
 * run, so each handler call receives a fresh array; the path guard below
 * keeps the injection idempotent even if a handler chain ever replays us
 * against the same options object.
 */
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = process.env.HOME ?? process.env.USERPROFILE ?? "";
const INSTRUCTIONS_DIR = join(HOME, ".pi", "agent", "instructions");

interface ContextFile {
	path: string;
	content: string;
}

/** Read every instruction file once, in deterministic order. */
function loadInstructionFiles(): ContextFile[] {
	if (!existsSync(INSTRUCTIONS_DIR)) return [];

	// sort() is code-unit ordering: deterministic across platforms/runs.
	const names = readdirSync(INSTRUCTIONS_DIR)
		.filter((name) => name.endsWith(".md"))
		.sort();

	const files: ContextFile[] = [];
	for (const name of names) {
		const path = join(INSTRUCTIONS_DIR, name);
		let content: string;
		try {
			content = readFileSync(path, "utf-8");
		} catch {
			continue; // unreadable file: skip deterministically (no timestamped warning)
		}
		// Normalize line endings and trim trailing whitespace so the bytes
		// depend only on content, not on editor quirks.
		content = content.replace(/\r\n/g, "\n").trimEnd();
		if (content.length === 0) continue;
		files.push({ path, content });
	}

	return files;
}

export default function (pi: ExtensionAPI) {
	const instructionFiles = loadInstructionFiles();
	if (instructionFiles.length === 0) return;

	// Frozen for the lifetime of the process: every before_agent_start adds
	// the exact same bytes, keeping the system prompt stable turn to turn.
	pi.on("before_agent_start", async (event) => {
		const contextFiles = event.systemPromptOptions.contextFiles;
		const present = new Set(contextFiles.map((file) => file.path));
		for (const file of instructionFiles) {
			if (present.has(file.path)) continue;
			contextFiles.push({ path: file.path, content: file.content });
		}
	});
}
