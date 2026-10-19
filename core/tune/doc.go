// Package tune automatically finds a working DPI-evasion strategy when a
// connection fails.
//
// The Tuner tries obfuscation strategies in priority order — the currently
// configured one, then the strategy remembered for this network, then the
// Balanced and Max presets from core/obfs, then zapret handshake-shaping
// alternatives — giving each attempt its own timeout inside a total time
// budget. The first strategy that connects wins and is remembered in a per-network cache tied
// to the F5 network fingerprint (core/profiles) for 30 days, so a familiar
// network starts from the strategy that worked there before and a new
// network starts from the default order.
//
// The package never applies a strategy itself: the caller supplies an
// AttemptFunc that configures the plan and probes the connection. Telemetry
// comes back as a Result whose Summary fits the session journal Detail line.
package tune
