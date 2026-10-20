package censor

// Session-layer siberian freeze tracker.
//
// Relationship to core/probe/freeze.go: that detector measures the
// phenomenon (passive dial samples, active differential parallel-vs-sequential
// probing). This tracker consumes *session* events — failed connection
// attempts the running session already produced — and turns them into
// policy: back off, rotate the fingerprint, rotate the SNI, fail over.
// The probe detector asks "is this SNI frozen right now"; this tracker
// answers "what should the session do about it".
//
// The tracker additionally enforces two rules the matrix demands and the
// probe detector does not:
//   - backoff ≥ 120 s after a freeze is recognized: no new handshakes to
//     the SNI and, crucially, no fingerprint rotation while the freeze is
//     hot. Rotating mid-freeze just burns the next fingerprint into the
//     same (subnet, SNI) flag.
//   - an escalation ladder: fingerprint rotation first (cheap, same
//     server), then SNI rotation (needs a pool of consistent SNIs, see
//     snipool.go), then failover to another server.
//
// Design note on the rotation order: the field reports behind T007 say
// Chrome/Safari/iOS fingerprints are the ones being frozen while
// Firefox/Edge/QQ/Android pass. The rotation therefore never returns to
// the suspect set. (core/probe's RotateFingerprint cycles through the
// suspect names too — that contradicts the field data; see the spec.)

import (
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	// freezeWindow bounds the tracker's memory. Freezes are acted on
	// within minutes; older failures are a different story.
	freezeWindow = 5 * time.Minute
	// freezeMinFailures is the evidence bar for naming a freeze. Below
	// three handshake failures on one SNI the pattern is indistinguishable
	// from an unhappy server.
	freezeMinFailures = 3
	// freezeEscalateAt is where fingerprint rotation alone stops being the
	// credible answer: this many failures mean the SNI itself is burned.
	freezeEscalateAt = 6
	// freezeParallelTrigger is the censor's own threshold from the field
	// reports: more than three parallel TLS handshakes with one SNI.
	freezeParallelTrigger = 3
	// freezeBackoff is the mandatory quiet period after a freeze is
	// recognized. It matches the observed freeze duration (~120 s):
	// hammering the SNI during the freeze cannot succeed and only feeds
	// the censor more triples to flag.
	freezeBackoff = 120 * time.Second
)

// siberianRotation lists the uTLS fingerprints that pass the behavioral
// check, in the order to try them. Chrome, Safari and iOS are deliberately
// absent: they are the fingerprints the freeze targets, so rotating *to*
// them is never the answer. The names are the engine-facing uTLS names
// (see engine/fingerprint.go); this package keeps its own copy to avoid an
// import cycle with engine.
var siberianRotation = []string{"firefox", "edge", "qq", "android"}

// NextSiberianFingerprint returns the next fingerprint to try after current.
// A current fingerprint outside the rotation (chrome, safari, ios, empty,
// unknown) restarts at the head: the first move is always away from the
// suspect set. ok=false means the rotation is exhausted and the session
// should fail over to another server instead of cycling fingerprints.
func NextSiberianFingerprint(current string) (next string, ok bool) {
	cur := strings.ToLower(strings.TrimSpace(current))
	for i, fp := range siberianRotation {
		if fp == cur {
			if i+1 < len(siberianRotation) {
				return siberianRotation[i+1], true
			}
			return "", false
		}
	}
	return siberianRotation[0], true
}

// SiberianAssessment is the tracker's answer about one SNI.
type SiberianAssessment struct {
	// Freeze reports that the SNI looks frozen by the censor.
	Freeze bool
	// Confidence is 0..1 for Freeze=true; meaningless otherwise.
	Confidence float64
	// RetryAfter is the earliest time the session may attempt this SNI
	// again or apply SuggestedFingerprint. It is always ≥ freezeBackoff
	// after the freeze was recognized: rotating the fingerprint or
	// retrying during the freeze burns the new triple for nothing.
	RetryAfter time.Time
	// SuggestedFingerprint is the next uTLS fingerprint to try *after*
	// RetryAfter. Empty while the backoff is hot or when the rotation is
	// exhausted — then Failover is the only move.
	SuggestedFingerprint string
	// RotateSNI advises changing the REALITY dest/SNI (from the pool of
	// consistent SNIs): fingerprint rotation alone is unlikely to help
	// anymore.
	RotateSNI bool
	// Failover advises switching servers: rotations did not help, the
	// (subnet, SNI) pair is burned.
	Failover bool
	// Evidence lists the observations the assessment rests on.
	Evidence []string
	// Explanation is the user-facing account. It understates, like every
	// string in this package.
	Explanation string
}

// freezeFailure is one counted handshake failure.
type freezeFailure struct {
	at    time.Time
	stall bool // the handshake stalled (timeout) rather than being killed
}

// sniTrack is the per-SNI memory.
type sniTrack struct {
	failures      []freezeFailure
	successAt     time.Time
	rotations     int
	maxInflight   int
	lastSeen      time.Time // last Begin/Observe/NoteRotation: keeps the track alive
	backoffEnd    time.Time // no new attempts before this (freezeBackoff rule)
	backoffArmedN int       // failure count at the last backoff arming
}

// FreezeDetector tracks TLS handshake outcomes per SNI and recognizes the
// siberian freeze pattern. It is safe for concurrent use.
//
// Production status (2026-10-20): NOT WIRED. Nothing feeds it and
// nothing consumes its SiberianAssessment: WatchCensorshipFailures
// (session) could feed Observe/ObserveSuccess, but the actions the
// assessment prescribes — fingerprint rotation, SNI rotation, plan
// failover — have no consumer in the session layer today, so feeding
// the tracker would produce verdicts nobody acts on (theater). The
// detector is kept for its unit tests and the designed policy;
// wiring it is an owner decision (SW4 tier 2): the session must learn
// to rotate fingerprints/SNI on a running plan first.
type FreezeDetector struct {
	mu         sync.Mutex
	tracks     map[string]*sniTrack
	inflight   map[string]int
	anySuccess time.Time
	now        func() time.Time
}

// NewFreezeDetector returns a detector with default tuning.
func NewFreezeDetector() *FreezeDetector {
	return &FreezeDetector{
		tracks:   map[string]*sniTrack{},
		inflight: map[string]int{},
		now:      time.Now,
	}
}

// normalizeSNI lowercases and trims the SNI so "Example.COM." and
// "example.com" share one track.
func normalizeSNI(sni string) string {
	return strings.ToLower(strings.TrimSuffix(strings.TrimSpace(sni), "."))
}

// trackFor returns the track for key, creating it on demand. The caller
// must hold d.mu.
func (d *FreezeDetector) trackFor(key string) *sniTrack {
	tr, ok := d.tracks[key]
	if !ok {
		tr = &sniTrack{}
		d.tracks[key] = tr
	}
	return tr
}

// prune drops failures older than the window and empties dead tracks. The
// caller must hold d.mu.
func (d *FreezeDetector) prune(now time.Time) {
	cutoff := now.Add(-freezeWindow)
	for key, tr := range d.tracks {
		kept := tr.failures[:0]
		for _, f := range tr.failures {
			if f.at.After(cutoff) {
				kept = append(kept, f)
			}
		}
		tr.failures = kept
		if len(kept) == 0 && tr.lastSeen.Before(cutoff) && d.inflight[key] == 0 {
			delete(d.tracks, key)
			delete(d.inflight, key)
		}
	}
	if d.anySuccess.Before(cutoff) {
		d.anySuccess = time.Time{}
	}
}

// Begin marks one TLS handshake attempt starting for sni and returns an end
// function the caller must invoke when the attempt finishes. The peak
// parallel count feeds the freeze evidence: the censor's trigger is more
// than three parallel handshakes with one SNI, and only measured
// parallelism can corroborate it.
func (d *FreezeDetector) Begin(sni string) (end func()) {
	key := normalizeSNI(sni)
	if key == "" {
		return func() {}
	}
	d.mu.Lock()
	d.inflight[key]++
	tr := d.trackFor(key)
	tr.lastSeen = d.now()
	if n := d.inflight[key]; n > tr.maxInflight {
		tr.maxInflight = n
	}
	d.mu.Unlock()
	return func() {
		d.mu.Lock()
		if d.inflight[key] > 0 {
			d.inflight[key]--
		}
		d.mu.Unlock()
	}
}

// Observe records one finished attempt. Only handshake-stage failures with
// no server bytes count toward a freeze: a refused or unanswered TCP
// connect is a dead server or IP filtering, a TLS alert is the server's
// voice, and bytes from the far end mean the path let the handshake
// through.
func (d *FreezeDetector) Observe(a Attempt) {
	if !a.Target.TLS {
		return
	}
	key := normalizeSNI(a.Target.SNI)
	if key == "" {
		return
	}
	t, sawBytesIn := terminalScan(a)
	if t == nil || t.Stage != StageTLS {
		return
	}
	if sawBytesIn || t.BytesIn > 0 {
		return
	}
	stall := false
	switch t.What {
	case WhatLocalTimeout:
		stall = true
	case WhatRemoteReset, WhatRemoteClose:
		// Killed right after the ClientHello, before any server bytes:
		// the freeze's other face.
	default:
		return
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.prune(now)
	tr := d.trackFor(key)
	tr.failures = append(tr.failures, freezeFailure{at: now, stall: stall})
	tr.lastSeen = now
}

// ObserveSuccess records a working connection. It clears the failure
// memory for that SNI — a freeze that lifted is not a freeze — and notes
// that the path itself works, which is what makes a per-SNI failure
// pattern targeted rather than a dead route.
func (d *FreezeDetector) ObserveSuccess(t Target) {
	key := normalizeSNI(t.SNI)
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.prune(now)
	d.anySuccess = now
	if key == "" {
		return
	}
	tr := d.trackFor(key)
	tr.failures = nil
	tr.successAt = now
	tr.rotations = 0
	tr.maxInflight = 0
	tr.lastSeen = now
	tr.backoffEnd = time.Time{}
}

// NoteRotation records that the session applied a fingerprint rotation for
// sni (usually the SuggestedFingerprint from the last assessment, after the
// backoff expired). If failures keep accumulating afterwards, the detector
// escalates to SNI rotation and then failover instead of suggesting
// another fingerprint.
func (d *FreezeDetector) NoteRotation(sni string) {
	key := normalizeSNI(sni)
	if key == "" {
		return
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	tr := d.trackFor(key)
	tr.rotations++
	tr.lastSeen = d.now()
}

// BackoffUntil reports when the session may next attempt sni. The second
// return value is false when no backoff is in force. Callers must honor
// it: attempting during the freeze cannot succeed and only feeds the
// censor more triples to flag.
func (d *FreezeDetector) BackoffUntil(sni string) (time.Time, bool) {
	key := normalizeSNI(sni)
	if key == "" {
		return time.Time{}, false
	}
	d.mu.Lock()
	defer d.mu.Unlock()
	tr, ok := d.tracks[key]
	if !ok || tr.backoffEnd.IsZero() {
		return time.Time{}, false
	}
	if now := d.now(); !now.Before(tr.backoffEnd) {
		return time.Time{}, false
	}
	return tr.backoffEnd, true
}

// Assess answers whether sni looks frozen and what to do about it.
// fingerprint is the uTLS fingerprint currently in use, for the rotation
// suggestion. While the backoff is hot the assessment says Freeze with an
// empty SuggestedFingerprint: the only correct action is to wait.
func (d *FreezeDetector) Assess(t Target, fingerprint string) SiberianAssessment {
	key := normalizeSNI(t.SNI)
	d.mu.Lock()
	defer d.mu.Unlock()
	now := d.now()
	d.prune(now)
	tr := d.tracks[key]
	if tr == nil || len(tr.failures) < freezeMinFailures {
		return SiberianAssessment{Freeze: false}
	}
	if !tr.successAt.IsZero() && tr.successAt.After(tr.failures[0].at) {
		// It worked after the failures started: recovered, not frozen.
		return SiberianAssessment{Freeze: false}
	}
	n := len(tr.failures)
	conf := 0.55 + 0.08*float64(n-freezeMinFailures)
	if conf > 0.85 {
		conf = 0.85
	}
	ev := []string{
		strconv.Itoa(n) + " TLS handshakes to " + key + " stalled or were killed before any server bytes in the last 5 minutes",
	}
	if tr.maxInflight > freezeParallelTrigger {
		ev = append(ev, "peak "+strconv.Itoa(tr.maxInflight)+" parallel handshakes with this SNI (the freeze triggers above 3)")
		conf += 0.05
		if conf > 0.85 {
			conf = 0.85
		}
	}
	if !d.anySuccess.IsZero() && d.anySuccess.After(tr.failures[0].at) &&
		(tr.successAt.IsZero() || d.anySuccess.After(tr.successAt)) {
		ev = append(ev, "connections to other destinations worked in the same window: the path is up, this SNI is targeted")
		conf += 0.05
		if conf > 0.85 {
			conf = 0.85
		}
	}
	// First recognition starts the backoff: ≥120 s of quiet, no
	// fingerprint games while the freeze is hot. New failures arriving
	// after the arming re-arm it: the freeze is still active.
	if tr.backoffEnd.IsZero() || len(tr.failures) > tr.backoffArmedN {
		tr.backoffEnd = now.Add(freezeBackoff)
		tr.backoffArmedN = len(tr.failures)
	}
	a := SiberianAssessment{
		Freeze:     true,
		Confidence: conf,
		RetryAfter: tr.backoffEnd,
		Evidence:   ev,
	}
	// Escalation ladder: rotate the fingerprint first (cheap, same
	// server), then the SNI, then give up on the server. The ladder only
	// moves forward on evidence: a rotation that did not stop the
	// failures, or enough failures that the SNI itself looks burned.
	// The ladder position is reported even while the backoff is hot, so
	// the caller knows what comes next — but SuggestedFingerprint stays
	// empty until the backoff expires: rotating mid-freeze burns the new
	// fingerprint into the same (subnet, SNI) flag.
	next, ok := NextSiberianFingerprint(fingerprint)
	a.RotateSNI = n >= freezeEscalateAt || tr.rotations > 0
	a.Failover = !ok || tr.rotations >= 2
	if a.Failover {
		a.Explanation = "This destination looks frozen by the network filter: repeated TLS handshakes die before the server can answer, while other destinations work. Fingerprint changes did not help — try another server."
	} else if a.RotateSNI {
		a.Explanation = "This destination looks frozen by the network filter: repeated TLS handshakes die before the server can answer. Changing the TLS fingerprint did not help — try another destination name for this server."
	} else {
		a.Explanation = "This destination looks frozen by the network filter: repeated TLS handshakes die before the server can answer. Trying a different TLS fingerprint usually helps."
	}
	if now.Before(tr.backoffEnd) {
		a.Explanation += " Do not retry or change the fingerprint yet — the freeze lasts about 2 minutes, and attempts during it only burn more fingerprints."
		return a
	}
	a.SuggestedFingerprint = next
	if a.Failover {
		a.SuggestedFingerprint = ""
	}
	return a
}
