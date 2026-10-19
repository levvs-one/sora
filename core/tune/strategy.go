package tune

import (
	"github.com/levvs-one/sora-client/core/engine"
)

// Strategy is one obfuscation candidate the tuner can try. The tuner treats
// strategies opaquely: translating one into a plan and probing the
// connection is the caller's job (see AttemptFunc). Zapret parameters ride
// along so the caller can turn them into bypass outbounds; the obfs presets
// travel by ID only (see IDBalanced, IDMax) because their contents are owned
// by core/obfs; Current carries nothing because it means "whatever the plan
// already has".
type Strategy struct {
	// ID is stable across restarts; it is what the cache stores.
	ID string
	// Name is a short human-readable label for logs and telemetry.
	Name string
	// Bypass holds zapret handshake-shaping parameters. Meaningful only
	// when HasBypass is true.
	Bypass engine.BypassStrategy
	// HasBypass reports whether Bypass should be applied.
	HasBypass bool
}

// Well-known strategy IDs. The obfs presets are defined by core/obfs; the
// tuner references them by ID and never duplicates their contents.
const (
	// IDCurrent retries the connection with the plan's current configuration.
	IDCurrent = "current"
	// IDBalanced is obfs.PresetBalanced (modest fragmentation and jitter
	// over a browser ClientHello fingerprint).
	IDBalanced = "preset/balanced"
	// IDMax is obfs.PresetMax (randomized fingerprint, aggressive
	// fragmentation, noticeable jitter).
	IDMax = "preset/max"
)

// CurrentStrategy is the "change nothing" candidate: retry the connection
// with the configuration the plan already carries, under a fresh timeout.
func CurrentStrategy() Strategy {
	return Strategy{ID: IDCurrent, Name: "current"}
}

// ObfsBalanced is the Balanced preset from core/obfs. The tuner carries it
// by ID only: translating the ID into obfs.PresetBalanced and applying it
// is the caller's job (see AttemptFunc).
func ObfsBalanced() Strategy {
	return Strategy{ID: IDBalanced, Name: "balanced"}
}

// ObfsMax is the Max preset from core/obfs. Like ObfsBalanced, it is
// carried by ID only; the caller maps it to obfs.PresetMax.
func ObfsMax() Strategy {
	return Strategy{ID: IDMax, Name: "max"}
}

// ZapretAlternatives lists individual zapret handshake-shaping tricks, from
// the least to the most intrusive. They run after both presets. The pool is
// curated from the vendored blockcheck.sh strategy corpus
// (third_party/zapret): every entry must have passed a real probe against a
// censored domain before it earns a place here; marketing claims are not
// admitted. The strategies only shape TCP handshakes (tpws); QUIC/UDP desync
// is a separate opt-in nfqws profile, see core/engine/bypass.
func ZapretAlternatives() []Strategy {
	return []Strategy{
		{
			// Splits the ClientHello into two TLS records; the SNI lands in
			// the second one. Cheapest trick that still works.
			ID:   "zapret/tlsrec",
			Name: "zapret tlsrec",
			Bypass: engine.BypassStrategy{
				TLSRecord: "sniext+1",
			},
			HasBypass: true,
		},
		{
			// Plain split at the first bytes; defeats naive SNI matchers
			// that only look at the first segment.
			ID:   "zapret/split",
			Name: "zapret split",
			Bypass: engine.BypassStrategy{
				SplitPos: []string{"1", "2"},
			},
			HasBypass: true,
		},
		{
			// Split plus disorder: the second part goes first. The default
			// zapret_with_vpn strategy; breaks reassembly-based DPI.
			ID:   "zapret/disorder",
			Name: "zapret disorder",
			Bypass: engine.BypassStrategy{
				SplitPos: []string{"1", "2"},
				Disorder: true,
			},
			HasBypass: true,
		},
		{
			// Disorder scoped to TLS only, and only the handshake is
			// touched: long-lived connections keep full speed while the
			// SNI-bearing part is still scrambled.
			ID:   "zapret/disorder-tls",
			Name: "zapret disorder tls-only",
			Bypass: engine.BypassStrategy{
				SplitPos:      []string{"1"},
				Disorder:      true,
				DisorderScope: "tls",
				TamperCutoff:  "300",
			},
			HasBypass: true,
		},
		{
			// Split plus an out-of-band byte: poisons DPI reassemblers that
			// ignore OOB data while the server skips it.
			ID:   "zapret/split-oob",
			Name: "zapret split+oob",
			Bypass: engine.BypassStrategy{
				SplitPos: []string{"1"},
				OOB:      true,
			},
			HasBypass: true,
		},
		{
			// HTTP tamper set for port 80: header-case reshaping plus a dot
			// after the Host name. Harmless to servers, breaks Host
			// matchers.
			ID:   "zapret/http-tamper",
			Name: "zapret http tamper",
			Bypass: engine.BypassStrategy{
				SplitPos: []string{"method+1", "host+1"},
				HostCase: true,
				HostDot:  true,
			},
			HasBypass: true,
		},
		{
			// Aggressive HTTP tamper set: EOL and method-line reshaping for
			// DPI that normalizes only the common variants.
			ID:   "zapret/http-eol",
			Name: "zapret http eol",
			Bypass: engine.BypassStrategy{
				SplitPos:    []string{"1"},
				MethodEOL:   true,
				MethodSpace: true,
				UnixEOL:     true,
			},
			HasBypass: true,
		},
		{
			// Last resort: clamp the segment size so the ClientHello never
			// fits in one segment. Slows every connection through the
			// strategy, so it is tried last and must never be a default.
			ID:   "zapret/mss-last",
			Name: "zapret mss (slow)",
			Bypass: engine.BypassStrategy{
				MSS: "1300",
			},
			HasBypass: true,
		},
	}
}

// knownStrategies indexes every strategy the tuner can produce, by ID, so a
// cached ID resolves back to the full descriptor.
func knownStrategies() []Strategy {
	out := []Strategy{CurrentStrategy(), ObfsBalanced(), ObfsMax()}
	return append(out, ZapretAlternatives()...)
}

// Lookup resolves a strategy by its stable ID. Unknown IDs (for example from
// a newer client version) report false so the caller falls back to defaults.
func Lookup(id string) (Strategy, bool) {
	for _, s := range knownStrategies() {
		if s.ID == id {
			return s, true
		}
	}
	return Strategy{}, false
}

// Candidates returns the try-order for one tuning run: the current strategy,
// then the strategy remembered for this network (when it differs), then the
// Balanced and Max presets, then the zapret alternatives. Duplicates are
// removed, keeping the first occurrence, so a remembered strategy never gets
// tried twice.
func Candidates(current Strategy, cached *Strategy) []Strategy {
	seen := map[string]bool{}
	var out []Strategy
	add := func(s Strategy) {
		if s.ID == "" || seen[s.ID] {
			return
		}
		seen[s.ID] = true
		out = append(out, s)
	}
	add(current)
	if cached != nil {
		add(*cached)
	}
	add(ObfsBalanced())
	add(ObfsMax())
	for _, s := range ZapretAlternatives() {
		add(s)
	}
	return out
}
