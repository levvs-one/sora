package control

import (
	"net/url"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/parser"
)

// TestHysteria2TuningSurvivesTheVault checks that bandwidth caps, hop
// ports, and the hop interval travel from the import link through the
// credential vault to the engine outbound, where they switch the engine
// from BBR to Brutal congestion control and enable port hopping.
func TestHysteria2TuningSurvivesTheVault(t *testing.T) {
	link := "hysteria2://secret@example.com:443?upmbps=20&downmbps=100" +
		"&mport=20000-30000%2C40000&hop-interval=30&obfs=salamander&obfs-password=obfssecret&sni=example.com#H2"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.UpMbps != 20 || o.DownMbps != 100 {
		t.Errorf("bandwidth caps = %d/%d, want 20/100", o.UpMbps, o.DownMbps)
	}
	if o.HopPorts != "20000-30000,40000" || o.HopInterval != 30 {
		t.Errorf("hop tuning = %q/%d, want %q/30", o.HopPorts, o.HopInterval, "20000-30000,40000")
	}
	if o.Obfs != "salamander" || o.ObfsParam != "obfssecret" {
		t.Errorf("salamander obfs = %q/%q", o.Obfs, o.ObfsParam)
	}
	// Garbage tuning parameters must degrade to "unset", not wedge the plan.
	bad, err := parser.LinkParser{}.Parse([]byte("hysteria2://secret@example.com:443?upmbps=abc&hop-interval=-5#H2"))
	if err != nil || len(bad.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", bad, err)
	}
	document, err = credentialDocument(bad.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	values, err = parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	o = engine.Outbound{}
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.UpMbps != 0 || o.HopInterval != 0 {
		t.Errorf("garbage tuning must degrade to unset, got up=%d interval=%d", o.UpMbps, o.HopInterval)
	}
}

// TestTUICTuningSurvivesTheVault checks that the congestion controller,
// UDP relay mode, and the v4 token reach the engine outbound.
func TestTUICTuningSurvivesTheVault(t *testing.T) {
	link := "tuic://123e4567-e89b-12d3-a456-426614174000:pass@example.com:443" +
		"?congestion_control=cubic&udp_relay_mode=quic&heartbeat=25#TUIC"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	document, err := credentialDocument(result.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.CongestionControl != "cubic" || o.UDPRelayMode != "quic" {
		t.Errorf("tuic tuning = %q/%q, want cubic/quic", o.CongestionControl, o.UDPRelayMode)
	}
	if o.TUICHeartbeat != 25 {
		t.Errorf("tuic heartbeat = %d, want 25 (CENSOR-P3 vault round-trip)", o.TUICHeartbeat)
	}
	if o.Password != "pass" {
		t.Errorf("tuic v5 password = %q, want pass", o.Password)
	}

	v4, err := parser.LinkParser{}.Parse([]byte("tuic://example.com:443?token=v4secret#TUICv4"))
	if err != nil || len(v4.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", v4, err)
	}
	document, err = credentialDocument(v4.Servers[0])
	if err != nil {
		t.Fatal(err)
	}
	values, err = parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	o = engine.Outbound{}
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.Token != "v4secret" {
		t.Errorf("tuic v4 token = %q, want v4secret", o.Token)
	}
}

// TestDownloadSplitSurvivesTheVault checks the end-to-end producer for
// the XHTTP up/down split (D1): the link's extra= JSON reaches the
// parser's OutboundSpec, travels through the credential vault, and
// lands in engine.Transport.DownloadAddress/DownloadPort, where the
// Xray renderer and plan validation honour it.
func TestDownloadSplitSurvivesTheVault(t *testing.T) {
	link := "vless://123e4567-e89b-12d3-a456-426614174000@up.example.com:443" +
		"?type=xhttp&security=tls" +
		"&extra=" + url.QueryEscape(`{"downloadSettings":{"address":"down.example.com","port":8443}}`) +
		"#X"
	result, err := parser.LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	spec := result.Servers[0]
	if spec.DownloadAddress != "down.example.com" || spec.DownloadPort != 8443 {
		t.Fatalf("parser spec = %q:%d, want down.example.com:8443", spec.DownloadAddress, spec.DownloadPort)
	}
	document, err := credentialDocument(spec)
	if err != nil {
		t.Fatal(err)
	}
	values, err := parseCredential(document)
	if err != nil {
		t.Fatal(err)
	}
	var o engine.Outbound
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.Transport.DownloadAddress != "down.example.com" || o.Transport.DownloadPort != 8443 {
		t.Errorf("transport split = %q:%d, want down.example.com:8443",
			o.Transport.DownloadAddress, o.Transport.DownloadPort)
	}
	// A forged credential document cannot smuggle an invalid port: the
	// port is re-bounded on the way in.
	values["download_port"] = "99999"
	o = engine.Outbound{}
	if err := applyCredential(&o, values); err != nil {
		t.Fatal(err)
	}
	if o.Transport.DownloadPort != 0 {
		t.Errorf("forged port 99999 survived as %d, want 0", o.Transport.DownloadPort)
	}
}
