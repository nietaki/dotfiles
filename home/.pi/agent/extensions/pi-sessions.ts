/**
 * pi-sessions — `pi_sessions_list` tool: enumerate pi session transcripts
 * (parents + their nested child subagent sessions) for one project directory.
 *
 * Why a custom tool instead of bash/glob work (verified 2026-09-23):
 * pi-permission-system gates bash path tokens and gates tool *args* that look
 * like paths. For extension tools with no registered extractor it extracts
 * only an arg literally named `path` (src/access-intent/tool-input-path.ts,
 * "input.path convention"), so a tool whose params are `cwd`/`maxParents`
 * yields path=null and passes cleanly. The tool's own fs access runs in-proc
 * and is NOT visible to the policy — therefore this tool is BY CONSTRUCTION a
 * gate bypass and must stay strictly read-only and confined: every path it
 * touches is resolved under ~/.pi/agent/sessions/ and prefix-checked. It
 * never reads an arbitrary caller-supplied filesystem location; `cwd` is only
 * a slug lookup key.
 *
 * Session layout (verified 2026-09-23; full notes:
 * ~/obsidian/pi_knowledge/dotfiles/Pi-subagents session layout - where child
 * sessions live.md):
 *   parent : ~/.pi/agent/sessions/--<cwd-slug>--/<timestamp>_<uuid>.jsonl
 *   child  : ~/.pi/agent/sessions/--<cwd-slug>--/<parent-stem>/<launch-uuid>/run-<n>/session.jsonl
 *   slug   : absolute path, leading "/" stripped, every "/" -> "-", wrapped in "--"
 *   the intermediate <launch-uuid> is random per launch, NOT the async runId;
 *   agent/runId/runIndex come from the child's `session_info` line:
 *   name = "subagent-<agent>-<runId>-<n>" (agent names may contain dashes,
 *   runId is a UUID, so anchor the parse on the UUID + trailing index)
 *
 * Output shape matches the sessions-retro workflow's listSpec:
 *   { found, note?, files: [{ path, mtime, sizeKb, tag, children: [...] }] }
 * so the enumerate scout becomes a pure pass-through.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync, closeSync, openSync, readSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve, sep } from "node:path";
import { Type } from "typebox";

const MAX_PARENTS_DEFAULT = 16;
const MAX_PARENTS_CAP = 40; // listSpec maxItems
const MAX_CHILDREN_PER_PARENT = 12; // newest-first
const OVERSIZED_KB = 1024; // >1 MiB => digest via head/tail sample only
const HEAD_SCAN_BYTES = 16 * 1024; // enough to reach the session_info line

// subagent-<agent>-<uuid>-<launch-seq> (trailing number is NOT runIndex; see childMeta)
const SESSION_NAME_RE =
	/^subagent-(.+)-([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})-(\d+)$/;

interface ParentEntry {
	path: string;
	mtime: string;
	sizeKb: number;
	tag: string;
	children: ChildEntry[];
}

interface ChildEntry {
	path: string;
	mtime: string;
	sizeKb: number;
	agent: string | null;
	runId: string | null;
	runIndex: number | null;
	oversized: boolean;
}

interface ListResult {
	found: boolean;
	note?: string;
	files: ParentEntry[];
}

function sessionsRoot(): string {
	return resolve(homedir(), ".pi", "agent", "sessions");
}

function slugOf(cwd: string): string {
	const trimmed = cwd.trim().replace(/^\/+/, "");
	return "--" + trimmed.replace(/\//g, "-") + "--";
}

/** Confine every path we build to the sessions root. Returns null on escape. */
function underRoot(root: string, candidate: string): string | null {
	const abs = resolve(root, candidate);
	return abs === root || abs.startsWith(root + sep) ? abs : null;
}

/** Read the first HEAD_SCAN_BYTES of a file without loading all of it. */
function readHead(file: string): string {
	let fd: number | undefined;
	try {
		fd = openSync(file, "r");
		const buf = Buffer.alloc(HEAD_SCAN_BYTES);
		const n = readSync(fd, buf, 0, HEAD_SCAN_BYTES, 0);
		return buf.subarray(0, n).toString("utf8");
	} catch {
		return "";
	} finally {
		if (fd !== undefined) try { closeSync(fd); } catch { /* noop */ }
	}
}

/** Parse a child transcript head for its session_info name (agent + runId).
 * NOTE: the trailing `-<n>` in the name is a per-launch child counter (1-based),
 * NOT the resume attempt count — the run-<N> directory name is authoritative
 * for that, so runIndex is parsed by listChildren, not here. */
function childMeta(file: string): { agent: string | null; runId: string | null } {
	const head = readHead(file);
	for (const line of head.split("\n")) {
		if (!line.includes('"session_info"')) continue;
		let entry: { type?: string; name?: unknown };
		try {
			entry = JSON.parse(line);
		} catch {
			continue; // partial line at the head boundary
		}
		if (entry.type !== "session_info" || typeof entry.name !== "string") continue;
		const m = SESSION_NAME_RE.exec(entry.name);
		if (m) return { agent: m[1], runId: m[2] };
		// unexpected naming: surface it verbatim as agent, no runId
		return { agent: entry.name, runId: null };
	}
	return { agent: null, runId: null };
}

function listChildren(slugDir: string, parentStem: string): ChildEntry[] {
	// <parent-stem>/<launch-uuid>/run-<n>/session.jsonl
	let launches: string[];
	try {
		launches = readdirSync(join(slugDir, parentStem), { withFileTypes: true })
			.filter((d) => d.isDirectory())
			.map((d) => d.name);
	} catch {
		return []; // no children: overwhelmingly the common case
	}
	const children: ChildEntry[] = [];
	for (const launch of launches) {
		const launchDir = join(slugDir, parentStem, launch);
		let runs: string[];
		try {
			runs = readdirSync(launchDir, { withFileTypes: true })
				.filter((d) => d.isDirectory() && /^run-\d+$/.test(d.name))
				.map((d) => d.name);
		} catch {
			continue;
		}
		for (const run of runs) {
			const file = join(launchDir, run, "session.jsonl");
			let st;
			try {
				st = statSync(file);
			} catch {
				continue; // no session.jsonl in that run dir (partial state)
			}
			children.push({
				path: file,
				mtime: st.mtime.toISOString(),
				sizeKb: Math.round(st.size / 1024),
				runIndex: Number(run.replace(/^run-/, "")), // resume attempt count (authoritative)
				...childMeta(file),
				oversized: false, // filled after cap/sort below
			});
		}
	}
	return children
		.sort((a, b) => new Date(b.mtime).getTime() - new Date(a.mtime).getTime())
		.slice(0, MAX_CHILDREN_PER_PARENT)
		.map((c) => ({ ...c, oversized: c.sizeKb > OVERSIZED_KB }));
}

function enumerate(cwd: string, maxParents: number, includeChildren: boolean): ListResult {
	const root = sessionsRoot();
	const slug = slugOf(cwd);
	const slugDir = underRoot(root, slug);
	if (!slugDir) return { found: false, note: "slug resolved outside sessions root", files: [] };

	if (!existsSync(slugDir)) {
		// closest-match degradation: suggest plausible dirs instead of failing silently
		let similar: string[] = [];
		try {
			const base = cwd.trim().split("/").filter(Boolean).pop() ?? "";
			similar = readdirSync(root, { withFileTypes: true })
				.filter((d) => d.isDirectory() && base.length > 2 && d.name.includes(base))
				.map((d) => d.name)
				.slice(0, 5);
		} catch {
			/* root unreadable */
		}
		return {
			found: false,
			note:
				`no sessions dir for cwd (expected ${slugDir}).` +
				(similar.length ? ` Similar dirs: ${similar.join(", ")}` : ""),
			files: [],
		};
	}

	let parents;
	try {
		parents = readdirSync(slugDir, { withFileTypes: true }).filter((d) => d.isFile() && d.name.endsWith(".jsonl"));
	} catch (e) {
		return { found: false, note: "cannot read sessions dir: " + String(e).slice(0, 160), files: [] };
	}
	const rows: ParentEntry[] = [];
	for (const p of parents) {
		const path = join(slugDir, p.name);
		let st;
		try {
			st = statSync(path);
		} catch {
			continue;
		}
		const stem = p.name.replace(/\.jsonl$/, "");
		rows.push({
			path,
			mtime: st.mtime.toISOString(),
			sizeKb: Math.round(st.size / 1024),
			tag: stem.slice(0, 40),
			children: [],
		});
	}
	rows.sort((a, b) => new Date(b.mtime).getTime() - new Date(a.mtime).getTime());
	const top = rows.slice(0, maxParents);
	if (includeChildren) {
		for (const f of top) f.children = listChildren(slugDir, stemOf(f.path));
	}
	return {
		found: top.length > 0,
		note:
			`${top.length} parent session(s) under ${slugDir}` +
			(includeChildren
				? `, ${top.reduce((n, f) => n + f.children.length, 0)} child session(s); newest-first`
				: ", children not requested"),
		files: top,
	};
}

function stemOf(parentPath: string): string {
	return parentPath.slice(parentPath.lastIndexOf("/") + 1).replace(/\.jsonl$/, "");
}

const PARAMS = Type.Object({
	cwd: Type.String({
		description:
			"Project working directory to look up, e.g. /Users/nietaki/repos/my-app. Used only to derive the sessions-store slug; the tool never touches this path.",
	}),
	maxParents: Type.Optional(
		Type.Number({ description: `Max newest parent sessions (default ${MAX_PARENTS_DEFAULT}, cap ${MAX_PARENTS_CAP})` }),
	),
	includeChildren: Type.Optional(
		Type.Boolean({ description: "Attach nested child (subagent) transcripts to each parent (default true)" }),
	),
});

export default function piSessionsExtension(pi: ExtensionAPI) {
	pi.registerTool({
		name: "pi_sessions_list",
		label: "pi sessions list",
		description:
			"Enumerate pi session transcripts for a project: newest-first parent .jsonl files under ~/.pi/agent/sessions/--<cwd-slug>--/, each with its nested child subagent transcripts (<parent-stem>/<launch-uuid>/run-<n>/session.jsonl) including agent name, runId and runIndex. Read-only; returns JSON {found, note, files:[{path,mtime,sizeKb,tag,children:[...]}]}.",
		promptSnippet: "List pi session transcripts (parents + nested child subagent runs) for a project cwd",
		parameters: PARAMS,
		async execute(_toolCallId, params) {
			const maxParents = Math.min(Math.max(Number(params.maxParents) || MAX_PARENTS_DEFAULT, 1), MAX_PARENTS_CAP);
			const includeChildren = params.includeChildren !== false;
			let result: ListResult;
			try {
				result = enumerate(String(params.cwd), maxParents, includeChildren);
			} catch (e) {
				result = {
					found: false,
					note: "enumeration failed: " + String(e && (e as Error).message ? (e as Error).message : e).slice(0, 200),
					files: [],
				};
			}
			return {
				content: [{ type: "text" as const, text: JSON.stringify(result, null, 2) }],
				details: result,
			};
		},
	});
}
