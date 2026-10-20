package control

import (
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// parrotReviewNotice is the monthly parrot watch's runtime surface
// (T050): when the core's fingerprint knowledge (newest known Chrome
// parrot, reference JA4, engines.lock pins) is older than the review
// interval, every Connect carries this notice into the session journal,
// next to the obfs startup notices. Chrome ships a milestone about every
// two weeks, so staleness is a when, not an if; the notice is the prompt
// to run the spec 02-utls-freshness.md §5 review and bump.
//
// Empty string means the knowledge is fresh: silence, as everywhere in
// the notices channel.
func parrotReviewNotice(now time.Time) string {
	if !engine.ParrotReviewOverdue(now) {
		return ""
	}
	return "fingerprint review overdue: the newest known Chrome parrot (" + engine.CurrentChromeParrot +
		") was last verified on " + engine.ParrotReviewedAt + ", over a month ago. Chrome ships a new " +
		"version about every two weeks, so the parrots this core trusts may no longer match a real " +
		"browser. Run the monthly parrot watch (uTLS freshness spec §5) and bump uTLS/engines."
}
