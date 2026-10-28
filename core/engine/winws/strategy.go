// Package winws owns the host's pinned Windows Zapret process. Its packet
// filter is system-wide; it never represents a SOCKS proxy or a VPN.
package winws

import (
	"fmt"
	"slices"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// Args exposes only supported shaping fields. Capture ports, address filtering
// and process lifetime remain host policy.
func Args(s engine.BypassStrategy) ([]string, error) {
	if err := (engine.Outbound{ID: "winws", Protocol: engine.ProtocolWinws, Bypass: &s}).Validate(); err != nil {
		return nil, err
	}
	if s.OOB || s.TLSRecord != "" {
		return nil, fmt.Errorf("winws: OOB and TLS-record splitting require the SOCKS backend")
	}
	args := []string{"--wf-l3=ipv4,ipv6", "--wf-tcp=80,443", "--wf-filter-lan=1"}
	if len(s.SplitPos) > 0 {
		mode := "multisplit"
		if s.Disorder {
			mode = "multidisorder"
		}
		args = append(args, "--dpi-desync="+mode, "--dpi-desync-split-pos="+strings.Join(s.SplitPos, ","))
	}
	if s.HostCase {
		args = append(args, "--hostcase")
	}
	if s.DomainCase {
		args = append(args, "--domcase")
	}
	if s.MethodEOL {
		args = append(args, "--methodeol")
	}
	return args, nil
}

// Has identifies the explicit Windows packet-filter mode.
func Has(p *engine.Plan) bool {
	return p != nil && slices.ContainsFunc(p.Outbounds, func(o engine.Outbound) bool { return o.Protocol == engine.ProtocolWinws })
}

// Rewrite projects a validated explicit filter mode onto the forwarder's direct
// route. The original plan must be admitted before this projection.
func Rewrite(p *engine.Plan) *engine.Plan {
	out := *p
	out.Outbounds = slices.Clone(p.Outbounds)
	for i, o := range out.Outbounds {
		if o.Protocol == engine.ProtocolWinws {
			out.Outbounds[i] = engine.Outbound{ID: o.ID, Name: o.Name, Protocol: engine.ProtocolDirect}
		}
	}
	return &out
}
