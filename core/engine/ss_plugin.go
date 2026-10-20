package engine

// Shadowsocks SIP002 plugin knowledge as data (CENSOR-P4).
//
// A plugin name in a plan is a promise: the traffic is obfuscated by
// that plugin before it leaves the client. Before this file, nothing
// validated the promise: any name and any option string passed plan
// validation, Xray's renderer dropped both silently (Xray has no
// SIP002 plugin support at all), and mihomo silently ignored names it
// does not spell its way (an imported "obfs-local" reached mihomo
// verbatim, but mihomo's built-in is named "obfs" — the plan ran
// unobfuscated while the UI showed a plugin).
//
// The catalog below is the single source of truth, measured against
// the pinned sources and binaries (mihomo 1.19.32
// adapter/outbound/shadowsocks.go; sing-box-lx 1.14.3-lx.22
// `sing-box check` on this machine, which resolves obfs-local and
// v2ray-plugin but reports "plugin not found" for gost-plugin and
// shadow-tls because sora ships no such binaries; Xray 26.10.17 has
// no plugin field and ignores unknown keys at load):
//
//   - KnownPlugins is what plan validation accepts. An unknown name
//     fails validation: a plugin sora cannot describe is a plugin
//     whose rendering sora cannot guarantee.
//   - Per engine, a plugin is either built in (mihomo), shipped /
//     resolvable by the engine binary (sing-box-lx: obfs-local,
//     v2ray-plugin), external (needs a plugin binary sora does not
//     ship — never selected, because presence is not probed), or
//     unsupported (Xray: all of them). Selection (catalog.go) and the
//     renderers both consume SSPluginEngines, so a plan is refused at
//     selection with the plugin named, and a hand-forced render fails
//     closed instead of dropping the plugin.
//   - MihomoNames maps a canonical SIP002 name onto the name
//     mihomo's adapter actually matches; the mihomo renderer must
//     translate through it.

import (
	"fmt"
	"net"
	"regexp"
	"strconv"
	"strings"
)

// SSPluginSpec describes one SIP002 plugin sora knows.
type SSPluginSpec struct {
	// Name is the canonical plugin name as it appears in SIP002
	// links and in the sing-box render (plugin binary name).
	Name string
	// MihomoName is the plugin name mihomo's adapter matches, when
	// it differs from Name. Empty means "same as Name".
	MihomoName string
	// Engines lists the engines that carry this plugin with the
	// builds sora ships (see the file comment for what "carry"
	// means per engine). An engine not listed never receives a plan
	// using this plugin through selection, and its renderer refuses.
	Engines []Kind
	// Opts is the option schema IN CANONICAL ORDER: the keys the
	// plugin accepts, in the order CanonicalSSPluginOpts emits
	// them. A key not in the schema fails validation — both real
	// implementations reject or misapply unknown options, so
	// passing one through would be a silent loss. The order is
	// data, so two plans that differ only in option order render
	// byte-identical plugin_opts (CENSOR-P4 "мелочи" §3).
	Opts []ssPluginOpt
	// Required lists option keys (a subset of Opts) that must be
	// present for the plugin to work at all: without one the plan
	// validates but dies inside the engine, or worse, runs with an
	// engine default the plan never chose (kcptun's key). Plan
	// validation refuses a plugin missing a required option, by
	// name (CENSOR-P4 fix M2).
	Required []string
	// MihomoOpts maps a canonical option key onto the key mihomo's
	// plugin-opts struct decodes it under, for every option mihomo
	// carries. A catalog option ABSENT from this map has no mihomo
	// spelling — mihomo's decode silently ignores map keys its
	// struct lacks (measured on the pinned 1.19.32 binary: a bogus
	// key passes `mihomo -t`) — so selection refuses the plan for
	// mihomo and the mihomo renderer fails closed instead of
	// dropping the option (CENSOR-P4 fix M3). Field sets follow the
	// pinned adapter/outbound/shadowsocks.go option structs:
	// simpleObfsOption carries mode/host only, the v2ray/gost
	// structs mode/host/path/tls/mux, shadowTLSOption the
	// sing-shadowtls fields, restlsOption password/host/
	// version-hint/restls-script, kcpTunOption the kcptun config
	// keys verbatim.
	MihomoOpts map[string]string
}

// MihomoOptKey returns the mihomo plugin-opts key for a canonical
// option key, and whether mihomo carries the option at all.
func (s *SSPluginSpec) MihomoOptKey(key string) (string, bool) {
	if s == nil {
		return "", false
	}
	mk, ok := s.MihomoOpts[key]
	return mk, ok
}

// ssPluginOpt is one schema entry: an option key and its value kind.
type ssPluginOpt struct {
	key  string
	kind ssPluginOptKind
}

// optKind returns the schema kind of an option key.
func (s *SSPluginSpec) optKind(key string) (ssPluginOptKind, bool) {
	for _, o := range s.Opts {
		if o.key == key {
			return o.kind, true
		}
	}
	return 0, false
}

// ssPluginOptKind classifies a plugin option value for validation.
type ssPluginOptKind int

const (
	// ssOptFlag is a boolean switch: bare ("tls"), "1"/"0" or
	// "true"/"false".
	ssOptFlag ssPluginOptKind = iota
	// ssOptHost is a hostname or IP literal (a fronting/SNI host).
	ssOptHost
	// ssOptPath is a URL path; it must start with "/".
	ssOptPath
	// ssOptString is free text without separators or controls.
	ssOptString
	// ssOptSecret is a password-like value (masked via PluginOpts in
	// Outbound.appendSecrets); same shape rules as ssOptString.
	ssOptSecret
	// ssOptInt is a non-negative integer.
	ssOptInt
	// ssOptModeWS is the websocket-only mode of v2ray/gost plugins.
	ssOptModeWS
	// ssOptObfsMode is simple-obfs's mode: "http" or "tls".
	ssOptObfsMode
	// ssOptTLSVersion is shadow-tls's version: 2 or 3.
	ssOptTLSVersion
)

// ssPlugins is the plugin catalog. Order is stable for error messages.
var ssPlugins = []SSPluginSpec{
	{
		// simple-obfs. sing-box-lx resolves the obfs-local binary
		// name; mihomo implements it natively as "obfs".
		Name: "obfs-local", MihomoName: "obfs",
		Engines: []Kind{KindSingBox, KindMihomo},
		Opts: []ssPluginOpt{
			{"obfs", ssOptObfsMode},
			{"obfs-host", ssOptHost},
			{"obfs-uri", ssOptPath},
			{"fast-open", ssOptFlag},
		},
		// Without a mode there is no obfuscation at all: the
		// plugin binary refuses to start.
		Required: []string{"obfs"},
		// simpleObfsOption decodes mode and host only: obfs-uri
		// (an http-mode request URI) and fast-open (TCP fast open)
		// have no mihomo field and would be silently ignored.
		MihomoOpts: map[string]string{"obfs": "mode", "obfs-host": "host"},
	},
	{
		Name:    "v2ray-plugin",
		Engines: []Kind{KindSingBox, KindMihomo},
		Opts: []ssPluginOpt{
			{"tls", ssOptFlag},
			{"mux", ssOptFlag},
			{"mode", ssOptModeWS},
			{"host", ssOptHost},
			{"path", ssOptPath},
			{"loglevel", ssOptString},
			{"cert", ssOptString},
			{"key", ssOptString},
			{"certRaw", ssOptString},
			{"keyRaw", ssOptString},
		},
		// v2rayObfsOption decodes mode/host/path/tls/mux (plus ECH
		// and http-upgrade shapes sora's schema does not offer);
		// the standalone binary's loglevel/cert/key options have
		// no field in mihomo's native implementation.
		MihomoOpts: map[string]string{
			"tls": "tls", "mux": "mux", "mode": "mode", "host": "host", "path": "path",
		},
	},
	{
		// mihomo implements gost-plugin natively (websocket obfs
		// with the v2ray-plugin option shape). On sing-box it is an
		// external binary sora does not ship, so sing-box is not a
		// carrying engine.
		Name:    "gost-plugin",
		Engines: []Kind{KindMihomo},
		Opts: []ssPluginOpt{
			{"tls", ssOptFlag},
			{"mux", ssOptFlag},
			{"mode", ssOptModeWS},
			{"host", ssOptHost},
			{"path", ssOptPath},
			{"skip-cert-verify", ssOptFlag},
			{"name-cert-verify", ssOptHost},
			{"fingerprint", ssOptString},
		},
		// gostObfsOption decodes the same five fields as
		// v2rayObfsOption; the verify/fingerprint keys have no
		// field there.
		MihomoOpts: map[string]string{
			"tls": "tls", "mux": "mux", "mode": "mode", "host": "host", "path": "path",
		},
	},
	{
		// mihomo native. The standalone shadow-tls binary would be
		// an external plugin for sing-box; sora does not ship it.
		Name: "shadow-tls", MihomoName: "shadow-tls",
		Engines: []Kind{KindMihomo},
		Opts: []ssPluginOpt{
			{"host", ssOptHost},
			{"password", ssOptSecret},
			{"version", ssOptTLSVersion},
			{"fingerprint", ssOptString},
			{"alpn", ssOptString},
			{"skip-cert-verify", ssOptFlag},
			{"name-cert-verify", ssOptHost},
		},
		// The password IS the shadow-tls authentication: without
		// it the handshake cannot be keyed, the engine default is
		// not a fallback sora may accept on the plan's behalf.
		Required: []string{"password"},
		// shadowTLSOption follows the sing-shadowtls client
		// fields (password/host/version/alpn/fingerprint/
		// skip-cert-verify); name-cert-verify has no field in
		// the plugin struct (it exists only on mihomo's generic
		// TLS options, not in plugin-opts).
		MihomoOpts: map[string]string{
			"host": "host", "password": "password", "version": "version",
			"fingerprint": "fingerprint", "alpn": "alpn", "skip-cert-verify": "skip-cert-verify",
		},
	},
	{
		// mihomo native; its adapter Mode is "restls" while the
		// SIP002 binary name is "restls-plugin".
		Name: "restls-plugin", MihomoName: "restls",
		Engines: []Kind{KindMihomo},
		Opts: []ssPluginOpt{
			{"host", ssOptHost},
			{"password", ssOptSecret},
			{"version-hint", ssOptString},
			{"restls-script", ssOptString},
			{"skip-cert-verify", ssOptFlag},
			{"fingerprint", ssOptString},
			{"name-cert-verify", ssOptHost},
		},
		// Like shadow-tls, the password is the scheme's
		// authentication secret; restls has no anonymous mode.
		Required: []string{"password"},
		// restlsOption decodes password/host/version-hint/
		// restls-script only.
		MihomoOpts: map[string]string{
			"host": "host", "password": "password",
			"version-hint": "version-hint", "restls-script": "restls-script",
		},
	},
	{
		Name: "jls-plugin", MihomoName: "jls",
		Engines: []Kind{KindMihomo},
		Opts: []ssPluginOpt{
			{"host", ssOptHost},
			{"username", ssOptString},
			{"password", ssOptSecret},
			{"alpn", ssOptString},
		},
		// The JLS handshake authenticates with username+password
		// against the fronting host; alpn has no field in
		// mihomo's jls option struct.
		MihomoOpts: map[string]string{
			"host": "host", "username": "username", "password": "password",
		},
	},
	{
		Name:    "kcptun",
		Engines: []Kind{KindMihomo},
		Opts: []ssPluginOpt{
			{"key", ssOptSecret},
			{"crypt", ssOptString},
			{"mode", ssOptString},
			{"conn", ssOptInt},
			{"autoexpire", ssOptInt},
			{"scavengettl", ssOptInt},
			{"mtu", ssOptInt},
			{"ratelimit", ssOptInt},
			{"sndwnd", ssOptInt},
			{"rcvwnd", ssOptInt},
			{"datashard", ssOptInt},
			{"parityshard", ssOptInt},
			{"dscp", ssOptInt},
			{"nocomp", ssOptFlag},
			{"acknodelay", ssOptFlag},
			{"nodelay", ssOptInt},
			{"interval", ssOptInt},
			{"resend", ssOptInt},
			{"nc", ssOptFlag},
			{"sockbuf", ssOptInt},
			{"keepalive", ssOptInt},
		},
		// The key is kcptun's pre-shared secret: without it the
		// client falls back to the kcptun library's built-in
		// default key, which is public knowledge — a plan must
		// never ride on it silently.
		Required: []string{"key"},
		// kcpTunOption mirrors the kcptun client config keys
		// verbatim, so every catalog key carries over unchanged.
		MihomoOpts: map[string]string{
			"key": "key", "crypt": "crypt", "mode": "mode", "conn": "conn",
			"autoexpire": "autoexpire", "scavengettl": "scavengettl", "mtu": "mtu",
			"ratelimit": "ratelimit", "sndwnd": "sndwnd", "rcvwnd": "rcvwnd",
			"datashard": "datashard", "parityshard": "parityshard", "dscp": "dscp",
			"nocomp": "nocomp", "acknodelay": "acknodelay", "nodelay": "nodelay",
			"interval": "interval", "resend": "resend", "nc": "nc",
			"sockbuf": "sockbuf", "keepalive": "keepalive",
		},
	},
}

// SSPluginByName returns the catalog entry for a canonical plugin
// name, or nil when sora does not know the plugin.
func SSPluginByName(name string) *SSPluginSpec {
	for i := range ssPlugins {
		if ssPlugins[i].Name == name {
			return &ssPlugins[i]
		}
	}
	return nil
}

// SSPluginNames lists the known plugin names, for error messages and
// UI pickers.
func SSPluginNames() []string {
	out := make([]string, len(ssPlugins))
	for i, p := range ssPlugins {
		out[i] = p.Name
	}
	return out
}

// SSPluginEngines returns the engines that carry the named plugin
// with the builds sora ships, and whether the plugin is known.
func SSPluginEngines(name string) ([]Kind, bool) {
	spec := SSPluginByName(name)
	if spec == nil {
		return nil, false
	}
	return spec.Engines, true
}

// SupportsSSPlugin reports whether the pinned build of kind carries
// the named plugin (or, for name "", a legacy Obfs mapping — carried
// by sing-box as obfs-local and natively by mihomo, never by Xray).
func SupportsSSPlugin(kind Kind, name string) bool {
	if name == "" {
		name = "obfs-local"
	}
	engines, known := SSPluginEngines(name)
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

// ssPluginOptKey is the option-key shape: a token both plugin
// implementations accept as a key.
var ssPluginOptKey = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_-]*$`)

// ssPluginOptPair is one parsed option: its key, its value, and
// whether the value was spelled with an explicit '='.
type ssPluginOptPair struct {
	key, val string
	hasValue bool
}

// parseSSPluginOpts splits a SIP002 option string ("k=v;k;flag") into
// key/value pairs in input order. Duplicate keys and malformed
// segments are errors: both engines build a map from the string, so a
// duplicate would silently keep only one value.
func parseSSPluginOpts(opts string) ([]ssPluginOptPair, error) {
	if strings.TrimSpace(opts) == "" {
		return nil, nil
	}
	var out []ssPluginOptPair
	seen := map[string]bool{}
	for _, part := range strings.Split(opts, ";") {
		part = strings.TrimSpace(part)
		if part == "" {
			return nil, fmt.Errorf("empty option segment (stray ';')")
		}
		k, v, has := strings.Cut(part, "=")
		k, v = strings.TrimSpace(k), strings.TrimSpace(v)
		if !ssPluginOptKey.MatchString(k) {
			return nil, fmt.Errorf("option key %q is not a valid token", k)
		}
		if seen[k] {
			return nil, fmt.Errorf("option %q is set twice", k)
		}
		seen[k] = true
		if strings.ContainsAny(v, ";\r\n\t\x00") {
			return nil, fmt.Errorf("option %q value contains a separator or control character", k)
		}
		out = append(out, ssPluginOptPair{key: k, val: v, hasValue: has})
	}
	return out, nil
}

// CanonicalSSPluginOpts re-emits a validated option string in the
// plugin's schema order, so the same option SET always produces the
// same string regardless of the order the import link spelled it in:
// sing-box renders this string, and byte-stable renders keep config
// diffs, caches and tests honest. Unknown plugins and unparseable
// strings pass through unchanged — validation owns rejecting them,
// canonicalization never invents a "fixed" string for broken input.
func CanonicalSSPluginOpts(plugin, opts string) string {
	spec := SSPluginByName(plugin)
	if spec == nil {
		return opts
	}
	pairs, err := parseSSPluginOpts(opts)
	if err != nil {
		return opts
	}
	byKey := make(map[string]ssPluginOptPair, len(pairs))
	for _, pr := range pairs {
		byKey[pr.key] = pr
	}
	var b strings.Builder
	emit := func(pr ssPluginOptPair) {
		if b.Len() > 0 {
			b.WriteByte(';')
		}
		b.WriteString(pr.key)
		if pr.hasValue {
			b.WriteByte('=')
			b.WriteString(pr.val)
		}
	}
	emitted := map[string]bool{}
	for _, o := range spec.Opts {
		if pr, ok := byKey[o.key]; ok {
			emit(pr)
			emitted[o.key] = true
		}
	}
	// Keys outside the schema keep input order after the known ones
	// (validation rejects them before any render of a checked plan;
	// this keeps the function total for unchecked callers).
	for _, pr := range pairs {
		if !emitted[pr.key] {
			emit(pr)
		}
	}
	return b.String()
}

// MihomoSSPluginOpts translates a canonical SIP002 option string
// into mihomo's plugin-opts map, driven by the catalog's MihomoOpts
// data — the mihomo renderer contains no per-plugin key knowledge
// of its own. Every option in the string must have a mihomo
// spelling: a key the catalog does not know, or a known key mihomo
// does not carry, is a named error, never a silent drop (mihomo's
// own decode ignores unknown map keys; CENSOR-P4 fix M3). Values
// are typed the way mihomo's structs decode them: flags become
// booleans, integers become ints, the shadow-tls version becomes
// an int. For v2ray-plugin and gost-plugin the mode is forced to
// "websocket" when the plan did not spell one: both mihomo
// adapters accept no other mode and require the key present.
func MihomoSSPluginOpts(plugin, opts string) (map[string]any, error) {
	spec := SSPluginByName(plugin)
	if spec == nil {
		return nil, fmt.Errorf("unknown shadowsocks plugin %q", plugin)
	}
	pairs, err := parseSSPluginOpts(opts)
	if err != nil {
		return nil, fmt.Errorf("shadowsocks plugin %s: plugin_opts: %v", plugin, err)
	}
	out := make(map[string]any, len(pairs))
	for _, kv := range pairs {
		kind, known := spec.optKind(kv.key)
		if !known {
			return nil, fmt.Errorf("shadowsocks plugin %s: unknown option %q", plugin, kv.key)
		}
		mk, carried := spec.MihomoOptKey(kv.key)
		if !carried {
			return nil, fmt.Errorf("shadowsocks plugin %s: option %q has no mihomo spelling and mihomo does not render it", plugin, kv.key)
		}
		switch kind {
		case ssOptFlag:
			out[mk] = kv.val == "" || kv.val == "1" || kv.val == "yes" || strings.EqualFold(kv.val, "true")
		case ssOptInt, ssOptTLSVersion:
			n, err := strconv.Atoi(kv.val)
			if err != nil {
				return nil, fmt.Errorf("shadowsocks plugin %s: option %q value is not an integer", plugin, kv.key)
			}
			out[mk] = n
		default:
			out[mk] = kv.val
		}
	}
	if (plugin == "v2ray-plugin" || plugin == "gost-plugin") && out["mode"] == nil {
		out["mode"] = "websocket"
	}
	return out, nil
}

// validateSSPluginOptValue checks one option value against its kind.
func validateSSPluginOptValue(plugin, key string, kind ssPluginOptKind, v string) error {
	bad := func(format string, args ...any) error {
		args = append([]any{plugin, key}, args...)
		return fmt.Errorf("plugin %s: option %s "+format, args...)
	}
	switch kind {
	case ssOptFlag:
		switch v {
		case "", "0", "1", "true", "false", "yes", "no":
		default:
			return bad("%q is not a boolean flag", v)
		}
	case ssOptHost:
		if v == "" {
			return bad("needs a host value")
		}
		if net.ParseIP(v) == nil {
			if err := validateAWGDomain(v); err != nil {
				return bad("%q is not a valid host: %v", v, err)
			}
		}
	case ssOptPath:
		if !strings.HasPrefix(v, "/") {
			return bad("%q is not an absolute path", v)
		}
	case ssOptInt:
		n, err := strconv.Atoi(v)
		if err != nil || n < 0 {
			return bad("%q is not a non-negative integer", v)
		}
	case ssOptModeWS:
		if v != "" && v != "websocket" {
			return bad("%q is not supported by sora's renderers (only websocket)", v)
		}
	case ssOptObfsMode:
		if v != "http" && v != "tls" {
			return bad("%q is not http or tls", v)
		}
	case ssOptTLSVersion:
		if v != "2" && v != "3" {
			return bad("%q is not 2 or 3", v)
		}
	case ssOptString, ssOptSecret:
		if v == "" {
			return bad("needs a value")
		}
	}
	return nil
}

// validateShadowsocksPlugin is the plan-level fail-closed check for a
// Shadowsocks outbound's plugin fields (explicit Plugin/PluginOpts and
// the legacy Obfs/ObfsParam simple-obfs mapping). It also owns the
// cross-protocol rule: plugin fields on any other protocol are a
// configuration bug every renderer would silently drop.
func validateShadowsocksPlugin(o Outbound) []error {
	var errs []error
	bad := func(format string, args ...any) {
		args = append([]any{o.ID}, args...)
		errs = append(errs, fmt.Errorf("outbound %s: "+format, args...))
	}
	if o.Protocol != ProtocolShadowsocks {
		if o.Plugin != "" || o.PluginOpts != "" {
			bad("shadowsocks plugin %q is set on a %s outbound; plugins belong to shadowsocks", o.Plugin, o.Protocol)
		}
		return errs
	}
	if o.PluginOpts != "" && o.Plugin == "" {
		bad("shadowsocks plugin_opts is set without a plugin")
	}
	if o.Plugin != "" {
		spec := SSPluginByName(o.Plugin)
		if spec == nil {
			bad("unknown shadowsocks plugin %q (known: %s)", o.Plugin, strings.Join(SSPluginNames(), ", "))
			return errs
		}
		pairs, err := parseSSPluginOpts(o.PluginOpts)
		if err != nil {
			bad("shadowsocks plugin %s: plugin_opts: %v", o.Plugin, err)
			return errs
		}
		present := make(map[string]bool, len(pairs))
		for _, kv := range pairs {
			present[kv.key] = true
			kind, ok := spec.optKind(kv.key)
			if !ok {
				bad("shadowsocks plugin %s: unknown option %q", o.Plugin, kv.key)
				continue
			}
			if err := validateSSPluginOptValue(o.Plugin, kv.key, kind, kv.val); err != nil {
				bad("shadowsocks %v", err)
			}
		}
		// Required options are catalog data (spec.Required): a
		// plugin missing one validates its present values cleanly
		// and still cannot work — it would die inside the engine
		// or fall back to an engine default. Name the missing
		// option; never echo any option VALUE (CENSOR-P4 fix M2).
		for _, req := range spec.Required {
			if !present[req] {
				bad("shadowsocks plugin %s: option %q is required", o.Plugin, req)
			}
		}
	}
	// The legacy Obfs mapping is simple-obfs by another name: on a
	// Shadowsocks outbound its only honest values are the simple-obfs
	// modes, and ObfsParam is the obfs-host — it is interpolated into
	// sing-box's plugin_opts string, so a ';' in it would inject
	// extra plugin options the plan never named.
	if o.Plugin == "" && o.Obfs != "" {
		if o.Obfs != "http" && o.Obfs != "tls" {
			bad("shadowsocks obfs %q is not a simple-obfs mode (http or tls); name a SIP002 plugin instead", o.Obfs)
		}
	}
	if strings.ContainsAny(o.ObfsParam, ";\r\n\t\x00") {
		bad("shadowsocks obfs-host contains a separator or control character")
	}
	if o.Plugin == "" && o.Obfs == "" && o.ObfsParam != "" {
		// An obfs-host with no obfs mode renders nowhere: sing-box
		// only emits it alongside a plugin, mihomo only as the native
		// obfs pair. Refuse the dead field instead of dropping it.
		bad("shadowsocks obfs-host is set without an obfs mode or plugin")
	}
	return errs
}
