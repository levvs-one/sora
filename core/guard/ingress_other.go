//go:build !linux && !windows

package guard

import (
	"github.com/levvs-one/sora-client/core/errs"
)

// newIngressBackend on platforms without a process-managed firewall:
// NoopFirewall needs no ingress rules; anything else is unsupported and
// fails closed instead of silently skipping the protection.
func newIngressBackend(inner Firewall, cfg IngressConfig) (ingressBackend, error) {
	if _, ok := inner.(NoopFirewall); ok {
		return nil, nil
	}
	return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
		"guard: ingress protection is not implemented for %T on this platform", inner)
}
