package obfs

import (
	crand "crypto/rand"
	"encoding/binary"
	rand "math/rand/v2"
	"net"
	"sync"
	"time"
)

// newJitterRand returns a rand source seeded from crypto/rand, falling back
// to a time-based seed if the OS RNG is unavailable (it never is on the
// platforms Sora targets, but jitter must never break a connection).
func newJitterRand() *rand.Rand {
	var seed [32]byte
	if _, err := crand.Read(seed[:]); err != nil {
		binary.LittleEndian.PutUint64(seed[:8], uint64(time.Now().UnixNano()))
	}
	pcg1, pcg2 := binary.LittleEndian.Uint64(seed[:8]), binary.LittleEndian.Uint64(seed[8:16])
	return rand.New(rand.NewPCG(pcg1, pcg2))
}

// jitterDelay draws a uniform delay in [0, max].
func jitterDelay(rng *rand.Rand, max time.Duration) time.Duration {
	if max <= 0 {
		return 0
	}
	return time.Duration(rng.Int64N(int64(max) + 1))
}

// jitterConn is a net.Conn wrapper that sleeps a random uniform [0, max]
// delay before every Write, spreading handshake packets in time. The
// delay applies to every Write for the connection's lifetime; see
// Profile.Jitter.
type jitterConn struct {
	net.Conn
	max time.Duration
	mu  sync.Mutex // guards rng: net.Conn allows concurrent Writes
	rng *rand.Rand
}

func (c *jitterConn) Write(p []byte) (int, error) {
	c.mu.Lock()
	d := jitterDelay(c.rng, c.max)
	c.mu.Unlock()
	if d > 0 {
		time.Sleep(d)
	}
	return c.Conn.Write(p)
}
