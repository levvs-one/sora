package diagnostics

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/obfs"
	utls "github.com/refraction-networking/utls"
)

// JA4 assessment of the TLS fingerprint the core emits on handshakes it
// initiates itself (obfs profiles: connectivity probing, DoH, subscription
// fetch).
//
// This is a real check, not a name lookup: it captures the actual
// ClientHello bytes the configured uTLS parrot would send (no network is
// involved — the handshake is run against a recording stand-in and
// aborted after the first flight), parses them, and computes the JA4
// fingerprint exactly as a DPI box would. The result is then judged for
// freshness:
//
//   - a JA4 in the stale set (e.g. the Chrome 133 parrot that
//     engine/fingerprint.go documents as blocked by TSPU) is stale;
//   - a randomized profile must produce distinct JA4 across captures —
//     identical hellos mean the randomization is broken;
//   - a JA4 matching a documented current parrot is fresh.
//
// JA4 reference: FoxIO JA4 spec (t13d1516h2_8daaf6152771_d8a2da3f94cd):
// JA4_a = t<tls-version><sni><cipher-count><ext-count><alpn>,
// JA4_b = sha256 hex[:12] of the cipher suites sorted, GREASE stripped,
// JA4_c = sha256 hex[:12] of the extensions sorted, GREASE stripped, SNI
// (0) and ALPN (16) excluded (both are already represented in JA4_a),
// followed by "_" and the signature algorithms in wire order.
// Sorting (not wire order) is the point: it keeps the fingerprint stable
// across the extension shuffling modern browsers do, which is what broke
// JA3.

// defaultJA4Timeout bounds one ClientHello capture. Captures are local
// and finish in milliseconds; the timeout only guards against a stuck
// handshake goroutine.
const defaultJA4Timeout = 5 * time.Second

// ja4CanarySNI is the SNI presented during capture. It never leaves the
// machine (the handshake runs against a recording stand-in), and the
// .invalid TLD guarantees it can never resolve.
const ja4CanarySNI = "ja4-probe.invalid"

// staleJA4 maps JA4 fingerprints known to be stale or reported blocked to
// the reason. Keep in sync with core/engine/fingerprint.go.
var staleJA4 = map[string]string{
	"t13d1516h2_8daaf6152771_d8a2da3f94cd": "Chrome 133 parrot, reported blocked by TSPU (see engine/fingerprint.go)",
}

// knownGoodJA4 maps JA4 fingerprints of documented current parrots.
var knownGoodJA4 = map[string]string{
	"t13d1517h2_8daaf6152771_cb7bf5808d99": "Chrome 155",
}

// JA4Input configures one JA4 assessment.
type JA4Input struct {
	// Fingerprint is the obfs profile uTLS name: "chrome", "firefox",
	// "safari", "randomized", "none"/"".
	Fingerprint string
	// ServerName is the SNI used for the captured hello; empty selects
	// the canary. The value does not affect the JA4 beyond the SNI
	// presence bit.
	ServerName string
	// NextProtos is the ALPN list for the captured hello; nil selects
	// ["h2"], matching the core's DoH/probe handshakes.
	NextProtos []string
	// Timeout bounds one ClientHello capture; zero selects the default.
	Timeout time.Duration
	// Hello captures one ClientHello the profile would emit; nil selects
	// the real capture. Tests inject fixed or failing captures here.
	Hello func(ctx context.Context) ([]byte, error)
}

// JA4Report is the outcome of one JA4 assessment.
type JA4Report struct {
	// Fingerprint is the normalized profile name.
	Fingerprint string
	// JA4 is the computed fingerprint of the captured hello, "" when
	// nothing was captured.
	JA4 string
	// Fresh reports whether the fingerprint looks current: not in the
	// stale set, offering the X25519MLKEM768 PQ hybrid key share that
	// modern browsers send, and actually varying for randomized profiles.
	Fresh bool
	// Detail carries the verdict basis in plain words.
	Detail string
}

// AssessJA4 captures the ClientHello the configured fingerprint emits,
// computes its JA4, and judges its freshness.
func AssessJA4(ctx context.Context, in JA4Input) JA4Report {
	name := engine.NormalizeFingerprint(in.Fingerprint)
	rep := JA4Report{Fingerprint: name}
	if name == "" || name == "none" {
		rep.Detail = "uTLS fingerprint disabled: the core emits plain TLS, nothing to assess"
		return rep
	}
	id, err := obfs.Profile{UTLS: name}.FingerprintID()
	if err != nil {
		rep.Detail = "unknown fingerprint " + strconv.Quote(in.Fingerprint)
		return rep
	}
	serverName := in.ServerName
	if serverName == "" {
		serverName = ja4CanarySNI
	}
	nextProtos := in.NextProtos
	if nextProtos == nil {
		nextProtos = []string{"h2"}
	}
	timeout := in.Timeout
	if timeout <= 0 {
		timeout = defaultJA4Timeout
	}
	capture := in.Hello
	if capture == nil {
		capture = func(ctx context.Context) ([]byte, error) {
			return captureHello(ctx, id, serverName, nextProtos, timeout)
		}
	}

	if name == obfs.UTLSRandomized {
		return assessRandomized(ctx, rep, capture)
	}
	raw, err := capture(ctx)
	if err != nil {
		rep.Detail = "ClientHello capture failed: " + err.Error()
		return rep
	}
	hello, err := parseCapturedHello(raw)
	if err != nil {
		rep.Detail = "ClientHello parse failed: " + err.Error()
		return rep
	}
	rep.JA4 = ja4Of(hello)
	// A "modern browser" ClientHello without the X25519MLKEM768 hybrid key
	// share contradicts what real Chrome 131+, Firefox 132+ and current
	// Safari send: the overwhelming majority of real browser traffic
	// carries it, so its absence is a distinguisher visible to DPI before
	// any HTTP is exchanged. That is a freshness failure, not a cosmetic
	// note: Fresh stays false and the detail names the contradiction.
	pq := hasPQKeyShare(hello)
	pqNote := "; no PQ key share"
	if pq {
		pqNote = "; offers X25519MLKEM768 PQ key share"
	}
	if reason, stale := staleJA4[rep.JA4]; stale {
		rep.Detail = "stale fingerprint " + rep.JA4 + ": " + reason + pqNote
		return rep
	}
	if what, ok := knownGoodJA4[rep.JA4]; ok {
		rep.Fresh = true
		rep.Detail = "JA4 " + rep.JA4 + " matches documented " + what + ": fresh" + pqNote
		return rep
	}
	rep.Fresh = pq
	if pq {
		rep.Detail = "JA4 " + rep.JA4 + " is not in the stale set (no documented reference for " + strconv.Quote(name) + ")" + pqNote
		return rep
	}
	rep.Detail = "JA4 " + rep.JA4 + " offers no X25519MLKEM768 PQ key share" +
		" (real Chrome 131+, Firefox 132+ and current Safari all send it):" +
		" a detectable contradiction for a modern browser fingerprint"
	return rep
}

// assessRandomized captures several hellos and requires the JA4 to vary:
// a "randomized" profile emitting identical hellos has broken
// randomization and is as fingerprintable as a static one.
func assessRandomized(ctx context.Context, rep JA4Report, capture func(context.Context) ([]byte, error)) JA4Report {
	const rounds = 3
	jas := make([]string, 0, rounds)
	for i := 0; i < rounds; i++ {
		raw, err := capture(ctx)
		if err != nil {
			rep.Detail = fmt.Sprintf("ClientHello capture %d/%d failed: %v", i+1, rounds, err)
			return rep
		}
		hello, err := parseCapturedHello(raw)
		if err != nil {
			rep.Detail = fmt.Sprintf("ClientHello parse %d/%d failed: %v", i+1, rounds, err)
			return rep
		}
		jas = append(jas, ja4Of(hello))
	}
	rep.JA4 = jas[0]
	distinct := map[string]bool{}
	for _, j := range jas {
		distinct[j] = true
	}
	if len(distinct) >= 2 {
		rep.Fresh = true
		rep.Detail = fmt.Sprintf("randomized: %d captures produced %d distinct JA4 (%s)", rounds, len(distinct), strings.Join(jas, ", "))
		return rep
	}
	rep.Detail = fmt.Sprintf("randomized fingerprint emitted identical JA4 %s %d times: randomization is broken", jas[0], rounds)
	return rep
}

// captureHello runs a uTLS handshake against a recording stand-in and
// returns the ClientHello bytes of the first flight. No network traffic
// is involved: the stand-in records writes and fails reads, so the
// handshake aborts right after the hello is captured.
func captureHello(ctx context.Context, id utls.ClientHelloID, serverName string, nextProtos []string, timeout time.Duration) ([]byte, error) {
	cfg := &utls.Config{
		ServerName:         serverName,
		NextProtos:         nextProtos,
		InsecureSkipVerify: true,
	}
	c := &captureConn{release: make(chan struct{})}
	uconn := utls.UClient(c, cfg, id)
	errCh := make(chan error, 1)
	go func() { errCh <- uconn.Handshake() }()
	defer c.close()

	deadline := time.Now().Add(timeout)
	for {
		c.mu.Lock()
		got := len(c.writes) > 0
		c.mu.Unlock()
		if got {
			break
		}
		if time.Now().After(deadline) {
			c.close() // release the handshake goroutine first
			<-errCh
			return nil, errors.New("ja4: timed out waiting for ClientHello")
		}
		select {
		case <-ctx.Done():
			c.close() // release the handshake goroutine first
			<-errCh
			return nil, ctx.Err()
		case <-time.After(5 * time.Millisecond):
		}
	}
	// Let any follow-up writes of the first flight land, then release the
	// handshake goroutine (it blocks reading the server flight).
	time.Sleep(50 * time.Millisecond)
	c.close()
	<-errCh // the handshake always fails here; the bytes are what matter
	c.mu.Lock()
	defer c.mu.Unlock()
	var raw []byte
	for _, w := range c.writes {
		raw = append(raw, w...)
	}
	return raw, nil
}

// captureConn is a net.Conn stand-in that records writes and fails reads.
// The uTLS handshake writes the ClientHello first, then blocks reading
// the server flight, which is exactly the point where we abort it.
type captureConn struct {
	mu      sync.Mutex
	writes  [][]byte
	release chan struct{}
	once    sync.Once
}

func (c *captureConn) Write(p []byte) (int, error) {
	cp := make([]byte, len(p))
	copy(cp, p)
	c.mu.Lock()
	c.writes = append(c.writes, cp)
	c.mu.Unlock()
	return len(p), nil
}

func (c *captureConn) Read([]byte) (int, error) {
	<-c.release
	return 0, errors.New("ja4: capture connection has no peer")
}

func (c *captureConn) close() {
	c.once.Do(func() { close(c.release) })
}

func (c *captureConn) Close() error                     { c.close(); return nil }
func (c *captureConn) LocalAddr() net.Addr              { return &net.TCPAddr{} }
func (c *captureConn) RemoteAddr() net.Addr             { return &net.TCPAddr{} }
func (c *captureConn) SetDeadline(time.Time) error      { return nil }
func (c *captureConn) SetReadDeadline(time.Time) error  { return nil }
func (c *captureConn) SetWriteDeadline(time.Time) error { return nil }

// clientHello is the parsed surface needed for JA4.
type clientHello struct {
	version    uint16
	ciphers    []uint16
	extensions []uint16
	hasSNI     bool
	sniIsIP    bool
	alpn       []string
	sigAlgs    []uint16
	// keyShareGroups are the named groups offered in the key_share
	// extension (51), in wire order. Empty when the extension is absent.
	keyShareGroups []uint16
}

// pqKeyShareGroup is X25519MLKEM768, the post-quantum hybrid key share
// Chrome has sent since release 131.
const pqKeyShareGroup = 0x11ec

// hasPQKeyShare reports whether the captured hello offers the
// X25519MLKEM768 post-quantum hybrid key share.
func hasPQKeyShare(h clientHello) bool {
	for _, g := range h.keyShareGroups {
		if g == pqKeyShareGroup {
			return true
		}
	}
	return false
}

// parseCapturedHello extracts the ClientHello from captured TLS records
// and parses it.
func parseCapturedHello(raw []byte) (clientHello, error) {
	var handshake []byte
	for len(raw) >= 5 {
		typ, ln := raw[0], int(raw[3])<<8|int(raw[4])
		if len(raw) < 5+ln {
			return clientHello{}, errors.New("ja4: truncated TLS record")
		}
		if typ == 22 { // handshake
			handshake = append(handshake, raw[5:5+ln]...)
		}
		raw = raw[5+ln:]
	}
	if len(handshake) < 4 {
		return clientHello{}, errors.New("ja4: no handshake message captured")
	}
	if handshake[0] != 1 {
		return clientHello{}, fmt.Errorf("ja4: first handshake message is type %d, not ClientHello", handshake[0])
	}
	ln := int(handshake[1])<<16 | int(handshake[2])<<8 | int(handshake[3])
	if len(handshake) < 4+ln {
		return clientHello{}, errors.New("ja4: truncated ClientHello")
	}
	return parseClientHello(handshake[4 : 4+ln])
}

// parseClientHello parses a ClientHello body (TLS 1.2 layout, RFC 5246
// 7.4.1.2): legacy_version, random, session_id, cipher_suites,
// compression_methods, extensions.
func parseClientHello(b []byte) (clientHello, error) {
	var h clientHello
	off := 0
	take := func(n int) ([]byte, error) {
		if off+n > len(b) {
			return nil, errors.New("ja4: ClientHello overrun")
		}
		s := b[off : off+n]
		off += n
		return s, nil
	}
	ver, err := take(2)
	if err != nil {
		return h, err
	}
	legacy := uint16(ver[0])<<8 | uint16(ver[1])
	if _, err := take(32); err != nil { // random
		return h, err
	}
	sid, err := take(1)
	if err != nil {
		return h, err
	}
	if _, err := take(int(sid[0])); err != nil {
		return h, err
	}
	cl, err := take(2)
	if err != nil {
		return h, err
	}
	csLen := int(cl[0])<<8 | int(cl[1])
	if csLen%2 != 0 {
		return h, errors.New("ja4: odd cipher suite list")
	}
	cs, err := take(csLen)
	if err != nil {
		return h, err
	}
	for i := 0; i < len(cs); i += 2 {
		h.ciphers = append(h.ciphers, uint16(cs[i])<<8|uint16(cs[i+1]))
	}
	cm, err := take(1)
	if err != nil {
		return h, err
	}
	if _, err := take(int(cm[0])); err != nil {
		return h, err
	}
	if off == len(b) {
		h.version = legacy
		return h, nil // no extensions
	}
	el, err := take(2)
	if err != nil {
		return h, err
	}
	extLen := int(el[0])<<8 | int(el[1])
	exts, err := take(extLen)
	if err != nil {
		return h, err
	}
	var versions []uint16
	for len(exts) >= 4 {
		typ := uint16(exts[0])<<8 | uint16(exts[1])
		dl := int(exts[2])<<8 | int(exts[3])
		if len(exts) < 4+dl {
			return h, errors.New("ja4: extension overrun")
		}
		data := exts[4 : 4+dl]
		h.extensions = append(h.extensions, typ)
		switch typ {
		case 0: // server_name
			h.hasSNI = true
			if name, ok := parseSNI(data); ok {
				_, err := netip.ParseAddr(name)
				h.sniIsIP = err == nil
			}
		case 16: // application_layer_protocol_negotiation
			h.alpn = parseALPN(data)
		case 13: // signature_algorithms
			h.sigAlgs = parseU16List(data, 2)
		case 43: // supported_versions
			versions = parseU16List(data, 1)
		case 51: // key_share
			h.keyShareGroups = parseKeyShareGroups(data)
		}
		exts = exts[4+dl:]
	}
	h.version = legacy
	for _, v := range versions {
		// GREASE versions (e.g. 0x0a0a) sort above real ones; skipping
		// them is what the JA4 version field means.
		if isGREASE(v) {
			continue
		}
		if v > h.version {
			h.version = v
		}
	}
	return h, nil
}

// parseKeyShareGroups extracts the named-group list from a key_share
// extension (RFC 8446 4.2.8): client_shares is a length-prefixed vector of
// KeyShareEntry { named_group, key_exchange }. Malformed entries stop the
// parse; JA4 only needs the groups that are present.
func parseKeyShareGroups(data []byte) []uint16 {
	if len(data) < 2 {
		return nil
	}
	end := 2 + int(data[0])<<8 | int(data[1])
	if end > len(data) {
		end = len(data)
	}
	var out []uint16
	for p := 2; p+4 <= end; {
		group := uint16(data[p])<<8 | uint16(data[p+1])
		kl := int(data[p+2])<<8 | int(data[p+3])
		p += 4
		if p+kl > end {
			break
		}
		out = append(out, group)
		p += kl
	}
	return out
}

// parseSNI extracts the first host_name from a server_name extension.
func parseSNI(data []byte) (string, bool) {
	if len(data) < 2 {
		return "", false
	}
	ll := int(data[0])<<8 | int(data[1])
	if len(data) < 2+ll || ll < 3 || data[2] != 0 {
		return "", false
	}
	nl := int(data[3])<<8 | int(data[4])
	if len(data) < 5+nl {
		return "", false
	}
	return string(data[5 : 5+nl]), true
}

// parseALPN extracts the protocol list from an ALPN extension.
func parseALPN(data []byte) []string {
	if len(data) < 2 {
		return nil
	}
	ll := int(data[0])<<8 | int(data[1])
	var out []string
	for p := 2; p < 2+ll && p < len(data); {
		l := int(data[p])
		p++
		if p+l > len(data) {
			break
		}
		out = append(out, string(data[p:p+l]))
		p += l
	}
	return out
}

// parseU16List parses a length-prefixed uint16 list: supported_versions
// uses a 1-byte length, signature_algorithms a 2-byte one. Overlong
// lengths are clamped, never fatal: JA4 only needs the values present.
func parseU16List(data []byte, lenBytes int) []uint16 {
	var hdr, body int
	if lenBytes == 1 {
		if len(data) < 1 {
			return nil
		}
		hdr, body = 1, int(data[0])
	} else {
		if len(data) < 2 {
			return nil
		}
		hdr, body = 2, int(data[0])<<8|int(data[1])
	}
	if hdr+body > len(data) {
		body = len(data) - hdr
	}
	var out []uint16
	for i := hdr; i+1 < hdr+body; i += 2 {
		out = append(out, uint16(data[i])<<8|uint16(data[i+1]))
	}
	return out
}

// isGREASE reports RFC 8701 GREASE values: both bytes share the high
// nibble and both low nibbles are 0xa (0x0a0a, 0x1a1a, ..., 0xfafa).
func isGREASE(v uint16) bool {
	return v&0x0f0f == 0x0a0a && v>>12 == (v>>4)&0xf
}

// ja4Of computes the JA4 fingerprint of a parsed ClientHello per the FoxIO
// JA4 specification (see the package doc): sorted cipher and extension
// lists with GREASE stripped, SNI/ALPN excluded from the extension hash
// but counted, signature algorithms appended in wire order.
func ja4Of(h clientHello) string {
	var ver string
	switch h.version {
	case 0x0304:
		ver = "13"
	case 0x0303:
		ver = "12"
	case 0x0302:
		ver = "11"
	case 0x0301:
		ver = "10"
	case 0x0300:
		ver = "s3"
	default:
		ver = "00"
	}
	sni := "i"
	if h.hasSNI && !h.sniIsIP {
		sni = "d"
	}
	ciphers := make([]string, 0, len(h.ciphers))
	for _, c := range h.ciphers {
		if !isGREASE(c) {
			ciphers = append(ciphers, fmt.Sprintf("%04x", c))
		}
	}
	exts := make([]string, 0, len(h.extensions))
	extCount := 0
	for _, e := range h.extensions {
		if isGREASE(e) {
			continue
		}
		extCount++
		// SNI and ALPN are already represented in JA4_a: counted, but
		// excluded from the extension hash.
		if e == 0x0000 || e == 0x0010 {
			continue
		}
		exts = append(exts, fmt.Sprintf("%04x", e))
	}
	alpn := "00"
	if len(h.alpn) > 0 {
		var an []rune
		for _, r := range h.alpn[0] {
			if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') {
				an = append(an, r)
			}
		}
		switch len(an) {
		case 0:
		case 1:
			alpn = string(an[0]) + string(an[0])
		default:
			alpn = string(an[0]) + string(an[len(an)-1])
		}
	}
	nc := len(ciphers)
	if nc > 99 {
		nc = 99
	}
	if extCount > 99 {
		extCount = 99
	}
	return fmt.Sprintf("t%s%s%02d%02d%s_%s_%s", ver, sni, nc, extCount, alpn,
		hash12Sorted(ciphers), ja4ExtHash(exts, h.sigAlgs))
}

// hash12Sorted returns the first 12 hex chars of the sha256 of the sorted,
// comma-joined list, or zeros for an empty list.
func hash12Sorted(list []string) string {
	if len(list) == 0 {
		return "000000000000"
	}
	sorted := append([]string(nil), list...)
	sort.Strings(sorted)
	sum := sha256.Sum256([]byte(strings.Join(sorted, ",")))
	return hex.EncodeToString(sum[:])[:12]
}

// ja4ExtHash hashes the extension section: sorted extensions, then the
// signature algorithms in wire order, joined with "_". GREASE values are
// stripped from the signature algorithms (as they already are from ciphers
// and extensions): modern parrots emit a fresh GREASE sigalg per handshake,
// and hashing it would make the JA4 non-deterministic — a fingerprint that
// changes on every capture cannot honestly signal anything (S8).
func ja4ExtHash(exts []string, sigAlgs []uint16) string {
	sorted := append([]string(nil), exts...)
	sort.Strings(sorted)
	s := strings.Join(sorted, ",")
	if len(sigAlgs) > 0 {
		var sa []string
		for _, v := range sigAlgs {
			if isGREASE(v) {
				continue
			}
			sa = append(sa, fmt.Sprintf("%04x", v))
		}
		if len(sa) > 0 {
			s += "_" + strings.Join(sa, ",")
		}
	}
	if s == "" {
		return "000000000000"
	}
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])[:12]
}
