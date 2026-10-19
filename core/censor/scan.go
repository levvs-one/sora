package censor

// terminalScan reduces an attempt to what the multi-attempt trackers need:
// the first terminal event and whether the far end ever sent payload bytes.
// It is the shared primitive of the siberian freeze tracker and the
// whitelist detector; it lives here (not in detect.go) so those trackers
// depend only on types.go.
func terminalScan(a Attempt) (terminal *Event, sawBytesIn bool) {
	for i, e := range a.Events {
		if e.BytesIn > 0 {
			sawBytesIn = true
		}
		if terminal == nil {
			switch e.What {
			case WhatRemoteReset, WhatRemoteClose, WhatLocalTimeout, WhatTLSAlert, WhatError:
				ev := a.Events[i]
				terminal = &ev
			}
		}
	}
	return terminal, sawBytesIn
}
