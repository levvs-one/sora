package bypass

import (
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/logs"
)

// stubRedactingEngine is a stubEngine whose Redactor mirrors the
// supervisor's: seeded with the plan's secrets and identifiers.
type stubRedactingEngine struct {
	stubEngine
	redactor *engine.Redactor
}

func (s stubRedactingEngine) Redactor() *engine.Redactor { return s.redactor }

// TestBypassLogLineIsRedacted pins the CENSOR-LEAK fix: tpws/nfqws
// output lines name the hosts and SNI values being desynced, and the
// bypass engine wrote them to the log center raw. They now pass the
// inner engine's redactor (seeded path) and, without one, at least
// the generic patterns.
func TestBypassLogLineIsRedacted(t *testing.T) {
	center := logs.New(logs.DefaultSettings())
	inner := stubRedactingEngine{redactor: engine.NewRedactor("seeded-server.example", "seeded-token-1234")}
	e := Wrap(inner, Binaries{}, t.TempDir(), center)
	e.logLine("tpws: new connection to seeded-server.example with token seeded-token-1234")
	entries := center.Matching(logs.Filter{})
	if len(entries) != 1 {
		t.Fatalf("log entries = %d, want 1", len(entries))
	}
	if strings.Contains(entries[0].Message, "seeded-server.example") || strings.Contains(entries[0].Message, "seeded-token-1234") {
		t.Errorf("bypass log line leaked a seeded value: %q", entries[0].Message)
	}

	// No redactor on the inner engine: the pattern path must still
	// mask an SNI assignment and a credential pair.
	center2 := logs.New(logs.DefaultSettings())
	e2 := Wrap(stubEngine{}, Binaries{}, t.TempDir(), center2)
	e2.logLine("nfqws: sni: pattern-sni.example token=PatternToken123")
	entries = center2.Matching(logs.Filter{})
	if len(entries) != 1 {
		t.Fatalf("log entries = %d, want 1", len(entries))
	}
	if strings.Contains(entries[0].Message, "pattern-sni.example") || strings.Contains(entries[0].Message, "PatternToken123") {
		t.Errorf("bypass log line leaked a pattern value: %q", entries[0].Message)
	}
	_ = time.Time{}
}

// TestBypassLineLevelAgreement pins the level classification: a
// bypass error line must not land at Info where level-filtered log
// queries would miss it.
func TestBypassLineLevelAgreement(t *testing.T) {
	cases := map[string]logs.Level{
		"tpws started, pid 123":              logs.LevelInfo,
		"[ERROR] cannot bind socket":         logs.LevelError,
		"error: queue 200 is busy":           logs.LevelError,
		"warning: hostlist is empty":         logs.LevelWarning,
		"nfqws: fatal: no such device":       logs.LevelError,
		"connection to example closed early": logs.LevelInfo,
	}
	for line, want := range cases {
		if got := bypassLineLevel(line); got != want {
			t.Errorf("bypassLineLevel(%q) = %v, want %v", line, got, want)
		}
	}
}
