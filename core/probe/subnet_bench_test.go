package probe

import (
	"fmt"
	"net/netip"
	"testing"
)

// BenchmarkSubnetObserveSteady measures Observe with a populated tracker:
// 500 subnets x 8 IPs of history — the shape a large subscription's probe
// rounds produce.
func BenchmarkSubnetObserveSteady(b *testing.B) {
	r := NewSubnetReputation()
	var addrs []netip.Addr
	for s := 0; s < 500; s++ {
		for i := 0; i < 8; i++ {
			a := netip.MustParseAddr(fmt.Sprintf("203.%d.%d.%d", s/256, s%256, i+1))
			addrs = append(addrs, a)
			r.Observe(a, i%3 != 0)
		}
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		r.Observe(addrs[i%len(addrs)], i%4 != 0)
	}
}
