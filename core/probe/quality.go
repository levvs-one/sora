package probe

import (
	"sort"
	"sync"
	"time"
)

// QualityKey identifies one measured path: a server reached over one
// transport. PathQuality series for different transports are never mixed:
// the T018 differential reads "this transport degraded, that one did not"
// off exactly this separation.
type QualityKey struct {
	Server    string
	Transport string
}

// QualityRegistry owns one PathQuality per (server, transport) pair. It
// is the sampling sink of CENSORSHIP-METER (T035, spec
// 35-quic-metrics.md §3): the prober feeds every measured dial into it,
// and diagnostics read the series back. Series are process-local memory
// only — path history is sensitive metadata (when and where the user
// connected), so nothing here is persisted or exported.
type QualityRegistry struct {
	mu sync.Mutex
	by map[QualityKey]*PathQuality
}

// NewQualityRegistry returns an empty registry.
func NewQualityRegistry() *QualityRegistry {
	return &QualityRegistry{by: map[QualityKey]*PathQuality{}}
}

// For returns the series for the pair, creating it on first use.
func (r *QualityRegistry) For(server, transport string) *PathQuality {
	r.mu.Lock()
	defer r.mu.Unlock()
	key := QualityKey{Server: server, Transport: transport}
	q, ok := r.by[key]
	if !ok {
		q = &PathQuality{}
		r.by[key] = q
	}
	return q
}

// Observe records one sample into the pair's series. It is exactly
// PathQuality.Observe addressed by key; callers with no server identity
// (anonymous samples) are dropped: a series without an owner can never
// be attributed and would only pollute the meter.
func (r *QualityRegistry) Observe(server, transport string, rtt time.Duration, ok bool, now time.Time) {
	if server == "" {
		return
	}
	r.For(server, transport).Observe(rtt, ok, now)
}

// Get returns the series for the pair without creating it.
func (r *QualityRegistry) Get(server, transport string) (*PathQuality, bool) {
	r.mu.Lock()
	defer r.mu.Unlock()
	q, ok := r.by[QualityKey{Server: server, Transport: transport}]
	return q, ok
}

// Keys lists the measured pairs in stable order, for diagnostics and
// tests.
func (r *QualityRegistry) Keys() []QualityKey {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]QualityKey, 0, len(r.by))
	for k := range r.by {
		out = append(out, k)
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Server != out[j].Server {
			return out[i].Server < out[j].Server
		}
		return out[i].Transport < out[j].Transport
	})
	return out
}
