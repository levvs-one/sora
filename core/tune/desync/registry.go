package desync

import (
	"fmt"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/bypass"
)

// The strategy registry: bypass strategies as DATA.
//
// A Profile is one curated strategy for one class of censor cascade,
// expressed as a genome (Params) plus provenance. Profiles are the
// single source of strategy defaults for the tuner: the Geneva search
// still scores everything live and may mutate around a winner, but it
// starts from this table — not from code scattered across callers —
// and a winner that came from the registry binds back to a network
// profile by the profile's stable ID.
//
// The format is versioned (RegistryVersion) exactly like the gene
// pool: a future registry can re-validate winners recorded against an
// older version instead of trusting them blindly. Validation is
// fail-closed: a profile whose genome does not convert faithfully to
// a strategy plan validation accepts is a build-time bug, and
// ValidateRegistry (run by the tests and by Service construction)
// refuses the whole table rather than serving a half-broken one.

// RegistryVersion versions the registry format and its seed set.
const RegistryVersion = 1

// Class names the censor cascade a profile targets. The classes are
// the TSPU cascade stages field practice distinguishes: the censor
// kills on the SNI, stalls the handshake, throttles QUIC, or — the
// Kazakh variant — intercepts with a whitelist/MITM posture where
// expectations differ.
type Class string

const (
	ClassSNIBlock     Class = "sni_block"
	ClassStall        Class = "stall"
	ClassQUICThrottle Class = "quic_throttle"
	ClassKZ           Class = "kz_variant"
)

// Profile is one registry entry: a strategy as data.
type Profile struct {
	// ID is stable and namespaced by class: "sni_block/fake-autottl".
	ID string
	// Class is the cascade class this strategy targets.
	Class Class
	// Params is the genome. SplitPos may carry bypass.MidSNIMarker:
	// the marker is registry-level data, resolved against the actual
	// canary SNI before execution (see ResolveFor).
	Params Params
	// Note is the provenance and the honest limit of the strategy.
	Note string
}

// registry is the curated seed table. Order within a class is the
// try-order: least intrusive first, like the gene pool. Every entry
// is re-validated by ValidateRegistry; nothing here is trusted to
// work on any given network until the tuner scores it live.
var registry = []Profile{
	// --- SNI block: the censor reads the ClientHello SNI and kills.
	{
		ID:    "sni_block/split-midsni",
		Class: ClassSNIBlock,
		Params: Params{Method: MethodSplit, SplitPos: bypass.MidSNIMarker,
			Scope: ScopeTLS},
		Note: "split in the middle of the actual SNI hostname (marker-resolved): fingerprint-agnostic, breaks naive SNI reassembly",
	},
	{
		ID:    "sni_block/fake-autottl-badseq",
		Class: ClassSNIBlock,
		Params: Params{Method: MethodFake, SplitPos: "2", FakeProto: "tls",
			AutoTTL: true, Fooling: "badseq", Scope: ScopeTLS},
		Note: "nfqws fake ClientHello with autottl and badseq fooling: the censor bites the fake, the server never sees it",
	},
	{
		ID:    "sni_block/disorder-midsni",
		Class: ClassSNIBlock,
		Params: Params{Method: MethodDisorder, SplitPos: bypass.MidSNIMarker,
			Fooling: "md5sig", Scope: ScopeTLS},
		Note: "nfqws disorder2 with the cut mid-SNI and md5sig fooling: reassembly-based DPI gives up",
	},
	{
		ID:    "sni_block/tlsrec",
		Class: ClassSNIBlock,
		Params: Params{Method: MethodTLSRec, SplitPos: "sniext+1",
			Scope: ScopeTLS},
		Note: "tpws TLS-record re-split after the SNI extension: the cheapest trick, runs without nfqws",
	},

	// --- Stall: the handshake (or the session right after it) freezes.
	{
		ID:    "stall/fake-repeats",
		Class: ClassStall,
		Params: Params{Method: MethodFake, SplitPos: "2", FakeProto: "tls",
			TTL: 5, Repeats: 2, Scope: ScopeTLS},
		Note: "repeated fake ClientHello, TTL 5: for censors that sample packets and stall on classification. Honest limit: a stall that is pure post-handshake throttling is a data-plane freeze — desync only helps when the freeze is keyed on the handshake",
	},
	{
		ID:    "stall/fake-sniext-autottl",
		Class: ClassStall,
		Params: Params{Method: MethodFake, SplitPos: "sniext+1", FakeProto: "tls",
			AutoTTL: true, Scope: ScopeTLS},
		Note: "fake at the SNI extension boundary with autottl: changes the stall-triggering byte layout without fixed-TTL risk",
	},

	// --- QUIC throttle: UDP/443 is dropped or squeezed so clients
	// fall back (or fail). QUIC has no SNI-in-cleartext beyond the
	// Initial's embedded ClientHello, so the strategies fake and
	// split the Initial itself.
	{
		ID:    "quic_throttle/fake-quic-ttl",
		Class: ClassQUICThrottle,
		Params: Params{Method: MethodFake, FakeProto: "quic", TTL: 3,
			Scope: ScopeQUIC},
		Note: "nfqws fake QUIC Initial (shipped payload), TTL 3: the censor classifies the fake, the real Initial follows",
	},
	{
		ID:    "quic_throttle/fake-quic-split-autottl",
		Class: ClassQUICThrottle,
		Params: Params{Method: MethodFake, SplitPos: "2", FakeProto: "quic",
			AutoTTL: true, Scope: ScopeQUIC},
		Note: "fake QUIC Initial plus a split of the real one, autottl-calibrated: for throttles keyed on the Initial's SNI",
	},
	{
		ID:    "quic_throttle/split-quic",
		Class: ClassQUICThrottle,
		Params: Params{Method: MethodSplit, SplitPos: "1", Fooling: "badseq",
			Scope: ScopeQUIC},
		Note: "nfqws split2 of the QUIC Initial with badseq fooling, no fake payload: the lightest QUIC desync",
	},

	// --- KZ variant: whitelist posture with MITM interception on
	// non-whitelisted SNI. Desync expectations are lower here — the
	// honest note on each entry says so — but SNI-keyed kills still
	// occur at the border and answer to the same tricks.
	{
		ID:    "kz_variant/fake-md5sig-autottl",
		Class: ClassKZ,
		Params: Params{Method: MethodFake, SplitPos: "1", FakeProto: "tls",
			AutoTTL: true, Fooling: "md5sig", Scope: ScopeTLS},
		Note: "fake ClientHello with md5sig fooling and autottl. Honest limit: against a whitelist/MITM posture desync helps only the SNI-kill stage; a hard whitelist needs a whitelisted front, not a strategy",
	},
	{
		ID:    "kz_variant/split-midsni",
		Class: ClassKZ,
		Params: Params{Method: MethodSplit, SplitPos: bypass.MidSNIMarker,
			Scope: ScopeTLS},
		Note: "marker-resolved mid-SNI split: the minimal-footprint strategy for the KZ border SNI check",
	},
}

// Profiles returns the registry table, in try-order.
func Profiles() []Profile {
	return append([]Profile(nil), registry...)
}

// ProfilesForClass returns the profiles targeting one cascade class.
func ProfilesForClass(c Class) []Profile {
	var out []Profile
	for _, p := range registry {
		if p.Class == c {
			out = append(out, p)
		}
	}
	return out
}

// LookupProfile resolves a registry profile by its stable ID.
func LookupProfile(id string) (Profile, bool) {
	for _, p := range registry {
		if p.ID == id {
			return p, true
		}
	}
	return Profile{}, false
}

// profileForParams finds the registry profile a genome came from, if
// any: the tuner binds winners by profile ID when the winner is a
// registry entry verbatim, and by genome ID otherwise.
func profileForParams(p Params) (Profile, bool) {
	for _, prof := range registry {
		if prof.Params.ID() == p.ID() {
			return prof, true
		}
	}
	return Profile{}, false
}

// ValidateProfile checks one profile fail-closed: identity shape, a
// class the ID agrees with, and a genome that — after marker
// resolution against a representative SNI — converts faithfully to a
// strategy plan validation accepts.
func ValidateProfile(p Profile) error {
	if p.ID == "" || p.Note == "" {
		return fmt.Errorf("desync: registry profile needs an id and a provenance note")
	}
	if !strings.HasPrefix(p.ID, string(p.Class)+"/") {
		return fmt.Errorf("desync: registry profile %q does not belong to class %q", p.ID, p.Class)
	}
	switch p.Class {
	case ClassSNIBlock, ClassStall, ClassQUICThrottle, ClassKZ:
	default:
		return fmt.Errorf("desync: registry profile %q has unknown class %q", p.ID, p.Class)
	}
	resolved, err := p.ResolveFor("example.com")
	if err != nil {
		return fmt.Errorf("desync: registry profile %q does not resolve: %w", p.ID, err)
	}
	s, ok := resolved.BypassStrategy()
	if !ok {
		return fmt.Errorf("desync: registry profile %q has no faithful strategy rendering", p.ID)
	}
	o := engine.Outbound{ID: "desync", Protocol: engine.ProtocolBypass, Bypass: &s}
	if err := o.Validate(); err != nil {
		return fmt.Errorf("desync: registry profile %q renders an invalid strategy: %w", p.ID, err)
	}
	return nil
}

// ValidateRegistry checks the whole table: every profile valid, IDs
// unique. The tuner refuses to run from a broken registry rather than
// serving half of it.
func ValidateRegistry() error {
	seen := map[string]bool{}
	for _, p := range registry {
		if seen[p.ID] {
			return fmt.Errorf("desync: duplicate registry profile %q", p.ID)
		}
		seen[p.ID] = true
		if err := ValidateProfile(p); err != nil {
			return err
		}
	}
	return nil
}

// ResolveFor returns the genome with every registry-level marker
// resolved against the target SNI (today: the mid-SNI split marker,
// through bypass.MidSNISplit). The result is the genome the executor
// actually runs for that target; a genome without markers returns
// unchanged.
func (p Profile) ResolveFor(sni string) (Params, error) {
	return resolveMarkers(p.Params, sni)
}

// resolveMarkers resolves the mid-SNI marker in a genome's split
// position. Genomes are values; the input is not mutated.
func resolveMarkers(p Params, sni string) (Params, error) {
	if p.SplitPos != bypass.MidSNIMarker {
		return p, nil
	}
	if sni == "" {
		return Params{}, fmt.Errorf("desync: genome %s carries the mid-SNI marker but no target SNI was given", p.ID())
	}
	pos, err := bypass.MidSNISplit(sni)
	if err != nil {
		return Params{}, err
	}
	p.SplitPos = pos
	return p, nil
}

// CandidateParams is the tuner's starting population as data: every
// registry profile (in table order) followed by the gene-pool seeds
// that are not already in the registry, deduplicated by genome ID.
func CandidateParams() []Params {
	seen := map[string]bool{}
	var out []Params
	add := func(p Params) {
		if id := p.ID(); !seen[id] {
			seen[id] = true
			out = append(out, p)
		}
	}
	for _, prof := range registry {
		add(prof.Params)
	}
	for _, p := range SeedParams() {
		add(p)
	}
	return out
}
