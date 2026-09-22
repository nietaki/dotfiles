/**
 * subagent-outputs — `/subagent-outputs` lists the saved output artifacts of
 * pi-subagents child runs for this project (newest first), then shows the
 * chosen report in a scrollable markdown viewer. Pure TUI surface: no model
 * involvement; data comes from the artifact files pi-subagents persists under
 * ~/.pi/agent/sessions/<cwd-slug>/subagent-artifacts/.
 *
 * Keys in the viewer: ↑/↓ or j/k line · PgUp/PgDn or space half-page ·
 * g/G top/bottom · q/esc/enter close.
 */
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { DynamicBorder, getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import { Container, Markdown, matchesKey, ScrollView, Text } from "@earendil-works/pi-tui";
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
			.custom((_tui, theme, _kb, done) => {
				const container = new Container();
				const border = new DynamicBorder((s: string) => theme.fg("accent", s));
				const md = new Markdown(markdown, 1, 1, getMarkdownTheme());
				const view = new ScrollView(md, { scrollbar: "always", overscroll: "contain" });
				container.addChild(border);
				container.addChild(new Text(theme.fg("accent", theme.bold(title)), 1, 0));
				container.addChild(new Text(theme.fg("dim", "↑↓/jk line · PgUp/PgDn/space page · g/G top/bottom · q/esc close"), 1, 0));
				container.addChild(view);
				container.addChild(border);
				const close = () => {
					done(undefined);
					resolve();
				};
				const half = () => Math.max(1, Math.floor(view.viewportHeight / 2) || 20);
				return {
					render: (width: number) => container.render(width),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => {
						if (matchesKey(data, "escape") || matchesKey(data, "q") || matchesKey(data, "enter")) return close();
						if (matchesKey(data, "up") || matchesKey(data, "k")) view.scrollBy(-1);
						else if (matchesKey(data, "down") || matchesKey(data, "j")) view.scrollBy(1);
						else if (matchesKey(data, "pageup")) view.scrollBy(-half());
						else if (matchesKey(data, "pagedown") || matchesKey(data, " ")) view.scrollBy(half());
						else if (matchesKey(data, "g")) view.scrollToStart();
						else if (matchesKey(data, "G")) view.scrollToEnd();
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
