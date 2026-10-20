package engine

// VisionFlow is the XTLS vision flow the plan enables automatically for
// VLESS outbounds that run over plain TCP with TLS or REALITY security
// and carry no explicit flow. The literal also appears in the engine
// renderers; this constant is the plan-level spelling of it.
const VisionFlow = "xtls-rprx-vision"

// HasVLESSEncryption reports whether the outbound carries an active
// VLESS Encryption string — anything but "" or "none". The distinction
// matters for the XTLS flow rules: upstream documents XTLS as available
// only under TCP+TLS/REALITY, OR under VLESS Encryption with no
// underlying transport restrictions at all
// (https://xtls.github.io/en/config/outbounds/vless.html). A vision
// flow on a non-TCP transport is therefore legal exactly when this
// reports true (PASS3 deep S3b).
func (o Outbound) HasVLESSEncryption() bool {
	return o.Encryption != "" && o.Encryption != "none"
}

// ApplyAutoVision enables XTLS vision on an outbound that benefits from
// it but did not ask for a flow explicitly: VLESS over TCP (""
// counts as TCP — it is the default transport) with TLS or REALITY
// security and an empty Flow. It sets Flow to VisionFlow and records the
// fact in FlowAuto, and reports whether it changed anything.
//
// Trojan is deliberately NOT auto-visioned (S2). No engine honours a
// vision flow for Trojan: the Xray renderer emits flow only for VLESS,
// and sing-box's and mihomo's trojan outbounds drop it too. Worse, the
// Xray mux gate keys off the plan-level Flow, so auto-assigning vision
// to a Trojan outbound silently disabled its mux while the flow itself
// never reached the wire — the user got neither vision nor mux, and
// the UI badge lied about both. Trojan keeps its mux; a flow a user
// sets manually on Trojan is still respected as-is (never overwritten),
// as before.
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
	if o.Protocol != ProtocolVLESS {
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
