package bypass

import "fmt"

// Fake-packet TTL calibration (T015/P30-2).
//
// A TCP fake must die after the censor but before the server: too small
// and it never reaches the censor (the trick silently does nothing); too
// large and it hits the server (RST on badseq overlap, or the server logs
// a junk ClientHello — burning the user's IP reputation).
//
// The naive autottl calibrates "by hops to the censor". That is broken
// against TSPU: it is an L2 transparent bridge in-path — it does not
// decrement TTL and is invisible in traceroute (criticalinfralab,
// 09.2026). There is no hop to find. The realizable semantics is:
//
//	TTL = distance_to_server − delta
//
// Measure to the SERVER (a normal traceroute target), subtract a safety
// margin, and the fake is guaranteed to expire before the server whether
// or not a transparent middlebox sits on the path. The censor, sitting
// in-path on the first hops, still sees it.
//
// Window collapse (P30-3): when the server is close (in-network GGC/CDN
// nodes are 2–4 hops away) there may be no valid TTL at all —
// distance−delta < 2 means "after the censor but before the server" is
// empty. FakeTTL reports that honestly so the caller falls back to
// split/disorder instead of shipping a fake that either does nothing or
// hits the server.

const (
	// DefaultTTLDelta is the safety margin subtracted from the measured
	// distance: anycast wobble and route flutter move the server by a hop
	// or two, and a fake that survives to the server is worse than no
	// fake at all.
	DefaultTTLDelta = 2
	// minFakeTTL is the smallest usable fake TTL. 1 dies at the first
	// hop — past the censor only if the censor is the default gateway,
	// which must not be assumed.
	minFakeTTL = 2
	// maxFakeTTL caps the result: real paths are far shorter, and an
	// absurd TTL is a sign the input distance was garbage.
	maxFakeTTL = 64
)

// FakeTTL computes the --dpi-desync-ttl for a fake packet from the
// measured hop distance to the server. An unknown or non-positive
// distance is an error, not a guess: without a measurement the caller
// must not use TTL-bound fakes at all. When the window collapses
// (server too close for any valid TTL) it returns ok=false so the
// caller falls back to a non-fake strategy.
//
// NOT WIRED: the tpws arg builder does not call this yet — it is a
// tested primitive waiting for the desync arg generation path (T015).
func FakeTTL(hopsToServer, delta int) (ttl int, ok bool, err error) {
	if hopsToServer <= 0 {
		return 0, false, fmt.Errorf("bypass: cannot calibrate a fake TTL without a measured distance to the server")
	}
	if delta < 0 {
		return 0, false, fmt.Errorf("bypass: negative TTL delta %d", delta)
	}
	ttl = hopsToServer - delta
	if ttl < minFakeTTL {
		// Window collapse: no TTL dies strictly between the censor
		// and the server. Say so instead of shipping ttl=1, which
		// would die before reaching any in-path censor.
		return 0, false, nil
	}
	if ttl > maxFakeTTL {
		ttl = maxFakeTTL
	}
	return ttl, true, nil
}
