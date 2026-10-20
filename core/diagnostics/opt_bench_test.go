package diagnostics_test

import (
	"context"
	"fmt"
	"testing"

	"github.com/levvs-one/sora-client/core/diagnostics"
)

// Benchmarks for the dnsleak classifiers (zone H). JA4 is intentionally not
// benchmarked here: core/diagnostics/ja4.go currently carries another
// agent's uncommitted changes and must not be touched.

func dnsLeakBenchInput(n int) diagnostics.DnsLeakInput {
	resolvers := make([]diagnostics.TunnelResolver, 0, n)
	for i := 0; i < n; i++ {
		resolvers = append(resolvers, diagnostics.TunnelResolver{
			Address:   fmt.Sprintf("10.64.%d.1", i%256),
			Transport: "udp",
		})
	}
	system := make([]string, 0, n)
	for i := 0; i < n; i++ {
		system = append(system, fmt.Sprintf("192.168.%d.1", i%256))
	}
	return diagnostics.DnsLeakInput{
		TunnelResolvers:    resolvers,
		DnsHijacked:        false,
		KillSwitchArmed:    false,
		SystemResolvers:    system,
		SystemEncryptedDNS: []string{},
		Probe: func(ctx context.Context, network, addr, host string) ([]string, error) {
			return []string{"1.1.1.1"}, nil
		},
	}
}

func BenchmarkCheckDnsLeaks16(b *testing.B) {
	in := dnsLeakBenchInput(16)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = diagnostics.CheckDnsLeaks(context.Background(), in)
	}
}
