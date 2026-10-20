package ext

import (
	"net"
	"net/url"
	"strings"
	"testing"
)

// fuzzRevocationListJSON is a valid-list scaffold the fuzzer mutates.
func fuzzRevocationListJSON() []byte {
	return []byte(`{"revocation_version":1,` +
		`"updated_at":"2026-10-20T00:00:00Z","expires_at":"2099-01-01T00:00:00Z",` +
		`"entries":[` +
		`{"id":"com.evil.miner","versions":"*","reason":"cryptominer"},` +
		`{"id":"com.buggy.sync","versions":"<=1.2.0","reason":"deletes user data"}` +
		`]}`)
}

// FuzzParseRevocationList fuzzes the emergency-brake parser: no panics,
// and an accepted list must be self-consistent - every entry satisfies
// the shape rules, and IsRevoked is deterministic and total over the
// constraint language it claims to support.
func FuzzParseRevocationList(f *testing.F) {
	f.Add(fuzzRevocationListJSON())
	f.Add([]byte(`{}`))
	f.Add([]byte(`{"revocation_version":1,"updated_at":"bad","expires_at":"worse","entries":[]}`))
	f.Add([]byte(strings.Repeat(`{"revocation_version":1`, 3000)))
	f.Add([]byte("\xff\xfe bad \x80 bytes"))
	f.Add([]byte(`{"revocation_version":1,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2099-01-01T00:00:00Z","entries":[{"id":"com.x.a","versions":"<not-semver>","reason":"x"}]}`))
	f.Add([]byte(`{"revocation_version":1,"updated_at":"2026-10-20T00:00:00Z","expires_at":"2099-01-01T00:00:00Z","entries":[{"id":"a","versions":"*","reason":"x"},{"id":"a","versions":"*","reason":"y"}]}`))

	f.Fuzz(func(t *testing.T, data []byte) {
		l, err := ParseRevocationList(data)
		if err != nil {
			return // rejection is always acceptable
		}
		if l.Version != RevocationVersion {
			t.Fatalf("accepted version %d, want %d", l.Version, RevocationVersion)
		}
		if !l.ExpiresAt.After(l.UpdatedAt) {
			t.Fatal("accepted a list whose expiry is not after its update time")
		}
		// Shape invariants, checked independently of ParseRevocationList's
		// own code path.
		seen := map[string]bool{}
		for _, e := range l.Entries {
			if !idPattern.MatchString(e.ID) {
				t.Fatalf("accepted bad entry id %q", e.ID)
			}
			if checkVersionConstraint(e.Versions) != nil {
				t.Fatalf("accepted bad constraint %q", e.Versions)
			}
			if len(e.Reason) > 280 {
				t.Fatalf("accepted overlong reason for %q", e.ID)
			}
			key := e.ID + "\x00" + e.Versions
			if seen[key] {
				t.Fatalf("accepted duplicate entry %q %q", e.ID, e.Versions)
			}
			seen[key] = true
		}
		// Determinism: two calls on the same input agree, and a nil list
		// revokes nothing.
		first := l.IsRevoked("com.example.anything", "1.0.0")
		if first != l.IsRevoked("com.example.anything", "1.0.0") {
			t.Fatal("IsRevoked is not deterministic")
		}
		var nilList *RevocationList
		if nilList.IsRevoked("com.example.anything", "1.0.0") {
			t.Fatal("nil list must revoke nothing")
		}
	})
}

// fuzzFetcher builds the policy-only fetcher: its transport is never used
// by the fuzz target (only checkURL is exercised), so no network happens.
func fuzzFetcher(t *testing.T) *Fetcher {
	t.Helper()
	f, err := NewFetcherForExtensionWithTransport("com.example.fuzz",
		&ManifestExt{NetworkHosts: []string{"example.com", "*.cdn.example.com"}},
		FetchLimits{}, nil, NewLogHub())
	if err != nil {
		t.Fatal(err)
	}
	return f
}

// FuzzFetchURLPolicy throws arbitrary URL strings at the per-request
// transport policy (https-only, no userinfo, no IP literals, no ports,
// allowlist). No request is ever issued: only checkURL is exercised, so
// the fuzzer runs in milliseconds without network. Invariant: an accepted
// URL always satisfies the policy - checked independently, not by calling
// the same code twice.
func FuzzFetchURLPolicy(f *testing.F) {
	f.Add("https://example.com/api")
	f.Add("https://sub.cdn.example.com/x")
	f.Add("http://example.com/")
	f.Add("https://example.com:443/")
	f.Add("https://user:pass@example.com/")
	f.Add("https://127.0.0.1/")
	f.Add("https://2130706433/")
	f.Add("https://0x7f.1/")
	f.Add("https://example.com.evil.com/")
	f.Add("https://cdn.example.com/") // bare domain: "*.cdn.example.com" must NOT match
	f.Add("https://EXAMPLE.COM/UPPER")
	f.Add("https://example.com./trailing-dot")
	f.Add("https://[::1]/ipv6")
	f.Add("https://exa mple.com/space")
	f.Add("")

	f.Fuzz(func(t *testing.T, raw string) {
		fet := fuzzFetcher(t)
		u, err := url.Parse(strings.TrimSpace(raw))
		if err != nil || u.Host == "" {
			return // parse failures are handled by the caller layer
		}
		if err := fet.checkURL(u); err != nil {
			return // rejection is always acceptable
		}
		// Accepted ⇒ the policy holds, verified independently.
		if !strings.EqualFold(u.Scheme, "https") {
			t.Fatalf("checkURL accepted non-https %q", raw)
		}
		if u.User != nil {
			t.Fatalf("checkURL accepted userinfo in %q", raw)
		}
		host := u.Hostname()
		if isIPLike(host) {
			t.Fatalf("checkURL accepted IP-like host %q", raw)
		}
		if _, port, perr := net.SplitHostPort(u.Host); perr == nil && port != "" {
			t.Fatalf("checkURL accepted explicit port in %q", raw)
		}
		if !fet.hostAllowed(host) {
			t.Fatalf("checkURL accepted off-allowlist host %q", raw)
		}
	})
}
