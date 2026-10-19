package xray

import (
	"testing"

	"github.com/levvs-one/sora-client/core/logs"
)

// TestParseLogReadsXrayLines checks real Xray 26.3.27 debug output, including
// access logs.
func TestParseLogReadsXrayLines(t *testing.T) {
	d := &driver{}
	at, level, msg := d.ParseLog(`2026/10/06 15:14:37.122282 [Warning] core: Xray 26.3.27 started`)
	if at.Year() != 2026 || at.Nanosecond() != 122282000 || level != logs.LevelWarning || msg != "core: Xray 26.3.27 started" {
		t.Fatalf("%v %s %q", at, level, msg)
	}
	if _, level, _ := d.ParseLog(`2026/10/06 07:45:44.068049 from tcp:127.0.0.1:38204 accepted tcp:www.gstatic.com:443 [mixed-in >> direct]`); level != logs.LevelDebug {
		t.Fatalf("an access line is debug, got %s", level)
	}
	if _, level, msg := d.ParseLog(`A unified platform for anti-censorship.`); level != logs.LevelInfo || msg == "" {
		t.Fatalf("the banner is kept at info: %s %q", level, msg)
	}
}

func TestConnectionTracesRespectTheDefaultCaptureLevel(t *testing.T) {
	d := &driver{}
	center := logs.New(logs.DefaultSettings())
	for _, message := range []string{
		"proxy/tun: processing from tcp:127.0.0.1:4000 to tcp:example.com:443",
		"proxy/dns: handling DNS traffic to udp:1.1.1.1:53",
		"proxy/vless/outbound: tunneling request to tcp:example.com:443 via example.com:443",
		"transport/internet/tcp: dialing TCP to tcp:example.com:443",
		"app/dispatcher: sniffed domain: example.com",
		"app/dispatcher: taking detour [proxy] for [tcp:example.com:443]",
	} {
		at, level, text := d.ParseLog("2026/10/14 15:41:15.188451 [Info] [1719274203] " + message)
		if level != logs.LevelDebug {
			t.Fatalf("connection detail classified as %s: %s", level, message)
		}
		center.Write(at, level, "xray", text)
	}
	if got := center.Query(logs.Filter{}, 0, 0).Stats.Total; got != 0 {
		t.Fatalf("default log retained %d connection traces", got)
	}
	for _, line := range []string{
		"2026/10/14 15:41:15.188451 [Warning] [1719274203] proxy/tun: connection failed",
		"2026/10/14 15:41:15.188451 [Info] proxy/tun: sora0 up",
	} {
		at, level, text := d.ParseLog(line)
		center.Write(at, level, "xray", text)
	}
	if got := center.Query(logs.Filter{}, 0, 0).Stats.Total; got != 2 {
		t.Fatalf("lost warnings or adapter status: %d", got)
	}
}
