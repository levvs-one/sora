package singbox

import (
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/logs"
)

// levelNames are the level tokens sing-box prints, longest first is not
// needed: none is a prefix of another.
var levelNames = []string{"TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL", "PANIC"}

// ParseLog reads one sing-box output line. Bracketed time is elapsed
// seconds, so records use the read time.
//
// This is a hand-written equivalent of the former regexp
// `^(TRACE|DEBUG|INFO|WARN|ERROR|FATAL|PANIC)\[\d+\] (.*)$`: the regexp
// cost a submatch slice allocation (plus the level's lowercase copy in
// ParseLevel) for every engine line, the hottest input path in the core.
// The fallbacks and edge cases match the regexp exactly, including the
// rejection of a message containing a newline ((.*) cannot span one and
// the pattern is anchored at the end of the text).
func (driver) ParseLog(line string) (time.Time, logs.Level, string) {
	for _, name := range levelNames {
		if !strings.HasPrefix(line, name) {
			continue
		}
		rest := line[len(name):]
		if len(rest) < 2 || rest[0] != '[' {
			continue
		}
		i := 1
		for i < len(rest) && rest[i] >= '0' && rest[i] <= '9' {
			i++
		}
		if i == 1 || i+1 >= len(rest) || rest[i] != ']' || rest[i+1] != ' ' {
			continue
		}
		message := rest[i+2:]
		if strings.IndexByte(message, '\n') >= 0 {
			break
		}
		level, _ := logs.ParseLevel(name)
		return time.Time{}, level, message
	}
	return time.Time{}, logs.LevelInfo, line
}
