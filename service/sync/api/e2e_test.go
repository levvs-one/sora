package api

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/discovery"
	"github.com/levvs-one/sora-client/sync/pairing"
	syncpkg "github.com/levvs-one/sora-client/sync/sync"
	"github.com/levvs-one/sora-client/sync/transport"
)

// TestDaemonPairingEndToEnd pairs two daemons over the real pairing path:
// QR generation, TCP dial to the pairing port, Noise handshake, token
// confirmation, and the first sync. mDNS is bypassed (the sandbox has no
// multicast); the port comes from the QR as in production.
func TestDaemonPairingEndToEnd(t *testing.T) {
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

	// Seed divergent documents.
	seed := func(d *Daemon, kind, name string, at int64, payload string) {
		t.Helper()
		changed, err := d.store.Put(syncpkg.Document{
			Meta:    syncpkg.Meta{Kind: kind, Name: name, UpdatedAt: at, Hash: syncpkg.HashOf([]byte(payload))},
			Payload: []byte(payload),
			From:    d.identity.ID,
		})
		if err != nil || !changed {
			t.Fatalf("seed %s/%s: %v %v", kind, name, changed, err)
		}
	}
	seed(a, "subscription", "main", 200, "sub-from-a")
	seed(b, "rules", "custom", 300, "rules-from-b")

	qr, _, err := a.StartPairing()
	if err != nil {
		t.Fatal(err)
	}
	inv, err := pairing.Decode(qr)
	if err != nil {
		t.Fatal(err)
	}
	self, err := b.transportSelf()
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	netConn, err := (&net.Dialer{}).DialContext(ctx, "tcp", fmt.Sprintf("127.0.0.1:%d", inv.Port))
	if err != nil {
		t.Fatal(err)
	}
	c, err := transport.Dial(ctx, netConn, inv, self)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer c.Close()
	if _, err := syncpkg.Sync(ctx, c, b.identity.ID, b.store, true); err != nil {
		t.Fatalf("sync: %v", err)
	}
	// Give the responder side a moment to finish its sync and upsert.
	deadline := time.Now().Add(5 * time.Second)
	for {
		peers := a.Peers()
		if len(peers) == 1 && peers[0].ID == b.identity.ID {
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("a did not pair with b: %+v", peers)
		}
		time.Sleep(50 * time.Millisecond)
	}
	// Documents converged on both sides.
	for _, d := range []*Daemon{a, b} {
		sub, ok := d.store.Get("subscription", "main")
		if !ok || string(sub.Payload) != "sub-from-a" {
			t.Fatalf("subscription did not converge on %s", d.identity.ID)
		}
		rules, ok := d.store.Get("rules", "custom")
		if !ok || string(rules.Payload) != "rules-from-b" {
			t.Fatalf("rules did not converge on %s", d.identity.ID)
		}
	}
}

// TestHTTPAPIEndToEnd drives the full contract flow over the HTTP API the
// app uses: POST /v1/pairing/start on A -> POST /v1/pairing/join on B with
// the raw QR string -> GET /v1/peers -> PUT a document on A ->
// POST /v1/peers/{id}/sync on B -> the document arrives on B. Discovery is
// stubbed to loopback (the sandbox has no multicast); the pairing port
// always comes from the QR, the sync port from the (stubbed) record.
func TestHTTPAPIEndToEnd(t *testing.T) {
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

	if err := a.StartSyncListener(); err != nil {
		t.Fatal(err)
	}
	aSyncPort := a.syncListener.Addr().(*net.TCPAddr).Port
	oldResolve := resolveDevice
	resolveDevice = func(ctx context.Context, id string, timeout time.Duration) (discovery.Peer, error) {
		return discovery.Peer{DeviceID: id, Addr: "127.0.0.1", Port: aSyncPort}, nil
	}
	t.Cleanup(func() { resolveDevice = oldResolve })

	aAddr, err := a.ServeHTTP()
	if err != nil {
		t.Fatal(err)
	}
	bAddr, err := b.ServeHTTP()
	if err != nil {
		t.Fatal(err)
	}

	// 1. A opens a pairing session; the QR payload decodes canonically.
	code, raw := doAPI(t, "POST", aAddr, a.token, "/v1/pairing/start", "")
	if code != http.StatusOK {
		t.Fatalf("pairing/start: %d: %s", code, raw)
	}
	var started struct {
		QRPayload string `json:"qr_payload"`
	}
	if err := json.Unmarshal(raw, &started); err != nil {
		t.Fatal(err)
	}
	if _, err := pairing.Decode(started.QRPayload); err != nil {
		t.Fatalf("qr_payload does not decode: %v", err)
	}

	// 2. B joins with the raw QR string.
	joinBody := `{"qr_payload":` + jsonQuote(started.QRPayload) + `}`
	code, raw = doAPI(t, "POST", bAddr, b.token, "/v1/pairing/join", joinBody)
	if code != http.StatusOK {
		t.Fatalf("pairing/join: %d: %s", code, raw)
	}
	var joined struct {
		Peer struct {
			ID string `json:"id"`
		} `json:"peer"`
	}
	if err := json.Unmarshal(raw, &joined); err != nil {
		t.Fatal(err)
	}
	if joined.Peer.ID != a.identity.ID {
		t.Fatalf("joined peer %q, want %q", joined.Peer.ID, a.identity.ID)
	}

	// 3. The daemon is the source of truth about peers.
	code, raw = doAPI(t, "GET", bAddr, b.token, "/v1/peers", "")
	if code != http.StatusOK {
		t.Fatalf("peers: %d: %s", code, raw)
	}
	if !strings.Contains(string(raw), a.identity.ID) {
		t.Fatalf("a missing from b's peers: %s", raw)
	}

	// 4. A publishes a subscription document.
	payload := base64.StdEncoding.EncodeToString([]byte(`{"url":"https://vpn.example/sub"}`))
	putBody := fmt.Sprintf(`{"payload":%q,"updated_at":%d}`, payload, time.Now().UnixMilli())
	code, raw = doAPI(t, "PUT", aAddr, a.token, "/v1/documents/subscription/main", putBody)
	if code != http.StatusOK {
		t.Fatalf("doc put: %d: %s", code, raw)
	}

	// 5. B syncs with A; the document really moves over Noise_XX.
	code, raw = doAPI(t, "POST", bAddr, b.token, "/v1/peers/"+a.identity.ID+"/sync", "")
	if code != http.StatusOK {
		t.Fatalf("peer sync: %d: %s", code, raw)
	}
	var rep struct {
		Pulled []struct {
			Kind string `json:"kind"`
			Name string `json:"name"`
		} `json:"pulled"`
	}
	if err := json.Unmarshal(raw, &rep); err != nil {
		t.Fatal(err)
	}
	if len(rep.Pulled) != 1 || rep.Pulled[0].Kind != "subscription" || rep.Pulled[0].Name != "main" {
		t.Fatalf("bad sync report: %s", raw)
	}

	// 6. The document is readable on B with the exact payload.
	code, raw = doAPI(t, "GET", bAddr, b.token, "/v1/documents/subscription/main", "")
	if code != http.StatusOK {
		t.Fatalf("doc get: %d: %s", code, raw)
	}
	var doc struct {
		Payload string `json:"payload"`
	}
	if err := json.Unmarshal(raw, &doc); err != nil {
		t.Fatal(err)
	}
	if doc.Payload != payload {
		t.Fatal("payload changed in transit")
	}
}

func jsonQuote(s string) string {
	raw, _ := json.Marshal(s)
	return string(raw)
}
