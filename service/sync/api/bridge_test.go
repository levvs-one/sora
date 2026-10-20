package api

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/discovery"
	"github.com/levvs-one/sora-client/sync/pairing"
)

// pairViaHTTP creates two daemons, starts A's sync listener, stubs LAN
// discovery to loopback, serves both HTTP APIs, and pairs B with A through
// the real HTTP flow (pairing/start -> pairing/join). It returns the
// daemons and their API addresses.
func pairViaHTTP(t *testing.T) (a, b *Daemon, aAddr, bAddr string) {
	t.Helper()
	var err error
	a, err = New(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(a.Shutdown)
	b, err = New(t.TempDir())
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

	aAddr, err = a.ServeHTTP()
	if err != nil {
		t.Fatal(err)
	}
	bAddr, err = b.ServeHTTP()
	if err != nil {
		t.Fatal(err)
	}

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
	joinBody := `{"qr_payload":` + jsonQuote(started.QRPayload) + `}`
	code, raw = doAPI(t, "POST", bAddr, b.token, "/v1/pairing/join", joinBody)
	if code != http.StatusOK {
		t.Fatalf("pairing/join: %d: %s", code, raw)
	}
	return a, b, aAddr, bAddr
}

// contractDoc is one F9-SYNC-CONTRACT.md §4 document kind with a payload
// shaped like the app really publishes it.
type contractDoc struct {
	kind, name, payload string
}

var contractDocs = []contractDoc{
	{"subscriptions", "list", `{"v":1,"items":[{"name":"Main","url":"https://vpn.example/sub","auto_update":true,"user_agent":"","update_interval_seconds":0}]}`},
	{"app_settings", "main", `{"theme":{"t":"s","v":"dark"},"killSwitch":{"t":"b","v":true}}`},
	{"overrides", "main", `{"s1":{"renames":{},"hidden":[]}}`},
	{"profiles", "main", `[]`},
	{"chains", "main", `[]`},
	{"obfs", "main", `{"preset":"off","utls":"","fragment":false,"jitter":false}`},
}

// TestDocumentKindsEndToEnd is the document-bridge contract test: A
// publishes one document per contract §4 kind, B syncs, and every document
// arrives byte-identical with kind/name/from/updated_at in the report.
func TestDocumentKindsEndToEnd(t *testing.T) {
	a, b, aAddr, bAddr := pairViaHTTP(t)

	for _, doc := range contractDocs {
		b64 := base64.StdEncoding.EncodeToString([]byte(doc.payload))
		body := fmt.Sprintf(`{"payload":%q,"updated_at":%d}`, b64, time.Now().UnixMilli())
		code, raw := doAPI(t, "PUT", aAddr, a.token, "/v1/documents/"+doc.kind+"/"+doc.name, body)
		if code != http.StatusOK {
			t.Fatalf("doc put %s/%s: %d: %s", doc.kind, doc.name, code, raw)
		}
	}

	code, raw := doAPI(t, "POST", bAddr, b.token, "/v1/peers/"+a.identity.ID+"/sync", "")
	if code != http.StatusOK {
		t.Fatalf("peer sync: %d: %s", code, raw)
	}
	var rep struct {
		Pulled []struct {
			Kind      string `json:"kind"`
			Name      string `json:"name"`
			From      string `json:"from"`
			UpdatedAt int64  `json:"updated_at"`
		} `json:"pulled"`
		Pushed []struct {
			Kind string `json:"kind"`
			Name string `json:"name"`
		} `json:"pushed"`
	}
	if err := json.Unmarshal(raw, &rep); err != nil {
		t.Fatal(err)
	}
	if len(rep.Pulled) != len(contractDocs) {
		t.Fatalf("pulled %d docs, want %d: %s", len(rep.Pulled), len(contractDocs), raw)
	}
	if len(rep.Pushed) != 0 {
		t.Fatalf("b pushed %d docs, want 0 (a published everything)", len(rep.Pushed))
	}
	want := map[string]string{}
	for _, doc := range contractDocs {
		want[doc.kind+"/"+doc.name] = doc.payload
	}
	for _, m := range rep.Pulled {
		if m.From != a.identity.ID {
			t.Errorf("pulled %s/%s: from=%q, want %q", m.Kind, m.Name, m.From, a.identity.ID)
		}
		if m.UpdatedAt <= 0 {
			t.Errorf("pulled %s/%s: bad updated_at %d", m.Kind, m.Name, m.UpdatedAt)
		}
		wantPayload, ok := want[m.Kind+"/"+m.Name]
		if !ok {
			t.Errorf("pulled unexpected %s/%s", m.Kind, m.Name)
			continue
		}
		delete(want, m.Kind+"/"+m.Name)
		code, raw := doAPI(t, "GET", bAddr, b.token, "/v1/documents/"+m.Kind+"/"+m.Name, "")
		if code != http.StatusOK {
			t.Errorf("doc get %s/%s: %d: %s", m.Kind, m.Name, code, raw)
			continue
		}
		var got struct {
			Payload string `json:"payload"`
			From    string `json:"from"`
		}
		if err := json.Unmarshal(raw, &got); err != nil {
			t.Errorf("doc get %s/%s: %v", m.Kind, m.Name, err)
			continue
		}
		decoded, err := base64.StdEncoding.DecodeString(got.Payload)
		if err != nil {
			t.Errorf("doc get %s/%s: bad payload: %v", m.Kind, m.Name, err)
			continue
		}
		if string(decoded) != wantPayload {
			t.Errorf("doc %s/%s changed in transit", m.Kind, m.Name)
		}
		if got.From != a.identity.ID {
			t.Errorf("doc %s/%s: from=%q, want %q", m.Kind, m.Name, got.From, a.identity.ID)
		}
	}
	for missing := range want {
		t.Errorf("missing pulled doc %s", missing)
	}

	// A second sync moves nothing: everything already converged.
	code, raw = doAPI(t, "POST", bAddr, b.token, "/v1/peers/"+a.identity.ID+"/sync", "")
	if code != http.StatusOK {
		t.Fatalf("second peer sync: %d: %s", code, raw)
	}
	var rep2 struct {
		Pulled []any `json:"pulled"`
		Pushed []any `json:"pushed"`
	}
	if err := json.Unmarshal(raw, &rep2); err != nil {
		t.Fatal(err)
	}
	if len(rep2.Pulled) != 0 || len(rep2.Pushed) != 0 {
		t.Fatalf("second sync moved docs: pulled=%d pushed=%d", len(rep2.Pulled), len(rep2.Pushed))
	}
}

// TestDocPutRejects pins the document endpoint's guards: unsafe names,
// bad base64, bad JSON and unknown documents are rejected honestly.
func TestDocPutRejects(t *testing.T) {
	a, _, aAddr, _ := pairViaHTTP(t)

	b64 := base64.StdEncoding.EncodeToString([]byte(`{}`))
	put := func(kind, name, body string) (int, []byte) {
		return doAPI(t, "PUT", aAddr, a.token, "/v1/documents/"+kind+"/"+name, body)
	}
	for _, tc := range []struct{ kind, name string }{
		{"../evil", "x"},
		{"subscriptions", ".."},
	} {
		// Path traversal never reaches the handler: the mux sanitizes `..`
		// before routing, so these are rejected at the router (404/405).
		// The assertion is that nothing is stored.
		if code, raw := put(tc.kind, tc.name, `{"payload":"`+b64+`"}`); code/100 == 2 {
			t.Errorf("put %s/%s: got %d, want rejection: %s", tc.kind, tc.name, code, raw)
		}
	}
	// Unsafe names that DO reach the handler are rejected with 400.
	if code, raw := put("sub scriptions", "x", `{"payload":"`+b64+`"}`); code != http.StatusBadRequest {
		t.Errorf("unsafe kind: got %d, want 400: %s", code, raw)
	}
	if code, raw := put("subscriptions", "a/b", `{"payload":"`+b64+`"}`); code/100 == 2 {
		t.Errorf("slash in name: got %d, want rejection: %s", code, raw)
	}
	if code, raw := put("subscriptions", "list", `{"payload":"!!!not-base64!!!"}`); code != http.StatusBadRequest {
		t.Errorf("bad base64: got %d, want 400: %s", code, raw)
	}
	if code, raw := put("subscriptions", "list", `not json`); code != http.StatusBadRequest {
		t.Errorf("bad JSON: got %d, want 400: %s", code, raw)
	}
	if code, raw := doAPI(t, "GET", aAddr, a.token, "/v1/documents/nope/none", ""); code != http.StatusNotFound {
		t.Errorf("get unknown: got %d, want 404: %s", code, raw)
	}
	// No updated_at: the daemon stamps it.
	if code, raw := put("app_settings", "main", `{"payload":"`+b64+`"}`); code != http.StatusOK {
		t.Fatalf("put without updated_at: %d: %s", code, raw)
	}
	code, raw := doAPI(t, "GET", aAddr, a.token, "/v1/documents/app_settings/main", "")
	if code != http.StatusOK {
		t.Fatalf("doc get: %d: %s", code, raw)
	}
	var got struct {
		UpdatedAt int64 `json:"updated_at"`
	}
	if err := json.Unmarshal(raw, &got); err != nil {
		t.Fatal(err)
	}
	if got.UpdatedAt <= 0 {
		t.Errorf("daemon did not stamp updated_at: %d", got.UpdatedAt)
	}
}
