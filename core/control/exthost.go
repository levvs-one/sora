package control

import (
	"net/http"
	"strconv"

	"github.com/levvs-one/sora-client/core/ext"
	"github.com/levvs-one/sora-client/core/session"
)

// ExtFetchTransport returns the transport factory for extension
// net.fetch: every extension request rides the session's loopback tunnel
// proxy (see ext.TunnelTransport) and fails closed when none is
// available - an extension fetch must never dial direct around the VPN.
//
// The proxy listener exists exactly when the session plan enables the
// local proxy (system-proxy mode, or TUN with an explicitly enabled
// listener); in pure TUN mode the lookup reports none and the fetch is
// refused with ext.netfetch.no-tunnel. The lookup is resolved per
// request, so reconnects and plan changes take effect without rebuilding
// the fetchers.
func (s *Server) ExtFetchTransport() func(extensionID string) http.RoundTripper {
	return func(_ string) http.RoundTripper {
		return &ext.TunnelTransport{Lookup: s.extTunnelProxyAddr}
	}
}

// extTunnelProxyAddr reports the live tunnel proxy address for extension
// fetches: the session must be up and its plan must open the local proxy
// listener. Otherwise (disconnected, or TUN without a listener) it
// reports none and the fetch fails closed.
func (s *Server) extTunnelProxyAddr() (string, bool) {
	if s.extProxyPort <= 0 {
		return "", false
	}
	cur := s.sessions.Current()
	if cur == nil {
		return "", false
	}
	switch cur.State() {
	case session.StateConnecting, session.StateConnected, session.StateReconnecting:
		// The engine opened the mixed listener before the first connect.
	default:
		return "", false
	}
	plan := cur.Plan()
	if plan == nil || !plan.LocalProxy.Enabled {
		return "", false
	}
	return "127.0.0.1:" + strconv.Itoa(s.extProxyPort), true
}

// ExtHostDeps supplies the worker scheduler and control-token check.
// Transport interceptors restrict ExtensionHost to control peers.
func (s *Server) ExtHostDeps() ext.Deps {
	return ext.Deps{
		Scheduler: s.extSched,
		WorkerEvent: func() string {
			current := s.sessions.Current()
			if current != nil && current.State() == session.StateConnected {
				return "session.connected"
			}
			return "session.disconnected"
		},
		VerifyControl: func(token []byte) bool {
			return s.auth.Verify(token)
		},
	}
}
