package api

// Contract pins for the []byte payload representation in the HTTP API:
// the JSON wire form must stay the base64 string clients already use,
// an empty payload must stay "" (never null), and invalid base64 must
// stay a 400.

import (
	"net/http"
	"strings"
	"testing"
)

func TestDocPutGetEmptyPayloadStaysEmptyString(t *testing.T) {
	_, addr, token := testDaemon(t)
	code, _ := doAPI(t, "PUT", addr, token, "/v1/documents/settings/empty", `{"payload":"","updated_at":5}`)
	if code != http.StatusOK {
		t.Fatalf("put empty: got %d", code)
	}
	code, raw := doAPI(t, "GET", addr, token, "/v1/documents/settings/empty", "")
	if code != http.StatusOK {
		t.Fatalf("get empty: got %d", code)
	}
	if !strings.Contains(string(raw), `"payload":""`) {
		t.Fatalf("empty payload must stay \"\", got %s", raw)
	}
}

func TestDocPutRejectsBadBase64(t *testing.T) {
	_, addr, token := testDaemon(t)
	code, _ := doAPI(t, "PUT", addr, token, "/v1/documents/settings/bad", `{"payload":"!!!","updated_at":5}`)
	if code != http.StatusBadRequest {
		t.Fatalf("bad base64: got %d, want 400", code)
	}
}
