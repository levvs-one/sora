package xray

import (
	"regexp"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

// logLine matches Xray output. Unleveled access logs count as debug so default
// capture excludes connection records.
var logLine = regexp.MustCompile(`^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?) (?:\[(\w+)\] )?(.*)$`)

// Xray emits per-flow routing and dialing at Info. Keep those traces available
// at Debug without flooding the default journal; preserve warnings and startup.
var connectionTrace = regexp.MustCompile(`^\[\d+\] (?:proxy/|transport/internet/|app/dispatcher:)`)

// ParseLog reads one Xray output line. Xray writes local time.
func (*driver) ParseLog(line string) (time.Time, logs.Level, string) {
	m := logLine.FindStringSubmatch(line)
	if m == nil {
		return time.Time{}, logs.LevelInfo, line
	}
	at, _ := time.ParseInLocation("2006/01/02 15:04:05.999999", m[1], time.Local)
	level, ok := logs.ParseLevel(m[2])
	if !ok {
		level = logs.LevelDebug
	}
	if level == logs.LevelInfo && connectionTrace.MatchString(m[3]) {
		level = logs.LevelDebug
	}
	return at, level, m[3]
}
