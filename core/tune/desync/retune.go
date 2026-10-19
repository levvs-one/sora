package desync

import (
	"strings"
	"sync"

	"github.com/levvs-one/sora-client/core/profiles"
)

// This file binds tuner winners to the F5 network profile and decides
// when to re-tune: on network change, or when passive signals from real
// traffic say the current strategy is dying. Passive signals are
// preferred over active probing — probing a live censor fingerprints
// itself, while the user's ordinary traffic reports the censor's mood
// for free.

// NetworkKey identifies the network attachment for strategy binding. It
// mirrors the key policy of package tune (SSID, gateway, ASN; the
// churning interface addresses are excluded) so a winner remembered by
// either package resolves to the same network.
func NetworkKey(fp profiles.Fingerprint) string {
	return strings.Join([]string{fp.SSID, fp.Gateway, fp.ASN}, "\x1f")
}

// NetworkChanged reports whether the attachment moved to a different
// network. Strategies are ISP-specific — a winner from the home ISP is
// not expected to work on mobile data — so a change means re-tune.
func NetworkChanged(prev, cur profiles.Fingerprint) bool {
	return NetworkKey(prev) != NetworkKey(cur)
}

// Signal is one passive fitness observation from real user traffic. The
// connection layer reports these; the tuner only aggregates.
type Signal int

const (
	// SignalSuccess is a connection that completed normally.
	SignalSuccess Signal = iota
	// SignalInjectedRST is a RST the far end did not send — the classic
	// TSPU kill signature.
	SignalInjectedRST
	// SignalBlockPage is a censor block page instead of the site.
	SignalBlockPage
	// SignalSNITimeout is a TLS handshake with a censored SNI that
	// stalled past the deadline.
	SignalSNITimeout
	// SignalReset is a plain connection reset / refused / timeout on an
	// otherwise reachable endpoint. Noisy: weighted less than the
	// censor-specific signals above.
	SignalReset
)

// bad reports whether the signal indicates interference rather than
// ordinary network trouble.
func (s Signal) bad() bool {
	switch s {
	case SignalInjectedRST, SignalBlockPage, SignalSNITimeout:
		return true
	default:
		return false
	}
}

// Health is a small sliding window of passive signals. It answers one
// question: "is the current strategy dying?" without any active probing.
type Health struct {
	mu     sync.Mutex
	window []Signal
	// size caps the window; 32 connections is enough to see a trend and
	// small enough to forget last week's network.
	size int
}

// NewHealth builds the window. size <= 0 means 32.
func NewHealth(size int) *Health {
	if size <= 0 {
		size = 32
	}
	return &Health{size: size}
}

// Add records one connection outcome.
func (h *Health) Add(s Signal) {
	h.mu.Lock()
	defer h.mu.Unlock()
	h.window = append(h.window, s)
	if len(h.window) > h.size {
		h.window = h.window[len(h.window)-h.size:]
	}
}

// FailRate is the fraction of recent connections showing censor
// interference. Plain resets count at half weight: they are noisy and
// often just a bad network.
func (h *Health) FailRate() float64 {
	h.mu.Lock()
	defer h.mu.Unlock()
	if len(h.window) == 0 {
		return 0
	}
	var bad float64
	for _, s := range h.window {
		switch {
		case s.bad():
			bad += 1
		case s == SignalReset:
			bad += 0.5
		}
	}
	return bad / float64(len(h.window))
}

// Samples reports how many connections the window holds.
func (h *Health) Samples() int {
	h.mu.Lock()
	defer h.mu.Unlock()
	return len(h.window)
}

// Retune thresholds. A strategy is declared dying when at least
// MinSamples connections were observed and the interference rate hits
// FailRateThreshold — conservative enough that one bad evening on hotel
// Wi-Fi does not trigger a full re-tune.
const (
	MinSamples        = 8
	FailRateThreshold = 0.5
)

// NeedsRetune decides whether the tuner should run again. keyChanged
// means the network attachment moved (see NetworkChanged); otherwise the
// passive health window decides. The returned string is the human reason,
// for the journal.
func NeedsRetune(keyChanged bool, h *Health) (bool, string) {
	if keyChanged {
		return true, "network changed"
	}
	if h != nil && h.Samples() >= MinSamples && h.FailRate() >= FailRateThreshold {
		return true, "strategy dying: interference on recent connections"
	}
	return false, ""
}
