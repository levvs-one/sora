package probe

// REALITY dest checklist (T006).
//
// A REALITY server is only as convincing as its dest: the decoy site the
// censor sees. The field reports behind T006 are unambiguous — REALITY has
// no protocol-level detector in the wild; servers get classified as
// proxies through deployment mistakes. The client cannot fix the server,
// but it can refuse to bless a bad dest. CheckDest runs the checklist
// from the matrix:
//
//   - the dest is a domain, not an IP literal;
//   - it resolves, and not into Cloudflare ranges (a dest behind
//     Cloudflare mimics the edge, not an origin — and CF is throttled
//     network-wide since 06.2025);
//   - it serves TLS 1.3 with ALPN h2, like a real modern site;
//   - it negotiates X25519 (the key share a real browser offers);
//   - it presents a certificate valid for the name.
//
// What this does NOT check, honestly: whether the domain is "large" or
// popular (no offline popularity signal exists — that stays a manual
// operator decision), and whether the SNI matches the server's ASN (needs
// an ASN table; see the spec). Passing the checklist means "plausible
// decoy", not "invisible".
//
// CheckDest is an on-demand diagnostic: two sequential TLS handshakes, no
// parallelism, no tunnel. It must not run in a hot loop.

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net"
	"net/netip"
	"strings"
	"time"
)

// Cloudflare ranges as published at https://www.cloudflare.com/ips
// (snapshot 2026-01). A dest resolving into these mimics the CF edge
// rather than an origin site. Refresh the snapshot when the list is
// older than a year; the check is advisory, so staleness degrades it
// instead of breaking it.
var cloudflareCIDRs = []string{
	"173.245.48.0/20", "103.21.244.0/22", "103.22.200.0/22", "103.31.4.0/22",
	"141.101.64.0/18", "108.162.192.0/18", "190.93.240.0/20", "188.114.96.0/20",
	"197.234.240.0/22", "198.41.128.0/17", "162.158.0.0/15", "104.16.0.0/13",
	"104.24.0.0/14", "172.64.0.0/13", "131.0.72.0/22",
	"2400:cb00::/32", "2606:4700::/32", "2803:f800::/32", "2405:b500::/32",
	"2405:8100::/32", "2a06:98c0::/29", "2c0f:f248::/32",
}

var cloudflarePrefixes []netip.Prefix

func init() {
	for _, c := range cloudflareCIDRs {
		if p, err := netip.ParsePrefix(c); err == nil {
			cloudflarePrefixes = append(cloudflarePrefixes, p)
		}
	}
}

// behindCloudflare reports whether any of the addresses falls into a
// published Cloudflare range.
func behindCloudflare(addrs []string) bool {
	for _, a := range addrs {
		ip, err := netip.ParseAddr(a)
		if err != nil {
			continue
		}
		for _, p := range cloudflarePrefixes {
			if p.Contains(ip) {
				return true
			}
		}
	}
	return false
}

// DestReport is the checklist result for one REALITY dest.
type DestReport struct {
	Host string
	// ResolvedIPs are the addresses the dest resolved to.
	ResolvedIPs []string
	// TLSVersionName is "1.3", "1.2" or "" when no handshake completed.
	TLSVersionName string
	// ALPNH2 reports that the server negotiated h2.
	ALPNH2 bool
	// X25519 reports that a handshake offering only X25519 succeeded.
	X25519 bool
	// BehindCloudflare reports that the dest resolves into CF ranges.
	BehindCloudflare bool
	// CertValid reports that the presented chain verifies for Host
	// against the system roots (or the test roots in tests).
	CertValid bool
	// CertNames are the DNS names on the leaf certificate.
	CertNames []string
	// Issues lists the checklist failures, most telling first.
	Issues []string
	// Passed is true when the checklist is clean.
	Passed bool
}

const destDialTimeout = 10 * time.Second

// checkDest is the injectable core: resolve maps a name to addresses,
// dial opens a TLS connection with the given config, roots overrides the
// system cert pool (nil = system). Tests inject all three; production
// passes nil.
func checkDest(ctx context.Context, host string, resolve func(context.Context, string) ([]string, error), dial func(context.Context, string, *tls.Config) (*tls.Conn, error), roots *x509.CertPool) (*DestReport, error) {
	r := &DestReport{Host: host}
	if strings.TrimSpace(host) == "" {
		return nil, fmt.Errorf("probe: empty dest host")
	}
	if _, err := netip.ParseAddr(host); err == nil {
		r.Issues = append(r.Issues, "dest is an IP literal, not a domain: REALITY must mimic a real website")
		return r, nil
	}
	if resolve == nil {
		resolve = defaultResolve
	}
	if dial == nil {
		dial = defaultDialTLS
	}
	rctx, cancel := context.WithTimeout(ctx, destDialTimeout)
	defer cancel()
	addrs, err := resolve(rctx, host)
	if err != nil {
		return nil, fmt.Errorf("probe: dest %q does not resolve: %w", host, err)
	}
	if len(addrs) == 0 {
		return nil, fmt.Errorf("probe: dest %q resolved to no addresses", host)
	}
	r.ResolvedIPs = addrs
	if behindCloudflare(addrs) {
		r.Issues = append(r.Issues, "dest resolves into Cloudflare ranges: it mimics the CDN edge, not an origin site")
		r.BehindCloudflare = true
	}
	base := &tls.Config{
		ServerName:         host,
		NextProtos:         []string{"h2", "http/1.1"},
		InsecureSkipVerify: true, // the certificate is verified manually below
		MinVersion:         tls.VersionTLS10,
	}
	conn, err := dial(rctx, addrs[0], base)
	if err != nil {
		return nil, fmt.Errorf("probe: TLS to dest %q failed: %w", host, err)
	}
	cs := conn.ConnectionState()
	conn.Close()
	switch cs.Version {
	case tls.VersionTLS13:
		r.TLSVersionName = "1.3"
	case tls.VersionTLS12:
		r.TLSVersionName = "1.2"
		r.Issues = append(r.Issues, "dest negotiates only TLS 1.2: a modern decoy must do TLS 1.3")
	default:
		r.Issues = append(r.Issues, "dest negotiates no modern TLS version")
		return r, nil
	}
	r.ALPNH2 = cs.NegotiatedProtocol == "h2"
	if !r.ALPNH2 {
		r.Issues = append(r.Issues, "dest does not negotiate h2: a real site serves HTTP/2")
	}
	// X25519-only handshake: success proves the server speaks the key
	// share real browsers offer. crypto/tls does not expose the
	// negotiated group, so offering only X25519 is the honest test.
	xcfg := base.Clone()
	xcfg.CurvePreferences = []tls.CurveID{tls.X25519}
	xconn, err := dial(rctx, addrs[0], xcfg)
	if err != nil {
		r.Issues = append(r.Issues, "dest does not complete a handshake offering only X25519")
	} else {
		r.X25519 = true
		xconn.Close()
	}
	if len(cs.PeerCertificates) > 0 {
		leaf := cs.PeerCertificates[0]
		r.CertNames = leaf.DNSNames
		opts := x509.VerifyOptions{DNSName: host, Intermediates: x509.NewCertPool(), Roots: roots}
		for _, c := range cs.PeerCertificates[1:] {
			opts.Intermediates.AddCert(c)
		}
		if _, err := leaf.Verify(opts); err != nil {
			r.Issues = append(r.Issues, "dest certificate does not verify for "+host+": "+firstLine(err.Error()))
		} else {
			r.CertValid = true
		}
	} else {
		r.Issues = append(r.Issues, "dest presented no certificate")
	}
	r.Passed = len(r.Issues) == 0
	return r, nil
}

func checkSNIConsistency(ctx context.Context, serverAddr, destHost string, resolve func(context.Context, string) ([]string, error)) (resolved []string, issues []string, err error) {
	if strings.TrimSpace(destHost) == "" {
		return nil, nil, fmt.Errorf("probe: empty dest host")
	}
	rctx, cancel := context.WithTimeout(ctx, destDialTimeout)
	defer cancel()
	addrs, err := resolve(rctx, destHost)
	if err != nil || len(addrs) == 0 {
		return nil, nil, fmt.Errorf("probe: dest %q does not resolve: %w", destHost, err)
	}
	resolved = addrs
	for _, a := range addrs {
		ip, perr := netip.ParseAddr(a)
		if perr != nil {
			continue
		}
		if !ip.IsGlobalUnicast() || ip.IsPrivate() {
			issues = append(issues, "dest resolves to non-public address "+a)
		}
	}
	if sip, serr := netip.ParseAddr(serverAddr); serr == nil {
		for _, a := range addrs {
			if ip, perr := netip.ParseAddr(a); perr == nil && ip == sip {
				issues = append(issues, "dest resolves to the REALITY server itself: use an independent real site as the decoy")
				break
			}
		}
	}
	return resolved, issues, nil
}

func defaultResolve(ctx context.Context, host string) ([]string, error) {
	return net.DefaultResolver.LookupHost(ctx, host)
}

func defaultDialTLS(ctx context.Context, addr string, cfg *tls.Config) (*tls.Conn, error) {
	d := &net.Dialer{}
	c, err := d.DialContext(ctx, "tcp", net.JoinHostPort(addr, "443"))
	if err != nil {
		return nil, err
	}
	tc := tls.Client(c, cfg)
	if err := tc.HandshakeContext(ctx); err != nil {
		c.Close()
		return nil, err
	}
	return tc, nil
}

func firstLine(s string) string {
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		return s[:i]
	}
	if len(s) > 160 {
		return s[:160] + "…"
	}
	return s
}
