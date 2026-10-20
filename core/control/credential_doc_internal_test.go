package control

import (
	"encoding/json"
	"strconv"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/parser"
)

// legacyCredentialDocument is the pre-opt40 map-based implementation,
// kept verbatim for byte-identity comparison only: the streaming
// builder in credentialDocument must produce exactly the documents the
// map version produced, so vault entries written by either version —
// and read after a downgrade — are indistinguishable.
func legacyCredentialDocument(spec parser.OutboundSpec) ([]byte, error) {
	values := map[string]string{
		"uuid": spec.UUID, "password": spec.Password, "method": spec.Cipher, "user": spec.User,
		"flow": spec.Flow, "public_key": spec.PublicKey, "short_id": spec.ShortID,
		"server_name": spec.ServerName, "fingerprint": spec.Fingerprint, "spider_x": spec.SpiderX,
		"mode": spec.Mode, "path": spec.Path, "host_header": spec.HostHeader,
		"service_name": spec.ServiceName, "alpn": strings.Join(spec.ALPN, ","),
		"security": spec.Security, "encryption": spec.Options["encryption"],
	}
	values["obfs"] = spec.Options["obfs"]
	for _, key := range []string{"obfs_param", "obfs-password", "obfs_password"} {
		if value := spec.Options[key]; value != "" {
			values["obfs_param"] = value
			break
		}
	}
	values["ss_plugin"] = spec.Options["ss_plugin"]
	values["ss_plugin_opts"] = spec.Options["ss_plugin_opts"]
	values["upmbps"] = spec.Options["upmbps"]
	values["downmbps"] = spec.Options["downmbps"]
	for _, key := range []string{"mport", "ports"} {
		if value := spec.Options[key]; value != "" {
			values["hop_ports"] = value
			break
		}
	}
	for _, key := range []string{"hop-interval", "hopinterval"} {
		if value := spec.Options[key]; value != "" {
			values["hop_interval"] = value
			break
		}
	}
	for _, key := range []string{"hop-interval-max", "hopintervalmax"} {
		if value := spec.Options[key]; value != "" {
			values["hop_interval_max"] = value
			break
		}
	}
	for _, key := range []string{"bbr-profile", "bbr_profile"} {
		if value := spec.Options[key]; value != "" {
			values["bbr_profile"] = value
			break
		}
	}
	values["congestion_control"] = spec.Options["congestion_control"]
	values["udp_relay_mode"] = spec.Options["udp_relay_mode"]
	values["token"] = spec.Options["token"]
	values["download_address"] = spec.DownloadAddress
	values["download_port"] = strconv.Itoa(int(spec.DownloadPort))
	if strings.EqualFold(spec.Protocol, "wireguard") {
		key, addresses, peers := wireguardMaterial(spec)
		values["private_key"] = key
		values["addresses"] = strings.Join(addresses, ",")
		if len(peers) > 0 {
			raw, err := json.Marshal(peers)
			if err != nil {
				return nil, err
			}
			values["peers"] = string(raw)
		}
		if awg := amneziaMaterial(spec.Options); len(awg) > 0 {
			raw, err := json.Marshal(awg)
			if err != nil {
				return nil, err
			}
			values["amneziawg"] = string(raw)
		}
	}
	if spec.AllowInsecure {
		values["insecure"] = "1"
	}
	if profile := spec.Options["profile"]; profile != "" {
		packed, err := packProfile(profile)
		if err != nil {
			return nil, err
		}
		values["xray_profile"] = packed
	}
	for key, value := range values {
		if value == "" {
			delete(values, key)
		}
	}
	return json.Marshal(values)
}

func richVLESSSpec(t *testing.T) parser.OutboundSpec {
	t.Helper()
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?type=xhttp&security=reality" +
		"&pbk=Z84J2IelR9ch3k8VtlVhhs5ycBUlXA7wHBWcBrjqnAw&sid=6ba85179e30d4fc2&sni=www.example.com&fp=chrome" +
		"&path=%2Fx&host=cdn.example.com&mode=stream-one&encryption=none&alpn=h2,http%2F1.1#Edge"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("parse rich spec: %v, servers %d", err, len(result.Servers))
	}
	return result.Servers[0]
}

// hopHostHysteria2Spec is a parsed hysteria2 link that carries a Host
// header (the host= query key) together with the hop options (mport
// range and hop intervals). The parser sets HostHeader and the hop
// options for any protocol, so this combination is a real import shape:
// it is the one that separates host_header from the hop_* keys in byte
// order (hop_* < host_header, because 'p' < 's').
func hopHostHysteria2Spec(t *testing.T) parser.OutboundSpec {
	t.Helper()
	link := "hysteria2://pw@edge.example.com:443?mport=20000-30000&hop-interval=30&hop-interval-max=65" +
		"&host=cdn.example.com&sni=www.example.com#Hy2Hop"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("parse hop/host spec: %v, servers %d", err, len(result.Servers))
	}
	return result.Servers[0]
}

// TestCredentialDocumentMatchesLegacyMapForm pins byte-identity of the
// streaming credential document builder against the map implementation
// across the shapes the import pipeline produces, including values that
// exercise every escaping branch (HTML-sensitive bytes, quotes, control
// bytes, non-ASCII and invalid UTF-8).
func TestCredentialDocumentMatchesLegacyMapForm(t *testing.T) {
	specs := []parser.OutboundSpec{
		richVLESSSpec(t),
		hopHostHysteria2Spec(t),
		{},
		{Protocol: "vless", UUID: "u", Password: "p<a>&\"\\\n\t\x01\x7f", Host: "h", Port: 1},
		{Protocol: "vless", Password: "invalid\xffutf8 and ünicode", ServerName: "пример.com"},
		{Protocol: "hysteria2", Password: "pw", Options: map[string]string{
			"upmbps": "100", "downmbps": "200", "mport": "20000-30000", "hop-interval": "30",
			"obfs": "salamander", "obfs-password": "opw", "bbr_profile": "aggressive",
		}},
		{Protocol: "tuic", UUID: "u", Options: map[string]string{"congestion_control": "bbr", "udp_relay_mode": "native", "token": "tok"}},
		{Protocol: "wireguard", Password: "aGVsbG8td29ybGQta2V5LWJhc2U2NC0wMDA=",
			Options: map[string]string{
				"address": "10.0.0.2/32,fd00::2/128", "publickey": "pub=", "presharedkey": "psk=",
				"allowedips": "0.0.0.0/0,::/0", "jc": "5", "jmin": "40", "jmax": "70", "s1": "30", "s2": "50",
				"h1": "111", "h2": "222", "h3": "333", "h4": "444",
			}},
		{Protocol: "wireguard", Peers: []parser.WireGuardPeer{{PublicKey: "pk", Endpoint: "e:1", AllowedIPs: []string{"0.0.0.0/0"}}},
			Options: map[string]string{"privatekey": "priv"}},
		{Protocol: "xray-profile", DisplayName: "P", Options: map[string]string{"profile": `{"outbounds":[{"protocol":"vless"}]}`}},
		{Protocol: "shadowsocks", Cipher: "aes-256-gcm", Password: "pw", AllowInsecure: true,
			Options: map[string]string{"ss_plugin": "v2ray-plugin", "ss_plugin_opts": "tls;host=x.com", "obfs_param": "op"}},
		{Protocol: "vless", DownloadAddress: "dl.example.com", DownloadPort: 8443, ALPN: []string{"h2", "http/1.1"}},
	}
	for i, spec := range specs {
		want, werr := legacyCredentialDocument(spec)
		got, gerr := credentialDocument(spec)
		if (werr == nil) != (gerr == nil) {
			t.Fatalf("spec %d: err mismatch want %v got %v", i, werr, gerr)
		}
		if string(want) != string(got) {
			t.Fatalf("spec %d:\nwant %s\ngot  %s", i, want, got)
		}
	}
}
