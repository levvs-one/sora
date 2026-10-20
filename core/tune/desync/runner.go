package desync

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/profiles"
)

// The production runner: how the Geneva tuner is actually invoked.
//
// doc.go's contract, made executable: the search runs ONLY from an
// explicit user action (the control plane's TuneDesync RPC), is
// rate-limited per network, probes only sora's own canary endpoints,
// binds the winner to the F5 network profile, and rotates on silent
// death. Passive signals (retune.go's Health) are the preferred
// trigger input: the control plane consults NeedsRetune before ever
// asking for an active run, and the Service exposes Observe for the
// connection layer to feed those signals in.

// Canary is one probing endpoint: the host the probe connects to and
// the SNI it presents. Probing measures a TLS handshake, so SNI is
// the signal-bearing field.
type Canary struct {
	Host string
	Port int
	SNI  string
}

// BlockedCanary is the endpoint the censor is known to interfere
// with: the same canary the core's DNS-intercept diagnostics use
// (a name that exists globally and is censored in RU). A candidate
// "works" when this handshake completes through it.
var BlockedCanary = Canary{Host: "youtube.com", Port: 443, SNI: "youtube.com"}

// ControlCanary is the unblocked control endpoint: the tunnel-DNS
// canary name the core already probes. A candidate that breaks THIS
// handshake is destructive, whatever it does to the blocked one.
var ControlCanary = Canary{Host: "one.one.one.one", Port: 443, SNI: "one.one.one.one"}

// IsCanary reports whether a target is one of the two sanctioned
// probing endpoints. The Service refuses to run a probe built for any
// other target: active probing fingerprints itself, so sora probes
// its own canaries and nothing else.
func IsCanary(c Canary) bool {
	return c == BlockedCanary || c == ControlCanary
}

// DefaultMinInterval is the per-network rate limit for active tuning
// runs. The value is derived, not round magic: a search may burn up
// to MaxTotalBudget (5 minutes, search.go) of probing, and a strategy
// the censor has learned is re-blocked in 5-15 minutes (the field
// window rotate.go's default maxAge encodes) — re-tuning inside that
// window re-probes a censor that has not yet changed its mind, and a
// user mashing "pick a strategy" must not turn the client into a
// probing beacon. 10 minutes sits between the search budget and the
// re-block window: at most one full search per re-block cycle.
const DefaultMinInterval = 10 * time.Minute

// ErrRateLimited is returned when a network was tuned too recently.
var ErrRateLimited = errors.New("desync: this network was tuned too recently; active probing is rate-limited")

// ProfileBinder binds a winning registry profile to the F5 network
// profile that matches the fingerprint, so the profile the user sees
// in the app names the strategy it will run. Implemented by the
// control plane over core/profiles; a nil Binder skips the F5 write
// (the BindingStore still remembers the winner by network key).
type ProfileBinder interface {
	BindDesyncProfile(ctx context.Context, fp profiles.Fingerprint, profileID string, winner Params) error
}

// Service is the production tuner facade: rate limiting, the
// registry-seeded search, binding, rotation and passive health in one
// place. Safe for concurrent use; runs are serialized (one active
// search at a time — parallel probing is both noisy and pointless).
type Service struct {
	Store  *BindingStore
	Binder ProfileBinder
	// MinInterval is the per-network rate limit; <= 0 means
	// DefaultMinInterval.
	MinInterval time.Duration
	// Now supplies the clock for tests; nil means time.Now.
	Now func() time.Time

	mu      sync.Mutex
	running bool
	lastRun map[string]time.Time
	health  map[string]*Health
}

// NewService builds a Service over a binding store. The registry is
// validated at construction: a broken registry is a build bug and the
// Service refuses to exist rather than tuning from bad data.
func NewService(store *BindingStore, binder ProfileBinder) (*Service, error) {
	if err := ValidateRegistry(); err != nil {
		return nil, err
	}
	if store == nil {
		store, _ = NewBindingStore("")
	}
	return &Service{Store: store, Binder: binder,
		lastRun: map[string]time.Time{}, health: map[string]*Health{}}, nil
}

func (s *Service) now() time.Time {
	if s.Now != nil {
		return s.Now()
	}
	return time.Now()
}

func (s *Service) minInterval() time.Duration {
	if s.MinInterval > 0 {
		return s.MinInterval
	}
	return DefaultMinInterval
}

// Tune runs one bounded search for the network: registry profiles and
// gene-pool seeds, markers resolved against the blocked canary's SNI,
// scored by probe. On success the winner is bound — to the binding
// store always, and to the matching F5 profile when a Binder is set
// and the winner is a registry profile. The returned result carries
// the winner even when binding persistence failed (BindingErr).
func (s *Service) Tune(ctx context.Context, fp profiles.Fingerprint, engine string, probe ProbeFunc) (SearchResult, error) {
	if probe == nil {
		return SearchResult{}, errors.New("desync: nil probe func")
	}
	key := NetworkKey(fp)
	s.mu.Lock()
	if s.running {
		s.mu.Unlock()
		return SearchResult{}, errors.New("desync: a tuning run is already in progress")
	}
	if last, ok := s.lastRun[key]; ok && s.now().Sub(last) < s.minInterval() {
		s.mu.Unlock()
		return SearchResult{}, fmt.Errorf("%w (next run for this network in %s)",
			ErrRateLimited, (s.minInterval() - s.now().Sub(last)).Round(time.Second))
	}
	s.running = true
	s.lastRun[key] = s.now()
	s.mu.Unlock()
	defer func() {
		s.mu.Lock()
		s.running = false
		s.mu.Unlock()
	}()

	// Resolve registry markers against the blocked canary: the
	// genome that runs — and the one that gets bound — is the
	// resolved one, so a restart re-serves exactly what was scored.
	var candidates []Params
	for _, p := range CandidateParams() {
		r, err := resolveMarkers(p, BlockedCanary.SNI)
		if err != nil {
			return SearchResult{}, err
		}
		candidates = append(candidates, r)
	}
	opts := DefaultOptions()
	if engine != "" {
		opts.Engine = engine
	}
	res, err := Search(ctx, candidates, opts, probe)
	if err != nil {
		return res, err
	}
	binding := Binding{
		Winner:          res.Best.Params,
		Score:           res.Best.Score,
		At:              s.now(),
		RegistryVersion: RegistryVersion,
		GenePoolVersion: GenePoolVersion,
	}
	if prof, ok := profileForParams(res.Best.Params); ok {
		binding.ProfileID = prof.ID
	}
	for _, sc := range res.Ranked {
		if sc.Working() && sc.Params.ID() != res.Best.Params.ID() {
			binding.Ranked = append(binding.Ranked, sc.Params)
			binding.RankedScores = append(binding.RankedScores, sc.Score)
		}
	}
	if berr := s.Store.Bind(fp, binding); berr != nil {
		res.BindErr = berr
	} else if s.Binder != nil && binding.ProfileID != "" {
		res.BindErr = s.Binder.BindDesyncProfile(ctx, fp, binding.ProfileID, binding.Winner)
	}
	return res, nil
}

// Current returns the rotation ring for a network: the bound winner
// and its working runners-up, re-validated before serving (a winner
// recorded under an older registry version, or one that no longer
// converts, is refused rather than trusted). ok=false means no usable
// binding: the caller should offer a fresh tune.
func (s *Service) Current(fp profiles.Fingerprint) (*Rotator, Binding, bool) {
	b, ok := s.Store.Lookup(fp)
	if !ok {
		return nil, Binding{}, false
	}
	if b.RegistryVersion != RegistryVersion {
		return nil, Binding{}, false
	}
	if _, err := resolveMarkers(b.Winner, BlockedCanary.SNI); err != nil {
		return nil, Binding{}, false
	}
	ranked := []Scored{{Params: b.Winner, Score: b.Score}}
	for i, p := range b.Ranked {
		score := b.Score // bindings written before RankedScores: keep order, reuse the winner's fitness
		if i < len(b.RankedScores) {
			score = b.RankedScores[i]
		}
		ranked = append(ranked, Scored{Params: p, Score: score})
	}
	rot := NewRotator(ranked, 3, 15*time.Minute)
	if rot.Empty() {
		return nil, Binding{}, false
	}
	return rot, b, true
}

// Observe feeds one passive signal from real traffic into the
// network's health window — the preferred retune input, costing no
// probe at all.
func (s *Service) Observe(fp profiles.Fingerprint, sig Signal) {
	key := NetworkKey(fp)
	s.mu.Lock()
	defer s.mu.Unlock()
	h, ok := s.health[key]
	if !ok {
		h = NewHealth(0)
		s.health[key] = h
	}
	h.Add(sig)
}

// ShouldRetune applies the retune policy for a network: a network
// change always retunes; otherwise the passive health window decides.
func (s *Service) ShouldRetune(prev, cur profiles.Fingerprint) (bool, string) {
	if NetworkChanged(prev, cur) {
		return true, "network changed"
	}
	s.mu.Lock()
	h := s.health[NetworkKey(cur)]
	s.mu.Unlock()
	return NeedsRetune(false, h)
}
