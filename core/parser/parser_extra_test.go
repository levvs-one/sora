package parser

import (
	"net/url"
	"testing"
)

// TestParseExtraXmuxAndPadding pins the CENSOR-P1 widening of the
// extra= import: the xmux tuning and the padding range are plan data
// like the download split, in all the value shapes the pinned Xray
// accepts (number, numeric string, "min-max" range — a range imports
// as its lower bound, the plan's single-int model).
func TestParseExtraXmuxAndPadding(t *testing.T) {
	extra := url.QueryEscape(`{"xmux":{"maxConcurrency":"16-32","maxConnections":4,"cMaxReuseTimes":10,"hMaxRequestTimes":"1000"},"xPaddingBytes":"100-1000"}`)
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?security=tls&type=xhttp&mode=stream-up&extra=" + extra + "#X"
	result, err := LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	spec := result.Servers[0]
	if spec.XmuxMaxConcurrency != 16 {
		t.Errorf("range \"16-32\" must import as its lower bound 16, got %d", spec.XmuxMaxConcurrency)
	}
	if spec.XmuxMaxConnections != 4 || spec.XmuxMaxReuseTimes != 10 || spec.XmuxMaxRequestTimes != 1000 {
		t.Errorf("xmux scalars lost: %+v", spec)
	}
	if spec.XPaddingBytes != "100-1000" {
		t.Errorf("xPaddingBytes lost: %q", spec.XPaddingBytes)
	}
	if spec.DownloadAddress != "" {
		t.Errorf("no downloadSettings in extra, got split %q", spec.DownloadAddress)
	}
}

// TestParseExtraSectionsAreIndependent pins that a broken or absent
// downloadSettings section does not take the xmux/padding sections
// down with it, and that garbage extra stays decoration.
func TestParseExtraSectionsAreIndependent(t *testing.T) {
	extra := url.QueryEscape(`{"downloadSettings":{"address":"","port":0},"xmux":{"maxConcurrency":8},"xPaddingBytes":"0-100"}`)
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?security=tls&type=xhttp&extra=" + extra + "#X"
	result, err := LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("Parse = %+v, %v", result, err)
	}
	spec := result.Servers[0]
	if spec.DownloadAddress != "" || spec.XmuxMaxConcurrency != 8 || spec.XPaddingBytes != "0-100" {
		t.Errorf("sections must apply independently: %+v", spec)
	}

	link = "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?security=tls&type=xhttp&extra=" +
		url.QueryEscape(`{not json`) + "#X"
	result, err = LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("garbage extra must not fail the import: %+v, %v", result, err)
	}
	if result.Servers[0].XmuxMaxConcurrency != 0 || result.Servers[0].XPaddingBytes != "" {
		t.Errorf("garbage extra must import nothing: %+v", result.Servers[0])
	}
}

// TestParseExtraTypeBrokenSectionDropsOnlyItself is the CENSOR-P1
// review T2 regression: a section whose values carry the wrong JSON
// types must lose only itself. The pre-fix applyExtra decoded the
// whole document into one typed struct in a single Unmarshal, so
// any one mistyped section silently dropped every other section
// with it, despite the documented independence. The vectors are the
// reviewer's own mutations, plus fully-broken JSON and empty extra.
func TestParseExtraTypeBrokenSectionDropsOnlyItself(t *testing.T) {
	parse := func(t *testing.T, extra string) OutboundSpec {
		t.Helper()
		link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?security=tls&type=xhttp&mode=stream-up&extra=" +
			url.QueryEscape(extra) + "#X"
		result, err := LinkParser{}.Parse([]byte(link))
		if err != nil || len(result.Servers) != 1 {
			t.Fatalf("extra %s: Parse = %+v, %v", extra, result, err)
		}
		return result.Servers[0]
	}

	// A numeric xPaddingBytes kills only the padding: the xmux
	// tuning in the same document must still import.
	spec := parse(t, `{"xmux":{"maxConcurrency":8},"xPaddingBytes":123}`)
	if spec.XmuxMaxConcurrency != 8 {
		t.Errorf("numeric xPaddingBytes must not take xmux down: %+v", spec)
	}
	if spec.XPaddingBytes != "" {
		t.Errorf("numeric xPaddingBytes must import no padding, got %q", spec.XPaddingBytes)
	}

	// A string port kills only the download split: xmux and
	// padding in the same document must still import.
	spec = parse(t, `{"downloadSettings":{"address":"dl.example.com","port":"443"},"xmux":{"maxConcurrency":8},"xPaddingBytes":"0-100"}`)
	if spec.DownloadAddress != "" || spec.DownloadPort != 0 {
		t.Errorf("string port must import no split, got %q:%d", spec.DownloadAddress, spec.DownloadPort)
	}
	if spec.XmuxMaxConcurrency != 8 || spec.XPaddingBytes != "0-100" {
		t.Errorf("string port must not take xmux/padding down: %+v", spec)
	}

	// An xmux section spelled as a string kills only the xmux
	// tuning: the padding must still import.
	spec = parse(t, `{"xmux":"oops","xPaddingBytes":"0-100"}`)
	if spec.XmuxMaxConcurrency != 0 {
		t.Errorf("string xmux must import no tuning: %+v", spec)
	}
	if spec.XPaddingBytes != "0-100" {
		t.Errorf("string xmux must not take padding down: %+v", spec)
	}

	// Fully broken JSON imports nothing and never fails the link.
	spec = parse(t, `{"xmux":{"maxConcurrency":8`)
	if spec.XmuxMaxConcurrency != 0 || spec.XPaddingBytes != "" || spec.DownloadAddress != "" {
		t.Errorf("truncated extra must import nothing: %+v", spec)
	}

	// Empty extra imports nothing.
	link := "vless://b831381d-6324-4d53-ad4f-8cda48b30811@edge.example.com:443?security=tls&type=xhttp#X"
	result, err := LinkParser{}.Parse([]byte(link))
	if err != nil || len(result.Servers) != 1 {
		t.Fatalf("no-extra link: Parse = %+v, %v", result, err)
	}
	if spec := result.Servers[0]; spec.XmuxMaxConcurrency != 0 || spec.XPaddingBytes != "" || spec.DownloadAddress != "" {
		t.Errorf("no-extra link must import no XHTTP tuning: %+v", spec)
	}
}
