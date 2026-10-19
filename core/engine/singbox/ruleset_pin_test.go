package singbox

import (
	"regexp"
	"testing"
)

// TestRemoteRuleSetURLsArePinned guards A20-16: the default rule-set URLs must
// carry a 40-hex commit SHA, never a branch tip. A branch tip would let a
// compromised SagerNet repository silently swap everyone's routing rules, and
// nothing in the pipeline would notice. The refs live in render.go next to the
// provenance and the refresh procedure.
func TestRemoteRuleSetURLsArePinned(t *testing.T) {
	pinned := regexp.MustCompile(`^https://raw\.githubusercontent\.com/SagerNet/(sing-geosite|sing-geoip)/[0-9a-f]{40}/(geosite|geoip)-%s\.srs$`)
	for name, url := range map[string]string{
		"geoSiteRuleSetURL": geoSiteRuleSetURL,
		"geoIPRuleSetURL":   geoIPRuleSetURL,
	} {
		if !pinned.MatchString(url) {
			t.Errorf("%s = %q: must pin a 40-hex commit SHA, not a branch tip", name, url)
		}
	}
	if len(geoSiteRuleSetRef) != 40 || len(geoIPRuleSetRef) != 40 {
		t.Errorf("rule-set refs must be full SHAs, got %q and %q", geoSiteRuleSetRef, geoIPRuleSetRef)
	}
}
