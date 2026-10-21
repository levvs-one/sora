package control

import (
	"context"
	"net/http"
	"strconv"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
	"github.com/levvs-one/sora-client/core/logs"
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

// ExtHostDeps adapts the control server's live state to the extension host's
// capability callbacks. The host enforces per-extension tokens and permission
// scopes on top of these; the gRPC auth interceptors additionally restrict
// the whole ExtensionHost service to control peers (unknown methods default
// to control-only).
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
		ListConnections: func(ctx context.Context) ([]ext.Connection, error) {
			running := s.sessions.Current()
			if running == nil {
				return nil, nil
			}
			list, err := running.Connections(ctx)
			if err != nil {
				return nil, err
			}
			out := make([]ext.Connection, 0, len(list))
			for _, c := range list {
				out = append(out, ext.Connection{
					ID:      c.ID,
					Process: c.Process,
					Host:    c.Host,
					Up:      c.Upload,
					Down:    c.Download,
				})
			}
			return out, nil
		},
		ListServers: func(context.Context) ([]ext.Server, error) {
			// Custom servers arrive through the merged subscription states
			// (see withCustomOutbounds); dedup by id so each server -
			// subscription or custom - is listed exactly once.
			seen := make(map[string]struct{})
			var out []ext.Server
			for _, sub := range s.subs.list() {
				for _, o := range sub.GetOutbounds() {
					id := o.GetId()
					if _, dup := seen[id]; dup {
						continue
					}
					seen[id] = struct{}{}
					out = append(out, ext.Server{
						ID:        id,
						Name:      o.GetDisplayName(),
						LatencyMs: -1,
					})
				}
			}
			return out, nil
		},
		Notify: func(_ context.Context, extensionID, title, body string) error {
			if s.logs == nil {
				return errs.Newf(errs.CodeUnavailable, errs.KeyInternal, "control: notification journal is unavailable")
			}
			s.logs.Write(time.Time{}, logs.LevelInfo, "ext:"+extensionID, title+": "+body)
			return nil
		},
		WatchEvents: func(ctx context.Context) (<-chan [2]string, error) {
			running := s.sessions.Current()
			if running == nil {
				return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeySessionRequired,
					"control: extension event watch needs an active session")
			}
			live, unsub := running.Journal().Subscribe(64)
			out := make(chan [2]string, 64)
			go func() {
				defer close(out)
				defer unsub()
				for {
					select {
					case <-ctx.Done():
						return
					case ev, ok := <-live:
						if !ok {
							return
						}
						kind := ""
						switch ev.Kind {
						case session.EventNetwork:
							kind = "network.changed"
						case session.EventState:
							switch ev.State {
							case session.StateConnected:
								kind = "session.connected"
							case session.StateDisconnected, session.StateFailed:
								kind = "session.disconnected"
							}
						}
						if kind == "" {
							continue
						}
						select {
						case out <- [2]string{kind, ""}:
						case <-ctx.Done():
							return
						}
					}
				}
			}()
			return out, nil
		},
	}
}
