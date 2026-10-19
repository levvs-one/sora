// Package wgobfusc is the R&D catalog (topic 5/20) of public, open
// WireGuard obfuscation techniques used by commercial VPN clients.
//
// It contains no rendering logic: it models each technique, its public
// source, and whether sora's engines can express it with configuration
// alone (no forked protocol, no provider-side daemon). The renderer work
// that consumes this catalog is specified in
// reports/WG-OBFUSCATION-RD.md and is intentionally not wired here.
package wgobfusc

// Engine is one of sora's pluggable cores.
type Engine string

const (
	EngineSingBox Engine = "sing-box"
	EngineXray    Engine = "xray"
	EngineMihomo  Engine = "mihomo"
)

// Engines lists every engine the catalog evaluates.
func Engines() []Engine { return []Engine{EngineSingBox, EngineXray, EngineMihomo} }

// Support describes how far an engine can express a technique with
// configuration alone, against the engine versions sora verifies
// (sing-box >= 1.12, mihomo >= 1.19, Xray >= 26.3.27).
type Support int

const (
	// Unsupported cannot be expressed on this engine at all.
	Unsupported Support = iota
	// Partial can be expressed but with caveats (extra hop, MTU loss,
	// needs server cooperation, or behaviour unverified).
	Partial
	// Supported can be expressed purely client-side via engine config.
	Supported
)

// Technique is one public obfuscation trick.
type Technique struct {
	// ID is a stable slug used by tests and the spec.
	ID string
	// Name is the human name, e.g. "UDP-over-TCP".
	Name string
	// Summary explains the trick in one or two sentences.
	Summary string
	// Sources are public references (vendor blogs, docs, open repos).
	Sources []string
	// NeedsServerSide is true when the VPN server must cooperate
	// (dedicated obfuscation endpoint); false when the trick is
	// purely client-side against a stock WireGuard server.
	NeedsServerSide bool
	// Support maps each engine to its config-level capability.
	Support map[Engine]Support
	// Note explains the Partial/Unsupported verdicts.
	Note string
}

// SupportedOn reports the capability level of engine e for technique t.
func (t Technique) SupportedOn(e Engine) Support {
	s, ok := t.Support[e]
	if !ok {
		return Unsupported
	}
	return s
}

// Catalog returns the full list of public techniques. The order is
// stable: cheapest client-side wins first.
func Catalog() []Technique {
	return []Technique{
		{
			ID:   "udp-over-tcp",
			Name: "UDP-over-TCP",
			Summary: "Wrap WireGuard UDP datagrams in a TCP stream (Mullvad " +
				"\"UDP-over-TCP\" on ports 80/443/5001). Survives networks " +
				"that block or throttle UDP; adds TCP-in-TCP meltdown risk " +
				"on lossy links.",
			Sources: []string{
				"https://mullvad.net/en/help/connecting-to-mullvad-vpn-from-restrictive-locations",
				"https://mullvad.net/en/blog/removing-openvpn-from-the-mullvad-vpn-app",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Partial,
				EngineXray:    Unsupported,
				EngineMihomo:  Unsupported,
			},
			Note: "No engine ships a generic UDP-over-TCP dialer for " +
				"WireGuard. sing-box can approximate it via a wireguard " +
				"endpoint detouring through a TCP-based outbound, but the " +
				"far side must decapsulate; Xray/mihomo WG paths are UDP-only.",
		},
		{
			ID:   "wg-over-shadowsocks",
			Name: "WireGuard inside Shadowsocks",
			Summary: "Tunnel WireGuard UDP packets through a Shadowsocks " +
				"UDP relay (Mullvad \"Shadowsocks\" obfuscation, PIA " +
				"Shadowsocks+Multi-Hop). The outer layer looks like " +
				"Shadowsocks, hiding the WireGuard signature from DPI.",
			Sources: []string{
				"https://mullvad.net/en/help/connecting-to-mullvad-vpn-from-restrictive-locations",
				"https://www.ivpn.net/blog/v2ray-obfuscation-available-all-ivpn-platforms/",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Supported,
				EngineXray:    Partial,
				EngineMihomo:  Supported,
			},
			Note: "sing-box: wireguard endpoint honors dialer_proxy, so it " +
				"can route its UDP through a Shadowsocks outbound. mihomo: " +
				"dialer-proxy works on wireguard proxies. Xray: wireguard " +
				"outbound ignores stream-level dialerProxy for its UDP " +
				"socket in practice; verify per Xray release before relying " +
				"on it.",
		},
		{
			ID:   "wg-over-v2ray",
			Name: "WireGuard inside V2Ray (VMess/TCP or VMess/QUIC)",
			Summary: "IVPN's open approach: wrap WireGuard in V2Ray VMess " +
				"so the flow looks like HTTPS web traffic or QUIC. Works " +
				"in single-hop and multihop.",
			Sources: []string{
				"https://www.ivpn.net/blog/v2ray-obfuscation-available-all-ivpn-platforms/",
				"https://www.privacyguides.org/news/2025/11/28/ivpn-announces-v2ray-obfuscation-on-android/",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Supported,
				EngineXray:    Partial,
				EngineMihomo:  Unsupported,
			},
			Note: "sing-box: same dialer_proxy/detour mechanism as " +
				"Shadowsocks, detouring into a vmess outbound. Xray has the " +
				"same UDP-socket caveat as above. mihomo has no VMess " +
				"detour primitive for wireguard proxies.",
		},
		{
			ID:   "port-agility",
			Name: "Port agility (443/53, user-chosen port)",
			Summary: "Run WireGuard on ports censors hesitate to block " +
				"(Mullvad lets users pick the WireGuard port; Shadowsocks " +
				"obfuscation defaults to 443). Purely operational: the " +
				"client only needs to allow the endpoint port override.",
			Sources: []string{
				"https://mullvad.net/en/help/connecting-to-mullvad-vpn-from-restrictive-locations",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Supported,
				EngineXray:    Supported,
				EngineMihomo:  Supported,
			},
			Note: "All engines take the peer endpoint from config; sora " +
				"only needs a plan-level port override. Zero crypto risk.",
		},
		{
			ID:   "multihop-wg",
			Name: "Multihop over WireGuard (nested chains)",
			Summary: "Route WireGuard through a first hop (Mullvad " +
				"Multihop, NordVPN Double VPN, Proton Secure Core). In " +
				"sora this is the generic proxy-chain mechanism; a " +
				"Shadowsocks/VLESS entry hop doubles as obfuscation.",
			Sources: []string{
				"https://www.ivpn.net/blog/v2ray-obfuscation-available-all-ivpn-platforms/",
			},
			NeedsServerSide: false,
			Support: map[Engine]Support{
				EngineSingBox: Supported,
				EngineXray:    Partial,
				EngineMihomo:  Supported,
			},
			Note: "sora already renders Via as dialer_proxy (sing-box) / " +
				"dialerProxy (Xray) / dialer-proxy (mihomo). Same Xray " +
				"UDP-socket caveat as wg-over-shadowsocks applies.",
		},
		{
			ID:   "header-scrambling",
			Name: "Header scrambling (LWO-style)",
			Summary: "Scramble the WireGuard packet header per packet " +
				"(Mullvad LWO: cheap, near-zero overhead alternative to " +
				"Shadowsocks). Requires a matching server side; not " +
				"replicable against stock WireGuard servers.",
			Sources: []string{
				"https://mullvad.net/en/blog/2025/11/12/introducing-lightweight-wireguard-obfuscation",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Unsupported,
				EngineXray:    Unsupported,
				EngineMihomo:  Unsupported,
			},
			Note: "Mullvad's LWO lives in their GotaTun fork; the wire " +
				"format is provider-specific. sora must not reimplement it " +
				"against third-party servers: both ends must agree.",
		},
		{
			ID:   "wg-in-quic-masque",
			Name: "WireGuard inside QUIC (MASQUE)",
			Summary: "Wrap WireGuard UDP in QUIC via MASQUE so the flow " +
				"is indistinguishable from HTTP/3 browsing (Mullvad QUIC " +
				"obfuscation). Strongest DPI camouflage of the catalog.",
			Sources: []string{
				"https://reclaimthenet.org/mullvad-vpn-wireguard-quic-masque-bypass-censorship",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Unsupported,
				EngineXray:    Unsupported,
				EngineMihomo:  Unsupported,
			},
			Note: "No sora engine has a MASQUE/HTTP-3 CONNECT-UDP client " +
				"for WireGuard. Track upstream; do not hand-roll QUIC " +
				"tunneling.",
		},
		{
			ID:   "pq-psk",
			Name: "Post-quantum PSK (Rosenpass-style)",
			Summary: "Run a post-quantum KEM alongside WireGuard and feed " +
				"the result into WireGuard's pre-shared-key slot " +
				"(Mullvad quantum-resistant tunnels; Rosenpass: Classic " +
				"McEliece + ML-KEM, PSK rotation every 2 min). Protects " +
				"recorded traffic against future quantum decryption.",
			Sources: []string{
				"https://mullvad.net/en/blog/2022/7/11/experimental-post-quantum-safe-vpn-tunnels",
				"https://github.com/rosenpass/rosenpass",
				"https://netbird.io/knowledge-hub/how-we-integrated-rosenpass",
				"https://www.webpronews.com/surfshark-completes-quantum-proof-wireguard-with-ml-dsa-authentication/",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Partial,
				EngineXray:    Partial,
				EngineMihomo:  Partial,
			},
			Note: "All engines accept a PSK per peer today, so the only " +
				"missing piece is a PQ KEM daemon (Rosenpass is Apache-2.0/" +
				"MIT) plus peer support. Surfshark/NordVPN ship the same " +
				"PSK-slot pattern (ML-KEM).",
		},
		{
			ID:   "traffic-shaping",
			Name: "Traffic shaping (DAITA-style padding)",
			Summary: "Pad packets to constant sizes and inject cover " +
				"traffic in both directions to defeat AI-guided traffic " +
				"analysis (Mullvad DAITA, built with Karlstad University " +
				"on the open-source Maybenot framework). Orthogonal to " +
				"obfuscation: hides *what* you do, not *that* you VPN.",
			Sources: []string{
				"https://mullvad.net/en/blog/tag/features?ref=devilreef.net&page=2",
				"https://techradar.com/vpn/ai-surveillance-is-on-the-horizon-but-mullvad-vpn-might-have-a-fix",
			},
			NeedsServerSide: true,
			Support: map[Engine]Support{
				EngineSingBox: Unsupported,
				EngineXray:    Unsupported,
				EngineMihomo:  Unsupported,
			},
			Note: "DAITA lives in Mullvad's GotaTun/talpid stack and needs " +
				"a cooperating server for the cover traffic. The Maybenot " +
				"framework is open, but client-only shaping without server " +
				"support is research-grade; do not ship a home-grown " +
				"traffic morpher without analysis.",
		},
	}
}

// ByID returns the technique with the given ID, or nil.
func ByID(id string) *Technique {
	for i := range catalog {
		if catalog[i].ID == id {
			return &catalog[i]
		}
	}
	return nil
}

var catalog = Catalog()

// ClientSideOnly returns techniques that work against a stock WireGuard
// server with no provider cooperation.
func ClientSideOnly() []Technique {
	out := make([]Technique, 0, len(catalog))
	for _, t := range catalog {
		if !t.NeedsServerSide {
			out = append(out, t)
		}
	}
	return out
}

// ExpressibleOn returns techniques the engine can express with config
// alone at at least the given support level.
func ExpressibleOn(e Engine, min Support) []Technique {
	out := make([]Technique, 0, len(catalog))
	for _, t := range catalog {
		if t.SupportedOn(e) >= min {
			out = append(out, t)
		}
	}
	return out
}
