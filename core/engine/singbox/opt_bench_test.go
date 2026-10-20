package singbox

import (
	"regexp"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

var oldSBLine = regexp.MustCompile(`^(TRACE|DEBUG|INFO|WARN|ERROR|FATAL|PANIC)\[\d+\] (.*)$`)

func oldSB(line string) (time.Time, logs.Level, string) {
	m := oldSBLine.FindStringSubmatch(line)
	if m == nil {
		return time.Time{}, logs.LevelInfo, line
	}
	level, _ := logs.ParseLevel(m[1])
	return time.Time{}, level, m[2]
}

func TestParseLogRegexpParity(t *testing.T) {
	lines := []string{
		"INFO[1234] inbound/tun: connection",
		"DEBUG[0002] [1403639248 0ms] dns: lookup",
		"WARN[0010] router: rule-set not ready",
		"TRACE[0] ",
		"ERROR[999999999] x",
		"INFO[] no digits",
		"INFO[12a] mixed",
		"INFO[12]no space",
		"WARNING[12] not a token",
		"INFO [12] space before bracket",
		"info[12] lowercase",
		"PANIC[1] multi\nline",
		"FATAL[1] ",
		"INFO[1] trailing\n",
		"",
		" INFO[1] leading space",
	}
	for _, line := range lines {
		wantAt, wantLevel, wantMsg := oldSB(line)
		gotAt, gotLevel, gotMsg := driver{}.ParseLog(line)
		if wantAt != gotAt || wantLevel != gotLevel || wantMsg != gotMsg {
			t.Errorf("line %q: old=%v %s %q new=%v %s %q", line, wantAt, wantLevel, wantMsg, gotAt, gotLevel, gotMsg)
		}
	}
}

var sbSink int

// Baseline before the hand-written parser: 120 B/op, 3 allocs/op; after: 0/0.
func BenchmarkParseLog(b *testing.B) {
	d := driver{}
	line := "INFO[1234] inbound/tun: connection to example.org:443"
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_, l, m := d.ParseLog(line)
		sbSink += int(l) + len(m)
	}
}
