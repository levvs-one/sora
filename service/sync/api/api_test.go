package api

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"
	"time"
)

func testDaemon(t *testing.T) (*Daemon, string, string) {
	t.Helper()
	d, err := New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(d.Shutdown)
	addr, err := d.ServeHTTP()
	if err != nil {
		t.Fatal(err)
	}
	return d, addr, d.token
}

func doAPI(t *testing.T, method, addr, token, path, body string) (int, []byte) {
	t.Helper()
	var rdr io.Reader
	if body != "" {
		rdr = strings.NewReader(body)
	}
	req, err := http.NewRequest(method, "http://"+addr+path, rdr)
	if err != nil {
		t.Fatal(err)
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = resp.Body.Close() }()
	raw, _ := io.ReadAll(resp.Body)
	return resp.StatusCode, raw
}

func TestStatusRequiresToken(t *testing.T) {
	_, addr, token := testDaemon(t)
	if code, _ := doAPI(t, "GET", addr, "", "/v1/status", ""); code != http.StatusUnauthorized {
		t.Fatalf("no token: got %d, want 401", code)
	}
	if code, _ := doAPI(t, "GET", addr, "wrong", "/v1/status", ""); code != http.StatusUnauthorized {
		t.Fatalf("bad token: got %d, want 401", code)
	}
	code, raw := doAPI(t, "GET", addr, token, "/v1/status", "")
	if code != http.StatusOK {
		t.Fatalf("status: got %d", code)
	}
	var st struct {
		DeviceID      string `json:"device_id"`
		DeviceName    string `json:"device_name"`
		PairingActive bool   `json:"pairing_active"`
	}
	if err := json.Unmarshal(raw, &st); err != nil {
		t.Fatal(err)
	}
	if st.DeviceID == "" || st.DeviceName == "" || st.PairingActive {
		t.Fatalf("bad status: %+v", st)
	}
}

func TestDocumentsRoundTrip(t *testing.T) {
	_, addr, token := testDaemon(t)
	payload := base64.StdEncoding.EncodeToString([]byte(`{"url":"https://x"}`))
	body := fmt.Sprintf(`{"payload":%q,"updated_at":123}`, payload)
	code, _ := doAPI(t, "PUT", addr, token, "/v1/documents/subscription/main", body)
	if code != http.StatusOK {
		t.Fatalf("put: got %d", code)
	}
	// Unsafe names are rejected (the mux also cleans ".." out of paths).
	if code, _ := doAPI(t, "PUT", addr, token, "/v1/documents/subscription/a%20b", body); code != http.StatusBadRequest {
		t.Fatalf("unsafe name: got %d, want 400", code)
	}
	code, raw := doAPI(t, "GET", addr, token, "/v1/documents", "")
	if code != http.StatusOK {
		t.Fatalf("list: got %d", code)
	}
	var list struct {
		Docs []struct {
			Kind string `json:"kind"`
			Name string `json:"name"`
		} `json:"docs"`
	}
	if err := json.Unmarshal(raw, &list); err != nil {
		t.Fatal(err)
	}
	if len(list.Docs) != 1 || list.Docs[0].Kind != "subscription" {
		t.Fatalf("bad list: %s", raw)
	}
	code, raw = doAPI(t, "GET", addr, token, "/v1/documents/subscription/main", "")
	if code != http.StatusOK {
		t.Fatalf("get: got %d", code)
	}
	var doc struct {
		Payload string `json:"payload"`
	}
	if err := json.Unmarshal(raw, &doc); err != nil {
		t.Fatal(err)
	}
	if doc.Payload != payload {
		t.Fatal("payload changed")
	}
	if code, _ := doAPI(t, "GET", addr, token, "/v1/documents/nope/nope", ""); code != http.StatusNotFound {
		t.Fatalf("missing doc: got %d, want 404", code)
	}
}

func TestPairingLifecycle(t *testing.T) {
	_, addr, token := testDaemon(t)
	code, raw := doAPI(t, "POST", addr, token, "/v1/pairing/start", "")
	if code != http.StatusOK {
		t.Fatalf("start: got %d: %s", code, raw)
	}
	var started struct {
		QRPayload string `json:"qr_payload"`
		ExpiresAt int64  `json:"expires_at"`
	}
	if err := json.Unmarshal(raw, &started); err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(started.QRPayload, "sora-sync://pair?") {
		t.Fatalf("bad qr payload: %q", started.QRPayload)
	}
	if started.ExpiresAt <= time.Now().Unix() {
		t.Fatal("expiry is not in the future")
	}
	// A second session is rejected while one is open.
	if code, _ := doAPI(t, "POST", addr, token, "/v1/pairing/start", ""); code != http.StatusConflict {
		t.Fatalf("second start: got %d, want 409", code)
	}
	code, raw = doAPI(t, "GET", addr, token, "/v1/status", "")
	if code != http.StatusOK {
		t.Fatalf("status: %d", code)
	}
	var st struct {
		PairingActive bool `json:"pairing_active"`
	}
	_ = json.Unmarshal(raw, &st)
	if !st.PairingActive {
		t.Fatal("status should report the active pairing")
	}
	if code, _ := doAPI(t, "POST", addr, token, "/v1/pairing/stop", ""); code != http.StatusOK {
		t.Fatalf("stop: got %d", code)
	}
	// Stopping an idle daemon is fine.
	if code, _ := doAPI(t, "POST", addr, token, "/v1/pairing/stop", ""); code != http.StatusOK {
		t.Fatalf("second stop: got %d", code)
	}
}

func TestPeersRevoke(t *testing.T) {
	d, addr, token := testDaemon(t)
	if err := d.upsertPeer("peer-1", "Phone", base64.RawURLEncoding.EncodeToString(make([]byte, 32))); err != nil {
		t.Fatal(err)
	}
	code, raw := doAPI(t, "GET", addr, token, "/v1/peers", "")
	if code != http.StatusOK {
		t.Fatalf("peers: got %d", code)
	}
	if !strings.Contains(string(raw), "peer-1") {
		t.Fatalf("peer missing: %s", raw)
	}
	if code, _ := doAPI(t, "DELETE", addr, token, "/v1/peers/peer-1", ""); code != http.StatusOK {
		t.Fatalf("revoke: got %d", code)
	}
	if code, _ := doAPI(t, "DELETE", addr, token, "/v1/peers/peer-1", ""); code != http.StatusNotFound {
		t.Fatalf("second revoke: got %d, want 404", code)
	}
	if code, _ := doAPI(t, "POST", addr, token, "/v1/peers/peer-1/sync", ""); code != http.StatusBadGateway {
		t.Fatalf("sync unknown: got %d, want 502", code)
	}
}
