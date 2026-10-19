// Ingress ruleset rendering for Linux nftables. Pure string building, no
// build tag, so the rules are unit-testable on every platform; the
// privileged install lives in ingress_linux.go.
package guard

import (
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

const (
	// nftIngressTable is owned by the ingress protection, separate from
	// the kill-switch table so either side can be armed, replaced, or
	// removed without touching the other.
	nftIngressTable = "sora_ingress"
	// nftIngressChain is the input hook the table installs.
	nftIngressChain = "ingress"
)

// NftIngressRuleset renders the ingress protection ruleset. Accept rules
// precede the final drop, in this order:
//
//  1. loopback — the local engine lives there;
//  2. the tunnel interface — inbound through the tunnel is not inbound
//     bypassing the tunnel;
//  3. established and related — replies and live VPN sessions keep working;
//  4. the configured VPN server endpoints, by address;
//  5. local networks, when cfg.AllowLAN, from the kill-switch bypass list.
//
// Everything else inbound is dropped. The drop therefore never touches an
// established connection: conntrack accepts those before the drop rule is
// evaluated. cfg must already be validated; invalid VPN endpoints fail
// closed here as well.
func NftIngressRuleset(cfg IngressConfig, bypass []string) (string, error) {
	endpoints, err := parseIngressEndpoints(cfg.VPNEndpoints)
	if err != nil {
		return "", err
	}
	networks := bypass
	if len(networks) == 0 {
		networks = DefaultBypassNetworks()
	}
	var b strings.Builder
	b.WriteString("table inet " + nftIngressTable + " {\n")
	b.WriteString("\tchain " + nftIngressChain + " {\n")
	b.WriteString("\t\ttype filter hook input priority filter; policy accept;\n")
	if cfg.AllowLoopback {
		b.WriteString("\t\tiif \"lo\" accept comment \"sora: ingress keeps loopback\"\n")
	}
	// Inbound arriving on the tunnel interface came through the tunnel;
	// only physical interfaces are hardened.
	b.WriteString("\t\tiifname \"" + engine.TunDevice + "\" accept comment \"sora: ingress keeps the tunnel\"\n")
	// Conntrack first: established VPN sessions and their replies must
	// never reach the drop below.
	b.WriteString("\t\tct state established,related accept comment \"sora: ingress keeps established connections\"\n")
	for _, addr := range endpoints {
		family := "ip"
		if addr.Is6() {
			family = "ip6"
		}
		b.WriteString("\t\t" + family + " saddr " + addr.String() + " accept comment \"sora: ingress keeps VPN server endpoints\"\n")
	}
	if cfg.AllowLAN {
		for _, network := range networks {
			prefix, ok := parseBypassNetwork(network)
			if !ok {
				// Same fail-closed rule as the kill switch: raw text
				// never reaches the ruleset.
				continue
			}
			family := "ip"
			if prefix.Addr().Is6() {
				family = "ip6"
			}
			b.WriteString("\t\t" + family + " saddr " + prefix.Masked().String() + " accept comment \"sora: ingress keeps local networks\"\n")
		}
	}
	b.WriteString("\t\tcounter drop comment \"sora: ingress drop\"\n")
	b.WriteString("\t}\n")
	b.WriteString("}\n")
	return b.String(), nil
}

// NftIngressRemove renders removal of the owned ingress table. A missing
// table is treated as success by the backend so repeated restores are safe.
func NftIngressRemove() string {
	return "delete table inet " + nftIngressTable + "\n"
}
