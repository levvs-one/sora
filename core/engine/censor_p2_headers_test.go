package engine

import (
	"strings"
	"testing"
)

// CENSOR-P2 fix (review §3): Transport.Headers was gated only for the
// transports P2 touched. On grpc and tcp/raw no pinned engine spells a
// generic header set at all, and on h2 only sing-box does — so a plan
// carrying headers there lost them silently (sing-box rejects a
// headers key on its gRPC transport as unknown; mihomo and Xray ignore
// one). The set now either reaches a renderer that spells it or fails
// with a named error, and the error never echoes header keys/values
// (values can carry secrets).

const p2HeaderSecret = "HeaderSecretValue"

func p2Headers() map[string]string {
	return map[string]string{"X-Auth": p2HeaderSecret, "User-Agent": "ua/1.0"}
}

func TestValidateHeadersNeedHTTPTransport(t *testing.T) {
	// No engine carries generic headers on these transports: plan
	// validation refuses the set, naming the transport.
	for _, typ := range []string{"", "tcp", "grpc"} {
		o := p2Outbound(ProtocolTrojan)
		o.Transport = Transport{Type: typ, Headers: p2Headers()}
		err := o.Validate()
		if err == nil {
			t.Errorf("transport %q with headers: Validate = nil, want a headers error", typ)
			continue
		}
		if !strings.Contains(err.Error(), "headers need the ws, httpupgrade, xhttp or h2 transport") {
			t.Errorf("transport %q: Validate = %v, want the named headers error", typ, err)
		}
		name := typ
		if name == "" {
			name = "tcp" // the empty type renders as tcp everywhere
		}
		if !strings.Contains(err.Error(), "\""+name+"\"") {
			t.Errorf("transport %q: Validate = %v, want the transport named", typ, err)
		}
		if strings.Contains(err.Error(), p2HeaderSecret) || strings.Contains(err.Error(), "X-Auth") {
			t.Errorf("transport %q: error leaks header data: %v", typ, err)
		}
	}
	// Empty vs absent: no headers is valid data on every transport.
	for _, typ := range []string{"", "tcp", "grpc", "ws", "httpupgrade", "xhttp", "h2"} {
		o := p2Outbound(ProtocolTrojan)
		o.Transport = Transport{Type: typ}
		if err := o.Validate(); err != nil {
			t.Errorf("transport %q without headers: Validate = %v", typ, err)
		}
		o.Transport.Headers = map[string]string{}
		if err := o.Validate(); err != nil {
			t.Errorf("transport %q with an empty header set: Validate = %v", typ, err)
		}
	}
}

func TestValidateHeadersCarriedTransports(t *testing.T) {
	// Regression: the P2 transports keep accepting the header set at
	// plan level (every renderer spells it there; h2 is sing-box-only
	// and catalog-gated below, not plan-rejected).
	for _, typ := range []string{"ws", "httpupgrade", "xhttp", "h2"} {
		o := p2Outbound(ProtocolTrojan)
		o.Transport = Transport{Type: typ, Path: "/p", Headers: p2Headers()}
		if err := o.Validate(); err != nil {
			t.Errorf("transport %q with headers: Validate = %v, want nil", typ, err)
		}
	}
}

func TestCatalogH2HeadersGate(t *testing.T) {
	mk := func(headers map[string]string) *Plan {
		o := p2Outbound(ProtocolTrojan)
		o.Transport = Transport{Type: "h2", Path: "/h2", Headers: headers}
		return &Plan{SessionID: "p2", Outbounds: []Outbound{o}}
	}
	withHeaders := mk(p2Headers())
	if !withHeaders.RequiredFeatures()[FeatureH2Headers] {
		t.Fatal("h2 plan with headers must require FeatureH2Headers")
	}
	if got := mk(nil); got.RequiredFeatures()[FeatureH2Headers] {
		t.Fatal("h2 plan without headers must not require FeatureH2Headers")
	}
	// sing-box spells h2 headers (probed on lx.22); the other engines
	// report the feature missing instead of receiving the plan.
	if missing := Catalog[KindSingBox].Missing(withHeaders); len(missing) != 0 {
		t.Errorf("sing-box: Missing = %v, want none for h2 headers", missing)
	}
	for _, kind := range []Kind{KindMihomo, KindXray} {
		found := false
		for _, m := range Catalog[kind].Missing(withHeaders) {
			if strings.Contains(m, string(FeatureH2Headers)) {
				found = true
			}
		}
		if !found {
			t.Errorf("%s: Missing = %v, want the h2-headers gate", kind, Catalog[kind].Missing(withHeaders))
		}
	}
	// Without headers there is no gate anywhere.
	for _, kind := range []Kind{KindSingBox, KindMihomo, KindXray} {
		for _, m := range Catalog[kind].Missing(mk(nil)) {
			if strings.Contains(m, string(FeatureH2Headers)) {
				t.Errorf("%s: Missing = %v, unexpected h2-headers gate without headers", kind, Catalog[kind].Missing(mk(nil)))
			}
		}
	}
}
