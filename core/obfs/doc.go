// Package obfs is the engine-independent obfuscation suite for the Sora core.
//
// It collects the traffic-masking techniques that the core applies to TLS
// handshakes it initiates itself (connectivity probing, DoH lookups,
// subscription fetches): uTLS ClientHello fingerprint selection, pure-Go
// ClientHello fragmentation, inter-packet timing jitter, and optional fake
// SNI rewriting for the initial handshake packets.
//
// The package is deliberately engine-independent: it works on net.Conn and
// tls.Config values, so every forwarding engine (sing-box, xray, mihomo,
// native) can reuse the same profiles without duplicating logic.
//
// A Profile describes one obfuscation setup. Profiles are validated with
// Validate, normalized with Clamp, and applied with WrapConn (for net.Conn)
// and the uTLS helpers (for TLS handshakes). PresetMax, PresetBalanced and
// PresetFast are ready-made starting points.
//
// Safety rules honored by this package:
//   - FakeSNI is only ever applied to handshakes the core initiates itself,
//     never injected into user traffic, and only where the protocol allows
//     the client to choose the presented name.
//   - All delays are clamped to sane maxima so a misconfigured profile can
//     slow a handshake down but never stall it forever.
package obfs
