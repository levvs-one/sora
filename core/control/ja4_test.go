package control

import (
	"context"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
)

func ja4TestPlan(fps ...string) *engine.Plan {
	p := &engine.Plan{}
	for _, fp := range fps {
		p.Outbounds = append(p.Outbounds, engine.Outbound{
			ID:   "o-" + fp,
			TLS:  engine.TLS{Fingerprint: fp},
			Name: fp,
		})
	}
	return p
}

// fakeAssess pretends the core measured: chrome is fresh, the stale
// parrot and the PQ-less hello are not, and bogus names resolve to
// nothing (JA4 == "" — no claim).
func fakeAssess(_ context.Context, in diagnostics.JA4Input) diagnostics.JA4Report {
	switch in.Fingerprint {
	case "chrome":
		return diagnostics.JA4Report{Fingerprint: "chrome", JA4: "t13d1517h2_ok", Fresh: true, Detail: "fresh"}
	case "hellochrome_133":
		return diagnostics.JA4Report{Fingerprint: "hellochrome_133", JA4: "t13d1516h2_stale", Detail: "stale fingerprint: Chrome 133 parrot, reported blocked by TSPU"}
	case "firefox-old":
		return diagnostics.JA4Report{Fingerprint: "firefox-old", JA4: "t13d9999h2_nopq", Detail: "no PQ key share"}
	default:
		return diagnostics.JA4Report{Fingerprint: in.Fingerprint, Detail: "unknown fingerprint"}
	}
}

func TestJA4FreshnessNotices(t *testing.T) {
	ctx := context.Background()
	got := ja4FreshnessNoticesWith(ctx, ja4TestPlan("chrome", "hellochrome_133", "firefox-old", "hellochrome_133"), fakeAssess)
	if len(got) != 2 {
		t.Fatalf("notices = %q, want 2 (the duplicate stale parrot must not repeat)", got)
	}
	if !strings.Contains(got[0], "fingerprint check: stale fingerprint") {
		t.Errorf("notice[0] = %q", got[0])
	}
	if !strings.Contains(got[1], "fingerprint check: no PQ key share") {
		t.Errorf("notice[1] = %q", got[1])
	}
}

func TestJA4FreshnessNoticesSilent(t *testing.T) {
	ctx := context.Background()
	// Nothing pinned: nothing to assess.
	if got := ja4FreshnessNoticesWith(ctx, ja4TestPlan(), fakeAssess); len(got) != 0 {
		t.Errorf("empty plan: notices = %q, want none", got)
	}
	// Fresh pins and unresolvable names stay silent: no measurement,
	// no claim.
	if got := ja4FreshnessNoticesWith(ctx, ja4TestPlan("chrome", "bogus-parrot"), fakeAssess); len(got) != 0 {
		t.Errorf("fresh/unknown: notices = %q, want none", got)
	}
}
