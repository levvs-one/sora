package censor

import (
	"fmt"
	"time"
)

// dataStallMinBytes is the floor for calling a mid-session silence a stall.
// Below it the event is indistinguishable from a handshake problem and the
// handshake rules own it. The ~16 KB figure from the 2026 field reports is
// reported as measured evidence, never as a required threshold:
// parameterize, don't hardcode.
const dataStallMinBytes = 1024

// dataStallRule fires when an established session carried data and then went
// silent until our own deadline, with no RST or FIN: the freeze/silent-drop
// signature of 2026 throttling (the path lets roughly the first 16 KB
// through, then holds the connection). It completes the SNI-I/II/III
// distinction:
//   - SNI-I: RST right after the ClientHello (sniBlockingRule).
//   - SNI-II/III: data flows, then the path stalls (this rule) or resets
//     mid-data (dataResetRule, which reports KindRSTInjection).
//
// Confidence stays below the top: a congested path can also stall mid-data,
// and the explanation admits it. When the instrumentation tracked no byte
// counts the rule stays silent — without byte evidence a data stall is
// indistinguishable from a handshake stall, and an uncertain verdict must
// read as uncertainty.
func dataStallRule(a Attempt, s failureScan) (candidate, bool) {
	t := s.terminal
	if t == nil || t.What != WhatLocalTimeout {
		return candidate{}, false
	}
	if s.furthest != StageData {
		return candidate{}, false
	}
	if t.BytesIn < dataStallMinBytes && !s.sawBytesIn {
		return candidate{}, false
	}
	bytesIn := t.BytesIn
	if bytesIn <= 0 {
		// Byte counts missing on the terminal event; fall back to the
		// largest count any event reported (precomputed by scan).
		bytesIn = s.maxBytesIn
	}
	if bytesIn < dataStallMinBytes {
		return candidate{}, false
	}
	ev := []string{
		fmt.Sprintf("%d bytes arrived, then silence until our deadline: the session froze mid-transfer", bytesIn),
		"no reset or close arrived: the path held the connection instead of tearing it down",
	}
	if d := stallDuration(a, t); d > 0 {
		ev = append(ev, fmt.Sprintf("the silence lasted %s after the last observed data", d.Round(time.Second)))
	}
	return candidate{KindDataStall, 0.7, ev}, true
}

// stallDuration measures from the last event that carried inbound bytes to
// the terminal timeout. Zero when the attempt carries no usable timestamps.
func stallDuration(a Attempt, t *Event) time.Duration {
	var last time.Time
	for _, e := range a.Events {
		if e.BytesIn > 0 && e.At.After(last) {
			last = e.At
		}
	}
	if last.IsZero() || t.At.IsZero() || !t.At.After(last) {
		return 0
	}
	return t.At.Sub(last)
}
