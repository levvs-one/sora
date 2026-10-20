package engine

import "testing"

// TestCensorP1XmuxBoundaries pins the xmux numeric boundaries
// (мелочи): zero keeps the engine default, 1 is the smallest real
// tuning, the per-subconnection cap value passes, negatives and the
// mutually exclusive pair fail.
func TestCensorP1XmuxBoundaries(t *testing.T) {
	base := func() Outbound {
		o := realityOutbound()
		o.Transport.Type = "xhttp"
		o.Transport.Mode = "stream-up"
		return o
	}
	ok := []Transport{
		{}, // all zero: engine default
		{XmuxMaxConcurrency: 1},
		{XmuxMaxConcurrency: 128},
		{XmuxMaxConnections: 1},
		{XmuxMaxReuseTimes: 1},
		{XmuxMaxRequestTimes: 1000},
	}
	for _, tr := range ok {
		o := base()
		o.Transport.XmuxMaxConcurrency = tr.XmuxMaxConcurrency
		o.Transport.XmuxMaxConnections = tr.XmuxMaxConnections
		o.Transport.XmuxMaxReuseTimes = tr.XmuxMaxReuseTimes
		o.Transport.XmuxMaxRequestTimes = tr.XmuxMaxRequestTimes
		if err := o.Validate(); err != nil {
			t.Errorf("xmux %+v: Validate = %v, want nil", tr, err)
		}
	}
	bad := []Transport{
		{XmuxMaxConcurrency: -1},
		{XmuxMaxConnections: -1},
		{XmuxMaxReuseTimes: -1},
		{XmuxMaxRequestTimes: -1},
		{XmuxMaxConcurrency: 4, XmuxMaxConnections: 4}, // mutually exclusive
	}
	for _, tr := range bad {
		o := base()
		o.Transport.XmuxMaxConcurrency = tr.XmuxMaxConcurrency
		o.Transport.XmuxMaxConnections = tr.XmuxMaxConnections
		o.Transport.XmuxMaxReuseTimes = tr.XmuxMaxReuseTimes
		o.Transport.XmuxMaxRequestTimes = tr.XmuxMaxRequestTimes
		if err := o.Validate(); err == nil {
			t.Errorf("xmux %+v: Validate = nil, want an error", tr)
		}
	}
	// Past the per-subconnection cap the plan still validates — the
	// excess is a warning (xhttp-xmux-proxy-limit), never a silent
	// clamp: the value the user wrote is the value rendered.
	o := base()
	o.Transport.XmuxMaxConcurrency = 129
	if err := o.Validate(); err != nil {
		t.Fatalf("xmux 129: Validate = %v, want nil (warning territory)", err)
	}
	if !contains(o.Warnings(), "xhttp-xmux-proxy-limit") {
		t.Error("xmux 129 must surface the xhttp-xmux-proxy-limit warning")
	}
}

// TestCensorP1PaddingBoundaries pins the XHTTP padding range
// boundaries (мелочи): 0 is a legal range end (Xray's own parser
// accepts 0), the wire cap is 65535 per side, inverted and
// over-cap ranges fail. Exercised through Outbound.Validate, where
// the range check lives.
func TestCensorP1PaddingBoundaries(t *testing.T) {
	for _, ok := range []string{"", "0", "0-0", "1", "100-1000", "65535", "0-65535"} {
		o := realityOutbound()
		o.Transport.Type = "xhttp"
		o.Transport.Mode = "stream-up"
		o.Transport.XPaddingBytes = ok
		if err := o.Validate(); err != nil {
			t.Errorf("padding %q: Validate = %v, want nil", ok, err)
		}
	}
	for _, bad := range []string{"65536", "0-65536", "1000-100", "-5", "abc", "10-", "1-2-3"} {
		o := realityOutbound()
		o.Transport.Type = "xhttp"
		o.Transport.Mode = "stream-up"
		o.Transport.XPaddingBytes = bad
		if err := o.Validate(); err == nil {
			t.Errorf("padding %q: Validate = nil, want an error", bad)
		}
	}
}
