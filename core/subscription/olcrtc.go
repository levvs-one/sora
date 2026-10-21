package subscription

import (
	"strconv"
	"strings"
	"time"
)

// OpenLibre subscription globals (olcrtc docs/sub.md, subscription
// format v1). A sub.md body is plain text: "#key: value" globals for
// the whole subscription, olcrtc:// server lines (parsed by
// core/parser, including the per-server "##" blocks), and no base64
// wrapper. The globals have no panel-header equivalent, so parseInfo
// maps the ones that fit Info — and only when the body actually is an
// olcrtc subscription, so a stray "#name:" line in another format
// changes nothing:
//
//   - #name:     -> Title (when no panel title was given)
//   - #refresh:  -> UpdateInterval (5s / 10m / 6h / 1d; "1d" is not a
//     Go duration, so the units are resolved here)
//   - #used:     -> usage: "10mb/10gb" fills Download with the used
//     amount — the UI's used figure is upload+download and an olcrtc
//     subscription reports one combined number — and Total with the
//     denominator; #available: fills Total when #used: carried none.
//
// #update: (a Unix timestamp of the last provider update) has no Info
// field — Expire is a different fact — and #color:/#icon: are UI
// decoration with no Info slot; both are left unmapped rather than
// forced into a field they are not. The spec does not define the byte
// unit convention for #used:/#available: beyond listing kb/mb/gb/tb;
// sora reads them as binary (1024-based) units, the convention of the
// panels this package already parses.

// applyOLCRTCGlobals fills info from the sub.md globals in values
// (the "#key: value" body headers parseInfo already collected).
func (info *Info) applyOLCRTCGlobals(values map[string]string) {
	if info.Title == "" {
		info.Title = cleanText(values["name"], maxTitleRunes, false)
	}
	if info.UpdateInterval == 0 {
		if d, ok := parseOLCRTCRefresh(values["refresh"]); ok {
			info.UpdateInterval = d
		}
	}
	if info.HasUsage {
		return
	}
	used, total, ok := parseOLCRTCUsed(values["used"])
	if !ok {
		return
	}
	info.HasUsage = true
	info.Download = used
	info.Total = total
	if info.Total == 0 {
		if available, ok := parseHumanTraffic(values["available"]); ok {
			info.Total = available
		}
	}
}

// parseOLCRTCRefresh parses a sub.md #refresh value: a number with a
// s/m/h/d unit suffix. Zero, malformed and over-a-year values are
// rejected, mirroring the package's interval bounds.
func parseOLCRTCRefresh(s string) (time.Duration, bool) {
	s = strings.TrimSpace(s)
	if len(s) < 2 {
		return 0, false
	}
	var unit time.Duration
	switch s[len(s)-1] {
	case 's':
		unit = time.Second
	case 'm':
		unit = time.Minute
	case 'h':
		unit = time.Hour
	case 'd':
		unit = 24 * time.Hour
	default:
		return 0, false
	}
	n, err := strconv.ParseFloat(strings.TrimSpace(s[:len(s)-1]), 64)
	if err != nil || n <= 0 {
		return 0, false
	}
	d := time.Duration(n) * unit
	if d <= 0 || d > maxIntervalHours*time.Hour {
		return 0, false
	}
	return d, true
}

// parseOLCRTCUsed parses a #used value: "<used>/<total>" or a bare
// "<used>", each side in the human units of parseHumanTraffic.
func parseOLCRTCUsed(s string) (used, total uint64, ok bool) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, 0, false
	}
	usedPart, totalPart, hasTotal := strings.Cut(s, "/")
	used, ok = parseHumanTraffic(usedPart)
	if !ok {
		return 0, 0, false
	}
	if hasTotal {
		total, ok = parseHumanTraffic(totalPart)
		if !ok {
			return 0, 0, false
		}
	}
	return used, total, true
}

// parseHumanTraffic parses "10mb", "9.99gb", "1.1gb", "500kb" or a
// bare byte count into bytes (1024-based units, see the file comment).
func parseHumanTraffic(s string) (uint64, bool) {
	s = strings.ToLower(strings.TrimSpace(s))
	if s == "" {
		return 0, false
	}
	mult := float64(1)
	for _, unit := range []struct {
		suffix string
		mult   float64
	}{
		{"tb", 1 << 40}, {"gb", 1 << 30}, {"mb", 1 << 20}, {"kb", 1 << 10},
	} {
		if strings.HasSuffix(s, unit.suffix) {
			mult = unit.mult
			s = strings.TrimSpace(strings.TrimSuffix(s, unit.suffix))
			break
		}
	}
	n, err := strconv.ParseFloat(s, 64)
	if err != nil || n < 0 {
		return 0, false
	}
	return uint64(n * mult), true
}

// isOLCRTCBody reports whether a (possibly base64-wrapped, though the
// format has no wrapper) subscription body is an olcrtc sub.md: its
// own line carries the scheme.
func isOLCRTCBody(text string) bool {
	for _, line := range strings.Split(text, "\n") {
		if strings.HasPrefix(strings.ToLower(strings.TrimSpace(line)), "olcrtc://") {
			return true
		}
	}
	return false
}
