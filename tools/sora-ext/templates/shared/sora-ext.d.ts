/**
 * Type definitions for the Sora extension panel API (`window.soraExt`).
 *
 * Panels are plain HTML/JS running in a WebView without Node, `dart:ffi`
 * or network access (v1). The ONLY bridge to the app is `window.soraExt`,
 * documented below. Every method is allow-listed per granted permission:
 * calling a method without its permission rejects the promise with a
 * `SoraExtError` whose `code` is `"permission-denied"`.
 *
 * Normative spec: docs/extensions.md §4. The app-side bridge
 * (app/lib/src/ext/bridge.dart) and the core host (core/ext/host.go) are
 * authoritative; this file mirrors them.
 *
 * Usage (TypeScript):
 * ```ts
 * /// <reference path="./sora-ext.d.ts" />
 * const conns = await window.soraExt.call('getConnections');
 * window.soraExt.onEvent((kind) => {
 *   if (kind === 'session.connected') refresh();
 * });
 * ```
 *
 * Usage (plain JS): the file is a pure `.d.ts` — it emits nothing. Copy it
 * next to your panel for editor autocomplete, or let `sora-ext scaffold`
 * drop it in for you.
 */

/** One live connection. Process name only — no PIDs or paths ever leave the core. */
export interface SoraExtensionConnection {
  /** Opaque connection id, stable for the lifetime of the connection. */
  id: string;
  /** Process name, e.g. "chrome". Empty when unknown. */
  process: string;
  /** Remote host, e.g. "example.com". Empty when unknown. */
  host: string;
  /** Bytes sent in this connection. */
  up_bytes: number;
  /** Bytes received in this connection. */
  down_bytes: number;
}

/** One server from the user's server list. */
export interface SoraExtensionServer {
  /** Opaque server id. */
  id: string;
  /** Display name, e.g. "DE-01 · Frankfurt". */
  name: string;
  /** Country as stored by the app; '' when the app has none for it. */
  country: string;
  /** Last measured latency in ms, or -1 when unknown or unreachable. */
  latency_ms: number;
}

/**
 * A DPI-bypass strategy: the snake_case JSON shape of
 * `sora.core.v1.BypassStrategy` (all 29 fields). Reads always carry the
 * full shape; writes may omit fields (proto defaults apply), but unknown
 * fields or wrong types reject with `invalid-argument`.
 */
export interface SoraBypassStrategy {
  split_pos: string[];
  disorder: boolean;
  oob: boolean;
  tls_record: string;
  host_case: boolean;
  domain_case: boolean;
  method_eol: boolean;
  disorder_scope: string;
  oob_scope: string;
  host_dot: boolean;
  host_tab: boolean;
  host_no_space: boolean;
  method_space: boolean;
  unix_eol: boolean;
  split_any_protocol: boolean;
  tamper_start: string;
  tamper_cutoff: string;
  oob_data: string;
  mss: string;
  desync: string[];
  fake_tls: string;
  fake_quic: string;
  fooling: string;
  ttl: number;
  auto_ttl: boolean;
  repeats: number;
  filter_tcp: string;
  filter_udp: string;
  filter_l7: string;
}

/** A partial strategy for writes: omitted fields take proto defaults. */
export type SoraBypassStrategyInput = Partial<SoraBypassStrategy>;

/** One per-destination binding of a bypass layer. */
export interface SoraBypassBinding {
  /** Destination in the core's form, e.g. "domain:example.com". */
  match: string;
  strategy: SoraBypassStrategyInput;
}

/** A bypass layer: one global strategy plus per-destination bindings. */
export interface SoraBypassLayer {
  global: SoraBypassStrategyInput | null;
  bindings: SoraBypassBinding[];
}

/** A layer as read back: full strategies plus the apply timestamp. */
export interface SoraBypassLayerState {
  global: SoraBypassStrategy | null;
  bindings: Array<{ match: string; strategy: SoraBypassStrategy }>;
  /**
   * RFC 3339 UTC timestamp of the last apply. Optional: a layer that
   * was never applied has no timestamp, and the host omits the key
   * entirely (the mock does the same).
   */
  updated_at?: string;
}

/** One desync backend's availability on this host. */
export interface SoraBypassBackend {
  /** Backend kind, e.g. "nfqws" or "tpws". */
  kind: string;
  available: boolean;
  /** Why the backend cannot run here; '' when it can. */
  reason: string;
}

/** Result of `getBypassCapabilities` (needs `bypass.read`). */
export interface SoraBypassCapabilities {
  platform: string;
  backends: SoraBypassBackend[];
}

/** Result of `getBypassState` (needs `bypass.read`). */
export interface SoraBypassState {
  platform: string;
  /** Where the current global strategy came from, e.g. "extension". */
  global_source: string;
  /** The extension id that applied it; '' when none did. */
  global_from: string;
  session_active: boolean;
  /** An applied layer is waiting for the next connect to take effect. */
  pending_apply: boolean;
  bindings_count: number;
}

/** Arguments for `tuneDesync`. */
export interface SoraTuneDesyncArgs {
  /** Executor to tune for: "nfqws" or "tpws"; '' = the core's default. */
  engine: string;
}

/** Result of `tuneDesync` (needs `bypass.tune`). */
export interface SoraTuneDesyncResult {
  /** Winning strategy id; '' when no candidate worked (an outcome, not an error). */
  winner_id: string;
  winner_describe: string;
  /** Winner fitness in [0, 1]. */
  score: number;
  attempts: number;
  /** The winning strategy, or null when no candidate worked. */
  strategy: SoraBypassStrategy | null;
}

/**
 * Detail payload of a `bypass.event` (delivered to `onEvent` as a JSON
 * string — parse it). Pushed while a bypass panel is open when the core
 * detects censorship.
 */
export interface SoraBypassEventDetail {
  kind: 'censorship';
  /** Detector classification, e.g. "sni_blocking". */
  censorship_kind: string;
  explanation: string;
  /** RFC 3339 UTC. */
  at: string;
}

/**
 * Lifecycle and network events delivered to `onEvent`.
 *
 * Only `session.connected` / `session.disconnected` are emitted by the
 * current panel bridge. The other two kinds are reserved by the spec:
 * panels may subscribe for them, but must not depend on receiving them
 * yet.
 */
export type SoraExtensionEventKind =
  | 'session.connected'
  | 'session.disconnected'
  /** Reserved: not emitted by the current panel bridge yet. */
  | 'network.changed'
  /**
   * Reserved: when the extension is disabled, the current panel bridge
   * tears the panel down without delivering this event first.
   */
  | 'extension.disabled'
  /**
   * Censorship detected by the core; `detail` is a JSON string holding a
   * SoraBypassEventDetail. Sent only to panels of extensions granted a
   * bypass permission, while the panel is open.
   */
  | 'bypass.event';

/** Listener for extension events. `detail` carries extra context when present. */
export type SoraExtensionEventListener = (
  kind: SoraExtensionEventKind,
  detail?: string,
) => void;

/**
 * Machine-readable error codes for rejected `call()` promises. These are
 * exactly the codes the panel bridge and the mock (`sora-ext serve`)
 * emit — no others. (There is no 'token-revoked' code on the panel path:
 * panels do not hold tokens, and a disabled extension's panel is simply
 * torn down.)
 */
export type SoraExtErrorCode =
  /** The extension was not granted the permission the method needs. */
  | 'permission-denied'
  /** The method name is unknown or its arguments are invalid. */
  | 'invalid-argument'
  /** `getConnections` was called while no VPN session is up. */
  | 'not-connected'
  /** Anything else the host could not complete. */
  | 'internal';

/** Rejection reason for `call()` promises. */
export interface SoraExtError extends Error {
  /** Stable code — switch on this, not on `message`. */
  code: SoraExtErrorCode;
  /**
   * The host's human-readable failure text, when it sent one: for
   * `invalid-argument` this is the core's own rejection wording (the
   * bridge carries it next to the code), otherwise a short host
   * sentence. Safe to show to the user as-is; never parse it.
   */
  message: string;
}

/** Arguments for `notify`. */
export interface SoraNotifyArgs {
  /** ≤ 120 characters. */
  title: string;
  /** ≤ 500 characters. */
  body: string;
}

/**
 * The extension API injected into every panel as `window.soraExt`.
 *
 * All `call()` methods return promises. A rejected promise always carries
 * a `SoraExtError` (never a bare string), so `catch (e) { e.code }` works.
 */
export interface SoraExt {
  /**
   * Live connection list (process, host, byte counters).
   * Needs the `connections.read` permission (sensitive).
   */
  call(method: 'getConnections'): Promise<SoraExtensionConnection[]>;
  /**
   * Server list (names, countries, latency).
   * Needs the `servers.read` permission.
   */
  call(method: 'getServers'): Promise<SoraExtensionServer[]>;
  /**
   * Show a notification. Title ≤ 120 chars, body ≤ 500 chars.
   * Needs the `notifications` permission.
   */
  call(method: 'notify', args: SoraNotifyArgs): Promise<void>;
  /**
   * Read the extension's own settings (defaults from `settings_schema`
   * merged with stored values). Needs no permission: an extension can
   * always read its own settings.
   */
  call(method: 'getSettings'): Promise<Record<string, unknown>>;
  /**
   * Write the extension's own settings. The write merges: only the keys
   * given here change, unmentioned keys keep their stored values (so a
   * one-key write like `setSettings({refresh_seconds: 10})` is safe).
   * Values are validated against `settings_schema`; invalid values
   * reject with `invalid-argument` and change nothing.
   * Needs no permission.
   */
  call(method: 'setSettings', args: Record<string, unknown>): Promise<void>;
  /**
   * Which desync backends can run on this host.
   * Needs the `bypass.read` permission (sensitive).
   */
  call(method: 'getBypassCapabilities'): Promise<SoraBypassCapabilities>;
  /**
   * Current bypass state: strategy provenance, session, pending apply.
   * Needs the `bypass.read` permission (sensitive).
   */
  call(method: 'getBypassState'): Promise<SoraBypassState>;
  /**
   * The current bypass layer (global strategy + bindings).
   * Needs the `bypass.read` permission (sensitive).
   */
  call(method: 'getBypassLayer'): Promise<SoraBypassLayerState>;
  /**
   * Replace the bypass layer wholesale. Takes effect at the next
   * connect; the app also writes the global strategy through to its own
   * settings (the user can override it there at any time — the user
   * wins). Needs the `bypass.write` permission (dangerous).
   */
  call(
    method: 'applyBypassLayer',
    args: SoraBypassLayer,
  ): Promise<{ updated_at: string }>;
  /**
   * Run the core's desync tuner once and return the winner.
   * Needs the `bypass.tune` permission (dangerous).
   */
  call(method: 'tuneDesync', args: SoraTuneDesyncArgs): Promise<SoraTuneDesyncResult>;
  /**
   * Subscribe to lifecycle/network events. Returns an unsubscribe function.
   * Needs no permission: every enabled extension may know whether the
   * session is up.
   */
  onEvent(listener: SoraExtensionEventListener): () => void;
}

declare global {
  interface Window {
    /**
     * The extension bridge. Present in every panel loaded from an installed
     * (or dev-mode) extension. Absent when the file is opened directly in a
     * desktop browser — use `sora-ext serve` (mock) for that case.
     */
    readonly soraExt: SoraExt;
  }
}

// This file is a module so the interfaces above can be imported in TS
// projects, while the `declare global` block still augments `window`.
export {};
