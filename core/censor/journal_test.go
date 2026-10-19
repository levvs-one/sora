package censor

import (
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

func TestAttemptFromLogRefused(t *testing.T) {
	now := time.Now()
	a := AttemptFromLog("srv1", Target{Host: "vpn.example.com", Port: 443}, []LogEvent{
		{At: now, Kind: "error", Detail: "connection refused", Code: errs.CodeUnavailable, Key: errs.KeyConnectionRefused},
	})
	v := Detector{}.Detect(a)
	if v.Kind != KindNoInterference {
		t.Fatalf("kind = %v, want no_interference", v.Kind)
	}
}

func TestAttemptFromLogKnownGood(t *testing.T) {
	now := time.Now()
	a := AttemptFromLog("srv1", Target{Host: "vpn.example.com", Port: 443}, []LogEvent{
		{At: now, Kind: "state", State: "connected"},
		{At: now.Add(time.Second), Kind: "error", Detail: "no such host", Key: "core.network.failed"},
	})
	if !a.KnownGoodHost {
		t.Fatal("a prior connected state must mark the host known-good")
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindDNSPoisoning {
		t.Fatalf("kind = %v, want dns_poisoning for nxdomain on a known-good host", v.Kind)
	}
}

// Negative: journal noise the adapter cannot recognize must be dropped, not
// guessed — a guessed event manufactures evidence.
func TestAttemptFromLogDropsUnrecognized(t *testing.T) {
	now := time.Now()
	a := AttemptFromLog("srv1", Target{Host: "vpn.example.com", Port: 443}, []LogEvent{
		{At: now, Kind: "error", Detail: "engine hiccup 42", Key: "core.engine.stopped"},
		{At: now, Kind: "log", Detail: "something happened"},
	})
	if len(a.Events) != 0 {
		t.Fatalf("unrecognized journal lines must not become attempt events, got %+v", a.Events)
	}
	v := Detector{}.Detect(a)
	if v.Kind != KindUnknown {
		t.Fatalf("kind = %v, want unknown for an empty journal", v.Kind)
	}
}
