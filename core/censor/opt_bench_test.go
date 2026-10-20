// Benchmarks for the censorship detector's classification path
// ([pass2-opt] regression control). Detect runs every rule over the
// attempt's event log; the journal path feeds it up to 256 events, so
// the per-rule cost must not multiply with the rule count.
package censor

import (
	"testing"
	"time"
)

// benchAttempt builds an attempt with n data events ending in a
// mid-data stall: the shape a long journal-fed attempt takes.
func benchAttempt(n int) Attempt {
	base := time.Now()
	events := []Event{
		{Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.7", At: base},
		{Stage: StageTCP, What: WhatConnected, At: base.Add(10 * time.Millisecond)},
		{Stage: StageTLS, What: WhatSent, At: base.Add(20 * time.Millisecond)},
		{Stage: StageTLS, What: WhatReceived, BytesIn: 1200, At: base.Add(40 * time.Millisecond)},
	}
	for i := 0; i < n; i++ {
		events = append(events, Event{
			Stage:   StageData,
			What:    WhatReceived,
			BytesIn: 4096,
			At:      base.Add(100*time.Millisecond + time.Duration(i)*10*time.Millisecond),
		})
	}
	events = append(events, Event{
		Stage:   StageData,
		What:    WhatLocalTimeout,
		BytesIn: 20000,
		At:      base.Add(30 * time.Second),
	})
	return Attempt{
		Target:    Target{Host: "203.0.113.7", Port: 443, SNI: "example.com", TLS: true},
		StartedAt: base,
		Events:    events,
	}
}

func BenchmarkDetectJournal256(b *testing.B) {
	a := benchAttempt(251) // 256 events total, the journal cap
	d := Detector{}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = d.Detect(a)
	}
}

func BenchmarkDetectSmall(b *testing.B) {
	base := time.Now()
	a := Attempt{
		Target:    Target{Host: "203.0.113.7", Port: 443, SNI: "example.com", TLS: true},
		StartedAt: base,
		Events: []Event{
			{Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.7", At: base},
			{Stage: StageTCP, What: WhatConnected, At: base.Add(10 * time.Millisecond)},
			{Stage: StageTLS, What: WhatSent, At: base.Add(20 * time.Millisecond)},
			{Stage: StageTLS, What: WhatRemoteReset, At: base.Add(25 * time.Millisecond)},
		},
	}
	d := Detector{}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = d.Detect(a)
	}
}
