package censor

import (
	"strings"
	"testing"
	"time"
)

// T028: the KZ-measured signature — the session times out after the
// ClientHello (OONI 2023-2024). The classifier must name it a confident
// handshake-timeout with the specific evidence, not the generic stall.

func kzStallAttempt() Attempt {
	base := time.Now()
	return Attempt{
		ServerID: "kz1",
		Target:   Target{Host: "example.com", Port: 443, SNI: "example.com", TLS: true},
		Events: []Event{
			{At: base, Stage: StageDNS, What: WhatResolved},
			{At: base.Add(50 * time.Millisecond), Stage: StageTCP, What: WhatConnected},
			{At: base.Add(60 * time.Millisecond), Stage: StageTLS, What: WhatSent, BytesOut: 512},
			{At: base.Add(5 * time.Second), Stage: StageTLS, What: WhatLocalTimeout},
		},
	}
}

func TestClientHelloStallRule(t *testing.T) {
	v := Detector{}.Detect(kzStallAttempt())
	if v.Kind != KindHandshakeTimeout {
		t.Fatalf("kind = %v, want handshake_timeout", v.Kind)
	}
	if v.Confidence < 0.65 {
		t.Errorf("confidence = %v, want >= 0.65 for the narrow stall signature", v.Confidence)
	}
	found := false
	for _, e := range v.Evidence {
		if strings.Contains(e, "client hello was sent") {
			found = true
		}
	}
	if !found {
		t.Errorf("evidence %v does not name the client-hello stall", v.Evidence)
	}
}

func TestClientHelloStallNeedsSentHello(t *testing.T) {
	// Timeout at TLS stage but the ClientHello never went out (e.g. the
	// write itself stalled): the narrow rule must stay out, the generic
	// rule still applies.
	a := kzStallAttempt()
	a.Events = []Event{
		{At: time.Now(), Stage: StageTCP, What: WhatConnected},
		{At: time.Now().Add(5 * time.Second), Stage: StageTLS, What: WhatLocalTimeout},
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindHandshakeTimeout {
		t.Fatalf("kind = %v, want handshake_timeout", v.Kind)
	}
	for _, e := range v.Evidence {
		if strings.Contains(e, "client hello was sent") {
			t.Errorf("narrow stall evidence claimed without a sent ClientHello: %v", v.Evidence)
		}
	}
}

func TestClientHelloStallNeedsSilence(t *testing.T) {
	// Server bytes arrived before the stall: mid-handshake stall, not the
	// KZ signature. The generic rule (0.6) must win over the narrow one.
	a := kzStallAttempt()
	a.Events = append(a.Events[:3], Event{
		At: time.Now().Add(4 * time.Second), Stage: StageTLS, What: WhatReceived, BytesIn: 1200,
	}, a.Events[3])
	v := Detector{}.Detect(a)
	if v.Kind != KindHandshakeTimeout {
		t.Fatalf("kind = %v, want handshake_timeout", v.Kind)
	}
	if v.Confidence >= 0.65 {
		t.Errorf("confidence = %v, want the generic 0.6 verdict when server bytes were seen", v.Confidence)
	}
}
