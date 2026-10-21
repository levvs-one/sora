package ext

import (
	"context"
	"errors"
	"net"
	"net/http"
	"net/netip"
	"strings"
	"sync"
	"time"

	"golang.org/x/net/proxy"

	"github.com/levvs-one/sora-client/core/errs"
)

// KeyNetFetchNoTunnel identifies a fetch refused without an isolated VPN proxy.
const KeyNetFetchNoTunnel errs.Key = "ext.netfetch.no-tunnel"

const tunnelProxyTimeout = 10 * time.Second

// TunnelProxy is core-only material for one session. Never log this value or
// send it to a worker: workers receive only allowlisted fetch results.
type TunnelProxy struct {
	Addr     string
	Username string
	Password string
}

// ProxyRoundTripper sends both destination DNS and TCP through the private
// SOCKS listener. Passing IPs to the engine avoids local target resolution in
// IP-only outbounds such as WireGuard. The original URL retains TLS SNI and Host.
func ProxyRoundTripper(p TunnelProxy) (*http.Transport, error) {
	host, port, err := net.SplitHostPort(p.Addr)
	if err != nil || host != "127.0.0.1" || port == "" || p.Username == "" || p.Password == "" {
		return nil, noTunnelErr("invalid private tunnel proxy")
	}
	dialer, err := proxy.SOCKS5("tcp", p.Addr, &proxy.Auth{User: p.Username, Password: p.Password},
		&net.Dialer{Timeout: tunnelProxyTimeout, KeepAlive: 30 * time.Second})
	if err != nil {
		return nil, noTunnelErr("cannot create tunnel dialer")
	}
	socks := dialer.(proxy.ContextDialer)
	resolver := &net.Resolver{PreferGo: true, StrictErrors: true,
		Dial: func(ctx context.Context, _, _ string) (net.Conn, error) {
			// Force DNS over TCP inside the same VPN route. No OS resolver,
			// search-domain query, engine DNS policy, or direct fallback.
			return socks.DialContext(ctx, "tcp", "1.1.1.1:53")
		}}
	return &http.Transport{
		DialContext: func(ctx context.Context, _, addr string) (net.Conn, error) {
			ctx, cancel := context.WithTimeout(ctx, tunnelProxyTimeout)
			defer cancel()
			host, port, err := net.SplitHostPort(addr)
			if err != nil {
				return nil, err
			}
			if _, err := netip.ParseAddr(host); err == nil {
				return socks.DialContext(ctx, "tcp", addr)
			}
			ips, err := resolver.LookupNetIP(ctx, "ip", strings.TrimSuffix(host, ".")+".")
			if err != nil {
				return nil, err
			}
			var failures []error
			for _, ip := range ips {
				conn, err := socks.DialContext(ctx, "tcp", net.JoinHostPort(ip.String(), port))
				if err == nil {
					return conn, nil
				}
				failures = append(failures, err)
			}
			return nil, errors.Join(failures...)
		},
		TLSHandshakeTimeout: tunnelProxyTimeout, ResponseHeaderTimeout: 30 * time.Second,
		MaxIdleConnsPerHost: 8, IdleConnTimeout: 30 * time.Second,
	}, nil
}

// TunnelTransport resolves the current authenticated VPN proxy per request.
// Only one session's pool is retained so reconnects retire stale credentials.
type TunnelTransport struct {
	Lookup func() (TunnelProxy, bool)

	mu     sync.Mutex
	proxy  TunnelProxy
	cached *http.Transport
}

// RoundTrip implements http.RoundTripper using the current session's proxy.
func (t *TunnelTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if t.Lookup == nil {
		return nil, noTunnelErr("no tunnel proxy lookup configured")
	}
	p, ok := t.Lookup()
	t.mu.Lock()
	if !ok || p != t.proxy {
		if t.cached != nil {
			t.cached.CloseIdleConnections()
		}
		t.cached = nil
		t.proxy = p
	}
	if !ok {
		t.mu.Unlock()
		return nil, noTunnelErr("the VPN tunnel is not available")
	}
	if t.cached == nil {
		rt, err := ProxyRoundTripper(p)
		if err != nil {
			t.mu.Unlock()
			return nil, err
		}
		t.cached = rt
	}
	rt := t.cached
	t.mu.Unlock()
	return rt.RoundTrip(req)
}

func noTunnelErr(detail string) error {
	return errs.Newf(errs.CodeUnavailable, KeyNetFetchNoTunnel,
		"ext: net.fetch needs the VPN tunnel: %s", detail)
}
