package probe

import (
	"bufio"
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"math/big"
	"net"
	"strings"
	"testing"
	"time"
)

// webLikeServer behaves like a minimal nginx: answers complete requests,
// waits on truncated ones, rejects overbuffers with 414.
func webLikeServer(t *testing.T, ln net.Listener) {
	t.Helper()
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			go func(c net.Conn) {
				defer c.Close()
				c.SetReadDeadline(time.Now().Add(10 * time.Second))
				r := bufio.NewReader(c)
				var b strings.Builder
				for {
					line, err := r.ReadString('\n')
					b.WriteString(line)
					if err != nil {
						return // client went away: wait, don't answer
					}
					if strings.Contains(b.String(), "\r\n\r\n") {
						c.Write([]byte("HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok"))
						return
					}
					if b.Len() > 64*1024 {
						c.Write([]byte("HTTP/1.1 414 URI Too Long\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"))
						return
					}
				}
			}(c)
		}
	}()
}

// proxyLikeServer is a trojan server without fallback: it drops any
// non-trojan connection without an HTTP response.
func proxyLikeServer(t *testing.T, ln net.Listener) {
	t.Helper()
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			go func(c net.Conn) {
				defer c.Close()
				c.SetReadDeadline(time.Now().Add(2 * time.Second))
				buf := make([]byte, 1024)
				c.Read(buf) // read (or time out), then die silently
			}(c)
		}
	}()
}

func testCert(t *testing.T) tls.Certificate {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "localhost"},
		DNSNames:     []string{"localhost"},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(time.Hour),
	}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, key.Public(), key)
	if err != nil {
		t.Fatal(err)
	}
	cert, err := tls.X509KeyPair(
		pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}),
		pem.EncodeToMemory(&pem.Block{Type: "EC PRIVATE KEY", Bytes: mustMarshalEC(key, t)}),
	)
	if err != nil {
		t.Fatal(err)
	}
	return cert
}

func mustMarshalEC(key *ecdsa.PrivateKey, t *testing.T) []byte {
	t.Helper()
	b, err := x509.MarshalECPrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func TestProbeTrojanFallbackWebLike(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	webLikeServer(t, ln)

	// The plaintext probes run directly: a full ProbeTrojanFallback would
	// also fire the TLS probes, which hang on their timeout against a
	// non-TLS port (correct behavior, but 16 wasted seconds in unit tests).
	// TLS-vs-web-like is covered by TestProbeTrojanFallbackTLS.
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	target := ln.Addr().String()
	for _, p := range []func(context.Context, string) TrojanProbeResult{
		probeH1Close, probeH1Incomplete, probeOverbufferIncomplete,
	} {
		r := p(ctx, target)
		t.Logf("%s: pass=%v detail=%s", r.Class, r.Pass, r.Detail)
		if !r.Pass {
			t.Errorf("%s should pass against a web-like server: %s", r.Class, r.Detail)
		}
	}
}

func TestProbeTrojanFallbackProxyLike(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	proxyLikeServer(t, ln)

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	rep, err := ProbeTrojanFallback(ctx, ln.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	if rep.OK {
		t.Error("proxy-like server must not pass the self-test")
	}
	// h1-close is the sharpest discriminator: no HTTP response at all.
	if rep.Results[TrojanProbeH1Close].Pass {
		t.Errorf("h1-close passed against a proxy-like server: %s", rep.Results[TrojanProbeH1Close].Detail)
	}
	if !strings.Contains(rep.Summary, "h1-close") {
		t.Errorf("summary should name the failed class: %q", rep.Summary)
	}
}

func TestProbeTrojanFallbackTLS(t *testing.T) {
	cert := testCert(t)
	ln, err := tls.Listen("tcp", "127.0.0.1:0", &tls.Config{Certificates: []tls.Certificate{cert}})
	if err != nil {
		t.Fatal(err)
	}
	defer ln.Close()
	webLikeServer(t, ln)

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	rep, err := ProbeTrojanFallback(ctx, ln.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	for _, class := range []TrojanProbeClass{TrojanProbeH1ALPNH2, TrojanProbeShortALPNH2} {
		r := rep.Results[class]
		if !r.Pass {
			t.Errorf("%s should pass against a TLS web-like server: %s", class, r.Detail)
		}
	}
}

func TestProbeTrojanFallbackInvalidTarget(t *testing.T) {
	if _, err := ProbeTrojanFallback(context.Background(), "not-a-target"); err == nil {
		t.Error("invalid target must fail")
	}
	if _, err := ProbeTrojanFallback(nil, "127.0.0.1:1"); err != nil {
		t.Errorf("nil ctx must default to Background, got %v", err)
	}
}

func TestTrojanProbeClassString(t *testing.T) {
	for c, want := range map[TrojanProbeClass]string{
		TrojanProbeH1Close: "h1-close", TrojanProbeH1Incomplete: "h1-incomplete",
		TrojanProbeOverbufferIncomplete: "overbuffer-incomplete",
		TrojanProbeH1ALPNH2:             "h1-alpn-h2",
		TrojanProbeShortALPNH2:          "short-alpn-h2",
	} {
		if c.String() != want {
			t.Errorf("class %d string = %q, want %q", int(c), c.String(), want)
		}
	}
}
