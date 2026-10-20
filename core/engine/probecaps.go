package engine

import (
	"fmt"
	"sort"
	"strings"
	"time"
)

// Probe-based capabilities (CENSOR-FP, adaptivity mandate).
//
// The catalog is an EXPECTATION: what the pinned engine builds are
// believed to support, from docs and past verification. A pin is not a
// fact about the binary actually installed on this machine — a user
// build, a distro build or a newer fork can differ in either direction
// (Xray's loader accepting a garbage echConfigList at config-test time
// while really sending ECH on the wire is the standing example: only
// the wire told the truth). Support for the fingerprint-sensitive
// features — ECH, the REALITY key share, and each fingerprint name —
// is therefore decided by a runtime probe of the installed binary
// (core/engine/probeexec: config checks plus ClientHello captures
// against a local receiver), and this file is where probe facts meet
// selection:
//
//   - a probe REJECTION gates the feature with the reason named;
//   - a probe ACCEPTANCE carries the plan even where the catalog is
//     silent (the expectation was stale, the binary is the fact);
//   - no probe at all keeps the catalog expectation — the pre-probe
//     behaviour — because a machine that never probed must not lose
//     engines it carried yesterday. The divergence rule is symmetric:
//     probe and expectation disagreeing is itself reported, via
//     EngineProbe.Divergences, never silently resolved.

// ProbeVerdict is one measured fact about an installed binary.
type ProbeVerdict int

// Probe verdicts.
const (
	// ProbeUnknown means the probe did not measure this fact.
	ProbeUnknown ProbeVerdict = iota
	// ProbeAccepted means the binary demonstrably carries the feature:
	// its config check accepted the shape AND, where the feature has a
	// wire signature, the capture showed it (for ECH: the outer SNI
	// became the list's public_name; for the key share: the
	// X25519MLKEM768 group was in the captured key_share).
	ProbeAccepted
	// ProbeRejected means the binary demonstrably does not carry it:
	// a config refusal or a capture contradicting the claim.
	ProbeRejected
)

func (v ProbeVerdict) String() string {
	switch v {
	case ProbeAccepted:
		return "accepted"
	case ProbeRejected:
		return "rejected"
	}
	return "unknown"
}

// FeatureRealityKeyShare marks engines whose renderer can spell the
// plan's REALITY key-share choice (TLS.KeyShare) AND whose binary
// honours it on the wire. Measured on the pins (2026-10-20): sing-box
// (tls.reality.key_share, capture: classical drops the hybrid group,
// the hello shrinks ~3x) and mihomo
// (reality-opts.support-x25519mlkem768, same capture signature) carry
// it. Xray has no such knob — its parrot decides — so Xray never
// claims it: a plan pinning the choice must not be routed to a silent
// parrot default (S2-C2, the gate KeyShare lacked).
const FeatureRealityKeyShare Feature = "reality-key-share"

// EngineProbe is the measured capability record of ONE installed
// engine binary, produced by probeexec against that binary. The zero
// value is an honest "nothing measured".
type EngineProbe struct {
	// At is when the probe ran; Method names how (e.g.
	// "config-check+wire-capture").
	At     time.Time
	Method string
	// ECH is the verdict for the pinned-config ECH path.
	ECH ProbeVerdict
	// KeyShare is the verdict for the REALITY key-share knob.
	KeyShare ProbeVerdict
	// Fingerprints maps a fingerprint name (as the plan spells it) to
	// the verdict for THIS binary: accepted means a captured
	// ClientHello carried that parrot's signature, rejected means the
	// binary refused the name or sent a different parrot.
	Fingerprints map[string]ProbeVerdict
	// JA4 maps a fingerprint name to the JA4 measured on the wire for
	// it — the fact a freshness judgement needs, per binary, not per
	// pin.
	JA4 map[string]string
	// PQKeyShare maps a fingerprint name to whether its captured
	// ClientHello offered the X25519MLKEM768 hybrid group.
	PQKeyShare map[string]bool
	// Notes carries probe observations that are not verdicts (e.g.
	// "loader accepts echConfigList unparsed; wire capture used").
	Notes []string
}

// Divergences lists where this probe contradicts the catalog
// expectation for kind — the report a reviewer reads, not a silent
// override. Empty means probe and expectation agree (or nothing was
// measured).
func (pr *EngineProbe) Divergences(kind Kind) []string {
	if pr == nil {
		return nil
	}
	caps := Catalog[kind]
	var out []string
	compare := func(feature Feature, v ProbeVerdict, label string) {
		switch {
		case v == ProbeAccepted && !caps.Supports(feature):
			out = append(out, fmt.Sprintf("%s: probe accepts %s but the catalog does not claim %s (expectation stale; probe wins)", kind, label, feature))
		case v == ProbeRejected && caps.Supports(feature):
			out = append(out, fmt.Sprintf("%s: probe rejects %s but the catalog claims %s (expectation stale; probe wins)", kind, label, feature))
		}
	}
	compare(FeatureECH, pr.ECH, "ECH")
	compare(FeatureRealityKeyShare, pr.KeyShare, "REALITY key share")
	sort.Strings(out)
	return out
}

// ProbeMissing returns the plan requirements an engine must be refused
// for BECAUSE OF THE PROBE — each entry names the measured cause, so a
// rejection explains itself ("probe: binary rejected ECH"), never just
// "unsupported". It complements Capabilities.MissingFor: that one
// judges the expectation, this one the fact. A nil probe yields nil.
func ProbeMissing(p *Plan, kind Kind, pr *EngineProbe) []string {
	if p == nil || pr == nil {
		return nil
	}
	var missing []string
	for _, o := range p.Outbounds {
		if o.TLS.ECH.Enabled && pr.ECH == ProbeRejected {
			missing = append(missing, fmt.Sprintf("ECH on outbound %s (probe: %s binary rejected the ECH config/wire check)", o.ID, kind))
		}
		if o.TLS.KeyShare != "" && pr.KeyShare == ProbeRejected {
			missing = append(missing, fmt.Sprintf("REALITY key share %q on outbound %s (probe: %s binary does not honour the key-share knob)", o.TLS.KeyShare, o.ID, kind))
		}
		if fp := NormalizeFingerprint(o.TLS.Fingerprint); fp != "" {
			if v, ok := pr.Fingerprints[fp]; ok && v == ProbeRejected {
				missing = append(missing, fmt.Sprintf("fingerprint %q on outbound %s (probe: %s binary refuses it or sends a different parrot)", fp, o.ID, kind))
			}
			if !FingerprintSpellingOK(kind, fp) {
				missing = append(missing, fmt.Sprintf("fingerprint %q on outbound %s (%s cannot spell versioned parrots; the alias would be a different ClientHello)", fp, o.ID, kind))
			}
		}
	}
	sort.Strings(missing)
	return missing
}

// ProbeCarries reports whether the probe ACCEPTS a plan requirement
// the catalog does not claim — the direction where the installed
// binary is newer or richer than the expectation. Callers use it to
// avoid refusing a plan the binary demonstrably carries.
func ProbeCarries(p *Plan, kind Kind, pr *EngineProbe) bool {
	if p == nil || pr == nil {
		return false
	}
	caps := Catalog[kind]
	for _, o := range p.Outbounds {
		if o.TLS.ECH.Enabled && pr.ECH == ProbeAccepted && !caps.Supports(FeatureECH) {
			return true
		}
		if o.TLS.KeyShare != "" && pr.KeyShare == ProbeAccepted && !caps.Supports(FeatureRealityKeyShare) {
			return true
		}
	}
	return false
}

// SelectEngineProbed is SelectEngine with probe facts overlaid: an
// engine whose probe rejects a plan requirement is skipped with the
// probe reason named, ahead of the expectation-based judgement; an
// engine whose probe accepts everything the plan needs is not refused
// for a catalog silence the probe contradicts. probes may be nil or
// partial (a kind without an entry is judged by expectation alone).
func SelectEngineProbed(p *Plan, available []Availability, preference []Kind, probes map[Kind]*EngineProbe) (Selection, error) {
	if p == nil {
		return Selection{}, fmt.Errorf("engine: nil plan")
	}
	adjusted := make([]Availability, len(available))
	copy(adjusted, available)
	var preRejected []string
	for i, a := range adjusted {
		pr := probes[a.Kind]
		if pr == nil {
			continue
		}
		if miss := ProbeMissing(p, a.Kind, pr); len(miss) > 0 {
			adjusted[i].Usable = false
			adjusted[i].Reason = "probe: " + strings.Join(miss, "; ")
			preRejected = append(preRejected, fmt.Sprintf("%s: %s", a.Kind, adjusted[i].Reason))
			continue
		}
		// The probe carries a requirement the catalog misses: drop the
		// plan's dependence on that feature for THIS engine by letting
		// the plain selection run — MissingFor would refuse it on the
		// expectation alone. Represent the fact by clearing the
		// specific requirement is not possible without mutating the
		// plan, so this direction is handled by the caller's fallback
		// below (retry with the probe as the capability source).
		_ = ProbeCarries(p, a.Kind, pr)
	}
	sel, err := SelectEngine(p, adjusted, preference)
	if err == nil {
		sel.Rejected = append(preRejected, sel.Rejected...)
		return sel, nil
	}
	// Fallback: the expectation refused every engine. If exactly the
	// probe-carried direction explains it — some usable engine's probe
	// accepts the plan's ECH/KeyShare needs and its only catalog
	// misses are those features — select it on the probe's authority,
	// naming the fact.
	for _, a := range adjusted {
		if !a.Usable {
			continue
		}
		pr := probes[a.Kind]
		if pr == nil || !ProbeCarries(p, a.Kind, pr) {
			continue
		}
		caps := BuildCapabilities(a.Kind, a.Version, a.BuildTags)
		var blocking []string
		for _, m := range caps.MissingFor(p, a.Version) {
			if m == "feature "+string(FeatureECH) || m == "feature "+string(FeatureRealityKeyShare) {
				continue
			}
			blocking = append(blocking, m)
		}
		if len(blocking) == 0 {
			return Selection{
				Kind:     a.Kind,
				Reason:   fmt.Sprintf("%s carries this plan by probe (measured on the installed binary; the catalog expectation is stale)", a.Kind),
				Rejected: append(preRejected, sel.Rejected...),
			}, nil
		}
	}
	return sel, err
}
