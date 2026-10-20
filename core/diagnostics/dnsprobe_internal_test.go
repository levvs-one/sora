package diagnostics

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"io"
	"math/big"
	"net"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"
	"time"
)

// dnsTestResponse builds a minimal wire-format DNS response for query
// with the given answer addresses, using a compression pointer for the
// answer names like real servers do.
func dnsTestResponse(t *testing.T, query []byte, addrs []string) []byte {
	t.Helper()
	if len(query) < 12 {
		t.Fatal("short query")
	}
	resp := make([]byte, 0, 512)
	resp = append(resp, query[0], query[1]) // ID
	resp = append(resp, 0x81, 0x80)         // QR+RD+RA, rcode 0
	resp = append(resp, 0x00, 0x01)         // QDCOUNT=1
	resp = append(resp, byte(len(addrs)>>8), byte(len(addrs)))
	resp = append(resp, 0x00, 0x00, 0x00, 0x00) // NSCOUNT=ARCOUNT=0
	resp = append(resp, query[12:]...)          // question
	for _, a := range addrs {
		ip := net.ParseIP(a)
		if ip == nil {
			t.Fatalf("bad test IP %q", a)
		}
		resp = append(resp, 0xc0, 0x0c) // name: pointer to the question
		if v4 := ip.To4(); v4 != nil {
			resp = append(resp, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x3c, 0x00, 0x04)
			resp = append(resp, v4...)
		} else {
			resp = append(resp, 0x00, 0x1c, 0x00, 0x01, 0x00, 0x00, 0x00, 0x3c, 0x00, 0x10)
			resp = append(resp, ip.To16()...)
		}
	}
	return resp
}

func TestDNSWireRoundTrip(t *testing.T) {
	q, err := dnsQueryMsg("Example.COM.", 1)
	if err != nil {
		t.Fatal(err)
	}
	resp := dnsTestResponse(t, q, []string{"203.0.113.7", "2001:db8::7"})
	got, err := dnsParseAddrs(resp)
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"203.0.113.7", "2001:db8::7"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestDNSParseErrors(t *testing.T) {
	q, _ := dnsQueryMsg("example.com", 1)
	for name, mutate := range map[string]func([]byte) []byte{
		"short":      func(b []byte) []byte { return b[:5] },
		"not-a-resp": func(b []byte) []byte { c := append([]byte(nil), b...); c[2] &^= 0x80; return c },
		"nxdomain":   func(b []byte) []byte { c := append([]byte(nil), b...); c[3] |= 0x03; return c },
		"truncated":  func(b []byte) []byte { return b[:len(b)-3] },
	} {
		resp := mutate(dnsTestResponse(t, q, []string{"203.0.113.7"}))
		if _, err := dnsParseAddrs(resp); err == nil {
			t.Errorf("%s: expected error, got nil", name)
		}
	}
	// A successful response with no answers is an error for the canary:
	// NXDOMAIN-for-canary is a signal, not an answer.
	empty := dnsTestResponse(t, q, nil)
	if _, err := dnsParseAddrs(empty); err == nil {
		t.Error("empty answer section: expected error, got nil")
	}
}

func TestDohVia(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if ct := r.Header.Get("Content-Type"); ct != "application/dns-message" {
			http.Error(w, "bad content type", http.StatusBadRequest)
			return
		}
		body, err := io.ReadAll(r.Body)
		if err != nil || len(body) < 16 {
			http.Error(w, "bad query", http.StatusBadRequest)
			return
		}
		qtype := int(body[len(body)-4])<<8 | int(body[len(body)-3])
		var addrs []string
		if qtype == 1 {
			addrs = []string{"203.0.113.7"}
		} else {
			addrs = []string{"2001:db8::7"}
		}
		w.Header().Set("Content-Type", "application/dns-message")
		_, _ = w.Write(dnsTestResponse(t, body, addrs))
	}))
	defer srv.Close()

	got, err := dohVia(context.Background(), srv.URL, "example.com")
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"203.0.113.7", "2001:db8::7"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestDohVia_BareAddressBecomesURL(t *testing.T) {
	if got := dohURL("1.1.1.1"); got != "https://1.1.1.1/dns-query" {
		t.Errorf("got %q", got)
	}
	if got := dohURL("https://dns.example/dns-query"); got != "https://dns.example/dns-query" {
		t.Errorf("full URL must pass through, got %q", got)
	}
}

func TestDohVia_HTTPError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		http.Error(w, "boom", http.StatusInternalServerError)
	}))
	defer srv.Close()
	if _, err := dohVia(context.Background(), srv.URL, "example.com"); err == nil {
		t.Error("HTTP 500 must fail the probe")
	}
}

func TestDohVia_RespectsDeadline(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		time.Sleep(2 * time.Second)
	}))
	defer srv.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()
	start := time.Now()
	if _, err := dohVia(ctx, srv.URL, "example.com"); err == nil {
		t.Error("expected timeout error")
	}
	if elapsed := time.Since(start); elapsed > 3*time.Second {
		t.Errorf("DoH probe overran its deadline: %v", elapsed)
	}
}

// dotTestServer starts a minimal DoT server answering every query with
// addrs, and returns its address.
func dotTestServer(t *testing.T, addrs []string) net.Addr {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1),
		Subject:      pkix.Name{CommonName: "dot.test"},
		NotBefore:    time.Now().Add(-time.Hour),
		NotAfter:     time.Now().Add(time.Hour),
		DNSNames:     []string{"dot.test"},
	}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	certPEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der})
	keyDER, err := x509.MarshalPKCS8PrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	keyPEM := pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: keyDER})
	cert, err := tls.X509KeyPair(certPEM, keyPEM)
	if err != nil {
		t.Fatal(err)
	}
	ln, err := tls.Listen("tcp", "127.0.0.1:0", &tls.Config{Certificates: []tls.Certificate{cert}})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = ln.Close() })
	go func() {
		for {
			c, err := ln.Accept()
			if err != nil {
				return
			}
			go func(c net.Conn) {
				defer func() { _ = c.Close() }()
				for {
					var hdr [2]byte
					if _, err := io.ReadFull(c, hdr[:]); err != nil {
						return
					}
					ln := int(hdr[0])<<8 | int(hdr[1])
					q := make([]byte, ln)
					if _, err := io.ReadFull(c, q); err != nil {
						return
					}
					resp := dnsTestResponse(t, q, addrs)
					out := []byte{byte(len(resp) >> 8), byte(len(resp))}
					out = append(out, resp...)
					if _, err := c.Write(out); err != nil {
						return
					}
				}
			}(c)
		}
	}()
	return ln.Addr()
}

func TestDotVia(t *testing.T) {
	addr := dotTestServer(t, []string{"203.0.113.7", "2001:db8::7"})
	got, err := dotVia(context.Background(), addr.String(), "example.com")
	if err != nil {
		t.Fatal(err)
	}
	want := []string{"203.0.113.7", "2001:db8::7"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestDotVia_Refused(t *testing.T) {
	// Bind and close a port so the dial is deterministically refused.
	ln, err := (&net.ListenConfig{}).Listen(context.Background(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	addr := ln.Addr().String()
	_ = ln.Close()
	if _, err := dotVia(context.Background(), addr, "example.com"); err == nil {
		t.Error("refused DoT must fail the probe")
	}
}

func TestProbeTimeout(t *testing.T) {
	if got := probeTimeout(context.Background(), 3*time.Second); got != 3*time.Second {
		t.Errorf("no deadline: got %v", got)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	if got := probeTimeout(ctx, 3*time.Second); got > time.Second || got <= 0 {
		t.Errorf("deadline shrinks timeout: got %v", got)
	}
	expired, cancel2 := context.WithDeadline(context.Background(), time.Now().Add(-time.Second))
	defer cancel2()
	if got := probeTimeout(expired, 3*time.Second); got > 0 {
		t.Errorf("expired context: got %v", got)
	}
}
