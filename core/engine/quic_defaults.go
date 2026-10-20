package engine

import (
	"fmt"
	"strconv"
	"strings"
)

// QUIC tuning defaults: the single source for Hysteria2 and TUIC
// numbers and vocabularies (CENSOR-P3). Plan fields carry zero as
// "unset"; the effective value of an unset field is the constant here,
// never a literal buried in a renderer, so the three engines cannot
// drift apart and a future default change lands in exactly one place.
// Every value below was verified against the pinned binaries by
// config acceptance — sing-box-lx 1.14.3-lx.22 `check`, mihomo
// 1.19.32 `-t`, Xray 26.10.17 `run -test` — and by the render and
// validation tests in this tree. Those checks are real: they are
// what caught the sing-box hop-port spelling the binary rejects
// at load. Live QUIC traffic was NOT verified in the audit
// environment (UDP is blocked there; see the probe note in
// core/engine/interop/hy2tuic_test.go): the traffic matrix in
// that file is the live check, it self-skips where UDP is
// unavailable, and it must be run on a UDP-capable dev machine.
const (
	// DefaultHy2HopIntervalSeconds is the port-hop interval both
	// hopping engines apply when a plan does not pin one. Why 30:
	// it is the documented default of both engines (sing-box
	// hop_interval, mihomo hop-interval) and of the reference
	// Hysteria2 client — the value is taken from the engines, not
	// chosen here, so an unset plan behaves exactly like a native
	// hy2 client (verified on the pins by `check`/`-t` config
	// acceptance, CENSOR-P3).
	DefaultHy2HopIntervalSeconds = 30
	// MinHy2HopIntervalSeconds is the protocol floor for a hop
	// interval. Why 5: the Hysteria2 specification's minimum hop
	// interval; below it the client would rebind UDP sockets faster
	// than NAT mappings settle, and both engines reject it.
	MinHy2HopIntervalSeconds = 5
	// MaxHy2BandwidthMbps bounds a stated Hysteria2 bandwidth cap:
	// above 100 Gbps a cap is a typo, not a tariff. The probe
	// package's brutal calibration clamps to this same constant
	// (probe.brutalMaxMbps aliases it), so a calibrated cap can
	// never be a value plan validation would reject.
	MaxHy2BandwidthMbps = 100000

	// DefaultTUICCongestion is the TUIC congestion controller every
	// TUIC engine runs when a plan does not pin one: BBR.
	DefaultTUICCongestion = "bbr"
	// DefaultTUICHeartbeatSeconds is the TUIC heartbeat interval
	// every TUIC engine applies when a plan does not pin one:
	// sing-box renders heartbeat as a duration, mihomo as
	// heartbeat-interval in milliseconds. Why 10: it is both
	// engines' own default (sing-box tuic heartbeat, mihomo
	// heartbeat-interval 10000ms — read from the pinned binaries'
	// accepted configs, CENSOR-P3) and comfortably inside typical
	// NAT UDP mapping lifetimes (~30s+), so rendering the effective
	// value explicitly changes nothing on the wire today and keeps
	// the engines from drifting if an upstream default moves.
	DefaultTUICHeartbeatSeconds = 10
	// MinTUICHeartbeatSeconds and MaxTUICHeartbeatSeconds bound a
	// pinned TUIC heartbeat: below 1s the keepalive floods the
	// censor-visible path, above 10 minutes it cannot keep a NAT
	// mapping alive, which is its only job.
	MinTUICHeartbeatSeconds = 1
	MaxTUICHeartbeatSeconds = 600
	// DefaultTUICUDPRelayMode is the TUIC UDP relay mode the engines
	// run when a plan does not pin one.
	DefaultTUICUDPRelayMode = "native"
)

// ValidHy2Obfs lists the Hysteria2 obfuscation types the hopping
// engines implement (sing-box obfs.type, mihomo obfs): salamander is
// the Hysteria2 standard, gecko is the sing-box 1.14 addition that
// mihomo 1.19.32 also accepts (verified with `mihomo -t` and
// `sing-box check` on the pinned binaries; live traffic through
// the interop suite was not run in the audit environment and is
// pending a UDP-capable dev machine — see hy2tuic_test.go, which
// self-skips there). Xray implements neither: its
// renderer refuses every obfs value and the FeatureHy2Obfs gate
// keeps obfuscated plans off it at selection time.
var ValidHy2Obfs = map[string]bool{"salamander": true, "gecko": true}

// ValidTUICCongestion lists the TUIC congestion controllers both
// TUIC engines implement. Verification note (CENSOR-P3): mihomo's
// `-t` accepts an unknown controller silently, so this plan-level
// list is the only gate that keeps a typo from becoming a silent
// engine default; sing-box rejects unknown values at config load.
var ValidTUICCongestion = map[string]bool{"bbr": true, "cubic": true, "new_reno": true}

// ValidTUICUDPRelayMode lists the TUIC UDP relay modes both TUIC
// engines implement. mihomo's `-t` likewise accepts an unknown mode
// silently, so the plan gate is load-bearing there too.
var ValidTUICUDPRelayMode = map[string]bool{"native": true, "quic": true}

// EffectiveTUICCongestion resolves a plan's TUIC congestion field to
// the controller the engines will run: the pinned value, or
// DefaultTUICCongestion when unset.
func (o Outbound) EffectiveTUICCongestion() string {
	if o.CongestionControl != "" {
		return o.CongestionControl
	}
	return DefaultTUICCongestion
}

// EffectiveTUICHeartbeatSeconds resolves a plan's TUIC heartbeat
// field to the interval the engines will run, in seconds.
func (o Outbound) EffectiveTUICHeartbeatSeconds() int {
	if o.TUICHeartbeat > 0 {
		return o.TUICHeartbeat
	}
	return DefaultTUICHeartbeatSeconds
}

// HopPortRanges parses the canonical plan hop-port spec
// ("20000-30000,40000") into inclusive [lo, hi] ranges. The plan
// syntax is the share-link syntax (mport/ports, dash ranges); each
// renderer translates it into its engine's spelling from these
// ranges — sing-box server_ports wants colon ranges with an explicit
// upper bound ("20000:30000", "40000:40000") and rejects the dash
// form at config load (verified with `sing-box check` on lx.22:
// "bad port range: 20000-30000"), while mihomo takes the plan
// spelling verbatim (verified with `mihomo -t`).
func HopPortRanges(spec string) ([][2]int, error) {
	if strings.TrimSpace(spec) == "" {
		return nil, nil
	}
	var out [][2]int
	for _, part := range strings.Split(spec, ",") {
		part = strings.TrimSpace(part)
		lo, hi, hasRange := strings.Cut(part, "-")
		if !hasRange {
			lo, hi = part, part
		}
		a, errA := strconv.Atoi(strings.TrimSpace(lo))
		b, errB := strconv.Atoi(strings.TrimSpace(hi))
		if errA != nil || errB != nil || a < 1 || b > 65535 || a > b {
			return nil, fmt.Errorf("%q is not a valid hysteria2 hop port spec", spec)
		}
		out = append(out, [2]int{a, b})
	}
	return out, nil
}

// SingBoxHopPorts renders the plan hop-port spec in sing-box
// server_ports spelling: one "lo:hi" string per range, single ports
// expanded to "p:p" (the binary rejects a bare "40000" as a bad port
// range, verified with `sing-box check` on lx.22).
func SingBoxHopPorts(spec string) ([]string, error) {
	ranges, err := HopPortRanges(spec)
	if err != nil {
		return nil, err
	}
	out := make([]string, 0, len(ranges))
	for _, r := range ranges {
		out = append(out, strconv.Itoa(r[0])+":"+strconv.Itoa(r[1]))
	}
	return out, nil
}
