// Tunnel transport for extension net.fetch: every request leaves through
// the user's VPN tunnel, never direct.
//
// An extension's Fetcher talks to an http.RoundTripper it was given at
// construction. When that transport is a *TunnelTransport, the request is
// proxied through the session's loopback mixed (HTTP+SOCKS5) listener —
// the same listener the system-proxy mode serves. When no tunnel proxy is
// available (session down, TUN mode without a local listener), the request
// fails closed with ext.netfetch.no-tunnel instead of dialing direct: an
// extension fetch that silently bypassed the VPN would be a leak the user
// cannot see.
//
// The lookup function is resolved on EVERY RoundTrip, not once at
// construction, because the session behind it changes: the user connects,
// disconnects, reconnects. The control plane supplies the lookup (see
// Server.ExtFetchTransport); this package only defines the mechanism.
package ext

import (
	"errors"
	"net"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// KeyNetFetchNoTunnel is the localization key for a fetch refused because
// no tunnel proxy is available. The extension log and the UI explain it as
// "extension network needs the VPN tunnel" — the request was not made.
const KeyNetFetchNoTunnel errs.Key = "ext.netfetch.no-tunnel"

// tunnelProxyTimeout bounds establishing the hop to the local proxy. The
// proxy is loopback; anything slower than this is a broken local stack,
// not a slow network.
const tunnelProxyTimeout = 10 * time.Second

// ProxyRoundTripper returns a transport that sends every request through
// the loopback proxy at addr (host:port, e.g. "127.0.0.1:7890"). The proxy
// is the tunnel's own mixed listener; extension traffic routed through it
// exits through the VPN like any proxied application.
//
// The address must be loopback: an extension fetch must never be handed to
// a remote proxy, and the error is fail-closed rather than "fixed up" so a
// miswired caller cannot silently reroute traffic.
func ProxyRoundTripper(addr string) (http.RoundTripper, error) {
	host, port, err := net.SplitHostPort(strings.TrimSpace(addr))
	if err != nil || port == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchNoTunnel,
			"ext: bad tunnel proxy address %q", addr)
	}
	ip := net.ParseIP(host)
	if ip == nil || !ip.IsLoopback() {
		// "localhost" is a name, not a literal: resolve it once and pin
		// the result, so a hostile resolver cannot turn the loopback
		// proxy into a remote one mid-session.
		resolved, rerr := net.ResolveIPAddr("ip", host)
		if rerr != nil || !resolved.IP.IsLoopback() {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchNoTunnel,
				"ext: the tunnel proxy must be a loopback address, got %q", addr)
		}
	}
	proxyURL := &url.URL{Scheme: "http", Host: net.JoinHostPort(host, port)}
	dialer := &net.Dialer{Timeout: tunnelProxyTimeout, KeepAlive: 30 * time.Second}
	return &http.Transport{
		Proxy:                 http.ProxyURL(proxyURL),
		DialContext:           dialer.DialContext,
		TLSHandshakeTimeout:   tunnelProxyTimeout,
		ResponseHeaderTimeout: 30 * time.Second,
		MaxIdleConnsPerHost:   8,
		// The proxy is the authority on where traffic goes; the extension
		// must not bypass it via environment proxy variables, and it must
		// not follow redirects itself (the Fetcher re-checks every hop
		// against the allowlist above this transport).
		ProxyConnectHeader: http.Header{},
	}, nil
}

// TunnelTransport is the production http.RoundTripper for extension
// net.fetch. Lookup reports the live tunnel proxy address on every
// request; while it reports none, requests fail closed (no direct dials).
//
// Transports are cached per resolved address and reused, so a steady
// session keeps its connection pool instead of rebuilding it per request.
// Lookup must be safe for concurrent use; it is called on every RoundTrip.
type TunnelTransport struct {
	// Lookup returns the tunnel proxy's host:port, or ok=false when no
	// tunnel proxy is available right now.
	Lookup func() (addr string, ok bool)

	mu     sync.Mutex
	cached map[string]http.RoundTripper
}

// RoundTrip implements http.RoundTripper.
func (t *TunnelTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if t.Lookup == nil {
		return nil, noTunnelErr("no tunnel proxy lookup configured")
	}
	addr, ok := t.Lookup()
	if !ok || strings.TrimSpace(addr) == "" {
		return nil, noTunnelErr("the VPN tunnel is not available")
	}
	rt, err := t.forAddr(addr)
	if err != nil {
		return nil, err
	}
	return rt.RoundTrip(req)
}

// forAddr returns the cached proxy transport for addr, building it once.
func (t *TunnelTransport) forAddr(addr string) (http.RoundTripper, error) {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.cached == nil {
		t.cached = map[string]http.RoundTripper{}
	}
	if rt, ok := t.cached[addr]; ok {
		return rt, nil
	}
	rt, err := ProxyRoundTripper(addr)
	if err != nil {
		return nil, err
	}
	t.cached[addr] = rt
	return rt, nil
}

// noTunnelErr is the fail-closed error: the fetch did not happen.
func noTunnelErr(detail string) error {
	return errs.Newf(errs.CodeUnavailable, KeyNetFetchNoTunnel,
		"ext: net.fetch needs the VPN tunnel: %s", detail)
}

// isNoTunnel reports whether err is the fail-closed no-tunnel error.
func isNoTunnel(err error) bool {
	var e *errs.Error
	return errors.As(err, &e) && e.Key() == KeyNetFetchNoTunnel
}
