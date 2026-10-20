// Package obfs is a library of traffic-masking techniques for TLS
// handshakes the core initiates itself: uTLS ClientHello fingerprint
// selection, pure-Go ClientHello fragmentation, inter-packet timing
// jitter, and optional fake SNI rewriting for the initial handshake
// packets. A Profile describes one setup; profiles are validated with
// Validate, normalized with Clamp, applied with WrapConn (for net.Conn)
// or DialTLS (dial + uTLS handshake + wrapping in one step), and
// converted to and from the wire contract with ProfileFromProto.
// PresetMax, PresetBalanced and PresetFast are ready-made starting
// points.
//
// Production status (2026-10-20): the package is wired into production
// in exactly one place — diagnostics calls Profile.FingerprintID to
// map a uTLS fingerprint name to the ClientHello bytes the JA4
// self-check measures. Nothing in the production tree applies an
// obfuscation profile to the handshakes the core initiates itself
// (connectivity probing, DoH lookups, subscription fetches): WrapConn
// and DialTLS exist, are covered by unit tests, and are not called by
// any production code path. The engines (sing-box, xray, mihomo) apply
// their own TLS behavior to user traffic; this package does not sit on
// that path either. Removing the package would only break the JA4
// diagnostics; wiring the profiles into probe/DoH/subscription fetch
// is a product decision (SW1d/SW1c) and is deliberately not done here.
//
// Safety rules honored by the techniques themselves:
//   - FakeSNI is only ever applied to handshakes the core initiates
//     itself, never injected into user traffic, and only where the
//     protocol allows the client to choose the presented name.
//   - All delays are clamped to sane maxima so a misconfigured profile
//     can slow a handshake down but never stall it forever.
package obfs
