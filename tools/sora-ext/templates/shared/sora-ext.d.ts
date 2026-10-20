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
  /** ISO country code or country name as stored by the app. */
  country: string;
  /** Last measured latency in ms, or -1 when unknown. */
  latency_ms: number;
}

/** Lifecycle and network events delivered to `onEvent`. */
export type SoraExtensionEventKind =
  | 'session.connected'
  | 'session.disconnected'
  | 'network.changed'
  /** The extension was disabled or uninstalled. The panel is torn down right after. */
  | 'extension.disabled';

/** Listener for extension events. `detail` carries extra context when present. */
export type SoraExtensionEventListener = (
  kind: SoraExtensionEventKind,
  detail?: string,
) => void;

/** Machine-readable error codes for rejected `call()` promises. */
export type SoraExtErrorCode =
  /** The extension was not granted the permission the method needs. */
  | 'permission-denied'
  /** The method name is unknown or its arguments are invalid. */
  | 'invalid-argument'
  /** The extension was disabled or its token was revoked. */
  | 'token-revoked'
  /** Anything else the host could not complete. */
  | 'internal';

/** Rejection reason for `call()` promises. */
export interface SoraExtError extends Error {
  /** Stable code — switch on this, not on `message`. */
  code: SoraExtErrorCode;
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
   * Write the extension's own settings. Values are validated against
   * `settings_schema`; invalid values reject with `invalid-argument`.
   * Needs no permission.
   */
  call(method: 'setSettings', args: Record<string, unknown>): Promise<void>;
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
