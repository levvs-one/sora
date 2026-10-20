package mihomo

import (
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/levvs-one/sora-client/core/logs"
)

// ParseLog reads one mihomo output line, which is logfmt, for example
// time="2026-10-06T15:14:37.119654768+03:00" level=info msg="Sniffer is
// closed".
//
// This is a hand-written equivalent of the former regexp
// `^time="([^"]+)" level=(\w+) msg=("(?:[^"\\]|\\.)*")`: the regexp cost a
// submatch slice allocation for every engine line, the hottest input path
// in the core. The fallbacks match the regexp exactly (the pattern is not
// anchored at the end, so trailing fields after the message are ignored),
// and an unquoted message without escapes is returned as a slice of the
// line instead of the copy strconv.Unquote used to make.
func (driver) ParseLog(line string) (time.Time, logs.Level, string) {
	rest, ok := strings.CutPrefix(line, `time="`)
	if !ok {
		return time.Time{}, logs.LevelInfo, line
	}
	end := strings.IndexByte(rest, '"')
	if end < 0 {
		return time.Time{}, logs.LevelInfo, line
	}
	stamp, rest := rest[:end], rest[end+1:]
	rest, ok = strings.CutPrefix(rest, " level=")
	if !ok {
		return time.Time{}, logs.LevelInfo, line
	}
	i := 0
	for i < len(rest) && isWordByte(rest[i]) {
		i++
	}
	if i == 0 {
		return time.Time{}, logs.LevelInfo, line
	}
	levelName, rest := rest[:i], rest[i:]
	rest, ok = strings.CutPrefix(rest, ` msg=`)
	if !ok {
		return time.Time{}, logs.LevelInfo, line
	}
	token, ok := scanQuoted(rest)
	if !ok {
		return time.Time{}, logs.LevelInfo, line
	}
	at, _ := time.Parse(time.RFC3339Nano, stamp)
	level, found := logs.ParseLevel(levelName)
	if !found {
		level = logs.LevelInfo
	}
	return at, level, unquote(token)
}

func isWordByte(c byte) bool {
	return c >= '0' && c <= '9' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c == '_'
}

// scanQuoted returns the double-quoted token at the start of s, including
// its quotes, honoring backslash escapes the way the former regexp's
// `"(?:[^"\\]|\\.)*"` did (an escape cannot swallow a newline).
func scanQuoted(s string) (string, bool) {
	if len(s) < 2 || s[0] != '"' {
		return "", false
	}
	for i := 1; i < len(s); i++ {
		switch s[i] {
		case '"':
			return s[:i+1], true
		case '\\':
			if i+1 >= len(s) || s[i+1] == '\n' {
				return "", false
			}
			i++
		}
	}
	return "", false
}

// unquote decodes a quoted message token. Content without escapes is
// already the result — strconv.Unquote would only copy it — so it is
// sliced out directly when every rune is printable and valid, the same
// condition under which Unquote accepts raw content; anything else takes
// the original Unquote path, including its fallback to the raw token.
func unquote(token string) string {
	inner := token[1 : len(token)-1]
	if !strings.ContainsRune(inner, '\\') && utf8.ValidString(inner) && printable(inner) {
		return inner
	}
	message, err := strconv.Unquote(token)
	if err != nil {
		return token
	}
	return message
}

func printable(s string) bool {
	for _, r := range s {
		if !unicode.IsPrint(r) {
			return false
		}
	}
	return true
}
