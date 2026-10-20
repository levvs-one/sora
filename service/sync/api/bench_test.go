package api

// BenchmarkPeersSerialization measures serializing the peer registry —
// the state savePeersLocked persists and what GET /v1/peers returns.

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"testing"
)

// benchPeers builds n paired-device entries.
func benchPeers(n int) map[string]*Peer {
	peers := make(map[string]*Peer, n)
	for i := 0; i < n; i++ {
		var key [32]byte
		for j := range key {
			key[j] = byte(i + j)
		}
		id := fmt.Sprintf("device-%03d", i)
		peers[id] = &Peer{
			ID:          id,
			Name:        fmt.Sprintf("Peer %d", i),
			IdentityKey: base64.RawURLEncoding.EncodeToString(key[:]),
			PairedAt:    1700000000000 + int64(i),
			LastSync:    1700000000000 + int64(i)*1000,
		}
	}
	return peers
}

// BenchmarkPeersSerialization measures Peers() + JSON marshal of a 100-peer
// registry: the hot core of persisting peer state.
func BenchmarkPeersSerialization(b *testing.B) {
	d := &Daemon{peers: benchPeers(100)}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if _, err := json.Marshal(d.Peers()); err != nil {
			b.Fatal(err)
		}
	}
}

// BenchmarkPeersList measures the registry copy alone.
func BenchmarkPeersList(b *testing.B) {
	d := &Daemon{peers: benchPeers(100)}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		if got := len(d.Peers()); got != 100 {
			b.Fatalf("listed %d peers, want 100", got)
		}
	}
}
