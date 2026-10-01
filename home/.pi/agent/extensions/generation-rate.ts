/**
 * generation-rate — publish the model's output-token rate to the powerline
 * footer under the stable status key `token-rate`.
 *
 * WHAT IT SHOWS
 * `NN t/s` — output tokens ÷ generation seconds for the most recent *assistant
 * message*, published as the plain-text `token-rate` extension status.
 * `npm:pi-powerline-footer` promotes that status into its own segment through
 * `powerline.customItems` in settings.json (positioned before `session-yolo`,
 * colored `muted` to match the built-in cache-read segment). Segment color,
 * prefix, and placement therefore live in that config, NOT here: this file
 * emits ANSI-free text only.
 *
 * MEASUREMENT (verified against @earendil-works/pi-coding-agent 0.99.2)
 * - `message_start` for an assistant message is emitted when the provider
 *   stream pushes its `start` event, i.e. after the request was sent and the
 *   first streamed event arrived. `timestamp` on the message itself is set
 *   earlier (when the partial message object is built, before the fetch), so
 *   the two boundaries are not interchangeable.
 * - `message_end` carries the authoritative finalized message with
 *   `usage.output`. Per docs/message-types.md, `reasoning` tokens are already
 *   included in `output` — do not add them again.
 * - Pi reports no provider-side generation duration, so the elapsed time is
 *   sampled with a monotonic clock in these two event callbacks. That is event
 *   driven (not a background timer) and measures generation only: it excludes
 *   time-to-first-token, tool execution, and any waiting between turns. One
 *   user prompt with N model calls therefore updates the rate N times; the
 *   footer shows the last completed call.
 *
 * HIDDEN RATHER THAN WRONG
 * The status is cleared/never published while a session has no completed
 * assistant message; aborted/error responses and samples shorter than
 * MIN_SAMPLE_MS are skipped so a truncated or non-streamed response cannot
 * print a bogus rate (the previously published value stays).
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const STATUS_KEY = "token-rate";

// Below this, the sample is dominated by request/stream bookkeeping rather than
// actual token generation (e.g. a non-streamed response emitted as
// message_start immediately followed by message_end), so the rate would be
// nonsense. Keep the previously published value instead.
const MIN_SAMPLE_MS = 100;

/** "42 t/s" / "3.4 t/s" for a believable sample; null when the sample is unusable. */
function formatRate(outputTokens: number, elapsedMs: number): string | null {
  if (!(outputTokens > 0) || elapsedMs < MIN_SAMPLE_MS) return null;
  const rate = outputTokens / (elapsedMs / 1000);
  if (!Number.isFinite(rate) || rate <= 0) return null;
  const text = rate < 10 ? rate.toFixed(1) : String(Math.min(9999, Math.round(rate)));
  return `${text} t/s`;
}

export default function generationRateExtension(pi: ExtensionAPI): void {
  let lastCtx: ExtensionContext | null = null;
  let lastText: string | null = null;
  // Generation start for the assistant message currently being streamed.
  // Assistant messages are produced one at a time per session, so a single
  // slot is enough; a fresh start always overwrites a stale one.
  let startedAtMs: number | null = null;

  const publish = (): void => {
    lastCtx?.ui.setStatus(STATUS_KEY, lastText ?? undefined);
  };

  const reset = (): void => {
    startedAtMs = null;
    lastText = null;
  };

  // --- Assistant message lifecycle -----------------------------------------
  pi.on("message_start", (event) => {
    if (event.message.role !== "assistant") return;
    startedAtMs = performance.now();
  });

  pi.on("message_end", (event, ctx) => {
    if (event.message.role !== "assistant") return;
    const message = event.message;

    const startedAt = startedAtMs;
    startedAtMs = null;

    // Provider error / user abort: `usage.output` can be zeroed or partial, so
    // it would print a meaningless rate. Keep whatever was last shown.
    if (message.stopReason === "error" || message.stopReason === "aborted") return;
    if (startedAt === null) return;

    const output = message.usage?.output ?? 0;
    const text = formatRate(output, performance.now() - startedAt);
    if (!text) return;

    lastCtx = ctx;
    lastText = text;
    publish();
  });

  // --- Session boundaries ---------------------------------------------------
  // Pi wipes every extension status on session invalidation (new / fork /
  // switch) and on /reload, so keep a fresh context and re-publish at the
  // boundaries. A resumed or brand-new session must not inherit another
  // session's rate, hence the reset.
  pi.on("session_start", (_event, ctx) => {
    lastCtx = ctx;
    reset();
    publish();
  });
  pi.on("before_agent_start", (_event, ctx) => {
    lastCtx = ctx;
    publish();
  });
  pi.on("session_shutdown", (_event, ctx) => {
    reset();
    lastText = null;
    ctx.ui.setStatus(STATUS_KEY, undefined);
    lastCtx = null;
  });
}
