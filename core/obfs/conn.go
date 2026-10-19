package obfs

import (
	"context"
	"crypto/tls"
	"errors"
	"net"
	"time"
)

// fragConn is a net.Conn wrapper that fragments ClientHello records on the
// write path. Non-handshake data and unparseable buffers pass through
// untouched, so the wrapper can sit under any TLS stack (crypto/tls or
// uTLS): both emit the plaintext ClientHello records through Write.
type fragConn struct {
	net.Conn
	sizes   []int
	delay   int64 // guarded by construction; nanoseconds, already clamped
	fakeSNI string
}

func (c *fragConn) Write(p []byte) (int, error) {
	recs, err := parseTLSRecords(p)
	if err != nil || !hasClientHello(recs) {
		return c.Conn.Write(p)
	}
	for _, rec := range recs {
		if isClientHelloRecord(rec) && c.fakeSNI != "" {
			if rewritten, err := RewriteClientHelloSNI(rec, c.fakeSNI); err == nil {
				rec = rewritten
			}
			// If the ClientHello cannot be rewritten we still send it
			// (possibly fragmented): obfuscation must never break the
			// write path.
		}
		var frags [][]byte
		if isClientHelloRecord(rec) && len(c.sizes) > 0 {
			frags, err = SplitClientHello(rec, c.sizes)
			if err != nil {
				frags = [][]byte{rec}
			}
		} else {
			frags = [][]byte{rec}
		}
		if err := writeFrags(c.Conn, frags, c.delay); err != nil {
			return 0, err
		}
	}
	return len(p), nil
}

func hasClientHello(recs [][]byte) bool {
	for _, r := range recs {
		if isClientHelloRecord(r) {
			return true
		}
	}
	return false
}

// writeFrags writes fragments with a fixed nanosecond pause between them.
func writeFrags(conn net.Conn, frags [][]byte, delayNs int64) error {
	for i, f := range frags {
		if i > 0 && delayNs > 0 {
			time.Sleep(time.Duration(delayNs))
		}
		if _, err := conn.Write(f); err != nil {
			return err
		}
	}
	return nil
}

// WrapConn applies the profile's write-path obfuscation to conn:
// FakeSNI rewriting and ClientHello fragmentation first, timing jitter
// around them. The profile is clamped, so extreme delays cannot stall the
// connection. Read paths are never touched.
//
// The returned conn reports n == len(p) from Write once all (possibly
// rewritten and fragmented) bytes hit the underlying connection.
func (p Profile) WrapConn(conn net.Conn) net.Conn {
	p = p.Clamp()
	if conn == nil {
		return nil
	}
	out := conn
	if p.Fragmentation() || p.FakeSNI != "" {
		out = &fragConn{Conn: out, sizes: p.FragSizes, delay: int64(p.FragDelay), fakeSNI: p.FakeSNI}
	}
	if p.Jitter > 0 {
		out = &jitterConn{Conn: out, max: p.Jitter, rng: newJitterRand()}
	}
	return out
}

// DialTLS dials network/address, then applies the profile: the raw
// connection is wrapped with WrapConn, and the TLS layer uses either uTLS
// with the profile fingerprint or plain crypto/tls when the profile
// disables uTLS. The returned connection has not handshaked yet.
//
// FakeSNI rewriting applies inside WrapConn to the ClientHello the TLS
// stack below emits; it only takes effect on handshakes the caller
// initiates through this function.
func (p Profile) DialTLS(ctx context.Context, dial func(ctx context.Context, network, address string) (net.Conn, error), network, address string, base *tls.Config) (net.Conn, error) {
	if dial == nil {
		return nil, errors.New("obfs: nil dial function")
	}
	if base == nil {
		return nil, errors.New("obfs: nil tls.Config")
	}
	// Fail fast on misconfiguration instead of silently downgrading
	// obfuscation (e.g. an unknown fingerprint would otherwise fall back
	// to plain TLS unnoticed).
	if err := p.Validate(); err != nil {
		return nil, err
	}
	raw, err := dial(ctx, network, address)
	if err != nil {
		return nil, err
	}
	wrapped := p.WrapConn(raw)
	if p.UTLSEnabled() {
		uc, err := p.NewUTLSConn(wrapped, p.UTLSConfig(base))
		if err != nil {
			raw.Close()
			return nil, err
		}
		return uc, nil
	}
	return tls.Client(wrapped, base), nil
}
