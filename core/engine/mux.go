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
// Architectural decision for the vision↔mux conflict (T002, corrected by
// PASS3 deep S3a): ALL THREE engines implement the vision flow —
// sing-box documents `flow: xtls-rprx-vision` on its VLESS outbound and
// the renderer emits it verbatim, and mihomo passes flow through to its
// VLESS stack. The earlier premise "sing-box and mihomo have no vision
// flow, so mux stays on for their REALITY outbounds" was false, and it
// produced configs that emitted multiplex+vision together on two of the
// three engines — a combination with no defined semantics on the server
// side (a vision user is not a mux user). The predicate below is now
// flow-aware for every engine: a vision flow suppresses mux everywhere,
// not just in the Xray renderer. Under vision the anti-parallelism role
// belongs to XHTTP+xmux (see the spec), not to outbound mux.
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
// REALITY outbound in a plan whose mux default is not disabled and whose
// flow is not an XTLS vision flow. The vision exclusion lives here, in
// the shared predicate, so no renderer can reintroduce mux+vision by
// forgetting its own guard (PASS3 deep S3a).
//
// XHTTP is excluded for the same reason vision is: the transport
// already multiplexes (xmux), and layering outbound mux (mux.cool on
// Xray, smux on sing-box/mihomo) over it is rejected by servers —
// proven by traffic (CENSOR-P1: an Xray server answers a mux.cool
// stream over XHTTP with "failed to read metadata" and closes it;
// the same plan with mux suppressed carries traffic on all three
// engines). Before this exclusion every non-vision REALITY+XHTTP
// plan was broken by the mux default it never asked for.
func RealityMux(o Outbound, mux MuxOptions) bool {
	return o.TLS.Reality && !mux.Disabled && !IsVisionFlow(o.Flow) && o.Transport.Type != "xhttp"
}
