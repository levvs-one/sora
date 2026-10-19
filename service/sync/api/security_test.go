package api

import (
	"context"
	"encoding/base64"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/discovery"
)

// TestLanAddrGate pins the anti-spoof dial gate: only loopback, RFC 1918,
// and link-local targets may be dialed. A spoofed mDNS answer pointing at
// a public IP must never cause a TCP connect (the Noise_XX handshake would
// otherwise disclose this device's static key to a remote party).
func TestLanAddrGate(t *testing.T) {
	accept := []string{
		"127.0.0.1", "::1",
		"192.168.1.10", "10.0.0.5", "172.16.4.4", "172.31.255.254",
		"::ffff:192.168.1.10",     // v4-mapped v6 unmaps to private
		"fe80::1", "fe80::1%eth0", // link-local, with zone
		"fc00::1", // unique local
	}
	reject := []string{
		"", "not-an-ip", "1.2.3.4:5678", // garbage / with port
		"8.8.8.8", "93.184.216.34", // public v4
		"::ffff:8.8.8.8",                      // v4-mapped public stays public
		"2001:db8::1", "2606:4700:4700::1111", // public v6
		"172.32.0.1", // just outside 172.16/12
		"100.64.0.1", // CGNAT: not LAN here, refused
		"0.0.0.0", "::",
		"224.0.0.251", "ff02::1", // multicast
	}
	for _, a := range accept {
		if !lanAddr(a) {
			t.Errorf("lanAddr(%q) = false, want true", a)
		}
	}
	for _, a := range reject {
		if lanAddr(a) {
			t.Errorf("lanAddr(%q) = true, want false", a)
		}
	}
}

// TestJoinRejectsSpoofedNonLANAddr drives Join against a spoofed discovery
// answer: the QR is genuine, but mDNS claims the inviter lives on a public
// IP. Join must refuse before dialing.
func TestJoinRejectsSpoofedNonLANAddr(t *testing.T) {
	a, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(a.Shutdown)
	b, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(b.Shutdown)

	qr, _, err := a.StartPairing()
	if err != nil {
		t.Fatal(err)
	}
	for _, spoof := range []string{"8.8.8.8", "::ffff:8.8.8.8"} {
		oldResolve := resolveDevice
		resolveDevice = func(ctx context.Context, id string, timeout time.Duration) (discovery.Peer, error) {
			return discovery.Peer{DeviceID: id, Addr: spoof, Port: 1234}, nil
		}
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		_, err = b.Join(ctx, qr)
		cancel()
		resolveDevice = oldResolve
		if err == nil || !strings.Contains(err.Error(), "outside the LAN") {
			t.Fatalf("spoofed addr %q: Join must refuse, got %v", spoof, err)
		}
	}
}

// TestSyncPeerRejectsSpoofedNonLANAddr is the same gate on the sync path:
// a spoofed mDNS answer for a paired peer must not be dialed either.
func TestSyncPeerRejectsSpoofedNonLANAddr(t *testing.T) {
	d, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(d.Shutdown)
	d.upsertPeer("peer-1", "Phone", base64.RawURLEncoding.EncodeToString(make([]byte, 32)))

	oldResolve := resolveDevice
	resolveDevice = func(ctx context.Context, id string, timeout time.Duration) (discovery.Peer, error) {
		return discovery.Peer{DeviceID: id, Addr: "93.184.216.34", Port: 443}, nil
	}
	t.Cleanup(func() { resolveDevice = oldResolve })

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_, _, err = d.SyncPeer(ctx, "peer-1")
	if err == nil || !strings.Contains(err.Error(), "outside the LAN") {
		t.Fatalf("SyncPeer must refuse a non-LAN peer addr, got %v", err)
	}
}

// TestTokenPersistsAcrossRestarts: the bearer token is long-lived by design
// (no TTL); the app holds it for the install lifetime, so a daemon restart
// must not rotate it behind the app's back.
func TestTokenPersistsAcrossRestarts(t *testing.T) {
	dir := t.TempDir()
	d1, err := New(dir)
	if err != nil {
		t.Fatal(err)
	}
	tok1 := d1.token
	d1.Shutdown()
	d2, err := New(dir)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(d2.Shutdown)
	if d2.token != tok1 {
		t.Fatal("token rotated across restart")
	}
	if len(tok1) != 43 { // 32 bytes base64url, no padding
		t.Fatalf("token has wrong length %d", len(tok1))
	}
	raw, err := base64.RawURLEncoding.DecodeString(tok1)
	if err != nil || len(raw) != 32 {
		t.Fatalf("token is not 32 random bytes: %v", err)
	}
}

// TestAuthHeaderVariants: only the exact "Bearer <token>" form passes.
func TestAuthHeaderVariants(t *testing.T) {
	_, addr, token := testDaemon(t)
	for _, h := range []string{
		"Bearer",                               // no token
		"bearer " + token,                      // wrong scheme case
		"Token " + token,                       // wrong scheme
		"Bearer  " + token,                     // double space
		"Bearer " + token[:len(token)-1] + "x", // one char off
	} {
		req, err := http.NewRequest("GET", "http://"+addr+"/v1/status", nil)
		if err != nil {
			t.Fatal(err)
		}
		req.Header.Set("Authorization", h)
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			t.Fatal(err)
		}
		resp.Body.Close()
		if resp.StatusCode != http.StatusUnauthorized {
			t.Errorf("header %q: got %d, want 401", h, resp.StatusCode)
		}
	}
	// Trailing OWS is stripped by the HTTP layer itself (RFC 7230), so
	// "Bearer <token> " authenticates. That is standard header parsing,
	// not a hole in the token check: the compared value is exact.
	req, err := http.NewRequest("GET", "http://"+addr+"/v1/status", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Authorization", "Bearer "+token+" ")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Errorf("trailing OWS: got %d, want 200", resp.StatusCode)
	}
}

// TestListenerBindsLoopbackOnly pins the localhost scope of the API.
func TestListenerBindsLoopbackOnly(t *testing.T) {
	_, addr, _ := testDaemon(t)
	if !strings.HasPrefix(addr, "127.0.0.1:") {
		t.Fatalf("API listens on %q, want 127.0.0.1 only", addr)
	}
}
