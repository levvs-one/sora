package control

import (
	"context"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/ext"
	"github.com/levvs-one/sora-client/core/logs"
)

// ExtHostDeps adapts the control server's live state to the extension host's
// capability callbacks. The host enforces per-extension tokens and permission
// scopes on top of these; the gRPC auth interceptors additionally restrict
// the whole ExtensionHost service to control peers (unknown methods default
// to control-only).
func (s *Server) ExtHostDeps() ext.Deps {
	return ext.Deps{
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
			// (see withCustomOutbounds); dedup by id so each server —
			// subscription or custom — is listed exactly once.
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
						select {
						case out <- [2]string{string(ev.Kind), ev.Detail}:
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
