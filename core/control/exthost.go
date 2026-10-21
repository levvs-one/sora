package control

import (
	"crypto/rand"
	"net/http"
	"strconv"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/session"
)

// ExtFetchTransport returns the transport factory for extension
// net.fetch: every extension request rides the session's loopback tunnel
// proxy (see ext.TunnelTransport) and fails closed when none is
// available - an extension fetch must never dial direct around the VPN.
//
// The private listener is independent of the ordinary local proxy and TUN.
// Its credential never leaves the core and its route precedes user rules.
func (s *Server) ExtFetchTransport() func(extensionID string) http.RoundTripper {
	return func(_ string) http.RoundTripper {
		return &ext.TunnelTransport{Lookup: s.extTunnelProxyAddr}
	}
}

// extTunnelProxyAddr reports the live tunnel proxy address for extension
// fetches. Only a connected VPN session with the private inbound qualifies.
func (s *Server) extTunnelProxyAddr() (ext.TunnelProxy, bool) {
	cur := s.sessions.Current()
	if cur == nil || cur.State() != session.StateConnected {
		return ext.TunnelProxy{}, false
	}
	x, ok := cur.ExtensionProxy()
	if !ok {
		return ext.TunnelProxy{}, false
	}
	return ext.TunnelProxy{Addr: "127.0.0.1:" + strconv.Itoa(x.Port), Username: x.Username, Password: x.Password}, true
}

func prepareExtensionProxy(plan *engine.Plan, in *corev1.SessionPlan) error {
	target := in.GetRouting().GetProxyTarget()
	if chain := in.GetChain(); len(chain) > 0 {
		target = chain[len(chain)-1]
	}
	if target == "" {
		for _, rule := range plan.Rules {
			if rule.Type == engine.RuleMatchAll {
				target = rule.Target
				break
			}
		}
	}
	if !plan.IsVPNTarget(target) {
		return nil
	}
	port, err := supervise.FreePort()
	if err != nil {
		return errs.Wrap(err, errs.CodeInternal, errs.KeyInternal)
	}
	plan.ExtensionProxy = &engine.ExtensionProxy{Port: port, Username: rand.Text(), Password: rand.Text() + rand.Text(), Target: target}
	return nil
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
