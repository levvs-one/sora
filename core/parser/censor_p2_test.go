package parser

import (
	"encoding/base64"
	"errors"
	"testing"
)

// CENSOR-P2: legacy VMess alterId must be refused as unsupported at
// import, never silently upgraded to AEAD.

func TestCensorP2VMessAlterIDLegacyRefused(t *testing.T) {
	for _, doc := range []string{
		`{"v":"2","ps":"legacy","add":"vmess.example.com","port":"443","id":"123e4567-e89b-12d3-a456-426614174000","aid":"64","scy":"auto","net":"ws","tls":"tls"}`,
		`{"v":"2","ps":"legacy","add":"vmess.example.com","port":443,"id":"123e4567-e89b-12d3-a456-426614174000","aid":64,"net":"tcp","tls":""}`,
	} {
		link := "vmess://" + base64.StdEncoding.EncodeToString([]byte(doc))
		if _, err := parseLink(link); !errors.Is(err, ErrUnsupported) {
			t.Fatalf("doc %s: parseLink = %v, want ErrUnsupported", doc, err)
		}
		res, _ := (LinkParser{}).Parse([]byte(link))
		if res.Report.Imported != 0 {
			t.Fatalf("doc %s: imported %d servers, want 0", doc, res.Report.Imported)
		}
	}
	// AEAD (aid 0 / absent) still imports.
	doc0 := `{"v":"2","ps":"aead","add":"vmess.example.com","port":"443","id":"123e4567-e89b-12d3-a456-426614174000","aid":"0","net":"tcp","tls":""}`
	if _, err := parseLink("vmess://" + base64.StdEncoding.EncodeToString([]byte(doc0))); err != nil {
		t.Fatalf("AEAD link refused: %v", err)
	}
	// URL form with ?aid=16.
	if _, err := parseLink("vmess://123e4567-e89b-12d3-a456-426614174000@vmess.example.com:443?aid=16#x"); !errors.Is(err, ErrUnsupported) {
		t.Fatalf("url-form aid = %v, want ErrUnsupported", err)
	}
	// sing-box-shaped JSON document with alter_id.
	if err := checkVMessAlterID(float64(4)); !errors.Is(err, ErrUnsupported) {
		t.Fatalf("checkVMessAlterID(4) = %v", err)
	}
	if err := checkVMessAlterID(nil); err != nil {
		t.Fatalf("checkVMessAlterID(nil) = %v", err)
	}
}
