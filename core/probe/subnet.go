package probe

import (
	"fmt"
	"net/netip"
	"sort"
	"sync"
	"time"
)

// Subnet reputation (T011 / T045).
//
// The October 2026 post-election wave moved TSPU from single-IP blocks to
// carpet bans of whole hosting-provider /24s: every server address inside
// the subnet dies at once, while servers elsewhere stay healthy. Picking
// another server in the same burned /24 only burns another handshake and,
// worse, teaches the client nothing. This tracker turns every measured
// dial into a per-subnet signal so server selection can avoid burned
// subnets instead of walking into them one IP at a time.
//
// What it is: a windowed reputation per IPv4 /24 (IPv6 /48 — the practical
// equivalent for a provider allocation) fed by the prober's own dial
// outcomes. Healthy / degraded / burned verdicts are derived from distinct
// server IPs, never from a single data point: one dead server is a dead
// server, not a carpet ban.
//
// What it is not: it cannot see blocks it never probed, it cannot
// distinguish a provider outage from a censor carpet ban (both look like
// "everything in this /24 is down" — the verdict text says so), and it is
// process-local memory only: subnet history is sensitive metadata, so
// nothing here is persisted or exported.
const (
	// subnetWindow bounds the tracker's memory: a subnet judged on data
	// older than this is a subnet judged on stale news. 15 minutes matches
	// the T011 spec window.
	subnetWindow = 15 * time.Minute
	// subnetMinIPs is the evidence bar: this many DISTINCT server IPs in
	// the subnet must carry outcomes before a verdict is named. Below it
	// the subnet is healthy-by-default — a single dead IP never condemns
	// its neighbors.
	subnetMinIPs = 3
	// subnetWaveMin is how many simultaneously burned subnets name a
	// carpet-ban wave rather than isolated trouble.
	subnetWaveMin = 3
)

// SubnetState is the reputation verdict for one subnet.
type SubnetState int

const (
	// SubnetHealthy means no evidence of trouble: too little data or the
	// subnet's servers answer.
	SubnetHealthy SubnetState = iota
	// SubnetDegraded means mixed outcomes: some servers in the subnet
	// answer, some do not. Worth a score penalty, not a veto.
	SubnetDegraded
	// SubnetBurned means every observed server IP in the subnet fails and
	// the evidence bar is met: the carpet-ban signature. Avoid the whole
	// subnet, not just the dead IPs.
	SubnetBurned
)

// String renders the state for logs, diagnostics and the meter UI.
func (s SubnetState) String() string {
	switch s {
	case SubnetDegraded:
		return "degraded"
	case SubnetBurned:
		return "burned"
	default:
		return "healthy"
	}
}

// SubnetOf maps an address to its reputation unit: the /24 for IPv4, the
// /48 for IPv6 (provider-allocation scale, the v6 analogue of a carpet
// ban). It reports false for invalid addresses and for address classes a
// carpet ban never targets (loopback, link-local, multicast, private).
func SubnetOf(addr netip.Addr) (netip.Prefix, bool) {
	if !addr.IsValid() || addr.IsLoopback() || addr.IsLinkLocalUnicast() ||
		addr.IsLinkLocalMulticast() || addr.IsMulticast() || addr.IsPrivate() ||
		addr.IsUnspecified() {
		return netip.Prefix{}, false
	}
	addr = addr.Unmap()
	bits := 24
	if addr.Is6() {
		bits = 48
	}
	p, err := addr.Prefix(bits)
	if err != nil {
		return netip.Prefix{}, false
	}
	return p.Masked(), true
}

type ipOutcome struct {
	ok bool
	at time.Time
}

// subnetTrack holds the windowed outcomes of one subnet's server IPs.
type subnetTrack struct {
	// ips maps server IP -> its latest outcome in the window.
	ips map[netip.Addr]ipOutcome
}

// SubnetReputation tracks per-subnet dial outcomes. It is safe for
// concurrent use; the zero value is not usable, use NewSubnetReputation.
type SubnetReputation struct {
	mu        sync.Mutex
	now       func() time.Time
	subs      map[netip.Prefix]*subnetTrack
	lastPrune time.Time
}

// NewSubnetReputation returns an empty tracker.
func NewSubnetReputation() *SubnetReputation {
	return &SubnetReputation{now: time.Now, subs: map[netip.Prefix]*subnetTrack{}}
}

// Observe records one dial outcome for the subnet containing addr.
// Addresses that do not map to a reputation unit are ignored.
func (r *SubnetReputation) Observe(addr netip.Addr, ok bool) {
	p, good := SubnetOf(addr)
	if !good {
		return
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	now := r.now()
	t := r.subs[p]
	if t == nil {
		t = &subnetTrack{ips: map[netip.Addr]ipOutcome{}}
		r.subs[p] = t
	}
	t.ips[addr.Unmap()] = ipOutcome{ok: ok, at: now}
	// Pruning is memory hygiene only — verdicts filter by the window at
	// read time (stateOf), so it is amortized: the touched track is swept
	// on every Observe, the whole map at most once per window. A full
	// sweep per Observe made every dial outcome cost O(all tracked IPs)
	// under the lock (~61µs at 500 subnets x 8 IPs).
	pruneTrackLocked(t, now)
	if now.Sub(r.lastPrune) >= subnetWindow {
		r.pruneLocked(now)
	}
}

// State returns the reputation verdict for the subnet containing addr.
func (r *SubnetReputation) State(addr netip.Addr) SubnetState {
	p, good := SubnetOf(addr)
	if !good {
		return SubnetHealthy
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	now := r.now()
	// No prune here: stateOf ignores out-of-window outcomes, so the
	// verdict is identical whether stale entries were swept or not.
	return stateOf(r.subs[p], now)
}

// stateOf derives the verdict from the track's in-window outcomes.
func stateOf(t *subnetTrack, now time.Time) SubnetState {
	if t == nil {
		return SubnetHealthy
	}
	var okIPs, badIPs int
	for _, o := range t.ips {
		if now.Sub(o.at) > subnetWindow {
			continue
		}
		if o.ok {
			okIPs++
		} else {
			badIPs++
		}
	}
	if okIPs+badIPs < subnetMinIPs {
		return SubnetHealthy
	}
	switch {
	case badIPs > 0 && okIPs == 0:
		return SubnetBurned
	case badIPs > 0:
		return SubnetDegraded
	default:
		return SubnetHealthy
	}
}

// SubnetInfo is one subnet's verdict for diagnostics and the meter.
type SubnetInfo struct {
	Subnet netip.Prefix
	State  SubnetState
	// GoodIPs and BadIPs count distinct server IPs with in-window
	// outcomes behind the verdict.
	GoodIPs, BadIPs int
}

// Subnets lists every tracked subnet with a current verdict, worst first,
// in stable order. It is the diagnostics readout behind CENSORSHIP-METER.
func (r *SubnetReputation) Subnets() []SubnetInfo {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := r.now()
	r.pruneLocked(now)
	out := make([]SubnetInfo, 0, len(r.subs))
	for p, t := range r.subs {
		var good, bad int
		for _, o := range t.ips {
			if now.Sub(o.at) > subnetWindow {
				continue
			}
			if o.ok {
				good++
			} else {
				bad++
			}
		}
		out = append(out, SubnetInfo{Subnet: p, State: stateOf(t, now), GoodIPs: good, BadIPs: bad})
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].State != out[j].State {
			return out[i].State > out[j].State
		}
		return out[i].Subnet.String() < out[j].Subnet.String()
	})
	return out
}

// Wave reports whether a carpet-ban wave is in progress: at least
// subnetWaveMin distinct subnets burned inside the window. The second
// return lists the burned subnets, worst first.
func (r *SubnetReputation) Wave() (bool, []SubnetInfo) {
	infos := r.Subnets()
	var burned []SubnetInfo
	for _, in := range infos {
		if in.State == SubnetBurned {
			burned = append(burned, in)
		}
	}
	return len(burned) >= subnetWaveMin, burned
}

// SummaryLines renders the reputation for the diagnostics report. Empty
// when nothing was observed: no data, no claims.
func (r *SubnetReputation) SummaryLines() []string {
	infos := r.Subnets()
	var lines []string
	if wave, burned := r.Wave(); wave {
		lines = append(lines, fmt.Sprintf("subnet reputation: CARPET-BAN WAVE — %d subnets burned in the last %s",
			len(burned), subnetWindow))
	}
	for _, in := range infos {
		if in.State == SubnetHealthy && in.BadIPs == 0 {
			continue
		}
		lines = append(lines, fmt.Sprintf("subnet %s: %s (%d ok / %d failed server IPs in %s)",
			in.Subnet, in.State, in.GoodIPs, in.BadIPs, subnetWindow))
	}
	return lines
}

// pruneLocked drops outcomes older than the window and empty tracks.
func (r *SubnetReputation) pruneLocked(now time.Time) {
	r.lastPrune = now
	for p, t := range r.subs {
		pruneTrackLocked(t, now)
		if len(t.ips) == 0 {
			delete(r.subs, p)
		}
	}
}

// pruneTrackLocked drops one track's out-of-window outcomes.
func pruneTrackLocked(t *subnetTrack, now time.Time) {
	cutoff := now.Add(-subnetWindow)
	for ip, o := range t.ips {
		if o.at.Before(cutoff) {
			delete(t.ips, ip)
		}
	}
}
