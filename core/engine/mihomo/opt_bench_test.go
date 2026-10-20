package mihomo

import (
	"regexp"
	"strconv"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

var oldMHLine = regexp.MustCompile(`^time="([^"]+)" level=(\w+) msg=("(?:[^"\\]|\\.)*")`)

func oldMH(line string) (time.Time, logs.Level, string) {
	m := oldMHLine.FindStringSubmatch(line)
	if m == nil {
		return time.Time{}, logs.LevelInfo, line
	}
	at, _ := time.Parse(time.RFC3339Nano, m[1])
	level, ok := logs.ParseLevel(m[2])
	if !ok {
		level = logs.LevelInfo
	}
	message, err := strconv.Unquote(m[3])
	if err != nil {
		message = m[3]
	}
	return at, level, message
}

func TestParseLogRegexpParity(t *testing.T) {
	lines := []string{
		`time="2026-10-06T15:14:37.119654768+03:00" level=info msg="Sniffer is closed"`,
		`time="2026-10-06T15:14:38.620076011+03:00" level=debug msg="[Rule] use \"default\" rules"`,
		"panic: unexpected",
		`time="bad" level=warn msg="x"`,
		`time="2026-13-06T15:14:37+03:00" level=error msg="bad month"`,
		`time="2026-10-06T15:14:37Z" level=INFO msg="upper"`,
		`time="2026-10-06T15:14:37Z" level=weird msg="unknown level"`,
		`time="2026-10-06T15:14:37Z" level=info msg="tab\tand\nescapes"`,
		`time="2026-10-06T15:14:37Z" level=info msg="bad \q escape"`,
		`time="2026-10-06T15:14:37Z" level=info msg="unicode Русский текст"`,
		`time="2026-10-06T15:14:37Z" level=info msg=""`,
		`time="2026-10-06T15:14:37Z" level=info msg="unterminated`,
		`time="2026-10-06T15:14:37Z" level=info msg="a" extra="field"`,
		`time="2026-10-06T15:14:37Z" level=info msg="quote at end\"`,
		`time="2026-10-06T15:14:37Z"level=info msg="no space"`,
		`time="2026-10-06T15:14:37Z" level= msg="empty level"`,
		`time="2026-10-06T15:14:37Z" level=info msg="ctrlchar"`,
		`xtime="2026-10-06T15:14:37Z" level=info msg="prefix junk"`,
		`time="2026-10-06T15:14:37Z" level=info msg="hex \x41\x42"`,
		`time="2026-10-06T15:14:37Z" level=info2 msg="level with digit"`,
	}
	for _, line := range lines {
		wantAt, wantLevel, wantMsg := oldMH(line)
		gotAt, gotLevel, gotMsg := driver{}.ParseLog(line)
		if !wantAt.Equal(gotAt) || wantAt.IsZero() != gotAt.IsZero() || wantLevel != gotLevel || wantMsg != gotMsg {
			t.Errorf("line %q:\n old=%v %s %q\n new=%v %s %q", line, wantAt, wantLevel, wantMsg, gotAt, gotLevel, gotMsg)
		}
	}
}

var mhSink int

// Baseline before the hand-written parser: 129 B/op, 2 allocs/op; after: 0/0.
func BenchmarkParseLog(b *testing.B) {
	d := driver{}
	line := `time="2026-10-06T15:14:37.119654768+03:00" level=info msg="Sniffer is closed for domain example.org"`
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		_, l, m := d.ParseLog(line)
		mhSink += int(l) + len(m)
	}
}
