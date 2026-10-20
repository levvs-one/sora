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
// probing endpoints. The production prober (control's
// desyncSessionProber.handshake) refuses any other target before
// dialling: active probing fingerprints itself, so sora probes its
// own canaries and nothing else. The structural half of the same
// guarantee is that the TuneDesync request carries no target field
// at all — this guard is the executable half.
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

// Rotation parameters for a bound winner's ring. The values are
// rotate.go's field-derived defaults, named here so the wiring is
// data, not literals at the call site: 3 consecutive failures declare
// a strategy dead, and 15 minutes is the TSPU re-block window — a
// winner older than that may have died silently.
const (
	rotatorMaxFails = 3
	rotatorMaxAge   = 15 * time.Minute
)

// boundRing is the persistent rotation state for one network: the
// ring built from a specific binding (identified by its scoring time
// and winner), kept across Current/Observe calls so failure counts
// and the winner's age survive between callers. Rebuilding the ring
// on every Current() — the previous behaviour — reset born to "now"
// on each call, so age rotation never fired and Fail() counts never
// accumulated: rotation existed only inside one returned instance
// that production never kept.
type boundRing struct {
	at       time.Time
	winnerID string
	rot      *Rotator
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
	// OnRefuse, when set, is told whenever Current refuses to serve a
	// stored binding (stale data versions, a winner that no longer
	// converts): the refusal is an event the caller journals, never a
	// silent serve and never a silent drop. The reason is one of the
	// stable tokens from validatedRing — it carries no genome content.
	OnRefuse func(fp profiles.Fingerprint, reason string)

	mu       sync.Mutex
	running  bool
	lastRun  map[string]time.Time
	health   map[string]*Health
	rotators map[string]*boundRing
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
		lastRun: map[string]time.Time{}, health: map[string]*Health{},
		rotators: map[string]*boundRing{}}, nil
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
	} else {
		// A fresh winner replaces the network's rotation ring: the
		// old ring's failure counts describe a strategy that is no
		// longer bound here.
		s.mu.Lock()
		delete(s.rotators, key)
		s.mu.Unlock()
		if s.Binder != nil && binding.ProfileID != "" {
			res.BindErr = s.Binder.BindDesyncProfile(ctx, fp, binding.ProfileID, binding.Winner)
		}
	}
	return res, nil
}

// validatedRing re-validates a stored binding before anything from
// it is served — the check binding.go's contract promises ("entries
// are served only after re-validation"). It returns the rotation
// material (winner first, markers resolved, runners-up that still
// convert) or a stable refusal token naming why the binding must not
// be served: a winner recorded under another registry or gene-pool
// version, an unresolvable marker, or a genome that no longer
// converts to a strategy plan validation accepts (a corrupt or
// hand-edited store can hold all three; the JSON layer cannot see
// any of them). Runners-up are filtered, not fatal: a dead runner-up
// must not kill a valid winner.
func validatedRing(b Binding) ([]Scored, string) {
	if b.RegistryVersion != RegistryVersion {
		return nil, "stale registry version"
	}
	if b.GenePoolVersion != GenePoolVersion {
		return nil, "stale gene pool version"
	}
	winner, err := resolveMarkers(b.Winner, BlockedCanary.SNI)
	if err != nil {
		return nil, "winner marker does not resolve"
	}
	if !winner.convertsValidly() {
		return nil, "winner no longer converts"
	}
	ranked := []Scored{{Params: winner, Score: b.Score}}
	for i, p := range b.Ranked {
		rp, err := resolveMarkers(p, BlockedCanary.SNI)
		if err != nil || !rp.convertsValidly() {
			continue
		}
		score := b.Score // bindings written before RankedScores: keep order, reuse the winner's fitness
		if i < len(b.RankedScores) {
			score = b.RankedScores[i]
		}
		ranked = append(ranked, Scored{Params: rp, Score: score})
	}
	return ranked, ""
}

// ringLocked returns the network's persistent rotation ring,
// building it from the binding when the binding changed (a new tune
// re-scores: the old ring's age and failure counts describe the old
// winner). The ring is born at Binding.At — the moment the winner was
// scored — not at first serve, so age rotation measures the winner's
// real age. s.mu must be held.
func (s *Service) ringLocked(fp profiles.Fingerprint, b Binding, ranked []Scored) *Rotator {
	key := NetworkKey(fp)
	if cur, ok := s.rotators[key]; ok && cur.at.Equal(b.At) && cur.winnerID == b.Winner.ID() {
		return cur.rot
	}
	born := b.At
	if born.IsZero() {
		born = s.now()
	}
	rot := NewRotatorBorn(ranked, rotatorMaxFails, rotatorMaxAge, born)
	s.rotators[key] = &boundRing{at: b.At, winnerID: b.Winner.ID(), rot: rot}
	return rot
}

// Current returns the rotation ring for a network: the bound winner
// and its working runners-up, re-validated before serving (see
// validatedRing). A binding that fails re-validation is refused —
// ok=false, "no usable winner" — and the refusal is reported through
// OnRefuse: serving an unconvertible or stale winner silently was
// the failure this guards against. ok=false with NO stored binding
// is the ordinary empty case and is not an event. The returned ring
// is the Service's persistent one for the network: repeated calls
// return the same Rotator, whose age runs from Binding.At and whose
// failure counts accumulate across callers.
func (s *Service) Current(fp profiles.Fingerprint) (*Rotator, Binding, bool) {
	b, ok := s.Store.Lookup(fp)
	if !ok {
		return nil, Binding{}, false
	}
	ranked, refuse := validatedRing(b)
	if refuse != "" {
		if s.OnRefuse != nil {
			s.OnRefuse(fp, refuse)
		}
		return nil, Binding{}, false
	}
	s.mu.Lock()
	rot := s.ringLocked(fp, b, ranked)
	s.mu.Unlock()
	if rot.Empty() {
		return nil, Binding{}, false
	}
	return rot, b, true
}

// Observe feeds one passive signal from real traffic into the
// network's health window — the preferred retune input, costing no
// probe at all. It also drives the network's persistent rotation
// ring: a censor-specific bad signal (injected RST, block page, SNI
// stall) counts as a ring failure and a clean connection as a ring
// success, so "the winner died quietly" accumulates in the same ring
// Current serves. Plain resets stay health-only — they are noise,
// and the ring must not rotate on noise.
func (s *Service) Observe(fp profiles.Fingerprint, sig Signal) {
	key := NetworkKey(fp)
	s.mu.Lock()
	h, ok := s.health[key]
	if !ok {
		h = NewHealth(0)
		s.health[key] = h
	}
	h.Add(sig)
	s.mu.Unlock()
	if sig != SignalSuccess && !sig.bad() {
		return
	}
	b, ok := s.Store.Lookup(fp)
	if !ok {
		return
	}
	ranked, refuse := validatedRing(b)
	if refuse != "" {
		return // not an event here: Current reports refusals; Observe stays a hot path
	}
	s.mu.Lock()
	rot := s.ringLocked(fp, b, ranked)
	s.mu.Unlock()
	if sig == SignalSuccess {
		rot.Success()
	} else {
		rot.Fail()
	}
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
