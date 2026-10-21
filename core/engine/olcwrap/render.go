package olcwrap

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// yamlParam maps one share-link parameter to its YAML leaf
// (SPEC §3.2). str marks the string enums (codec, qr_recovery);
// every other parameter is a decimal integer.
type yamlParam struct {
	uri  string
	yaml string
	str  bool
}

// transportSections is the URI→YAML dictionary, in the canonical
// order the golden renders pin. Sections and keys not listed here
// are never rendered: the sidecar's YAML loader is strict
// (KnownFields), so an invented key fails the session, and an
// unknown link parameter — preserved in the credential document for
// forward compatibility — has no YAML spelling to render into.
var transportSections = map[string]struct {
	section string
	params  []yamlParam
}{
	"vp8channel": {"vp8", []yamlParam{
		{uri: "vp8-fps", yaml: "fps"},
		{uri: "vp8-batch", yaml: "batch_size"},
	}},
	"seichannel": {"sei", []yamlParam{
		{uri: "fps", yaml: "fps"},
		{uri: "batch", yaml: "batch_size"},
		{uri: "frag", yaml: "fragment_size"},
		{uri: "ack-ms", yaml: "ack_timeout_ms"},
	}},
	"videochannel": {"video", []yamlParam{
		{uri: "video-w", yaml: "width"},
		{uri: "video-h", yaml: "height"},
		{uri: "video-fps", yaml: "fps"},
		{uri: "video-codec", yaml: "codec", str: true},
		{uri: "video-qr-size", yaml: "qr_size"},
		{uri: "video-qr-recovery", yaml: "qr_recovery", str: true},
		{uri: "video-tile-module", yaml: "tile_module"},
		{uri: "video-tile-rs", yaml: "tile_rs"},
	}},
}

// RenderYAML renders the sidecar configuration for one tunnel in
// client mode ("cnc"): provider, room, key, transport, the plan
// resolver and the authenticated loopback listener, plus the
// transport's own section holding exactly the parameters the plan
// carries (the session layer applies its defaults to the rest —
// the same defaults the import layer canonicalized against).
//
// The output is deterministic (fixed key order, dictionary order
// inside sections) and contains only keys of the strict upstream
// schema. String values are double-quoted via strconv.Quote: its
// escapes are a subset of YAML's double-quoted escapes, and quoting
// everything keeps room ids that are URLs — or contain ':' or '#'
// — from corrupting the document.
func RenderYAML(cfg Config, lis Listener) ([]byte, error) {
	if cfg.Mode != "" && cfg.Mode != "cnc" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyOlcrtcServerMode,
			"olcrtc: mode %q refused: sora renders client (\"cnc\") configurations only", cfg.Mode)
	}
	var b strings.Builder
	b.WriteString("mode: cnc\n")
	b.WriteString("auth:\n")
	fmt.Fprintf(&b, "  provider: %s\n", strconv.Quote(cfg.Provider))
	if cfg.AuthToken != "" {
		fmt.Fprintf(&b, "  token: %s\n", strconv.Quote(cfg.AuthToken))
	}
	b.WriteString("room:\n")
	fmt.Fprintf(&b, "  id: %s\n", strconv.Quote(cfg.Room))
	if cfg.Channel != "" {
		fmt.Fprintf(&b, "  channel: %s\n", strconv.Quote(cfg.Channel))
	}
	b.WriteString("crypto:\n")
	fmt.Fprintf(&b, "  key: %s\n", strconv.Quote(cfg.KeyHex))
	b.WriteString("net:\n")
	fmt.Fprintf(&b, "  transport: %s\n", strconv.Quote(cfg.Transport))
	fmt.Fprintf(&b, "  dns: %s\n", strconv.Quote(cfg.DNS))
	b.WriteString("socks:\n")
	b.WriteString("  host: \"127.0.0.1\"\n")
	fmt.Fprintf(&b, "  port: %d\n", lis.Port)
	fmt.Fprintf(&b, "  user: %s\n", strconv.Quote(lis.User))
	fmt.Fprintf(&b, "  pass: %s\n", strconv.Quote(lis.Pass))
	if cfg.EngineName != "" || cfg.EngineURL != "" || cfg.EngineToken != "" {
		b.WriteString("engine:\n")
		if cfg.EngineName != "" {
			fmt.Fprintf(&b, "  name: %s\n", strconv.Quote(cfg.EngineName))
		}
		if cfg.EngineURL != "" {
			fmt.Fprintf(&b, "  url: %s\n", strconv.Quote(cfg.EngineURL))
		}
		if cfg.EngineToken != "" {
			fmt.Fprintf(&b, "  token: %s\n", strconv.Quote(cfg.EngineToken))
		}
	}
	if sec, ok := transportSections[cfg.Transport]; ok {
		var lines []string
		for _, p := range sec.params {
			v, present := cfg.Params[p.uri]
			if !present {
				continue
			}
			if p.str {
				lines = append(lines, fmt.Sprintf("  %s: %s", p.yaml, strconv.Quote(v)))
				continue
			}
			n, err := strconv.Atoi(v)
			if err != nil {
				return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeyOlcrtcInvalid,
					"olcrtc: parameter %s=%q is not a decimal integer", p.uri, v)
			}
			lines = append(lines, fmt.Sprintf("  %s: %d", p.yaml, n))
		}
		if len(lines) > 0 {
			b.WriteString(sec.section + ":\n")
			b.WriteString(strings.Join(lines, "\n") + "\n")
		}
	}
	return []byte(b.String()), nil
}

// PlanResolver derives the one resolver the sidecar may use from
// the plan — never the binary's own 8.8.8.8 default, which the
// rendered net.dns always overrides:
//
//  1. the plan's first plain (UDP) or TCP resolver, verbatim as
//     host:port (port 53 when the plan leaves it unset);
//  2. otherwise the host of the plan's first resolver of any other
//     transport, on port 53 — the resolver operator is the plan's
//     choice even when its transport (DoH/DoT) is not one the
//     sidecar's plain resolver can speak;
//  3. otherwise the host's first nameserver from /etc/resolv.conf
//     (what "system DNS" means on the platforms that have one);
//  4. otherwise an honest error: a plan with no resolver anywhere
//     cannot lend the sidecar one.
func PlanResolver(p *engine.Plan) (string, error) {
	if p == nil {
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyOlcrtcInvalid, "olcrtc: no plan to take a resolver from")
	}
	var fallback string
	for _, s := range p.DNS.Servers {
		if s.Transport == engine.DNSSystem || s.Address == "" || s.Address == "system" {
			continue
		}
		port := s.Port
		if port == 0 {
			port = 53
		}
		switch s.Transport {
		case engine.DNSPlain, engine.DNSTCP:
			return net.JoinHostPort(s.Address, strconv.Itoa(int(port))), nil
		}
		if fallback == "" {
			fallback = net.JoinHostPort(s.Address, "53")
		}
	}
	if fallback != "" {
		return fallback, nil
	}
	if ns := systemNameserver(); ns != "" {
		return net.JoinHostPort(ns, "53"), nil
	}
	return "", errs.Newf(errs.CodeInvalidArgument, errs.KeyOlcrtcInvalid,
		"olcrtc: the plan carries no resolver and the host names none, so the sidecar would fall back to its own default")
}

// systemNameserver returns the first nameserver of /etc/resolv.conf,
// or "" where there is none (including non-Linux hosts, whose
// resolver configuration has no such file).
func systemNameserver() string {
	raw, err := os.ReadFile("/etc/resolv.conf") //nolint:gosec // a fixed system path, read-only
	if err != nil {
		return ""
	}
	for _, line := range strings.Split(string(raw), "\n") {
		fields := strings.Fields(line)
		if len(fields) == 2 && fields[0] == "nameserver" && net.ParseIP(fields[1]) != nil {
			return fields[1]
		}
	}
	return ""
}
