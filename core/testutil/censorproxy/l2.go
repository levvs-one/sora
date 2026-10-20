package censorproxy

import (
	"context"
	"fmt"
	"strings"

	"github.com/levvs-one/sora-client/core/diagnostics"
)

// findClientHello scans outbound payloads for a TLS handshake record
// carrying a ClientHello and returns the payload from the start of that
// record. The returned bytes are in TLS-record form, exactly what
// diagnostics.AssessJA4 expects from its Hello capture hook, so the JA4
// computation below reuses core/diagnostics instead of duplicating it.
func findClientHello(f *Flow) ([]byte, bool) {
	for _, p := range f.Packets {
		if p.Dir != Outbound || len(p.Payload) < 6 {
			continue
		}
		b := p.Payload
		// 0x16 = handshake record, 0x03 = TLS 1.x, b[5] = handshake type 1
		// (ClientHello).
		if b[0] != 0x16 || b[1] != 0x03 || b[5] != 0x01 {
			continue
		}
		ln := int(b[3])<<8 | int(b[4])
		if 5+ln > len(b) {
			continue // truncated record; keep scanning
		}
		return b, true
	}
	return nil, false
}

// ja4Freshness extracts the ClientHello from the flow and assesses it via
// core/diagnostics.AssessJA4 (the same code that judges the engine's own
// fingerprint — no duplication). Score mapping is coupled to the wording of
// diagnostics.JA4Report.Detail; the behavior is pinned by tests.
func ja4Freshness(f *Flow, cfg Config) DetectorResult {
	const name = "ja4-freshness"
	raw, ok := findClientHello(f)
	if !ok {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "ClientHello не наблюдался в потоке — JA4 не вычислен"}
	}
	profile := cfg.Profile
	if profile == "" {
		profile = "chrome"
	}
	rep := diagnostics.AssessJA4(context.Background(), diagnostics.JA4Input{
		Fingerprint: profile,
		ServerName:  cfg.DestHost,
		Hello: func(context.Context) ([]byte, error) {
			return raw, nil
		},
	})
	if rep.JA4 == "" {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "JA4 не вычислен: " + rep.Detail}
	}
	base := fmt.Sprintf("JA4 %s: %s", rep.JA4, rep.Detail)
	switch {
	case rep.Fresh:
		return DetectorResult{Name: name, Score: 0, Explain: base + " — свежий отпечаток"}
	case strings.Contains(rep.Detail, "stale fingerprint"):
		return DetectorResult{Name: name, Score: 1.0, Explain: base + " — отпечаток из стоп-листа устаревших"}
	case strings.Contains(rep.Detail, "no X25519MLKEM768"):
		return DetectorResult{Name: name, Score: 0.7, Explain: base + " — нет PQ key share, противоречие современному браузеру"}
	default:
		return DetectorResult{Name: name, Score: 0.35, Explain: base + " — неизвестный отпечаток, разбор вручную"}
	}
}

// extractSNI parses the SNI hostname out of TLS-record bytes holding a
// ClientHello. Minimal parser: record -> handshake -> ClientHello body ->
// extensions -> server_name (0). Only what the SNI-consistency detector
// needs; JA4 hashing itself stays in core/diagnostics.
func extractSNI(raw []byte) (string, bool) {
	if len(raw) < 5 || raw[0] != 0x16 {
		return "", false
	}
	ln := int(raw[3])<<8 | int(raw[4])
	if len(raw) < 5+ln {
		return "", false
	}
	rec := raw[5 : 5+ln]
	if len(rec) < 4 || rec[0] != 1 { // handshake type ClientHello
		return "", false
	}
	hlen := int(rec[1])<<16 | int(rec[2])<<8 | int(rec[3])
	if len(rec) < 4+hlen {
		return "", false
	}
	b := rec[4 : 4+hlen]
	off := 0
	take := func(n int) ([]byte, bool) {
		if off+n > len(b) {
			return nil, false
		}
		s := b[off : off+n]
		off += n
		return s, true
	}
	if _, ok := take(2); !ok { // legacy_version
		return "", false
	}
	if _, ok := take(32); !ok { // random
		return "", false
	}
	l, ok := take(1) // session_id
	if !ok {
		return "", false
	}
	if _, ok := take(int(l[0])); !ok {
		return "", false
	}
	l, ok = take(2) // cipher_suites
	if !ok {
		return "", false
	}
	csLen := int(l[0])<<8 | int(l[1])
	if _, ok := take(csLen); !ok {
		return "", false
	}
	l, ok = take(1) // compression_methods
	if !ok {
		return "", false
	}
	if _, ok := take(int(l[0])); !ok {
		return "", false
	}
	l, ok = take(2) // extensions length
	if !ok {
		return "", false
	}
	exts, ok := take(int(l[0])<<8 | int(l[1]))
	if !ok {
		return "", false
	}
	for len(exts) >= 4 {
		typ := int(exts[0])<<8 | int(exts[1])
		el := int(exts[2])<<8 | int(exts[3])
		if len(exts) < 4+el {
			return "", false
		}
		data := exts[4 : 4+el]
		if typ == 0 { // server_name
			if len(data) < 2 {
				return "", false
			}
			ll := int(data[0])<<8 | int(data[1])
			if len(data) < 2+ll {
				return "", false
			}
			list := data[2 : 2+ll]
			for len(list) >= 3 {
				if list[0] == 0 { // host_name
					nl := int(list[1])<<8 | int(list[2])
					if len(list) < 3+nl {
						return "", false
					}
					return string(list[3 : 3+nl]), true
				}
				nl := int(list[1])<<8 | int(list[2])
				if len(list) < 3+nl {
					return "", false
				}
				list = list[3+nl:]
			}
			return "", false
		}
		exts = exts[4+el:]
	}
	return "", false
}

func normalizeHost(h string) string {
	return strings.ToLower(strings.TrimSuffix(strings.TrimSpace(h), "."))
}

// sniConsistency checks that the SNI sent in the ClientHello matches the
// intended destination host. A mismatch (SNI fronting leftovers, wrong
// config) is exactly what a censor's SNI filter keys on.
func sniConsistency(f *Flow, cfg Config) DetectorResult {
	const name = "sni-consistency"
	raw, ok := findClientHello(f)
	if !ok {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "ClientHello не наблюдался в потоке — SNI не проверен"}
	}
	if normalizeHost(cfg.DestHost) == "" {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "эталонный хост не задан — SNI не с чем сверять"}
	}
	sni, ok := extractSNI(raw)
	if !ok {
		return DetectorResult{Name: name, Score: 0.5,
			Explain: "ClientHello без SNI — censor видит IP без имени хоста"}
	}
	if normalizeHost(sni) == normalizeHost(cfg.DestHost) {
		return DetectorResult{Name: name, Score: 0,
			Explain: fmt.Sprintf("SNI %q совпадает с Host %q", sni, cfg.DestHost)}
	}
	return DetectorResult{Name: name, Score: 1.0,
		Explain: fmt.Sprintf("SNI %q не совпадает с Host %q — рассинхрон, видимый SNI-фильтру", sni, cfg.DestHost)}
}
