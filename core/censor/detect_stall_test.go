package censor

import (
	"strings"
	"testing"
	"time"
)

func dataStallAttempt() Attempt {
	a := withStart(mkAttempt())
	base := time.Unix(1000, 0)
	a.Events = []Event{
		{At: base, Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.7"},
		{At: base.Add(100 * time.Millisecond), Stage: StageTCP, What: WhatConnected},
		{At: base.Add(150 * time.Millisecond), Stage: StageTLS, What: WhatSent, Detail: "client_hello"},
		{At: base.Add(300 * time.Millisecond), Stage: StageTLS, What: WhatReceived, Detail: "server_hello", BytesIn: 120},
		{At: base.Add(500 * time.Millisecond), Stage: StageData, What: WhatReceived, BytesIn: 8100},
		{At: base.Add(700 * time.Millisecond), Stage: StageData, What: WhatReceived, BytesIn: 16101},
		{At: base.Add(30 * time.Second), Stage: StageData, What: WhatLocalTimeout, BytesIn: 16101},
	}
	return a
}

func TestDetectDataStall(t *testing.T) {
	v := Detector{}.Detect(dataStallAttempt())
	if v.Kind != KindDataStall {
		t.Fatalf("kind = %v, want data_stall", v.Kind)
	}
	if v.Confidence != 0.7 {
		t.Fatalf("confidence = %v, want 0.7", v.Confidence)
	}
	if v.HasProfile {
		t.Fatalf("profile = %+v, want none: no handshake obfuscation fixes a mid-data freeze", v.Profile)
	}
	found := false
	for _, e := range v.Evidence {
		if strings.Contains(e, "16101") {
			found = true
		}
	}
	if !found {
		t.Fatalf("evidence %q does not report the measured byte count", v.Evidence)
	}
	if !strings.Contains(v.Explanation, "froze") {
		t.Fatalf("explanation %q does not name the freeze", v.Explanation)
	}
}

func TestDataStallIsNotAReset(t *testing.T) {
	// Same bytes, but the path tore the connection down: that is RST
	// injection, not a stall. The distinction is the point of the new kind.
	a := dataStallAttempt()
	a.Events[len(a.Events)-1] = Event{At: time.Unix(1000, 0).Add(2 * time.Second),
		Stage: StageData, What: WhatRemoteReset, BytesIn: 16101}
	v := Detector{}.Detect(a)
	if v.Kind != KindRSTInjection {
		t.Fatalf("kind = %v, want rst_injection", v.Kind)
	}
}

func TestDataStallIsNotAHandshakeTimeout(t *testing.T) {
	// Silence during the handshake stays a handshake timeout even when the
	// byte counts are large: the stall kind is only for established data.
	a := withStart(mkAttempt())
	base := time.Unix(1000, 0)
	a.Events = []Event{
		{At: base, Stage: StageDNS, What: WhatResolved, Detail: "203.0.113.7"},
		{At: base.Add(100 * time.Millisecond), Stage: StageTCP, What: WhatConnected},
		{At: base.Add(150 * time.Millisecond), Stage: StageTLS, What: WhatSent, Detail: "client_hello", BytesOut: 512},
		{At: base.Add(30 * time.Second), Stage: StageTLS, What: WhatLocalTimeout, BytesOut: 512},
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindHandshakeTimeout {
		t.Fatalf("kind = %v, want handshake_timeout", v.Kind)
	}
}

func TestDataStallBelowFloorStaysSilent(t *testing.T) {
	// A few hundred bytes then silence is indistinguishable from handshake
	// trouble; the stall rule must not claim it.
	a := withStart(mkAttempt())
	base := time.Unix(1000, 0)
	a.Events = []Event{
		{At: base, Stage: StageTCP, What: WhatConnected},
		{At: base.Add(500 * time.Millisecond), Stage: StageData, What: WhatReceived, BytesIn: 400},
		{At: base.Add(30 * time.Second), Stage: StageData, What: WhatLocalTimeout, BytesIn: 400},
	}
	v := Detector{}.Detect(a)
	if v.Kind == KindDataStall {
		t.Fatalf("kind = data_stall for only 400 bytes; the floor must hold")
	}
}

func TestDataStallWithoutByteCountsStaysSilent(t *testing.T) {
	// No byte instrumentation: a data-stage timeout without byte evidence
	// must not become a confident stall claim.
	a := withStart(mkAttempt())
	base := time.Unix(1000, 0)
	a.Events = []Event{
		{At: base, Stage: StageTCP, What: WhatConnected},
		{At: base.Add(500 * time.Millisecond), Stage: StageData, What: WhatSent},
		{At: base.Add(30 * time.Second), Stage: StageData, What: WhatLocalTimeout},
	}
	v := Detector{}.Detect(a)
	if v.Kind == KindDataStall {
		t.Fatal("kind = data_stall with no byte evidence; uncertain must read as uncertain")
	}
}

func TestDataStallIgnoresOrderlyClose(t *testing.T) {
	// FIN after data is an orderly close, not a freeze.
	a := dataStallAttempt()
	a.Events[len(a.Events)-1] = Event{At: time.Unix(1000, 0).Add(2 * time.Second),
		Stage: StageData, What: WhatRemoteClose, BytesIn: 16101}
	v := Detector{}.Detect(a)
	if v.Kind == KindDataStall {
		t.Fatal("kind = data_stall for an orderly close")
	}
}

func TestKindDataStallString(t *testing.T) {
	if KindDataStall.String() != "data_stall" {
		t.Fatalf("String() = %q", KindDataStall.String())
	}
}
