package desync

// GenePoolVersion versions the curated seed population. The tuner records
// the version alongside a winner so a future pool can re-validate old
// winners instead of trusting them blindly.
const GenePoolVersion = 1

// Seed is one curated starting genome: a strategy known from public
// zapret/tpws practice to have worked somewhere, with a note on where it
// came from. Seeds are not trusted — the tuner scores every one against
// live canaries and drops the ones that score 0. They exist because pure
// random search against a live censor is slow, noisy, and fingerprints
// itself; Geneva's own runs were seeded from past finds for the same
// reason.
type Seed struct {
	Params Params
	// Note is the provenance: which public practice this came from.
	Note string
}

// GenePool returns the curated starting population, ordered from the
// least to the most intrusive — the same order a human running blockcheck
// would try. Every entry is re-validated at tune time; nothing here is
// assumed to work on the user's network.
func GenePool() []Seed {
	return []Seed{
		{
			Params: Params{Method: MethodSplit, SplitPos: "1", Scope: ScopeTLS},
			Note:   "classic tpws split: minimal, breaks almost nothing",
		},
		{
			Params: Params{Method: MethodSplit, SplitPos: "2", Scope: ScopeTLS},
			Note:   "tpws split at 2: the historical GoodbyeDPI position",
		},
		{
			Params: Params{Method: MethodOOB, SplitPos: "1", Scope: ScopeTLS},
			Note:   "split + out-of-band byte: defeats naive SNI reassembly",
		},
		{
			Params: Params{Method: MethodDisorder, SplitPos: "2", Scope: ScopeTLS},
			Note:   "disorder: parts arrive reversed, middlebox gives up",
		},
		{
			Params: Params{Method: MethodTLSRec, SplitPos: "sniext+1", Scope: ScopeTLS},
			Note:   "TLS record re-split after the SNI extension",
		},
		{
			Params: Params{Method: MethodHTTPShuffle, SplitPos: "method+1", Scope: ScopeHTTP},
			Note:   "HTTP reshaping: for keyword censors on plain HTTP",
		},
		{
			Params: Params{Method: MethodSplit, SplitPos: "midsld+2", Scope: ScopeTLS},
			Note:   "split mid-SNI: finer than fixed positions",
		},
		// Everything below needs nfqws. They stay in the pool so the
		// tuner can use them the moment sora gains an nfqws executor,
		// and so the search knows what to try when tpws alone scores 0.
		{
			Params: Params{Method: MethodFake, SplitPos: "2", FakeProto: "tls", TTL: 3},
			Note:   "nfqws fake ClientHello, TTL 3: censor bites the fake",
		},
		{
			Params: Params{Method: MethodFake, SplitPos: "2", FakeProto: "tls", AutoTTL: true, Fooling: "badseq"},
			Note:   "nfqws fake + autottl + badseq fooling",
		},
		{
			Params: Params{Method: MethodFake, FakeProto: "quic", TTL: 3, Scope: ScopeQUIC},
			Note:   "nfqws fake QUIC Initial: UDP/443 needs its own strategy",
		},
		{
			Params: Params{Method: MethodDisorder, SplitPos: "2", Fooling: "md5sig", Scope: ScopeTLS},
			Note:   "nfqws disorder with md5sig fooling",
		},
		{
			Params: Params{Method: MethodFake, SplitPos: "2", FakeProto: "tls", TTL: 5, Repeats: 2},
			Note:   "nfqws fake repeated: for censors that sample packets",
		},
	}
}

// SeedParams flattens the pool to genomes for the search.
func SeedParams() []Params {
	seeds := GenePool()
	out := make([]Params, 0, len(seeds))
	for _, s := range seeds {
		out = append(out, s.Params)
	}
	return out
}

// ExecutableSeeds returns only the seeds the named executor can run:
// "tpws" excludes the nfqws-only genomes; "nfqws" (the executor in
// core/engine/bypass) runs the whole pool.
func ExecutableSeeds(engine string) []Params {
	var out []Params
	for _, p := range SeedParams() {
		if engine == "nfqws" || !p.RequiresNFQWS() {
			out = append(out, p)
		}
	}
	return out
}
