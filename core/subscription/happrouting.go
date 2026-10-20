package subscription

// Provider routing from a subscription's happRouting value (C3).
// The payload is decoded and converted by core/happrouting; this
// file only adapts the result to the stored ProviderRouting form.

import (
	"github.com/levvs-one/sora-client/core/happrouting"
)

// ProxyTargetSentinel is the outbound_id stored for provider proxy
// rules. The client substitutes its session proxy target for it when
// merging subscription rules into a plan.
const ProxyTargetSentinel = "proxy"

// ProviderRoutingFromPayload decodes a happRouting payload (deep
// link, bare base64, or raw JSON) and converts it to the stored
// provider routing layer. An invalid payload is an error: the caller
// logs it and keeps the previously stored layer, so a provider's
// broken update never wipes working rules.
func ProviderRoutingFromPayload(payload string) (*ProviderRouting, error) {
	profile, err := happrouting.DecodePayload(payload)
	if err != nil {
		return nil, err
	}
	conv := profile.Convert(ProxyTargetSentinel)
	out := &ProviderRouting{
		Name:        conv.Name,
		GlobalProxy: conv.GlobalProxy,
		RemoteDNS:   conv.RemoteDNS,
		DomesticDNS: conv.DomesticDNS,
		Skipped:     conv.Skipped,
	}
	for _, r := range conv.Rules {
		out.Rules = append(out.Rules, OverrideRule{Destination: r.Destination, OutboundID: r.OutboundID})
	}
	for _, n := range conv.Notes {
		out.Notes = append(out.Notes, ProviderNote{Field: n.Field, Applied: n.Applied, Reason: n.Reason})
	}
	return out, nil
}
