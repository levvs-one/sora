package xray

import (
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

// ParseLog reads one Xray output line. Xray writes local time.
//
// This is a hand-written equivalent of the former regexp pair
// `^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?) (?:\[(\w+)\] )?(.*)$`
// plus the connection-trace regexp below: together they cost three
// allocations for every engine line, the hottest input path in the core.
// The fallbacks and edge cases match the regexps exactly, including the
// rejection of a message containing a newline, and a timestamp the
// standard parser refuses (month 13, day 30 of February, …) yielding the
// zero time while the level and message still parse, as the ignored
// ParseInLocation error did.
func (*driver) ParseLog(line string) (time.Time, logs.Level, string) {
	stamp, rest, ok := scanTimestamp(line)
	if !ok {
		return time.Time{}, logs.LevelInfo, line
	}
	levelName := ""
	if strings.HasPrefix(rest, "[") {
		if name, tail, ok := scanBracketLevel(rest); ok {
			levelName, rest = name, tail
		}
	}
	if strings.IndexByte(rest, '\n') >= 0 {
		return time.Time{}, logs.LevelInfo, line
	}
	level, found := logs.ParseLevel(levelName)
	if !found {
		level = logs.LevelDebug
	}
	if level == logs.LevelInfo && isConnectionTrace(rest) {
		level = logs.LevelDebug
	}
	return stamp, level, rest
}

// scanTimestamp splits the leading "2006/01/02 15:04:05[.fraction] " from
// the line and converts it with the same range checks time.Parse applies;
// an out-of-range field yields the zero time, not a rejection.
func scanTimestamp(line string) (time.Time, string, bool) {
	// Fixed layout: 19 bytes of digits and separators, then a space, with
	// an optional ".digits" fraction before that space.
	if len(line) < 20 {
		return time.Time{}, "", false
	}
	for i := 0; i < 19; i++ {
		c := line[i]
		switch i {
		case 4, 7:
			if c != '/' {
				return time.Time{}, "", false
			}
		case 10:
			if c != ' ' {
				return time.Time{}, "", false
			}
		case 13, 16:
			if c != ':' {
				return time.Time{}, "", false
			}
		default:
			if c < '0' || c > '9' {
				return time.Time{}, "", false
			}
		}
	}
	rest := line[19:]
	nsec := 0
	if strings.HasPrefix(rest, ".") {
		i := 1
		for i < len(rest) && rest[i] >= '0' && rest[i] <= '9' {
			if i <= 9 { // further digits are truncated, as time.Parse does
				nsec = nsec*10 + int(rest[i]-'0')
			}
			i++
		}
		if i == 1 {
			return time.Time{}, "", false
		}
		for digits := i - 1; digits < 9; digits++ {
			nsec *= 10
		}
		rest = rest[i:]
	}
	if !strings.HasPrefix(rest, " ") {
		return time.Time{}, "", false
	}
	year := atoi(line[0:4])
	month := atoi(line[5:7])
	day := atoi(line[8:10])
	hour := atoi(line[11:13])
	minute := atoi(line[14:16])
	second := atoi(line[17:19])
	if month < 1 || month > 12 || day < 1 || day > daysIn(time.Month(month), year) ||
		hour > 23 || minute > 59 || second > 59 {
		return time.Time{}, rest[1:], true
	}
	return time.Date(year, time.Month(month), day, hour, minute, second, nsec, time.Local), rest[1:], true
}

func atoi(s string) int {
	n := 0
	for i := 0; i < len(s); i++ {
		n = n*10 + int(s[i]-'0')
	}
	return n
}

func daysIn(month time.Month, year int) int {
	switch month {
	case time.February:
		if year%4 == 0 && (year%100 != 0 || year%400 == 0) {
			return 29
		}
		return 28
	case time.April, time.June, time.September, time.November:
		return 30
	}
	return 31
}

// scanBracketLevel reads "[name] " at the start of rest, where name is one
// or more word characters (\w in the former regexp).
func scanBracketLevel(rest string) (string, string, bool) {
	i := 1
	for i < len(rest) && isWordByte(rest[i]) {
		i++
	}
	if i == 1 || i+1 >= len(rest) || rest[i] != ']' || rest[i+1] != ' ' {
		return "", "", false
	}
	return rest[1:i], rest[i+2:], true
}

func isWordByte(c byte) bool {
	return c >= '0' && c <= '9' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c == '_'
}

// isConnectionTrace is the former regexp
// `^\[\d+\] (?:proxy/|transport/internet/|app/dispatcher:)` written out.
// Xray emits per-flow routing and dialing at Info. Keep those traces
// available at Debug without flooding the default journal; preserve
// warnings and startup.
func isConnectionTrace(message string) bool {
	if !strings.HasPrefix(message, "[") {
		return false
	}
	i := 1
	for i < len(message) && message[i] >= '0' && message[i] <= '9' {
		i++
	}
	if i == 1 || i+1 >= len(message) || message[i] != ']' || message[i+1] != ' ' {
		return false
	}
	tail := message[i+2:]
	return strings.HasPrefix(tail, "proxy/") ||
		strings.HasPrefix(tail, "transport/internet/") ||
		strings.HasPrefix(tail, "app/dispatcher:")
}
