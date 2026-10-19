package obfs

import (
	"encoding/binary"
	"strings"
	"testing"
)

func TestRewriteClientHelloSNI(t *testing.T) {
	for _, fake := range []string{"decoy.test", "much-longer-decoy-name.example.org", "x.io"} {
		rec := testClientHelloRecord(t, "example.com", true)
		out, err := RewriteClientHelloSNI(rec, fake)
		if err != nil {
			t.Fatalf("fake %q: %v", fake, err)
		}
		if got := testRecordSNI(t, out); got != fake {
			t.Fatalf("fake %q: SNI after rewrite = %q", fake, got)
		}
		// The record must still parse as exactly one well-formed record,
		// and the trailing supported_versions extension must be intact.
		recs, err := parseTLSRecords(out)
		if err != nil || len(recs) != 1 {
			t.Fatalf("fake %q: rewritten record does not parse: %v", fake, err)
		}
		if !strings.HasSuffix(string(out), string([]byte{0x00, 0x2b, 0x00, 0x03, 0x02, 0x03, 0x04})) {
			t.Fatalf("fake %q: trailing extension corrupted", fake)
		}
		// All enclosing lengths consistent.
		if n := int(binary.BigEndian.Uint16(out[3:5])); n+recordHeaderLen != len(out) {
			t.Fatalf("fake %q: record length prefix wrong", fake)
		}
		body := out[recordHeaderLen+4:]
		if _, _, _, err := findServerNameExt(body); err != nil {
			t.Fatalf("fake %q: extensions no longer parse: %v", fake, err)
		}
	}
}

func TestRewriteClientHelloSNI_IdempotentName(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", false)
	out, err := RewriteClientHelloSNI(rec, "example.com")
	if err != nil {
		t.Fatalf("RewriteClientHelloSNI: %v", err)
	}
	if got := testRecordSNI(t, out); got != "example.com" {
		t.Fatalf("SNI = %q", got)
	}
}

func TestRewriteClientHelloSNI_Errors(t *testing.T) {
	rec := testClientHelloRecord(t, "example.com", false)
	cases := []struct {
		name   string
		record []byte
		fake   string
	}{
		{"bad fake hostname", rec, "-nope.example"},
		{"empty fake hostname", rec, ""},
		{"no SNI extension", testClientHelloRecordNoSNI(t), "decoy.test"},
		{"truncated", rec[:20], "decoy.test"},
		{"not a handshake", append([]byte{21, 3, 1, 0, 5}, 1, 2, 3, 4, 5), "decoy.test"},
		{"two records", append(append([]byte(nil), rec...), rec...), "decoy.test"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := RewriteClientHelloSNI(tc.record, tc.fake); err == nil {
				t.Fatal("expected error, got nil")
			}
		})
	}
}
