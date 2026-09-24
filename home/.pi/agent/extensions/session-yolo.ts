/**
 * session-yolo — a session-scoped operator switch for how pi-permission-system
 * resolves its `ask` decisions, WITHOUT touching the rule engine.
 *
 * WHY THIS EXISTS
 * The package's built-in `yoloMode` auto-approves every ask, but it is a
 * *persisted config knob*: the `/permission-system` modal / `save()` writes
 * `~/.pi/agent/extensions/pi-permission-system/config.json`, and the config is
 * re-read from disk on refresh — so it is not an ephemeral, per-session toggle
 * and is not reliably session-scoped. We want a switch that lives only in this
 * process and resets with the session.
 *
 * MECHANISM (verified against @gotgenes/pi-permission-system@31.1.3 source)
 * 1. The gate pipeline `policy/permission-gate.ts :: applyPermissionGate` only
 *    escalates to the live-authority chain when the deterministic rule resolves
 *    to `ask`. `allow` → allowed by rule; `deny` → blocked by rule; the chain is
 *    never consulted. => A registered authorizer link CANNOT override the
 *    rule-based logic. It only decides the interactive prompts. (This is the
 *    whole point of "bypass interactive asks, not the rule-based logic".)
 * 2. A downstream extension registers a named link via the session-keyed
 *    `PermissionsService.registerAuthorizer`. It decides NOTHING until the
 *    operator names it in the config's top-level `authorizerChain` (opt-in
 *    activation), which we set in extensions/pi-permission-system/config.json.
 *    If a named link is ever missing, the chain skips it fail-safe and the ask
 *    still reaches the human prompt — so mis-registration can never lock the
 *    agent out or silently auto-approve.
 * 3. The chain owner wraps every link in a bounded-delegation envelope
 *    (`authority/delegation-envelope.ts`): a link's `allow` on the `path` or
 *    `external_directory` surface FAMILY is downgraded to `defer` (the ask falls
 *    through to the human). `deny`/`defer` are never widened. => In `allow` mode
 *    bash / mcp / skill / per-tool asks are auto-approved, but path &
 *    external-directory asks STILL prompt. That is a deliberate package-level
 *    guardrail we do not (and cannot) defeat.
 *
 * SERVICE ACCESS
 * The service is reached through the documented process-global map keyed by
 * `Symbol.for("@gotgenes/pi-permission-system:session-services")` — the same
 * slot `publishPermissionsService` / `getPermissionsService(sessionId)` use, and
 * the mechanism that survives Pi's per-extension jiti isolation. We read the map
 * directly instead of `import`-ing the package: this extension lives in
 * `~/.pi/agent/extensions/`, but the package installs under
 * `~/.pi/agent/npm/node_modules` — NOT on Node's upward resolution path from
 * this directory — so a bare `import` would fail to resolve here.
 *
 * MODES (in-memory only; reset to `prompt` whenever the session id changes)
 *   prompt  — link defers; asks go to the normal interactive dialog (default)
 *   allow   — link approves the asks it is permitted to (see envelope cap above)
 *   deny    — link refuses asks with a teaching reason (strict / headless)
 *
 * CONTROLS (operator-facing; deliberately NOT model-callable for changes)
 *   /yolo [on|off|allow|deny|prompt|toggle|status]  — set or inspect the mode
 *   Ctrl+Alt+Y  — toggle prompt <-> allow
 *   `session_yolo_status` tool — the agent may READ the mode (to propose
 *       enabling YOLO before a long autonomous run); it has NO way to change it.
 *
 * SUBAGENT NOTE
 * Each Pi session (root + in-process children) loads its own instance with its
 * own state. A non-UI child *relays* its asks to the serving parent, and the
 * PARENT's chain adjudicates them — so enable the mode in the interactive
 * session that answers the prompts, not in a child.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";
import { Type } from "typebox";

type AskMode = "prompt" | "allow" | "deny";

// --- Local structural types for the permission-service seam we use. ----------
// Declared here (rather than imported) so this extension has no runtime/module
// dependency on the package's module resolution. The shapes mirror the package's
// public `AuthorizerVerdict` / `registerAuthorizer` contract.
type AuthorizerVerdict =
  | { kind: "allow" }
  | { kind: "deny"; reason?: string }
  | { kind: "defer" };
type AuthorizeFn = (
  details: unknown,
  query: unknown,
  log: unknown,
) => Promise<AuthorizerVerdict>;
interface PermissionsServiceLike {
  registerAuthorizer(name: string, authorize: AuthorizeFn): () => void;
}
interface ReadyEventLike {
  sessionId: string | null;
}

// --- Constants --------------------------------------------------------------
const SESSION_SERVICES_KEY = Symbol.for(
  "@gotgenes/pi-permission-system:session-services",
);
const LINK_NAME = "session-yolo";
const STATUS_KEY = "session-yolo";

// Truecolor matches pi-footer's own model-name rendering (see footer-provider).
const DIM = "\x1b[38;2;120;120;120m";
const AMBER = "\x1b[38;2;255;176;0m";
const RED = "\x1b[38;2;255;95;95m";
const RESET = "\x1b[39m";

const MODE_LABEL: Record<AskMode, string> = {
  prompt: "session-yolo:prompt",
  allow: "session-yolo:auto-allow",
  deny: "session-yolo:auto-deny",
};

function modeColor(mode: AskMode): string {
  return mode === "allow" ? AMBER : mode === "deny" ? RED : DIM;
}

/** Resolve the node's own service from the documented process-global map. */
function getPermissionService(
  sessionId: string,
): PermissionsServiceLike | undefined {
  const store = globalThis as Record<symbol, unknown>;
  const map = store[SESSION_SERVICES_KEY] as
    | Map<string, PermissionsServiceLike>
    | undefined;
  if (!map || typeof map.get !== "function") return undefined;
  const svc = map.get(sessionId);
  return svc && typeof svc.registerAuthorizer === "function" ? svc : undefined;
}

export default function sessionYoloExtension(pi: ExtensionAPI): void {
  // --- Per-session state (this instance belongs to exactly one node/session). -
  let mode: AskMode = "prompt";
  let activeSessionId: string | null = null;
  let disposeAuthorizer: (() => void) | null = null;
  let linkRegistered = false;
  let lastCtx: ExtensionContext | null = null;

  const publishStatus = (): void => {
    if (!lastCtx) return;
    // Always visible, like the provider segment, so "is YOLO on?" is at a glance.
    // Append a subtle marker if the allow/deny mode is inert (link not active).
    const inert = mode !== "prompt" && !linkRegistered ? " (!)" : "";
    lastCtx.ui.setStatus(
      STATUS_KEY,
      `${modeColor(mode)}${MODE_LABEL[mode]}${inert}${RESET}`,
    );
  };

  const setMode = (next: AskMode, ctx: ExtensionContext, quiet = false): void => {
    mode = next;
    lastCtx = ctx;
    publishStatus();
    if (quiet) return;
    if (next === "prompt") {
      ctx.ui.notify("session-yolo: asks will prompt (normal).", "info");
    } else if (next === "allow") {
      ctx.ui.notify(
        linkRegistered
          ? "session-yolo ON: permitted asks auto-approved. (path/external-directory asks still prompt.)"
          : "session-yolo ON, but the authorizer link is not active — asks still prompt. Check the config authorizerChain and that this package is reloaded.",
        "warning",
      );
    } else {
      ctx.ui.notify(
        linkRegistered
          ? "session-yolo DENY: asks will be auto-rejected (rules unchanged)."
          : "session-yolo DENY set, but the authorizer link is not active — asks still prompt.",
        "warning",
      );
    }
  };

  const toggleMode = (ctx: ExtensionContext): void => {
    setMode(mode === "allow" ? "prompt" : "allow", ctx);
  };

  // --- Authorizer registration (on the session's service) --------------------
  const authorize: AuthorizeFn = async () => {
    // Only ever reached for an `ask` (see applyPermissionGate). Rule allow/deny
    // never call into the chain, so this cannot override the deterministic policy.
    if (mode === "allow") return { kind: "allow" };
    if (mode === "deny") {
      return {
        kind: "deny",
        reason:
          "Auto-rejected by session-yolo (mode=deny). Rules are unchanged; ask again after '/yolo off' if this was expected.",
      };
    }
    // prompt: pass through to the next link / terminal (the human dialog).
    return { kind: "defer" };
  };

  const ensureRegistered = (sessionId: string): void => {
    // Idempotent: permissions:ready fires at least once per session and repeats.
    if (activeSessionId === sessionId && disposeAuthorizer) return;

    // New session (resume / /new / child) → reset to conservative defaults.
    if (activeSessionId !== sessionId) {
      disposeAuthorizer?.();
      disposeAuthorizer = null;
      linkRegistered = false;
      mode = "prompt";
      activeSessionId = sessionId;
      publishStatus();
    }

    const service = getPermissionService(sessionId);
    if (!service) {
      // No service for this node yet — a later `permissions:ready` re-announcement
      // (first before_agent_start) will retry. Leave the link unregistered so the
      // ask still reaches the terminal prompt (fail-safe), and mark inert.
      linkRegistered = false;
      publishStatus();
      return;
    }
    try {
      disposeAuthorizer = service.registerAuthorizer(LINK_NAME, authorize);
      linkRegistered = true;
    } catch {
      // Duplicate registration throws; treat the existing link as ours.
      linkRegistered = true;
    }
    publishStatus();
  };

  // --- Lifecycle / events ----------------------------------------------------
  pi.events.on("permissions:ready", (raw) => {
    const { sessionId } = (raw ?? {}) as ReadyEventLike;
    if (!sessionId) return;
    ensureRegistered(sessionId);
  });

  // Keep a fresh context and re-publish the footer segment at turn boundaries,
  // the same reason footer-provider republishes on these events.
  pi.on("session_start", (_event, ctx) => {
    lastCtx = ctx;
    publishStatus();
  });
  pi.on("before_agent_start", (_event, ctx) => {
    lastCtx = ctx;
    // Retry registration in case the first `permissions:ready` predated publish.
    try {
      const sid = ctx.sessionManager.getSessionId();
      if (sid) ensureRegistered(sid);
    } catch {
      /* sessionManager may be unavailable in some hosts */
    }
    publishStatus();
  });
  pi.on("model_select", (_event, ctx) => {
    lastCtx = ctx;
    publishStatus();
  });
  pi.on("session_shutdown", () => {
    disposeAuthorizer?.();
    disposeAuthorizer = null;
    linkRegistered = false;
    activeSessionId = null;
    mode = "prompt";
    lastCtx?.ui.setStatus(STATUS_KEY, undefined);
    lastCtx = null;
  });

  // --- Operator command ------------------------------------------------------
  pi.registerCommand("yolo", {
    description:
      "Session-scoped ask handler (does NOT change rules): on|off|allow|deny|prompt|toggle|status",
    getArgumentCompletions: (prefix) => {
      const norm = (prefix ?? "").trim().toLowerCase();
      const opts = [
        { value: "on", label: "on", description: "Auto-approve permitted asks" },
        { value: "allow", label: "allow", description: "Same as on" },
        { value: "off", label: "off", description: "Resume prompting (default)" },
        { value: "prompt", label: "prompt", description: "Same as off" },
        { value: "deny", label: "deny", description: "Auto-reject asks (rules unchanged)" },
        { value: "toggle", label: "toggle", description: "Flip prompt <-> allow" },
        { value: "status", label: "status", description: "Show current mode" },
      ];
      const filtered = opts.filter((o) => o.value.startsWith(norm));
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args, ctx) => {
      const choice = (args ?? "").trim().toLowerCase();
      lastCtx = ctx;
      switch (choice) {
        case "":
        case "toggle":
          toggleMode(ctx);
          break;
        case "on":
        case "allow":
          setMode("allow", ctx);
          break;
        case "off":
        case "prompt":
        case "normal":
          setMode("prompt", ctx);
          break;
        case "deny":
        case "block":
          setMode("deny", ctx);
          break;
        case "status":
        case "show":
          ctx.ui.notify(
            `session-yolo: mode=${mode} link=${linkRegistered ? "active" : "inactive"} ` +
              `(allow is capped on path/external_directory asks)`,
            "info",
          );
          break;
        default:
          ctx.ui.notify(
            "Usage: /yolo [on|off|allow|deny|prompt|toggle|status]",
            "warning",
          );
      }
    },
  });

  // --- Operator shortcut (Ctrl+Alt+Y; Ctrl+Y is Pi's yank) -------------------
  pi.registerShortcut(Key.ctrlAlt("y"), {
    description: "Toggle session-yolo (auto-approve asks <-> prompt)",
    handler: (ctx) => toggleMode(ctx),
  });

  // --- Read-only status tool (agent may query, never change) -----------------
  pi.registerTool({
    name: "session_yolo_status",
    label: "session-yolo status",
    description:
      "READ-ONLY: report the current session ask-handling mode (prompt | allow | deny), " +
      "whether the session-yolo authorizer link is active, and its cap. It cannot change " +
      "the mode. If mode is 'prompt' and you are about to run a long autonomous task, tell " +
      "the operator they can enable auto-approval with /yolo or Ctrl+Alt+Y — do NOT attempt " +
      "to toggle it yourself.",
    promptSnippet: "Read the session ask-handling (YOLO) mode (read-only)",
    parameters: Type.Object({}, { additionalProperties: false }),
    async execute(_toolCallId) {
      const capNote =
        mode === "allow"
          ? " Note: allow is capped by the package — path & external-directory asks still prompt."
          : "";
      const text =
        `session-yolo: mode=${mode}; link=${linkRegistered ? "active" : "inactive"}; ` +
        `rules are always enforced by the engine; this only affects 'ask' resolutions.` +
        capNote;
      return {
        content: [{ type: "text" as const, text }],
        details: { mode, linkRegistered, capped: true },
      };
    },
  });
}
