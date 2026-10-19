package serversel

import (
	"fmt"
	"math"
	"sort"
	"sync"
	"time"
)

// AdvisorConfig tunes degradation detection and the anti-flap hysteresis.
// The zero value is usable: unset fields take the reference defaults,
// except LatencySlack where an explicit zero means "no slack".
type AdvisorConfig struct {
	// WindowSize is how many observations make one evaluation window.
	// Clamped to [4, 1000].
	WindowSize int
	// ConfirmWindows is how many consecutive degraded windows are needed
	// before a switch is advised. Clamped to [1, 100].
	ConfirmWindows int
	// LatencyFactor marks a window degraded when its p95 latency exceeds
	// baseline*LatencyFactor. Clamped to [1.05, 100].
	LatencyFactor float64
	// LatencySlack is added to the baseline as an absolute floor, so a
	// tiny baseline does not flap on noise: the limit is
	// max(baseline*LatencyFactor, baseline+LatencySlack).
	// Clamped to [0, 30s].
	LatencySlack time.Duration
	// ErrorRate marks a window degraded when more than this fraction of
	// observations failed. Clamped to (0, 1].
	ErrorRate float64
	// MinSwitchInterval is the hysteresis: no second advised switch may
	// follow the previous one sooner than this. Clamped to [1m, 24h].
	MinSwitchInterval time.Duration
	// Now is overridden in tests.
	Now func() time.Time
}

// DefaultAdvisorConfig returns the reference tuning.
func DefaultAdvisorConfig() AdvisorConfig {
	return AdvisorConfig{
		WindowSize:        20,
		ConfirmWindows:    3,
		LatencyFactor:     2.0,
		LatencySlack:      500 * time.Millisecond,
		ErrorRate:         0.2,
		MinSwitchInterval: 10 * time.Minute,
	}
}

func (c AdvisorConfig) clamped() AdvisorConfig {
	d := DefaultAdvisorConfig()
	// Zero means "default" for every field where zero is out of range;
	// LatencySlack keeps an explicit zero as "no slack".
	if c.WindowSize == 0 {
		c.WindowSize = d.WindowSize
	}
	if c.ConfirmWindows == 0 {
		c.ConfirmWindows = d.ConfirmWindows
	}
	if c.LatencyFactor == 0 || math.IsNaN(c.LatencyFactor) {
		c.LatencyFactor = d.LatencyFactor
	}
	if c.ErrorRate == 0 || math.IsNaN(c.ErrorRate) {
		c.ErrorRate = d.ErrorRate
	}
	if c.MinSwitchInterval == 0 {
		c.MinSwitchInterval = d.MinSwitchInterval
	}
	c.WindowSize = clampInt(c.WindowSize, 4, 1000)
	c.ConfirmWindows = clampInt(c.ConfirmWindows, 1, 100)
	c.LatencyFactor = clampFloat(c.LatencyFactor, 1.05, 100)
	if c.LatencySlack < 0 {
		c.LatencySlack = 0
	}
	if c.LatencySlack > 30*time.Second {
		c.LatencySlack = 30 * time.Second
	}
	c.ErrorRate = clampFloat(c.ErrorRate, 0.01, 1)
	if c.MinSwitchInterval < time.Minute {
		c.MinSwitchInterval = time.Minute
	}
	if c.MinSwitchInterval > 24*time.Hour {
		c.MinSwitchInterval = 24 * time.Hour
	}
	return c
}

type sample struct {
	latency time.Duration
	ok      bool
}

// Advisor watches one active server and advises a switch when it degrades.
// Hysteresis comes from three places: degradation must persist for
// ConfirmWindows consecutive windows, one healthy window resets the counter,
// and MinSwitchInterval separates two advised switches. It is safe for
// concurrent use.
type Advisor struct {
	cfg AdvisorConfig
	now func() time.Time

	mu           sync.Mutex
	armed        bool
	serverID     string
	baseline     time.Duration
	window       []sample
	consec       int
	lastSwitch   time.Time
	everSwitched bool
}

// NewAdvisor clamps the config.
func NewAdvisor(cfg AdvisorConfig) *Advisor {
	cfg = cfg.clamped()
	now := cfg.Now
	if now == nil {
		now = time.Now
	}
	return &Advisor{cfg: cfg, now: now}
}

// Config returns the clamped configuration in effect.
func (a *Advisor) Config() AdvisorConfig { return a.cfg }

// Arm starts watching serverID; baselineLatency is the healthy latency the
// degradation limit is derived from. It resets the window and the
// consecutive-degraded counter.
func (a *Advisor) Arm(serverID string, baselineLatency time.Duration) {
	if baselineLatency < 0 {
		baselineLatency = 0
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	a.armed = true
	a.serverID = serverID
	a.baseline = baselineLatency
	a.window = a.window[:0]
	a.consec = 0
}

// Switched re-arms the advisor on the new server after a switch (manual or
// advised) and starts the cooldown before the next advised switch.
func (a *Advisor) Switched(serverID string, baselineLatency time.Duration) {
	a.Arm(serverID, baselineLatency)
	a.mu.Lock()
	defer a.mu.Unlock()
	a.lastSwitch = a.now()
	a.everSwitched = true
}

// Observe records one outcome — e.g. one request round-trip or one
// heartbeat. It returns switchNow=true only when the server is clearly
// degraded and the hysteresis allows a switch; the caller then picks an
// alternative (e.g. via Picker, excluding the current server) and calls
// Switched.
func (a *Advisor) Observe(latency time.Duration, ok bool) (switchNow bool, reason string) {
	if latency < 0 {
		latency = 0
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	if !a.armed {
		return false, "advisor is not armed"
	}
	a.window = append(a.window, sample{latency: latency, ok: ok})
	if len(a.window) < a.cfg.WindowSize {
		return false, ""
	}
	degraded, detail := a.evaluateLocked()
	a.window = a.window[:0]
	if !degraded {
		a.consec = 0
		return false, ""
	}
	a.consec++
	if a.consec < a.cfg.ConfirmWindows {
		return false, ""
	}
	if a.everSwitched {
		if left := a.cfg.MinSwitchInterval - a.now().Sub(a.lastSwitch); left > 0 {
			// Still cooling down: keep the counter so the switch
			// fires as soon as the cooldown ends while the server
			// is still degraded.
			return false, fmt.Sprintf("degraded (%s) but cooling down for %s", detail, left.Round(time.Second))
		}
	}
	a.consec = 0
	a.lastSwitch = a.now()
	a.everSwitched = true
	return true, fmt.Sprintf("server %q degraded: %s", a.serverID, detail)
}

// Armed reports whether the advisor is watching a server.
func (a *Advisor) Armed() bool {
	a.mu.Lock()
	defer a.mu.Unlock()
	return a.armed
}

// evaluateLocked judges the full window. Callers must hold the mutex and
// consume the window afterwards.
func (a *Advisor) evaluateLocked() (degraded bool, detail string) {
	n := len(a.window)
	fails := 0
	lats := make([]time.Duration, 0, n)
	for _, s := range a.window {
		if s.ok {
			lats = append(lats, s.latency)
		} else {
			fails++
		}
	}
	errRate := float64(fails) / float64(n)
	latLimit := a.baseline + a.cfg.LatencySlack
	if byFactor := time.Duration(float64(a.baseline) * a.cfg.LatencyFactor); byFactor > latLimit {
		latLimit = byFactor
	}
	latDegraded := false
	p95 := time.Duration(0)
	if len(lats) > 0 {
		sort.Slice(lats, func(i, j int) bool { return lats[i] < lats[j] })
		p95 = lats[int(math.Ceil(0.95*float64(len(lats))))-1]
		latDegraded = p95 > latLimit
	}
	errDegraded := errRate > a.cfg.ErrorRate
	degraded = errDegraded || latDegraded
	detail = fmt.Sprintf("error rate %.0f%% (limit %.0f%%), p95 latency %s (limit %s)",
		errRate*100, a.cfg.ErrorRate*100, p95.Round(time.Millisecond), latLimit.Round(time.Millisecond))
	return degraded, detail
}
