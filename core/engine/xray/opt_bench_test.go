package xray

import (
	"regexp"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

var oldLogLine = regexp.MustCompile(`^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?) (?:\[(\w+)\] )?(.*)$`)
var oldTrace = regexp.MustCompile(`^\[\d+\] (?:proxy/|transport/internet/|app/dispatcher:)`)

func oldParse(line string) (time.Time, logs.Level, string) {
	m := oldLogLine.FindStringSubmatch(line)
	if m == nil {
		return time.Time{}, logs.LevelInfo, line
	}
	at, _ := time.ParseInLocation("2006/01/02 15:04:05.999999", m[1], time.Local)
	level, ok := logs.ParseLevel(m[2])
	if !ok {
		level = logs.LevelDebug
	}
	if level == logs.LevelInfo && oldTrace.MatchString(m[3]) {
		level = logs.LevelDebug
	}
	return at, level, m[3]
}

func TestParseLogRegexpParity(t *testing.T) {
	lines := []string{
		"2026/10/06 15:14:37.122282 [Warning] core: Xray 26.3.27 started",
		"2026/10/06 07:45:44.068049 from tcp:127.0.0.1:38204 accepted tcp:www.gstatic.com:443 [mixed-in >> direct]",
		"A unified platform for anti-censorship.",
		"2026/10/14 15:41:15.188451 [Info] [1719274203] proxy/tun: processing",
		"2026/10/14 15:41:15.188451 [Info] [1719274203] app/dispatcher: sniffed",
		"2026/10/14 15:41:15 [Info] proxy/tun: no digits bracket in msg",
		"2026/10/14 15:41:15 [Info] [42] transport/internet/tcp: dialing",
		"2026/10/14 15:41:15 [Info] [42] app/dispatcher/x not colon",
		"2026/13/14 15:41:15 [Error] bad month",
		"2026/02/29 15:41:15 [Error] not a leap year",
		"2024/02/29 15:41:15 [Error] leap year",
		"2026/10/14 24:41:15 [Error] bad hour",
		"2026/10/14 15:41:60 [Error] bad second",
		"2026/10/14 15:41:15.123456789012 [Info] long fraction",
		"2026/10/14 15:41:15. [Info] empty fraction",
		"2026/10/14 15:41:15 [foo bar] bracket with space",
		"2026/10/14 15:41:15 [] empty bracket",
		"2026/10/14 15:41:15 [foo]msg no space after bracket",
		"2026/10/14 15:41:15 ",
		"2026/10/14 15:41:15",
		"2026/1/14 15:41:15 [Info] short month",
		"2026/10/14 15:41:15 [DEBUG] msg",
		"2026/10/14 15:41:15 [debug] msg",
		"2026/10/14 15:41:15 [DeBuG] msg",
		"2026/10/14 15:41:15 [panic] msg",
		"0000/01/01 00:00:00 [Info] epoch",
		"9999/12/31 23:59:59 [Info] end",
		"2026/10/14 15:41:15 [Info] multi\nline",
		"2026/10/14 15:41:15 [Info] trailing\n",
		"2026/04/31 15:41:15 [Info] april 31",
		"1900/02/29 15:41:15 [Info] 1900 not leap",
		"2000/02/29 15:41:15 [Info] 2000 leap",
		"2026/10/14 15:41:15\t[Info] tab separator",
		"2026/10/14  15:41:15 [Info] double space",
	}
	d := &driver{}
	for _, line := range lines {
		wantAt, wantLevel, wantMsg := oldParse(line)
		gotAt, gotLevel, gotMsg := d.ParseLog(line)
		if !wantAt.Equal(gotAt) || wantAt.IsZero() != gotAt.IsZero() || wantLevel != gotLevel || wantMsg != gotMsg {
			t.Errorf("line %q:\n old=%v %s %q\n new=%v %s %q", line, wantAt, wantLevel, wantMsg, gotAt, gotLevel, gotMsg)
		}
	}
}

var xrSink int

// Baselines before the hand-written parser: 136 B/op, 3 allocs/op for both
// line shapes; after: 0/0.
func BenchmarkParseLogTrace(b *testing.B) {
	d := &driver{}
	line := "2026/10/06 15:14:37.123456 [Info] [123456] proxy/vless/outbound: tunneling request to tcp:example.org:443"
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_, l, m := d.ParseLog(line)
		xrSink += int(l) + len(m)
	}
}

func BenchmarkParseLogPlain(b *testing.B) {
	d := &driver{}
	line := "2026/10/06 15:14:37 [Warning] core: Xray started"
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_, l, m := d.ParseLog(line)
		xrSink += int(l) + len(m)
	}
}
