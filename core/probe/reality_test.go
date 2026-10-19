package probe

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"math/big"
	"net"
	"strings"
	"testing"
	"time"
)

// testPKI builds a CA and a server certificate for host, returning the CA
// (for the roots pool) and the server's tls.Certificate.
func testPKI(t *testing.T, host string) (*x509.Certificate, tls.Certificate) {
	t.Helper()
	caKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	caTpl := &x509.Certificate{
		SerialNumber:          big.NewInt(1),
		Subject:               pkix.Name{CommonName: "test CA"},
		NotBefore:             time.Now().Add(-time.Hour),
		NotAfter:              time.Now().Add(time.Hour),
		IsCA:                  true,
		KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageDigitalSignature,
		BasicConstraintsValid: true,
	}
	caDER, err := x509.CreateCertificate(rand.Reader, caTpl, caTpl, &caKey.PublicKey, caKey)
	if err != nil {
		t.Fatal(err)
	}
	ca, err := x509.ParseCertificate(caDER)
	if err != nil {
		t.Fatal(err)
	}
	srvKey, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	srvTpl := &x509.Certificate{
		SerialNumber: big.NewInt(2),
		Subject:      pkix.Name{CommonName: host},
		DNSNames:     []string{host},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(time.Hour),
		KeyUsage:     x509.KeyUsageDigitalSignature,
		ExtKeyUsage:  []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
	}
	srvDER, err := x509.CreateCertificate(rand.Reader, srvTpl, ca, &srvKey.PublicKey, caKey)
	if err != nil {
		t.Fatal(err)
	}
	return ca, tls.Certificate{
		Certificate: [][]byte{srvDER, caDER},
		PrivateKey:  srvKey,
	}
}

// testTLSServer starts a TLS listener with the given server-side config and
// returns its address. It answers handshakes and then closes.
func testTLSServer(t *testing.T, cert tls.Certificate, cfg *tls.Config) net.Addr {
	t.Helper()
	c := cfg.Clone()
	c.Certificates = []tls.Certificate{cert}
	ln, err := tls.Listen("tcp", "127.0.0.1:0", c)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { ln.Close() })
	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			go func() {
				defer conn.Close()
				_ = conn.(*tls.Conn).Handshake()
			}()
		}
	}()
	return ln.Addr()
}

// localResolve pretends host resolves to 127.0.0.1.
func localResolve(context.Context, string) ([]string, error) {
	return []string{"127.0.0.1"}, nil
}

// dialAddr dials addr (the test server) with the caller's TLS config.
func dialAddr(addr net.Addr) func(context.Context, string, *tls.Config) (*tls.Conn, error) {
	return func(ctx context.Context, _ string, cfg *tls.Config) (*tls.Conn, error) {
		d := &net.Dialer{}
		c, err := d.DialContext(ctx, "tcp", addr.String())
		if err != nil {
			return nil, err
		}
		tc := tls.Client(c, cfg)
		if err := tc.HandshakeContext(ctx); err != nil {
			c.Close()
			return nil, err
		}
		return tc, nil
	}
}

func testRoots(t *testing.T, ca *x509.Certificate) *x509.CertPool {
	t.Helper()
	p := x509.NewCertPool()
	p.AddCert(ca)
	return p
}

func TestCheckDestGood(t *testing.T) {
	ca, cert := testPKI(t, "dest.test")
	addr := testTLSServer(t, cert, &tls.Config{
		NextProtos: []string{"h2"},
		MinVersion: tls.VersionTLS13,
		MaxVersion: tls.VersionTLS13,
	})
	r, err := checkDest(context.Background(), "dest.test", localResolve, dialAddr(addr), testRoots(t, ca))
	if err != nil {
		t.Fatal(err)
	}
	if !r.Passed {
		t.Fatalf("expected clean checklist, got issues %v", r.Issues)
	}
	if r.TLSVersionName != "1.3" || !r.ALPNH2 || !r.X25519 || !r.CertValid {
		t.Fatalf("unexpected report: %+v", r)
	}
	if len(r.CertNames) != 1 || r.CertNames[0] != "dest.test" {
		t.Fatalf("unexpected cert names: %v", r.CertNames)
	}
}

func TestCheckDestNegative(t *testing.T) {
	ca, cert := testPKI(t, "dest.test")
	ctx := context.Background()
	t.Run("TLS 1.2 only is flagged", func(t *testing.T) {
		addr := testTLSServer(t, cert, &tls.Config{MaxVersion: tls.VersionTLS12})
		r, err := checkDest(ctx, "dest.test", localResolve, dialAddr(addr), testRoots(t, ca))
		if err != nil {
			t.Fatal(err)
		}
		if r.Passed || r.TLSVersionName != "1.2" {
			t.Fatalf("expected TLS 1.2 flag, got %+v", r)
		}
	})
	t.Run("missing h2 is flagged", func(t *testing.T) {
		addr := testTLSServer(t, cert, &tls.Config{NextProtos: []string{"http/1.1"}})
		r, err := checkDest(ctx, "dest.test", localResolve, dialAddr(addr), testRoots(t, ca))
		if err != nil {
			t.Fatal(err)
		}
		if r.Passed || r.ALPNH2 {
			t.Fatalf("expected h2 flag, got %+v", r)
		}
	})
	t.Run("no X25519 is flagged", func(t *testing.T) {
		addr := testTLSServer(t, cert, &tls.Config{CurvePreferences: []tls.CurveID{tls.CurveP256}})
		r, err := checkDest(ctx, "dest.test", localResolve, dialAddr(addr), testRoots(t, ca))
		if err != nil {
			t.Fatal(err)
		}
		if r.Passed || r.X25519 {
			t.Fatalf("expected X25519 flag, got %+v", r)
		}
	})
	t.Run("untrusted cert is flagged", func(t *testing.T) {
		addr := testTLSServer(t, cert, &tls.Config{NextProtos: []string{"h2"}})
		r, err := checkDest(ctx, "dest.test", localResolve, dialAddr(addr), nil) // system roots: test CA unknown
		if err != nil {
			t.Fatal(err)
		}
		if r.Passed || r.CertValid {
			t.Fatalf("expected cert flag, got %+v", r)
		}
	})
	t.Run("IP literal is rejected without dialing", func(t *testing.T) {
		dialed := false
		dial := func(context.Context, string, *tls.Config) (*tls.Conn, error) {
			dialed = true
			return nil, nil
		}
		r, err := checkDest(ctx, "127.0.0.1", localResolve, dial, nil)
		if err != nil {
			t.Fatal(err)
		}
		if dialed {
			t.Fatal("IP literal must not be dialed")
		}
		if r.Passed || len(r.Issues) == 0 || !strings.Contains(r.Issues[0], "IP literal") {
			t.Fatalf("expected IP-literal issue, got %+v", r.Issues)
		}
	})
	t.Run("unresolvable dest errors", func(t *testing.T) {
		badResolve := func(context.Context, string) ([]string, error) {
			return nil, &net.DNSError{IsNotFound: true}
		}
		if _, err := checkDest(ctx, "nope.invalid", badResolve, nil, nil); err == nil {
			t.Fatal("expected resolution error")
		}
	})
	t.Run("empty host errors", func(t *testing.T) {
		if _, err := checkDest(ctx, " ", localResolve, nil, nil); err == nil {
			t.Fatal("expected empty-host error")
		}
	})
}

func TestBehindCloudflare(t *testing.T) {
	if !behindCloudflare([]string{"104.16.0.1", "8.8.8.8"}) {
		t.Fatal("104.16.0.1 is a published Cloudflare address")
	}
	if !behindCloudflare([]string{"2a06:98c0::1"}) {
		t.Fatal("2a06:98c0::1 is a published Cloudflare v6 address")
	}
	if behindCloudflare([]string{"8.8.8.8", "1.0.0.127"}) {
		t.Fatal("non-CF addresses must not match")
	}
	if behindCloudflare(nil) {
		t.Fatal("empty input must not match")
	}
}

func TestCheckSNIConsistency(t *testing.T) {
	ctx := context.Background()
	resolve := func(context.Context, string) ([]string, error) {
		return []string{"93.184.216.34"}, nil
	}
	resolved, issues, err := checkSNIConsistency(ctx, "203.0.113.7", "dest.test", resolve)
	if err != nil {
		t.Fatal(err)
	}
	if len(resolved) != 1 || len(issues) != 0 {
		t.Fatalf("expected clean consistency, got %v %v", resolved, issues)
	}
	// Dest pointing at the server itself is flagged.
	self := func(context.Context, string) ([]string, error) {
		return []string{"203.0.113.7"}, nil
	}
	_, issues, err = checkSNIConsistency(ctx, "203.0.113.7", "dest.test", self)
	if err != nil {
		t.Fatal(err)
	}
	if len(issues) == 0 {
		t.Fatal("expected self-pointing dest to be flagged")
	}
}
