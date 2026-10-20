package censor

// Session-layer siberian freeze POLICY.
//
// Recognition has exactly one source of truth: probe.FreezeDetector
// (core/probe/freeze.go) — the differential measurement (parallel TLS
// handshakes to one SNI stall while sequential ones succeed), fed by the
// prober's dials and by the active FreezeProber. This file no longer
// keeps its own per-SNI failure counting: the tracker that used to live
// here duplicated the recognizer with a weaker signature (any three
// pre-byte TLS failures) and a rotation list that contradicted the
// prober's. Both are gone; what remains is the policy the recognizer
// cannot own:
//
//   - a mandatory quiet period after a freeze is recognized: ≥120 s
//     with no new handshakes to the SNI and, crucially, no fingerprint
//     rotation while the freeze is hot — rotating mid-freeze burns the
//     next fingerprint into the same (subnet, SNI) flag;
//   - an escalation ladder: fingerprint rotation first (cheap, same
//     server), then SNI rotation (needs a pool of consistent SNIs, see
//     snipool.go), then failover to another server;
//   - the T007 rotation order, read from probe.FreezeFingerprintRotation
//     so there is exactly one list: Chrome, Safari and iOS are the
//     fingerprints the freeze targets and are never suggested.
//
// Production status (2026-10-20): the RECOGNIZER is wired (the control
// prober carries a FreezeDetector; a confirmed freeze surfaces as a
// censorship journal event and expedites subscription refreshes). The
// POLICY's actions — fingerprint/SNI rotation and plan failover on a
// running session — still have no consumer: the session layer cannot
// rotate a fingerprint or SNI on a live plan yet (SW4 tier 2, an owner
// decision). The policy is kept, tested, and fed through ObserveAttempt
// so the day the session learns to act, the ladder is already correct.

import (
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/probe"
)

const (
	// freezeWindow bounds the policy's bookkeeping memory. A freeze is
	// acted on within minutes; older state is a different story.
	freezeWindow = 5 * time.Minute
	// freezeBackoff is the mandatory quiet period after a freeze is
	// recognized. It matches the observed freeze duration (~120 s):
	// hammering the SNI during the freeze cannot succeed and only feeds
	// the censor more triples to flag.
	freezeBackoff = 120 * time.Second
	// freezeEscalateAt: this many stalled parallel handshakes mean
	// fingerprint rotation alone is not the credible answer — the SNI
	// itself looks burned.
	freezeEscalateAt = 6
)

// siberianRotation is the uTLS rotation order for freeze recovery. It is
// probe.FreezeFingerprintRotation() — the single source of truth — kept
// as a package-level alias so the policy and its tests read naturally.
// Chrome, Safari and iOS are deliberately absent (see the file doc).
var siberianRotation = probe.FreezeFingerprintRotation()

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

// SiberianAssessment is the policy's answer about one SNI.
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

// freezePolicyTrack is the per-SNI policy bookkeeping: when the quiet
// period ends, how much stall evidence had arrived when it was armed,
// and how many rotations the session already applied. It holds no dial
// samples — samples live in the recognizer.
type freezePolicyTrack struct {
	backoffEnd  time.Time
	stallsAtArm int
	rotations   int
	lastSeen    time.Time
}

// FreezePolicy turns the shared recognizer's verdicts into session
// policy: backoff, retry timing, and the escalation ladder. It is safe
// for concurrent use.
type FreezePolicy struct {
	det *probe.FreezeDetector

	mu     sync.Mutex
	tracks map[string]*freezePolicyTrack
	now    func() time.Time
}

// NewFreezePolicy returns a policy reading verdicts from det, the shared
// probe.FreezeDetector. A nil detector yields a policy that never fires:
// fail-closed, because a freeze claim without the differential evidence
// would be a guess.
func NewFreezePolicy(det *probe.FreezeDetector) *FreezePolicy {
	return &FreezePolicy{
		det:    det,
		tracks: map[string]*freezePolicyTrack{},
		now:    time.Now,
	}
}

// normalizeSNI lowercases and trims the SNI so "Example.COM." and
// "example.com" share one track. It matches the recognizer's key
// normalization (probe applies the same rule on Observe/Verdict).
func normalizeSNI(sni string) string {
	return strings.ToLower(strings.TrimSuffix(strings.TrimSpace(sni), "."))
}

// trackForLocked returns the track for key, creating it on demand. The
// caller must hold p.mu.
func (p *FreezePolicy) trackForLocked(key string) *freezePolicyTrack {
	tr, ok := p.tracks[key]
	if !ok {
		tr = &freezePolicyTrack{}
		p.tracks[key] = tr
	}
	return tr
}

// pruneLocked drops bookkeeping for SNIs untouched for a whole window.
// The caller must hold p.mu.
func (p *FreezePolicy) pruneLocked(now time.Time) {
	cutoff := now.Add(-freezeWindow)
	for key, tr := range p.tracks {
		if tr.lastSeen.Before(cutoff) {
			delete(p.tracks, key)
		}
	}
}

// ObserveAttempt feeds one session attempt into the shared recognizer,
// so session traffic contributes to the same single source of truth the
// prober feeds. Attempts are sequential (concurrency 1): they supply the
// control group of the differential — a success proves the endpoint is
// alive, a TLS-stage stall with no server bytes is one sequential stall.
// Resets, closes and TLS alerts are deliberately NOT fed: they are the
// SNI-blocking signature (handled by Detector), and counting them as
// freeze evidence was the old duplicate tracker's mistake.
func (p *FreezePolicy) ObserveAttempt(a Attempt) {
	if p.det == nil || !a.Target.TLS {
		return
	}
	key := normalizeSNI(a.Target.SNI)
	if key == "" {
		return
	}
	t, sawBytesIn := terminalScan(a)
	if t == nil {
		p.det.Observe(probe.FreezeSample{SNI: key, Concurrent: 1})
		return
	}
	if t.Stage != StageTLS || sawBytesIn || t.BytesIn > 0 {
		return
	}
	if t.What != WhatLocalTimeout {
		return
	}
	p.det.Observe(probe.FreezeSample{SNI: key, Concurrent: 1, Stalled: true})
}

// NoteRotation records that the session applied a fingerprint rotation for
// sni (usually the SuggestedFingerprint from the last assessment, after the
// backoff expired). If failures keep accumulating afterwards, the policy
// escalates to SNI rotation and then failover instead of suggesting
// another fingerprint.
func (p *FreezePolicy) NoteRotation(sni string) {
	key := normalizeSNI(sni)
	if key == "" {
		return
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	tr := p.trackForLocked(key)
	tr.rotations++
	tr.lastSeen = p.now()
}

// BackoffUntil reports when the session may next attempt sni. The second
// return value is false when no backoff is in force. Callers must honor
// it: attempting during the freeze cannot succeed and only feeds the
// censor more triples to flag.
func (p *FreezePolicy) BackoffUntil(sni string) (time.Time, bool) {
	key := normalizeSNI(sni)
	if key == "" {
		return time.Time{}, false
	}
	p.mu.Lock()
	defer p.mu.Unlock()
	tr, ok := p.tracks[key]
	if !ok || tr.backoffEnd.IsZero() {
		return time.Time{}, false
	}
	if now := p.now(); !now.Before(tr.backoffEnd) {
		return time.Time{}, false
	}
	return tr.backoffEnd, true
}

// Assess answers whether sni looks frozen and what to do about it. The
// freeze verdict itself comes from the shared recognizer; the policy
// adds the backoff and the ladder. fingerprint is the uTLS fingerprint
// currently in use, for the rotation suggestion. While the backoff is
// hot the assessment says Freeze with an empty SuggestedFingerprint:
// the only correct action is to wait.
func (p *FreezePolicy) Assess(t Target, fingerprint string) SiberianAssessment {
	key := normalizeSNI(t.SNI)
	if key == "" || p.det == nil {
		return SiberianAssessment{Freeze: false}
	}
	v := p.det.Verdict(key)
	p.mu.Lock()
	defer p.mu.Unlock()
	now := p.now()
	p.pruneLocked(now)
	if !v.Frozen {
		// The freeze lifted (or never held): forget the bookkeeping so
		// a future freeze starts the ladder from the bottom.
		delete(p.tracks, key)
		return SiberianAssessment{Freeze: false}
	}
	tr := p.trackForLocked(key)
	tr.lastSeen = now
	// Arm the quiet period on first recognition, and re-arm it whenever
	// fresh stall evidence arrived since the last arming: the freeze is
	// still active, and attempts during it only burn more fingerprints.
	if tr.backoffEnd.IsZero() || v.ParallelStalled > tr.stallsAtArm {
		tr.backoffEnd = now.Add(freezeBackoff)
		tr.stallsAtArm = v.ParallelStalled
	}
	a := SiberianAssessment{
		Freeze:     true,
		Confidence: v.Confidence,
		RetryAfter: tr.backoffEnd,
		Evidence:   append([]string(nil), v.Evidence...),
	}
	a.Evidence = append(a.Evidence,
		strconv.Itoa(v.ParallelStalled)+" stalled parallel handshakes feed the shared freeze recognizer")
	// Escalation ladder: rotate the fingerprint first (cheap, same
	// server), then the SNI, then give up on the server. The ladder only
	// moves forward on evidence: a rotation that did not stop the
	// failures, or enough stalled parallels that the SNI itself looks
	// burned.
	next, ok := NextSiberianFingerprint(fingerprint)
	a.RotateSNI = v.ParallelStalled >= freezeEscalateAt || tr.rotations > 0
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
	if !a.Failover {
		a.SuggestedFingerprint = next
	}
	return a
}
