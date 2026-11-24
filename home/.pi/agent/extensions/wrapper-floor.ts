/**
 * wrapper-floor — auto-approve the *benign* indirection-wrapper ask that
 * @gotgenes/pi-permission-system raises for timing/nicing prefixes.
 *
 * WHY THIS EXISTS
 * `time`, `timeout`, `nice` and `nohup` are hardcoded as indirection wrappers
 * (src/access-intent/bash/wrapper-analysis.ts :: INDIRECTION_WRAPPER_NAMES), so
 * a command unit starting with one has its resolved `allow` clamped UP to
 * `ask` AFTER rule resolution (handlers/gates/bash-command.ts ::
 * resolveCommandUnit -> resolveWrapperUnit). No `bash` rule can lift that: an
 * `allow` is inert, only a `deny`/`ask` decides earlier. Consequences:
 *   - `bash: {"*": "allow"}` still prompts on `time make lint` (log sentinel
 *     `<indirection-bash-wrapper>`);
 *   - in a headless/subagent context with no live authority the ask degrades
 *     to `confirmation_unavailable`, i.e. a hard block.
 * The package lifts the floor itself only for a *proven pure reader* behind the
 * wrapper (wrapper transparency, 21-word core), so `time ls` is silent while
 * `time make lint` prompts. This link generalizes that rule to the whole
 * ruleset: it lets the wrapper through when the command it actually runs
 * resolves to `allow` on its own.
 *
 * MECHANISM (verified against @gotgenes/pi-permission-system@31.1.3 source)
 * 1. The gate consults the live-authority chain ONLY when the deterministic
 *    rule resolves to `ask` (policy/permission-gate.ts :: applyPermissionGate).
 *    A link therefore cannot override a rule: `allow` is already allowed and
 *    `deny` is already blocked before the chain is reached.
 * 2. The link is registered via the session-keyed `PermissionsService
 *    .registerAuthorizer` and decides nothing until named in the config's
 *    top-level `authorizerChain` (opt-in activation). A missing link is skipped
 *    fail-safe, so mis-registration cannot lock the agent out.
 * 3. `details.payload.request` carries the gate's own facts — `surface`,
 *    `value`, `matchedPattern`, `executedUnit` (presentation/prompt-payload.ts
 *    :: PromptRequestFacts). A subagent's forwarded ask ships the child's
 *    payload up intact (presentation/forwarded-ask-payload.ts), so this link
 *    works for children too; only a version-skewed ask loses the facts, and
 *    that case defers.
 * 4. The injected `PermissionQuery` answers "what would the rules say about
 *    THIS command" at gate parity, which is what makes the decision
 *    policy-preserving rather than a blanket bypass.
 *
 * WHAT IT DELIBERATELY DOES NOT DO
 *   - Never matches the opaque sentinel `<opaque-bash-wrapper>` (`bash -c`,
 *     `eval`): an unparsed payload stays behind the human.
 *   - Never matches a wrapper outside SAFE_WRAPPERS, so `sudo`, `env`, `xargs`,
 *     `doas`, `watch`, `flock`, … keep their floor.
 *   - Never widens anything: an `ask`/`deny` from the inner command's own rule
 *     defers to the normal dialog. `time git reset --hard` still prompts,
 *     because `git reset *` denies the peeled unit (the floor is currently the
 *     only thing that prompts for it, since the pattern never matches the
 *     wrapper-prefixed text).
 *   - Never touches the path / external_directory surfaces, and no-ops when
 *     every ask is already auto-approved (`/yolo`, `yoloMode`).
 *
 * SERVICE ACCESS
 * Reached through the documented process-global map keyed by
 * `Symbol.for("@gotgenes/pi-permission-system:session-services")` rather than a
 * bare import: this file lives in `~/.pi/agent/extensions/` while the package
 * installs under `~/.pi/agent/npm/node_modules`, which is not on Node's upward
 * resolution path from here. Same seam as extensions/session-yolo.ts.
 *
 * The file has NO runtime imports (type-only), so the decision function below
 * can be exercised directly with `node` type stripping.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

// --- Local structural types for the permission-service seam we use. ----------
// Declared here (rather than imported) so this extension has no runtime/module
// dependency on the package's resolution. Shapes mirror the package's public
// `Authorizer` / `PermissionQuery` / `AuthorizerLog` contracts.
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

/** The gate facts this link reads (a subset of `PromptRequestFacts`). */
export interface RequestFactsLike {
  readonly requester?: { readonly agentName?: string | null } | null;
  readonly surface: string;
  readonly value: string;
  readonly matchedPattern: string | null;
  readonly executedUnit: string | null;
}
interface QueryLike {
  checkPermission(surface: string, value?: string, agentName?: string): {
    state: string;
  };
}
interface LogLike {
  review(event: string, details?: Record<string, unknown>): void;
  debug(event: string, details?: Record<string, unknown>): void;
}

// --- Constants --------------------------------------------------------------
const SESSION_SERVICES_KEY = Symbol.for(
  "@gotgenes/pi-permission-system:session-services",
);

export const LINK_NAME = "wrapper-floor";

/** Synthetic `matchedPattern` the gate stamps on a floored indirection unit. */
export const INDIRECTION_SENTINEL = "<indirection-bash-wrapper>";

/**
 * Wrappers this link may lift the floor for. Extend deliberately: every entry
 * means "when the command behind this prefix is allowed, do not prompt".
 * `sudo`/`doas`/`env`/`xargs` are intentionally absent — they change *who* runs
 * or *what* is fed to the command, which is the case the floor exists for.
 */
export const SAFE_WRAPPERS: ReadonlySet<string> = new Set([
  "time",
  "timeout",
  "nice",
  "nohup",
]);

/** First word of a command unit, with any directory prefix removed. */
function headWord(value: string): string {
  const first = value.trim().split(/\s+/)[0] ?? "";
  return first.replace(/^.*\//, "");
}

/**
 * The decision for one `ask`, as a pure function of the gate facts.
 *
 * Returns `allow` only when every clause holds; `defer` (never `deny`) in every
 * other case, so anything this link does not positively understand still
 * reaches the human prompt exactly as before.
 */
export function decideWrapperFloor(
  request: RequestFactsLike,
  query: QueryLike,
  log?: LogLike,
): AuthorizerVerdict {
  const defer = (reason: string, extra?: Record<string, unknown>): AuthorizerVerdict => {
    log?.debug("wrapper_floor.deferred", { reason, ...extra });
    return { kind: "defer" };
  };

  // 1. bash only — a path/external_directory ask is not ours, and the package's
  //    delegation envelope would cap an `allow` there anyway.
  if (request.surface !== "bash") return defer("surface", { surface: request.surface });

  // 2. Only the indirection floor. The opaque sentinel (`bash -c`, `eval`)
  //    means the payload was never parsed, so there is no inner command to
  //    trust.
  if (request.matchedPattern !== INDIRECTION_SENTINEL) {
    return defer("not-indirection-floor", { matchedPattern: request.matchedPattern });
  }

  // 3. The peeled inner command is what decides; without it there is nothing to
  //    check (version-skewed forwarded ask, or an unestablished peel).
  const inner = request.executedUnit;
  if (!inner) return defer("no-executed-unit");

  // 4. Prefix allowlist.
  const head = headWord(request.value);
  if (!SAFE_WRAPPERS.has(head)) return defer("wrapper-not-allowed", { head });

  // 5. Policy parity: the command that actually runs must itself be allowed.
  //    An `ask`/`deny` here defers to the normal dialog.
  const agentName = request.requester?.agentName ?? undefined;
  const innerCheck = query.checkPermission("bash", inner, agentName);
  if (innerCheck.state !== "allow") {
    return defer("inner-not-allowed", { inner, innerState: innerCheck.state });
  }

  log?.review("wrapper_floor.allowed", {
    head,
    command: request.value,
    executedUnit: inner,
  });
  return { kind: "allow" };
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

export default function wrapperFloorExtension(pi: ExtensionAPI): void {
  let activeSessionId: string | null = null;
  let disposeAuthorizer: (() => void) | null = null;

  const authorize: AuthorizeFn = async (details, query, log) => {
    // Only ever reached for an `ask` (applyPermissionGate), so this cannot
    // override the deterministic policy. Fail closed on any surprise: an
    // exception must not turn into an allow.
    try {
      const payload = (details as { payload?: { request?: RequestFactsLike } })
        ?.payload;
      const request = payload?.request;
      if (!request) return { kind: "defer" };
      return decideWrapperFloor(request, query as QueryLike, log as LogLike);
    } catch {
      return { kind: "defer" };
    }
  };

  const ensureRegistered = (sessionId: string): void => {
    // Idempotent: `permissions:ready` fires at least once per session and repeats.
    if (activeSessionId === sessionId && disposeAuthorizer) return;

    if (activeSessionId !== sessionId) {
      disposeAuthorizer?.();
      disposeAuthorizer = null;
      activeSessionId = sessionId;
    }

    const service = getPermissionService(sessionId);
    if (!service) return; // A later `permissions:ready` retries.
    try {
      disposeAuthorizer = service.registerAuthorizer(LINK_NAME, authorize);
    } catch (error) {
      // Only a duplicate registration means the link is already live; anything
      // else leaves it unregistered, so asks still reach the normal prompt.
      const msg = error instanceof Error ? error.message : String(error);
      if (!/duplicate|already/i.test(msg)) disposeAuthorizer = null;
    }
  };

  pi.events.on("permissions:ready", (raw) => {
    const { sessionId } = (raw ?? {}) as ReadyEventLike;
    if (!sessionId) return;
    ensureRegistered(sessionId);
  });

  pi.on("before_agent_start", (_event, ctx: ExtensionContext) => {
    // Retry in case the first `permissions:ready` predated the service publish.
    try {
      const sid = ctx.sessionManager.getSessionId();
      if (sid) ensureRegistered(sid);
    } catch {
      /* sessionManager may be unavailable in some hosts */
    }
  });

  pi.on("session_shutdown", () => {
    disposeAuthorizer?.();
    disposeAuthorizer = null;
    activeSessionId = null;
  });
}
