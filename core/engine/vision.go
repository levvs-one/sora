package engine

// VisionFlow is the XTLS vision flow the plan enables automatically for
// VLESS/Trojan outbounds that run over plain TCP with TLS or REALITY
// security and carry no explicit flow. The literal also appears in the
// engine renderers; this constant is the plan-level spelling of it.
const VisionFlow = "xtls-rprx-vision"

// ApplyAutoVision enables XTLS vision on an outbound that benefits from
// it but did not ask for a flow explicitly: VLESS/Trojan over TCP (""
// counts as TCP — it is the default transport) with TLS or REALITY
// security and an empty Flow. It sets Flow to VisionFlow and records the
// fact in FlowAuto, and reports whether it changed anything.
//
// A manually configured flow is never overwritten: any non-empty Flow —
// including the vision-udp443 variant — is respected as-is.
//
// Vision on a non-TCP transport is not fixed up here; that combination
// cannot work and stays a hard render error (xray checkStreamCompat),
// so ApplyAutoVision leaves it alone instead of papering over it.
//
// Callers: control.outboundFromProto runs this while assembling the plan,
// so every plan-building path (UI import, subscriptions, benchmarks)
// gets the same normalization.
func (o *Outbound) ApplyAutoVision() bool {
	if o.Flow != "" {
		return false
	}
	if o.Protocol != ProtocolVLESS && o.Protocol != ProtocolTrojan {
		return false
	}
	if t := o.Transport.Type; t != "" && t != "tcp" {
		return false
	}
	if !o.TLS.Enabled && !o.TLS.Reality {
		return false
	}
	o.Flow = VisionFlow
	o.FlowAuto = true
	return true
}
