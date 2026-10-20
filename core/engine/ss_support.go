package engine

// Per-engine Shadowsocks method support, measured on the pinned builds
// (CENSOR-P4, 2026-10-20): every method below was rendered for each
// engine and accepted or refused by the real binary — sing-box-lx
// 1.14.3-lx.22 `sing-box check`, Xray 26.10.17 `xray run -test`,
// mihomo 1.19.32 `mihomo -t`. The sets are data: when an engine pin
// changes, re-run the matrix and update this file; the gates in
// catalog.go (selection) and in each renderer (fail-closed render)
// consume only this table, never a renderer's private guess.
//
// Measured asymmetries the table encodes:
//   - 2022-blake3-chacha12-poly1305: NO pinned engine implements it
//     (all three refuse it), so a plan naming it fails selection on
//     every engine with the method named instead of dial-failing.
//   - 2022-blake3-chacha8-poly1305: mihomo only.
//   - aes-192-gcm: sing-box and mihomo, not Xray.
//   - The pre-IETF aliases chacha20-poly1305 / xchacha20-poly1305:
//     Xray only; sing-box and mihomo know only the -ietf- spellings.
//   - Stream ciphers and "none"/"plain": Xray dropped them entirely;
//     sing-box and mihomo still carry them (with the warnings in
//     ss.go). The bare "chacha20" stream cipher is mihomo-only.
//
// A method sora does not know at all is in no engine's set: selection
// refuses it everywhere (the plan-level form of the unknown-method
// warning), so an unknown cipher can never reach an engine that would
// misapply or silently substitute it.

import "strings"

// ssMethodEngines maps a normalized method name to the engines whose
// pinned build implements it. Stream ciphers are matched by prefix in
// classifyShadowsocksMethod; their per-engine sets live in
// ssStreamEngines because the variants share one verdict per engine.
var ssMethodEngines = map[string][]Kind{
	// SIP022 (AEAD-2022).
	"2022-blake3-aes-128-gcm":       {KindSingBox, KindXray, KindMihomo},
	"2022-blake3-aes-256-gcm":       {KindSingBox, KindXray, KindMihomo},
	"2022-blake3-chacha20-poly1305": {KindSingBox, KindXray, KindMihomo},
	"2022-blake3-chacha8-poly1305":  {KindMihomo},
	"2022-blake3-chacha12-poly1305": {},
	// SIP004/SIP007 AEAD.
	"aes-128-gcm":             {KindSingBox, KindXray, KindMihomo},
	"aes-192-gcm":             {KindSingBox, KindMihomo},
	"aes-256-gcm":             {KindSingBox, KindXray, KindMihomo},
	"chacha20-ietf-poly1305":  {KindSingBox, KindXray, KindMihomo},
	"xchacha20-ietf-poly1305": {KindSingBox, KindXray, KindMihomo},
	"chacha20-poly1305":       {KindXray},
	"xchacha20-poly1305":      {KindXray},
	// No encryption.
	"none":  {KindSingBox, KindMihomo},
	"plain": {KindSingBox, KindMihomo},
}

// ssStreamEngines maps each deprecated stream-cipher prefix of
// shadowsocksStreamPrefixes to its engines. All measured prefixes are
// carried by sing-box and mihomo and refused by Xray, except the bare
// chacha20/xchacha20 stream forms, which only mihomo still implements.
var ssStreamEngines = map[string][]Kind{
	"chacha20":  {KindMihomo},
	"xchacha20": {KindMihomo},
}

var ssStreamDefaultEngines = []Kind{KindSingBox, KindMihomo}

// ShadowsocksMethodEngines returns the engines whose pinned build
// implements the (normalized) method, and whether sora knows the
// method at all. An empty engine list with known=true means the method
// is real but no pinned engine carries it (today:
// 2022-blake3-chacha12-poly1305).
func ShadowsocksMethodEngines(method string) (engines []Kind, known bool) {
	m := normalizeShadowsocksMethod(method)
	if list, ok := ssMethodEngines[m]; ok {
		return list, true
	}
	if classifyShadowsocksMethod(m) == ssClassStream {
		for _, p := range shadowsocksStreamPrefixes {
			if m == p || strings.HasPrefix(m, p+"-") || strings.HasPrefix(m, p+"8") {
				if list, ok := ssStreamEngines[p]; ok {
					return list, true
				}
				return ssStreamDefaultEngines, true
			}
		}
	}
	return nil, false
}

// SupportsShadowsocksMethod reports whether the pinned build of kind
// implements method. Renderers call it to fail closed on a method the
// engine would refuse at load or silently replace; selection calls it
// through Capabilities.MissingFor so the plan is refused earlier, with
// the same fact.
func SupportsShadowsocksMethod(kind Kind, method string) bool {
	engines, known := ShadowsocksMethodEngines(method)
	if !known {
		return false
	}
	for _, k := range engines {
		if k == kind {
			return true
		}
	}
	return false
}
