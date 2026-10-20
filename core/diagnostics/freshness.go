package diagnostics

import (
	"context"
	"time"

	utls "github.com/refraction-networking/utls"

	"github.com/levvs-one/sora-client/core/engine"
)

// Freshness by fact (CENSOR-FP, strengthened mandate): which parrots
// the LINKED uTLS can actually render is measured by capturing each
// constructible ClientHelloID — never read off a version string or a
// doc. The set below is every Chrome parrot the linked library
// exports today; when a uTLS bump adds a newer one, Auto moves with
// it (HelloChrome_Auto is an alias in the library), the Auto capture
// stops matching engine.ReferenceChromeJA4, and
// TestParrotFreshnessByFact fires — staleness caught by a test, not
// by a user behind a censor (T056).
//
// A parrot that does not exist yet (HelloChrome_156 at the time of
// writing) has no constructible ID in the library, so there is
// nothing to probe: its absence IS the measured fact, recorded by
// the capture table containing no newer Chrome JA4 than the
// reference.

// ParrotFact is one measured profile: the name diagnostics asked for
// and the byte facts of the hello the linked uTLS actually sent.
type ParrotFact struct {
	Name  string
	Facts HelloFacts
}

// ParrotFacts is the measured parrot table of the installed build.
type ParrotFacts struct {
	Profiles []ParrotFact
	// AutoJA4 is the measured JA4 of HelloChrome_Auto.
	AutoJA4 string
	// AutoIs names the enumerated profile whose JA4 equals Auto's —
	// the Auto parrot's identity by measurement ("" when none match,
	// e.g. Auto moved to a parrot this build does not enumerate).
	AutoIs string
	// AutoMatchesReference: Auto's JA4 equals the reviewed browser
	// reference (engine.ReferenceChromeJA4).
	AutoMatchesReference bool
}

// constructibleChrome lists the Chrome ClientHelloIDs the linked
// uTLS exports, oldest to newest.
func constructibleChrome() []struct {
	name string
	id   utls.ClientHelloID
} {
	return []struct {
		name string
		id   utls.ClientHelloID
	}{
		{"HelloChrome_120", utls.HelloChrome_120},
		{"HelloChrome_131", utls.HelloChrome_131},
		{"HelloChrome_133", utls.HelloChrome_133},
		{"HelloChrome_155", utls.HelloChrome_155},
		{"HelloChrome_Auto", utls.HelloChrome_Auto},
	}
}

// EnumerateParrots captures every constructible parrot and returns
// the measured table. serverName/nextProtos shape the hellos the
// same way AssessJA4's canary does.
func EnumerateParrots(ctx context.Context) (ParrotFacts, error) {
	var out ParrotFacts
	ids := constructibleChrome()
	ids = append(ids,
		struct {
			name string
			id   utls.ClientHelloID
		}{"HelloFirefox_Auto", utls.HelloFirefox_Auto},
		struct {
			name string
			id   utls.ClientHelloID
		}{"HelloSafari_Auto", utls.HelloSafari_Auto},
		struct {
			name string
			id   utls.ClientHelloID
		}{"HelloIOS_Auto", utls.HelloIOS_Auto},
	)
	for _, e := range ids {
		raw, err := captureHello(ctx, e.id, ja4CanarySNI, []string{"h2"}, 5*time.Second)
		if err != nil {
			return out, err
		}
		facts, err := AnalyzeHello(raw)
		if err != nil {
			return out, err
		}
		out.Profiles = append(out.Profiles, ParrotFact{Name: e.name, Facts: facts})
		if e.name == "HelloChrome_Auto" {
			out.AutoJA4 = facts.JA4
		}
	}
	for _, p := range out.Profiles {
		if p.Name != "HelloChrome_Auto" && p.Facts.JA4 == out.AutoJA4 {
			out.AutoIs = p.Name
		}
	}
	out.AutoMatchesReference = out.AutoJA4 == engine.ReferenceChromeJA4
	return out, nil
}
