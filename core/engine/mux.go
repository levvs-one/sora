package engine

// Multiplexing defaults for REALITY (T002/T007).
//
// The siberian freeze triggers on more than three parallel TLS handshakes
// sharing one SNI. Multiplexing many application streams over a single
// TLS connection keeps the handshake count at one and cuts the trigger
// off at the source. It is on by default for REALITY outbounds because a
// browser-like dest site expects connection reuse anyway; disabling it
// must be a deliberate choice.
//
// Architectural decision for the vision↔mux conflict (T002): in Xray,
// mux is inert under xtls-rprx-vision, so the renderer skips it there —
// vision wins, mux is not emitted. The anti-parallelism role under vision
// belongs to XHTTP+xmux (see the spec), not to outbound mux. sing-box and
// mihomo have no vision flow, so mux stays on for their REALITY outbounds.
//
// NOTE: Options.Mux is declared in plan.go (Options struct). The type
// lives here to keep this file the single home of the mux policy.
type MuxOptions struct {
	// Disabled turns the REALITY multiplexing default off. Only set this
	// when the server is known to mishandle mux.
	Disabled bool
	// Concurrency caps the multiplexed streams per TLS connection
	// (Xray "concurrency", sing-box "max_streams"). Zero uses the engine
	// default. Values above ~32 rarely help and can trip server limits.
	Concurrency int
}

// MuxConcurrency resolves the effective stream cap: the configured value
// clamped to a sane range, or the default when unset.
func MuxConcurrency(o MuxOptions) int {
	if o.Concurrency > 0 {
		if o.Concurrency > 128 {
			return 128
		}
		return o.Concurrency
	}
	return 8
}

// RealityMux reports whether the outbound gets default multiplexing: a
// REALITY outbound in a plan whose mux default is not disabled. Vision
// flows are excluded by the renderers themselves (see the architectural
// decision above), so this predicate stays engine-neutral.
func RealityMux(o Outbound, mux MuxOptions) bool {
	return o.TLS.Reality && !mux.Disabled
}
