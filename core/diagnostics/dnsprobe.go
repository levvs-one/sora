package diagnostics

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
)

// DNS probers for the tunnel-DNS canary check. resolveVia covers plain
// UDP/TCP, dohVia covers DNS-over-HTTPS (RFC 8484) and dotVia covers
// DNS-over-TLS (RFC 7858). All three are standard-library only, honor the
// probe timeout, and return the union of A and AAA answers like
// net.Resolver.LookupIPAddr does, so results stay comparable across
// transports.
//
// None of the probers authenticate the resolver: like a plain-DNS canary,
// they check reachability and answer sanity, not identity.

// probeTimeout bounds one probe: the configured default, shrunk to whatever
// the caller's context still allows.
func probeTimeout(ctx context.Context, def time.Duration) time.Duration {
	t := def
	if deadline, ok := ctx.Deadline(); ok {
		if left := time.Until(deadline); left < t {
			t = left
		}
	}
	return t
}

// resolveVia performs a plain DNS query for host through resolverAddr
// ("ip" or "ip:port", default port 53) using only the standard library,
// over the given network ("udp" or "tcp").
func resolveVia(ctx context.Context, network, resolverAddr, host string) ([]string, error) {
	addr := resolverAddr
	if _, _, err := net.SplitHostPort(addr); err != nil {
		// Bare address: JoinHostPort adds brackets for IPv6 itself.
		addr = net.JoinHostPort(strings.Trim(addr, "[]"), "53")
	}
	if network != "tcp" {
		network = "udp"
	}
	timeout := probeTimeout(ctx, defaultResolveTimeout)
	r := &net.Resolver{
		PreferGo: true,
		Dial: func(ctx context.Context, _, _ string) (net.Conn, error) {
			// The dialer timeout is belt and suspenders next to the
			// context deadline: resolveVia must never hang on a bare
			// context either.
			d := &net.Dialer{Timeout: timeout}
			return d.DialContext(ctx, network, addr)
		},
	}
	addrs, err := r.LookupIPAddr(ctx, host)
	if err != nil {
		return nil, err
	}
	ips := make([]string, 0, len(addrs))
	for _, a := range addrs {
		ips = append(ips, a.IP.String())
	}
	return ips, nil
}

// dohURL normalizes a DoH endpoint: a full URL is used as-is, a bare
// address becomes https://addr/dns-query.
func dohURL(endpoint string) string {
	endpoint = strings.TrimSpace(endpoint)
	if strings.Contains(endpoint, "://") {
		return endpoint
	}
	return "https://" + strings.Trim(endpoint, "[]") + "/dns-query"
}

// dohVia performs DNS-over-HTTPS queries (RFC 8484) for host through the
// DoH endpoint (a full URL, or a bare address meaning
// https://addr/dns-query). A and AAAA are queried in parallel and the
// answers unioned; one side succeeding is enough.
func dohVia(ctx context.Context, endpoint, host string) ([]string, error) {
	url := dohURL(endpoint)
	timeout := probeTimeout(ctx, defaultResolveTimeout)
	if timeout <= 0 {
		return nil, errors.New("doh: no time left")
	}
	queries := make([][]byte, 0, 2)
	for _, qtype := range []uint16{1, 28} {
		q, err := dnsQueryMsg(host, qtype)
		if err != nil {
			return nil, err
		}
		queries = append(queries, q)
	}
	client := &http.Client{Timeout: timeout}
	type result struct {
		ips []string
		err error
	}
	results := make([]result, len(queries))
	var wg sync.WaitGroup
	for i, q := range queries {
		wg.Add(1)
		go func(i int, q []byte) {
			defer wg.Done()
			req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(q))
			if err != nil {
				results[i].err = err
				return
			}
			req.Header.Set("Content-Type", "application/dns-message")
			req.Header.Set("Accept", "application/dns-message")
			resp, err := client.Do(req)
			if err != nil {
				results[i].err = err
				return
			}
			defer func() { _ = resp.Body.Close() }()
			if resp.StatusCode != http.StatusOK {
				results[i].err = fmt.Errorf("doh: unexpected HTTP status %d", resp.StatusCode)
				return
			}
			body, err := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
			if err != nil {
				results[i].err = err
				return
			}
			results[i].ips, results[i].err = dnsParseAddrs(body)
		}(i, q)
	}
	wg.Wait()
	seen := map[string]bool{}
	var out []string
	var errs []string
	for _, r := range results {
		if r.err != nil {
			errs = append(errs, r.err.Error())
			continue
		}
		for _, ip := range r.ips {
			if !seen[ip] {
				seen[ip] = true
				out = append(out, ip)
			}
		}
	}
	if len(out) == 0 {
		return nil, errors.New("doh: " + strings.Join(errs, "; "))
	}
	return out, nil
}

// dotVia performs DNS-over-TLS queries (RFC 7858) for host through addr
// ("ip" or "ip:port", default port 853). The TLS identity is not verified:
// the canary checks reachability and answer sanity, exactly like the
// plain-DNS prober, and authenticating a configured resolver address is
// the session's job, not the diagnostic's.
func dotVia(ctx context.Context, addr, host string) ([]string, error) {
	if _, _, err := net.SplitHostPort(addr); err != nil {
		addr = net.JoinHostPort(strings.Trim(addr, "[]"), "853")
	}
	timeout := probeTimeout(ctx, defaultResolveTimeout)
	if timeout <= 0 {
		return nil, errors.New("dot: no time left")
	}
	conn, err := (&tls.Dialer{NetDialer: &net.Dialer{Timeout: timeout},
		Config: &tls.Config{InsecureSkipVerify: true}}).DialContext(ctx, "tcp", addr) //nolint:gosec // diagnostic canary, see above
	if err != nil {
		return nil, err
	}
	defer func() { _ = conn.Close() }()
	if err := conn.SetDeadline(time.Now().Add(timeout)); err != nil {
		return nil, err
	}
	seen := map[string]bool{}
	var out []string
	var errs []string
	for _, qtype := range []uint16{1, 28} {
		q, err := dnsQueryMsg(host, qtype)
		if err != nil {
			return nil, err
		}
		ips, err := dotQuery(conn, q)
		if err != nil {
			errs = append(errs, err.Error())
			continue
		}
		for _, ip := range ips {
			if !seen[ip] {
				seen[ip] = true
				out = append(out, ip)
			}
		}
	}
	if len(out) == 0 {
		return nil, errors.New("dot: " + strings.Join(errs, "; "))
	}
	return out, nil
}

// dotQuery writes one length-prefixed query and reads one length-prefixed
// response on an established DoT connection.
func dotQuery(conn net.Conn, query []byte) ([]string, error) {
	if len(query) > 0xffff {
		return nil, errors.New("dot: query too large")
	}
	frame := make([]byte, 2+len(query))
	frame[0], frame[1] = byte(len(query)>>8), byte(len(query)&0xff) //nolint:gosec // The frame length is bounded to 65535 above.
	copy(frame[2:], query)
	if _, err := conn.Write(frame); err != nil {
		return nil, err
	}
	var hdr [2]byte
	if _, err := io.ReadFull(conn, hdr[:]); err != nil {
		return nil, err
	}
	ln := int(hdr[0])<<8 | int(hdr[1])
	if ln < 12 || ln > 64<<10 {
		return nil, fmt.Errorf("dot: bad response length %d", ln)
	}
	resp := make([]byte, ln)
	if _, err := io.ReadFull(conn, resp); err != nil {
		return nil, err
	}
	return dnsParseAddrs(resp)
}

// dnsQueryMsg builds a wire-format DNS query (RFC 1035) for host/qtype
// with the RD flag set.
func dnsQueryMsg(host string, qtype uint16) ([]byte, error) {
	h := strings.ToLower(strings.TrimSuffix(strings.TrimSpace(host), "."))
	if h == "" || len(h) > 253 {
		return nil, fmt.Errorf("dns: bad host %q", host)
	}
	var id [2]byte
	if _, err := rand.Read(id[:]); err != nil {
		return nil, err
	}
	msg := make([]byte, 0, 64)
	msg = append(msg, id[0], id[1], 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
	for _, label := range strings.Split(h, ".") {
		if len(label) == 0 || len(label) > 63 {
			return nil, fmt.Errorf("dns: bad label in %q", host)
		}
		msg = append(msg, byte(len(label))) //nolint:gosec // DNS labels are checked to be 1..63 bytes above.
		msg = append(msg, label...)
	}
	msg = append(msg, 0x00, byte(qtype>>8), byte(qtype&0xff), 0x00, 0x01)
	return msg, nil
}

// dnsParseAddrs extracts the A and AAAA answers from a wire-format DNS
// response. A non-zero RCODE or an empty answer section is an error: the
// canary wants addresses, and NXDOMAIN for the canary host is a signal,
// not an answer.
func dnsParseAddrs(msg []byte) ([]string, error) {
	if len(msg) < 12 {
		return nil, errors.New("dns: response too short")
	}
	if msg[2]&0x80 == 0 {
		return nil, errors.New("dns: not a response")
	}
	if rcode := msg[3] & 0x0f; rcode != 0 {
		return nil, fmt.Errorf("dns: rcode %d", rcode)
	}
	qd := int(msg[4])<<8 | int(msg[5])
	an := int(msg[6])<<8 | int(msg[7])
	off := 12
	for i := 0; i < qd; i++ {
		var err error
		if off, err = dnsSkipName(msg, off); err != nil {
			return nil, err
		}
		if off+4 > len(msg) {
			return nil, errors.New("dns: truncated question")
		}
		off += 4
	}
	var out []string
	seen := map[string]bool{}
	for i := 0; i < an; i++ {
		var err error
		if off, err = dnsSkipName(msg, off); err != nil {
			return nil, err
		}
		if off+10 > len(msg) {
			return nil, errors.New("dns: truncated RR header")
		}
		typ := int(msg[off])<<8 | int(msg[off+1])
		rdlen := int(msg[off+8])<<8 | int(msg[off+9])
		off += 10
		if off+rdlen > len(msg) {
			return nil, errors.New("dns: truncated rdata")
		}
		var ip net.IP
		switch {
		case typ == 1 && rdlen == net.IPv4len:
			ip = net.IP(msg[off : off+rdlen])
		case typ == 28 && rdlen == net.IPv6len:
			ip = net.IP(msg[off : off+rdlen])
		}
		if ip != nil {
			if s := ip.String(); !seen[s] {
				seen[s] = true
				out = append(out, s)
			}
		}
		off += rdlen
	}
	if len(out) == 0 {
		return nil, errors.New("dns: no address answers")
	}
	return out, nil
}

// dnsSkipName skips one (possibly compressed) domain name at off and
// returns the offset just past it.
func dnsSkipName(msg []byte, off int) (int, error) {
	for {
		if off >= len(msg) {
			return 0, errors.New("dns: name overrun")
		}
		b := msg[off]
		switch b & 0xc0 {
		case 0xc0:
			if off+1 >= len(msg) {
				return 0, errors.New("dns: truncated compression pointer")
			}
			return off + 2, nil
		case 0x00:
			if b == 0 {
				return off + 1, nil
			}
			off += 1 + int(b)
		default:
			return 0, errors.New("dns: bad label length")
		}
	}
}
