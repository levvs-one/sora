package engine

import "testing"

// TestValidateXHTTP pins the T009 guards: XHTTP-only tuning must not leak
// onto other transports (where every renderer would silently drop it), and
// broken XHTTP combinations must fail at plan validation instead of at the
// engine. The cases mirror spec 09-xhttp: mode whitelist, XHTTP+Vision,
// downloadSettings rules, xmux rules, xPaddingBytes format, ALPN h3 gating.
func TestValidateXHTTP(t *testing.T) {
	xhttp := func(mut func(*Outbound)) Outbound {
		o := Outbound{ID: "x1", Protocol: ProtocolVLESS}
		o.Transport.Type = "xhttp"
		if mut != nil {
			mut(&o)
		}
		return o
	}
	plain := func(mut func(*Outbound)) Outbound {
		o := Outbound{ID: "p1", Protocol: ProtocolVLESS}
		o.Transport.Type = "tcp"
		if mut != nil {
			mut(&o)
		}
		return o
	}

	cases := []struct {
		name    string
		out     Outbound
		wantErr bool
	}{
		{"plain transport without xhttp fields", plain(nil), false},
		{"downloadSettings on tcp is rejected", plain(func(o *Outbound) {
			o.Transport.DownloadAddress = "dl.example.com"
			o.Transport.DownloadPort = 443
		}), true},
		{"xmux tuning on tcp is rejected", plain(func(o *Outbound) {
			o.Transport.XmuxMaxConcurrency = 8
		}), true},
		{"xPaddingBytes on tcp is rejected", plain(func(o *Outbound) {
			o.Transport.XPaddingBytes = "100-1000"
		}), true},
		{"xhttp minimal", xhttp(nil), false},
		{"xhttp unknown mode", xhttp(func(o *Outbound) {
			o.Transport.Mode = "stream-sideways"
		}), true},
		{"xhttp packet-up mode", xhttp(func(o *Outbound) {
			o.Transport.Mode = "packet-up"
		}), false},
		{"xhttp with vision flow", xhttp(func(o *Outbound) {
			o.Flow = "xtls-rprx-vision"
		}), true},
		{"download address without port", xhttp(func(o *Outbound) {
			o.Transport.Mode = "stream-up"
			o.Transport.DownloadAddress = "dl.example.com"
		}), true},
		{"download port without address", xhttp(func(o *Outbound) {
			o.Transport.Mode = "stream-up"
			o.Transport.DownloadPort = 443
		}), true},
		{"downloadSettings with stream-one", xhttp(func(o *Outbound) {
			o.Transport.Mode = "stream-one"
			o.Transport.DownloadAddress = "dl.example.com"
			o.Transport.DownloadPort = 443
		}), true},
		{"downloadSettings valid pair on stream-up", xhttp(func(o *Outbound) {
			o.Transport.Mode = "stream-up"
			o.Transport.DownloadAddress = "dl.example.com"
			o.Transport.DownloadPort = 443
		}), false},
		{"download address is not a host", xhttp(func(o *Outbound) {
			o.Transport.Mode = "stream-up"
			o.Transport.DownloadAddress = "https://dl.example.com/path"
			o.Transport.DownloadPort = 443
		}), true},
		{"xmux negative value", xhttp(func(o *Outbound) {
			o.Transport.XmuxMaxReuseTimes = -1
		}), true},
		{"xmux concurrency and connections are exclusive", xhttp(func(o *Outbound) {
			o.Transport.XmuxMaxConcurrency = 8
			o.Transport.XmuxMaxConnections = 4
		}), true},
		{"xmux concurrency alone", xhttp(func(o *Outbound) {
			o.Transport.XmuxMaxConcurrency = 8
		}), false},
		{"xPaddingBytes not a range", xhttp(func(o *Outbound) {
			o.Transport.XPaddingBytes = "lots"
		}), true},
		{"xPaddingBytes inverted range", xhttp(func(o *Outbound) {
			o.Transport.XPaddingBytes = "1000-100"
		}), true},
		{"xPaddingBytes above MTU sanity bound", xhttp(func(o *Outbound) {
			o.Transport.XPaddingBytes = "70000"
		}), true},
		{"xPaddingBytes valid range", xhttp(func(o *Outbound) {
			o.Transport.XPaddingBytes = "100-1000"
		}), false},
		{"ALPN h3 without TLS", xhttp(func(o *Outbound) {
			o.TLS.ALPN = []string{"h3"}
		}), true},
		{"ALPN h3 with TLS", xhttp(func(o *Outbound) {
			o.TLS.Enabled = true
			o.TLS.ALPN = []string{"h3"}
		}), false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			errs := validateXHTTP(tc.out)
			if tc.wantErr && len(errs) == 0 {
				t.Fatalf("expected a validation error, got none")
			}
			if !tc.wantErr && len(errs) > 0 {
				t.Fatalf("expected no validation error, got %v", errs)
			}
		})
	}
}
