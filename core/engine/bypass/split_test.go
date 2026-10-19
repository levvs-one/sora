package bypass

import (
	"regexp"
	"strings"
	"testing"
)

func TestMidSNISplit(t *testing.T) {
	for sni, want := range map[string]string{
		// 9 + 11/2 = 14: cut after "examp", inside the hostname.
		"example.com": "sniext+14",
		// 9 + 10/2 = 14.
		"google.com": "sniext+14",
		// 9 + 1/2 = 9: single-char hostname, cut right at its start.
		"x": "sniext+9",
		// Trailing dot is normalized away before the math.
		"example.com.": "sniext+14",
	} {
		got, err := MidSNISplit(sni)
		if err != nil {
			t.Errorf("MidSNISplit(%q): unexpected error %v", sni, err)
			continue
		}
		if got != want {
			t.Errorf("MidSNISplit(%q) = %q, want %q", sni, got, want)
		}
		// The result must pass the strategy position validator.
		if !bypassPositionCheck(got) {
			t.Errorf("MidSNISplit(%q) = %q does not validate as a split position", sni, got)
		}
	}
}

func TestMidSNISplitRejectsGarbage(t *testing.T) {
	for _, sni := range []string{
		"",
		".",
		"exa mple.com",
		"example.com\n",
		"мвд.рф", // not wire-format: must be punycode before calling
		strings.Repeat("a", 254) + ".com",
	} {
		if _, err := MidSNISplit(sni); err == nil {
			t.Errorf("MidSNISplit(%q): expected an error", sni)
		}
	}
}

// bypassPositionCheck mirrors the engine's split-position syntax
// (core/engine/validate.go) for the marker form this helper emits. It is
// duplicated here so the test runs standalone while engine is mid-refactor;
// the canonical check stays in validate.go.
var bypassPositionCheck = regexp.MustCompile(`^(method|host|endhost|sld|midsld|endsld|sniext)([+-][0-9]{1,4})?$`).MatchString
