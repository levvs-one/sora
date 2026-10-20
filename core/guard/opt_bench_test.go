package guard_test

import (
	"fmt"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
)

// Benchmarks for the kill-switch and ingress nft batch rendering (zone H).
// Guard is the kill switch: these only measure render cost; the fail-closed
// invariants and batch atomicity are covered by the existing tests and must
// not change for speed.

func ingressCfgN(n int) guard.IngressConfig {
	cfg := guard.DefaultIngressConfig()
	cfg.VPNEndpoints = make([]string, 0, n)
	for i := 0; i < n; i++ {
		// Mix of bare IPs and ip:port pairs, v4 and v6.
		if i%2 == 0 {
			cfg.VPNEndpoints = append(cfg.VPNEndpoints, fmt.Sprintf("203.0.113.%d:443", i%250+1))
		} else {
			cfg.VPNEndpoints = append(cfg.VPNEndpoints, fmt.Sprintf("2001:db8::%x", i))
		}
	}
	return cfg
}

func bypassN(n int) []string {
	out := make([]string, 0, n)
	for i := 0; i < n; i++ {
		out = append(out, fmt.Sprintf("10.%d.0.0/16", i%256))
	}
	return out
}

func BenchmarkNftIngressRuleset64(b *testing.B) {
	cfg := ingressCfgN(64)
	bypass := bypassN(8)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, err := guard.NftIngressRuleset(cfg, bypass); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkNftRulesetBypass64(b *testing.B) {
	bypass := bypassN(64)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = guard.NftRuleset(1000, bypass)
	}
}

func BenchmarkNftReplaceDefault(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = guard.NftReplace(1000, nil)
	}
}
