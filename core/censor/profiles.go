package censor

import (
	obfsv1 "github.com/levvs-one/sora-client/core/gen/sora/obfs/v1"
)

// RecommendedProfile maps a verdict kind to the obfuscation preset most
// likely to route around that interference.
//
// The preset is the real sora.obfs.v1.ObfsPreset contract: the client can
// hand it straight to ObfsControl.ApplyObfsProfile. DisplayName and Why are
// the human-readable account of what the preset changes about the
// connection's appearance on the wire.
//
// Kinds with no honest prescription have no row. DNS poisoning is fixed by
// encrypted DNS, not by handshake obfuscation; an unreachable IP is fixed by
// another server or port; Unknown and NoInterference need nothing. Suggesting
// a preset where none helps would be decoration, not a solution.
func RecommendedProfile(k Kind) (ProfileRef, bool) {
	p, ok := profileForKind[k]
	return p, ok
}

// profileForKind is the whole prescription table. It is small on purpose:
// every row must name a strategy with a real mechanism behind it.
var profileForKind = map[Kind]ProfileRef{
	KindSNIBlocking: {
		Preset:      obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		DisplayName: "Balanced obfuscation",
		Why:         "a browser-like handshake split into fragments, so SNI filters cannot match it at a glance",
	},
	KindRSTInjection: {
		Preset:      obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		DisplayName: "Balanced obfuscation",
		Why:         "fragmenting the handshake denies pattern-matching resets their signature",
	},
	KindHandshakeTimeout: {
		Preset:      obfsv1.ObfsPreset_OBFS_PRESET_BALANCED,
		DisplayName: "Balanced obfuscation",
		Why:         "a camouflaged handshake with jitter is not held the way a recognizable one is",
	},
}
