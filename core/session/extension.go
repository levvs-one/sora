package session

import "github.com/levvs-one/sora-client/core/engine"

// ExtensionProxy reports a ready engine's isolated listener. A plan alone is
// insufficient: custom engines may connect without implementing this inbound.
func (s *Session) ExtensionProxy() (engine.ExtensionProxy, bool) {
	p := s.Plan()
	if s.State() != StateConnected || s.eng.State() != engine.StateRunning ||
		!s.eng.Capabilities().Supports(engine.FeatureExtensionProxy) || p.ExtensionProxy == nil ||
		!p.IsVPNTarget(p.ExtensionProxy.Target) {
		return engine.ExtensionProxy{}, false
	}
	return *p.ExtensionProxy, true
}
