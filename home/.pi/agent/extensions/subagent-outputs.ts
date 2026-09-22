/**
 * subagent-outputs — `/subagent-outputs` lists the saved output artifacts of
 * pi-subagents child runs for this project (newest first), then shows the
 * chosen report in a scrollable markdown viewer. Pure TUI surface: no model
 * involvement; data comes from the artifact files pi-subagents persists under
 * ~/.pi/agent/sessions/<cwd-slug>/subagent-artifacts/.
 *
 * Keys in the viewer: ↑/↓ or j/k line · PgUp/space page · Home/End or g/G
 * top/bottom · q/esc/enter close.
 *
 * Why manual windowing (no ScrollView): ui.custom() components are mounted
 * inside pi's `editorContainer`, a plain Container with no [LAYOUT_NODE].
 * pi-tui's layout engine treats that whole slot as one leaf, so a nested
 * ScrollView never receives updateLayout() — its viewportHeight stays 0 and
 * every scrollBy() is silently clamped to a no-op. Instead we render the
 * Markdown to styled lines ourselves and slice a terminal-height window in
 * render(), tracking offset in the key handler.
 */
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { matchesKey, Markdown } from "@earendil-works/pi-tui";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

type Found = { path: string; mtime: number; size: number };

const MAX_FILES = 40;
const MAX_LINES = 6000;

function collectMarkdown(dir: string, out: Found[], depth = 0): void {
	if (depth > 4 || out.length >= 500) return;
	let entries: string[];
	try {
		entries = readdirSync(dir);
	} catch {
		return;
	}
	for (const name of entries) {
		const p = join(dir, name);
		let st;
		try {
			st = statSync(p);
		} catch {
			continue;
		}
		if (st.isDirectory()) collectMarkdown(p, out, depth + 1);
		else if (st.isFile() && name.endsWith(".md")) out.push({ path: p, mtime: st.mtimeMs, size: st.size });
	}
}

function artifactDirs(ctx: ExtensionCommandContext): string[] {
	const sessionsRoot = join(homedir(), ".pi", "agent", "sessions");
	if (!existsSync(sessionsRoot)) return [];
	const slug = "--" + ctx.cwd.replace(/^\//, "").replace(/[/:\\]/g, "-") + "--";
	const projectDir = join(sessionsRoot, slug, "subagent-artifacts");
	if (existsSync(projectDir)) return [projectDir];
	// fallback: every project's artifacts, so the command still works after moves
	return readdirSync(sessionsRoot)
		.map((d) => join(sessionsRoot, d, "subagent-artifacts"))
		.filter((d) => existsSync(d));
}

function describe(path: string): string {
	const file = path.split("/").pop() ?? path;
	const run = file.match(/^[0-9a-f-]{36}_/);
	const agent = run ? file.slice(37).replace(/_\d+_(output|transcript)\.md$/, "").replace(/\.md$/, "") : "";
	const kind = /_output\.md$/.test(file) || path.includes("/outputs/") ? "output" : "artifact";
	return agent ? `${agent} · ${kind}` : kind;
}

function formatSize(bytes: number): string {
	return bytes >= 1024 ? `${(bytes / 1024).toFixed(1)} KB` : `${bytes} B`;
}

function showViewer(title: string, markdown: string, ctx: ExtensionCommandContext): Promise<void> {
	return new Promise((resolve) => {
		ctx.ui
			.custom((tui, theme, _kb, done) => {
				const md = new Markdown(markdown, 1, 1, getMarkdownTheme());
				let offset = 0; // first visible body line (scroll position)
				const CHROME = 6; // blank + title + hints + status + blank + slack
				const close = () => {
					done(undefined);
					resolve();
				};
				const dim = (s: string) => theme.fg("dim", s);
				return {
					render: (width: number) => {
						const bodyH = Math.max(5, (tui.terminal?.rows ?? 24) - CHROME);
						const all = md.render(width);
						const maxOff = Math.max(0, all.length - bodyH);
						if (offset > maxOff) offset = maxOff;
						const visible = all.slice(offset, offset + bodyH);
						const pct = all.length === 0 ? 100 : Math.round(((offset + visible.length) / all.length) * 100);
						const pos = `${offset + 1}-${offset + visible.length}/${all.length} lines · ${pct}%`;
						return [
							"",
							theme.fg("accent", theme.bold(title)),
							dim("↑↓/jk line · PgUp/space page · Home/End or g/G ends · q/esc close"),
							...visible,
							dim(pos + (offset + visible.length >= all.length ? " · end" : "")),
							"",
						];
					},
					invalidate: () => {},
					handleInput: (data: string) => {
						const rows = Math.max(5, (tui.terminal?.rows ?? 24) - CHROME);
						if (matchesKey(data, "escape") || matchesKey(data, "enter") || data === "q") return close();
						if (matchesKey(data, "up") || data === "k") offset -= 1;
						else if (matchesKey(data, "down") || data === "j") offset += 1;
						else if (matchesKey(data, "pageUp")) offset -= rows;
						else if (matchesKey(data, "pageDown") || data === " ") offset += rows;
						else if (matchesKey(data, "home") || data === "g") offset = 0;
						else if (matchesKey(data, "end") || data === "G") offset = Number.MAX_SAFE_INTEGER; // clamped in render
						else return; // unhandled key: no redraw
						if (offset < 0) offset = 0;
						tui.requestRender();
					},
				};
			})
			.catch(resolve);
	});
}

export default function (pi: ExtensionAPI): void {
	pi.registerCommand("subagent-outputs", {
		description: "Browse saved pi-subagents child outputs (newest first) in a scrollable viewer",
		handler: async (args, ctx) => {
			const files: Found[] = [];
			for (const dir of artifactDirs(ctx)) collectMarkdown(dir, files);
			files.sort((a, b) => b.mtime - a.mtime);
			const query = (args ?? "").trim().toLowerCase();
			const filtered = query ? files.filter((f) => f.path.toLowerCase().includes(query)) : files;
			const top = filtered.slice(0, MAX_FILES);
			if (top.length === 0) {
				ctx.ui.notify(query ? `No subagent outputs matching "${query}"` : "No subagent output artifacts found yet", "info");
				return;
			}
			if (ctx.mode !== "tui") {
				for (const f of top) ctx.ui.notify(`${new Date(f.mtime).toISOString().slice(0, 16)}  ${formatSize(f.size).padStart(8)}  ${f.path}`, "info");
				return;
			}
			const labels = top.map(
				(f) => `${new Date(f.mtime).toISOString().slice(5, 16)}  ${formatSize(f.size).padStart(8)}  ${describe(f.path)}  ${f.path.split("/").pop()}`,
			);
			const choice = await ctx.ui.select(`Subagent outputs (${top.length} newest${query ? `, filter: ${query}` : ""})`, labels);
			if (!choice) return;
			const file = top[labels.indexOf(choice)];
			if (!file) return;
			let text: string;
			try {
				text = readFileSync(file.path, "utf8");
			} catch (err) {
				ctx.ui.notify(`Cannot read ${file.path}: ${(err as Error).message}`, "error");
				return;
			}
			const lines = text.split("\n");
			if (lines.length > MAX_LINES) text = lines.slice(0, MAX_LINES).join("\n") + `\n\n… truncated at ${MAX_LINES} lines — full file: ${file.path}`;
			await showViewer(`${describe(file.path)} · ${new Date(file.mtime).toISOString().slice(0, 16)} · ${file.path}`, text, ctx);
		},
	});
}
