package ext

import (
	"net"
	"net/url"
	"strings"
	"testing"
)

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
