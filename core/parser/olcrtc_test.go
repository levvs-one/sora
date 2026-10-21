package parser

import (
	"errors"
	"reflect"
	"strings"
	"testing"
)

const olcrtcTestKey = "d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799"

// TestParseOLCRTCDocumentedLinks parses every verbatim URI example
// from the olcrtc documents (docs/uri.md examples and the docs/sub.md
// full example), as reproduced in the OpenLibre SPEC §2.1.
func TestParseOLCRTCDocumentedLinks(t *testing.T) {
	tests := []struct {
		name      string
		link      string
		provider  string
		transport string
		room      string
		mimo      string
		params    map[string]string
	}{
		{
			name: "wbstream datachannel uri.md", provider: "wbstream", transport: "datachannel",
			link: "olcrtc://wbstream?datachannel@room-01#" + olcrtcTestKey + "$RU / olc free sub / IPv6",
			room: "room-01", mimo: "RU / olc free sub / IPv6",
		},
		{
			name: "wbstream vp8channel uri.md", provider: "wbstream", transport: "vp8channel",
			link: "olcrtc://wbstream?vp8channel<vp8-fps=60&vp8-batch=64>@room-01#" + olcrtcTestKey + "$RU / olc free sub / IPv6",
			room: "room-01", mimo: "RU / olc free sub / IPv6",
			// vp8-batch=64 is the session default: canonicalized away.
			params: map[string]string{"vp8-fps": "60"},
		},
		{
			name: "wbstream seichannel uri.md", provider: "wbstream", transport: "seichannel",
			link: "olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#" + olcrtcTestKey + "$DE / olc free sub",
			room: "room-01", mimo: "DE / olc free sub",
			// batch/frag/ack-ms are spelled with their defaults.
			params: map[string]string{"fps": "60"},
		},
		{
			name: "wbstream seichannel sub.md", provider: "wbstream", transport: "seichannel",
			link: "olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#" + olcrtcTestKey + "$RU / olcng free sub / IPv6",
			room: "room-01", mimo: "RU / olcng free sub / IPv6",
			params: map[string]string{"fps": "60"},
		},
		{
			name: "telemost videochannel uri.md", provider: "telemost", transport: "videochannel",
			link: "olcrtc://telemost?videochannel<video-w=1080&video-h=1080&video-fps=60&video-codec=qrcode>@room-01#" + olcrtcTestKey + "$MIMO",
			room: "room-01", mimo: "MIMO",
			// video-h=1080 and video-codec=qrcode are the defaults.
			params: map[string]string{"video-w": "1080", "video-fps": "60"},
		},
		{
			name: "jitsi datachannel url room uri.md", provider: "jitsi", transport: "datachannel",
			link: "olcrtc://jitsi?datachannel@https://meet.example.org/myroom#" + olcrtcTestKey + "$RU / olc free sub",
			room: "https://meet.example.org/myroom", mimo: "RU / olc free sub",
		},
		{
			name: "wbstream datachannel sub.md second server", provider: "wbstream", transport: "datachannel",
			link:   "olcrtc://wbstream?datachannel@abc123xyz#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$DE / backup / IPv4",
			room:   "abc123xyz",
			mimo:   "DE / backup / IPv4",
			params: nil,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r, err := (LinkParser{}).Parse([]byte(tt.link))
			if err != nil {
				t.Fatal(err)
			}
			if len(r.Servers) != 1 {
				t.Fatalf("servers = %d, report %+v", len(r.Servers), r.Report)
			}
			o := r.Servers[0]
			if o.Protocol != "olcrtc" || o.Transport != tt.transport || o.Security != "olc2" {
				t.Errorf("protocol/transport/security = %q/%q/%q", o.Protocol, o.Transport, o.Security)
			}
			if o.Options["olcrtc_provider"] != tt.provider {
				t.Errorf("provider = %q, want %q", o.Options["olcrtc_provider"], tt.provider)
			}
			if o.Host != tt.room || o.Options["olcrtc_room"] != tt.room {
				t.Errorf("room host/option = %q/%q, want %q", o.Host, o.Options["olcrtc_room"], tt.room)
			}
			if o.Port != 0 {
				t.Errorf("port = %d, want 0 (olcrtc has no host:port endpoint)", o.Port)
			}
			wantKey := olcrtcTestKey
			if strings.Contains(tt.link, "#aaaa") {
				wantKey = strings.Repeat("a", 64)
			}
			if o.Password != wantKey {
				t.Errorf("key = %q, want %q", o.Password, wantKey)
			}
			if o.DisplayName != tt.mimo {
				t.Errorf("name = %q, want MIMO %q", o.DisplayName, tt.mimo)
			}
			for k, v := range tt.params {
				if o.Options[k] != v {
					t.Errorf("param %s = %q, want %q (options %v)", k, o.Options[k], v, o.Options)
				}
			}
		})
	}
}

// TestParseOLCRTCVariations covers documented shapes beyond the
// verbatim examples: telemost full-URL rooms (the provider code
// accepts both bare ids and URLs), provider none with no room, an
// install.sh-style comment, separators inside a room, an uppercase
// scheme and an uppercase hex key.
func TestParseOLCRTCVariations(t *testing.T) {
	tests := []struct{ name, link, room, mimo string }{
		{
			name: "telemost full url room",
			link: "olcrtc://telemost?videochannel@https://telemost.yandex.ru/j/abc123#" + olcrtcTestKey,
			room: "https://telemost.yandex.ru/j/abc123",
		},
		{
			name: "jitsi room with at sign",
			link: "olcrtc://jitsi?datachannel@https://user@meet.example.org/room#" + olcrtcTestKey,
			room: "https://user@meet.example.org/room",
		},
		{
			name: "jitsi room with fragment hash",
			link: "olcrtc://jitsi?datachannel@https://meet.example.org/room#section#" + olcrtcTestKey,
			room: "https://meet.example.org/room#section",
		},
		{
			name: "install.sh comment",
			link: "olcrtc://jitsi?datachannel@https://meet.example.org/olcrtc-xxxxxxxx#" + olcrtcTestKey + "$olc - t.me/openlibrecommunity",
			room: "https://meet.example.org/olcrtc-xxxxxxxx", mimo: "olc - t.me/openlibrecommunity",
		},
		{
			name: "provider none without room",
			link: "olcrtc://none?datachannel@#" + olcrtcTestKey,
			room: "",
		},
		{
			name: "uppercase scheme",
			link: "OLCRTC://jitsi?datachannel@room-01#" + olcrtcTestKey,
			room: "room-01",
		},
		{
			name: "no mimo",
			link: "olcrtc://wbstream?datachannel@room-01#" + olcrtcTestKey,
			room: "room-01",
		},
		{
			name: "empty mimo after dollar",
			link: "olcrtc://wbstream?datachannel@room-01#" + olcrtcTestKey + "$",
			room: "room-01",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			o, err := parseOLCRTCLink(tt.link)
			if err != nil {
				t.Fatal(err)
			}
			if o.Host != tt.room || o.DisplayName != tt.mimo {
				t.Errorf("room/name = %q/%q, want %q/%q", o.Host, o.DisplayName, tt.room, tt.mimo)
			}
		})
	}
	// An uppercase hex key is the same key and is preserved verbatim.
	o, err := parseOLCRTCLink("olcrtc://jitsi?datachannel@room-01#" + strings.ToUpper(olcrtcTestKey))
	if err != nil {
		t.Fatal(err)
	}
	if o.Password != strings.ToUpper(olcrtcTestKey) {
		t.Errorf("key case not preserved: %q", o.Password)
	}
}

// TestParseOLCRTCRejects is the negative corpus: every entry must be
// refused — as unsupported (unknown provider/transport) or invalid
// (grammar, key shape, parameter dictionary) — never imported.
func TestParseOLCRTCRejects(t *testing.T) {
	key := olcrtcTestKey
	tests := []struct {
		name string
		link string
		want error
	}{
		{"key 63 hex", "olcrtc://jitsi?datachannel@room#" + key[:63], ErrInvalid},
		{"key 65 hex", "olcrtc://jitsi?datachannel@room#" + key + "a", ErrInvalid},
		{"key not hex", "olcrtc://jitsi?datachannel@room#" + strings.Repeat("g", 64), ErrInvalid},
		{"key base64 shape", "olcrtc://jitsi?datachannel@room#" + strings.Repeat("a", 43) + "=", ErrInvalid},
		{"no key separator", "olcrtc://jitsi?datachannel@room", ErrInvalid},
		{"empty key", "olcrtc://jitsi?datachannel@room#", ErrInvalid},
		{"no at", "olcrtc://jitsi?datachannel#" + key, ErrInvalid},
		{"no transport separator", "olcrtc://jitsi@room#" + key, ErrInvalid},
		{"empty transport", "olcrtc://jitsi?@room#" + key, ErrInvalid},
		{"empty provider", "olcrtc://?datachannel@room#" + key, ErrInvalid},
		{"unknown provider", "olcrtc://zoom?datachannel@room#" + key, ErrUnsupported},
		{"provider case sensitive", "olcrtc://Jitsi?datachannel@room#" + key, ErrUnsupported},
		{"unknown transport", "olcrtc://jitsi?carrierpigeon@room#" + key, ErrUnsupported},
		{"empty room", "olcrtc://jitsi?datachannel@#" + key, ErrInvalid},
		{"wbstream placeholder room", "olcrtc://wbstream?datachannel@any#" + key, ErrInvalid},
		{"datachannel with payload", "olcrtc://jitsi?datachannel<fps=60>@room#" + key, ErrInvalid},
		{"payload unclosed", "olcrtc://wbstream?seichannel<fps=60@room#" + key, ErrInvalid},
		{"payload stray close", "olcrtc://wbstream?seichannel>@room#" + key, ErrInvalid},
		{"payload nested bracket", "olcrtc://wbstream?seichannel<fps=<60>>@room#" + key, ErrInvalid},
		{"payload junk after close", "olcrtc://wbstream?seichannel<fps=60>x@room#" + key, ErrInvalid},
		{"param without equals", "olcrtc://wbstream?seichannel<fps>@room#" + key, ErrInvalid},
		{"param empty value", "olcrtc://wbstream?seichannel<fps=>@room#" + key, ErrInvalid},
		{"param empty key", "olcrtc://wbstream?seichannel<=60>@room#" + key, ErrInvalid},
		{"param duplicated", "olcrtc://wbstream?seichannel<fps=60&fps=61>@room#" + key, ErrInvalid},
		{"fps zero", "olcrtc://wbstream?seichannel<fps=0>@room#" + key, ErrInvalid},
		{"fps above 240", "olcrtc://wbstream?vp8channel<vp8-fps=241>@room#" + key, ErrInvalid},
		{"fps not a number", "olcrtc://wbstream?seichannel<fps=fast>@room#" + key, ErrInvalid},
		{"fps negative", "olcrtc://wbstream?seichannel<fps=-1>@room#" + key, ErrInvalid},
		{"batch zero", "olcrtc://wbstream?seichannel<batch=0>@room#" + key, ErrInvalid},
		{"frag zero", "olcrtc://wbstream?seichannel<frag=0>@room#" + key, ErrInvalid},
		{"frag above 60000", "olcrtc://wbstream?seichannel<frag=60001>@room#" + key, ErrInvalid},
		{"ack zero", "olcrtc://wbstream?seichannel<ack-ms=0>@room#" + key, ErrInvalid},
		{"video width too small", "olcrtc://telemost?videochannel<video-w=15>@room#" + key, ErrInvalid},
		{"video width too large", "olcrtc://telemost?videochannel<video-w=8193>@room#" + key, ErrInvalid},
		{"video codec unknown", "olcrtc://telemost?videochannel<video-codec=vp9>@room#" + key, ErrInvalid},
		{"qr recovery unknown", "olcrtc://telemost?videochannel<video-qr-recovery=ultra>@room#" + key, ErrInvalid},
		{"qr size negative", "olcrtc://telemost?videochannel<video-qr-size=-1>@room#" + key, ErrInvalid},
		{"tile module above 270", "olcrtc://telemost?videochannel<video-codec=tile&video-tile-module=271>@room#" + key, ErrInvalid},
		{"tile rs above 200", "olcrtc://telemost?videochannel<video-codec=tile&video-tile-rs=201>@room#" + key, ErrInvalid},
		{"tile keys without tile codec", "olcrtc://telemost?videochannel<video-tile-module=4>@room#" + key, ErrInvalid},
		{"tile keys with qrcode codec", "olcrtc://telemost?videochannel<video-codec=qrcode&video-tile-rs=20>@room#" + key, ErrInvalid},
		{"tile wrong width", "olcrtc://telemost?videochannel<video-codec=tile&video-w=720>@room#" + key, ErrInvalid},
		{"tile wrong height", "olcrtc://telemost?videochannel<video-codec=tile&video-h=720>@room#" + key, ErrInvalid},
		{"sei key on vp8 transport", "olcrtc://wbstream?vp8channel<fps=60>@room#" + key, nil}, // unknown for vp8: preserved, not an error
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			o, err := parseLink(tt.link)
			if tt.want == nil {
				if err != nil {
					t.Fatalf("parseLink = %v, want success (cross-transport keys are unknown keys)", err)
				}
				if o.Options["fps"] != "60" {
					t.Errorf("unknown key must be preserved, options = %v", o.Options)
				}
				return
			}
			if err == nil {
				t.Fatalf("parseLink imported %+v, want %v", o, tt.want)
			}
			if !errors.Is(err, tt.want) {
				t.Fatalf("parseLink error = %v, want sentinel %v", err, tt.want)
			}
			// Through Parse the link is reported, never imported.
			r, perr := (LinkParser{}).Parse([]byte(tt.link))
			if perr != nil {
				t.Fatal(perr)
			}
			if len(r.Servers) != 0 {
				t.Fatalf("Parse imported %d servers from a rejected link", len(r.Servers))
			}
			if errors.Is(err, ErrUnsupported) && r.Report.Unsupported != 1 {
				t.Errorf("report unsupported = %d, want 1", r.Report.Unsupported)
			}
			if errors.Is(err, ErrInvalid) && r.Report.Invalid != 1 {
				t.Errorf("report invalid = %d, want 1", r.Report.Invalid)
			}
		})
	}
}

// TestOLCRTCUnknownAndDeprecatedParams: unknown payload keys survive
// import and round-trip; the deprecated video-bitrate/video-hw keys
// survive import (the runtime ignores them) but are never re-emitted.
func TestOLCRTCUnknownAndDeprecatedParams(t *testing.T) {
	link := "olcrtc://wbstream?seichannel<fps=60&future-x=7&aaa=1>@room-01#" + olcrtcTestKey
	o, err := parseLink(link)
	if err != nil {
		t.Fatal(err)
	}
	if o.Options["future-x"] != "7" || o.Options["aaa"] != "1" {
		t.Fatalf("unknown params lost: %v", o.Options)
	}
	dep := "olcrtc://telemost?videochannel<video-fps=60&video-bitrate=5000&video-hw=1>@room-01#" + olcrtcTestKey
	o, err = parseLink(dep)
	if err != nil {
		t.Fatal(err)
	}
	if o.Options["video-bitrate"] != "5000" || o.Options["video-hw"] != "1" {
		t.Fatalf("deprecated params must be preserved on import: %v", o.Options)
	}
	out, err := o.ShareLink()
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out, "video-bitrate") || strings.Contains(out, "video-hw") {
		t.Errorf("emitter must not produce deprecated keys: %s", out)
	}
}

// TestOLCRTCRoundTrip: parse∘ShareLink is the identity on the corpus,
// and ShareLink reproduces the input byte-for-byte when the input is
// already in canonical emitted form (non-default params only, in
// dictionary order, unknown keys sorted last).
func TestOLCRTCRoundTrip(t *testing.T) {
	corpus := []string{
		"olcrtc://wbstream?datachannel@room-01#" + olcrtcTestKey + "$RU / olc free sub / IPv6",
		"olcrtc://wbstream?vp8channel<vp8-fps=60&vp8-batch=64>@room-01#" + olcrtcTestKey + "$RU / olc free sub / IPv6",
		"olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#" + olcrtcTestKey + "$DE / olc free sub",
		"olcrtc://telemost?videochannel<video-w=1080&video-h=1080&video-fps=60&video-codec=qrcode>@room-01#" + olcrtcTestKey + "$MIMO",
		"olcrtc://jitsi?datachannel@https://meet.example.org/myroom#" + olcrtcTestKey + "$RU / olc free sub",
		"olcrtc://wbstream?datachannel@abc123xyz#" + strings.Repeat("a", 64) + "$DE / backup / IPv4",
		"olcrtc://telemost?videochannel<video-codec=tile&video-tile-module=4&video-tile-rs=20>@room-01#" + olcrtcTestKey,
		"olcrtc://wbstream?seichannel<fps=60&future-x=7>@room-01#" + olcrtcTestKey,
		"olcrtc://none?datachannel@#" + olcrtcTestKey,
		"olcrtc://jitsi?datachannel@room-01#" + olcrtcTestKey,
	}
	for _, link := range corpus {
		spec, err := parseLink(link)
		if err != nil {
			t.Fatalf("parse %q: %v", link, err)
		}
		emitted, err := spec.ShareLink()
		if err != nil {
			t.Fatalf("emit %q: %v", link, err)
		}
		again, err := parseLink(emitted)
		if err != nil {
			t.Fatalf("reparse %q (from %q): %v", emitted, link, err)
		}
		if !reflect.DeepEqual(spec, again) {
			t.Errorf("parse∘emit not identity for %q:\nfirst:  %+v\nsecond: %+v\nemitted: %s", link, spec, again, emitted)
		}
		if spec.StableKey() != again.StableKey() {
			t.Errorf("stable key changed over round-trip for %q", link)
		}
	}
	canonical := []string{
		"olcrtc://wbstream?datachannel@room-01#" + olcrtcTestKey + "$RU / olc free sub / IPv6",
		"olcrtc://wbstream?seichannel<fps=61&batch=65&frag=901&ack-ms=2001>@room-01#" + olcrtcTestKey + "$X",
		"olcrtc://wbstream?seichannel<fps=60&aaa=1&future-x=7>@room-01#" + olcrtcTestKey,
		"olcrtc://jitsi?datachannel@https://meet.example.org/myroom#" + olcrtcTestKey + "$RU / olc free sub",
		"olcrtc://telemost?videochannel<video-w=1080&video-fps=60>@room-01#" + olcrtcTestKey + "$MIMO",
	}
	for _, link := range canonical {
		spec, err := parseLink(link)
		if err != nil {
			t.Fatal(err)
		}
		emitted, err := spec.ShareLink()
		if err != nil {
			t.Fatal(err)
		}
		if emitted != link {
			t.Errorf("canonical emit = %q, want byte-identical %q", emitted, link)
		}
	}
	// Defaults are dropped on emit: the documented seichannel example
	// carries three default values and re-emits with only fps=60.
	spec, err := parseLink("olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#" + olcrtcTestKey + "$DE / olc free sub")
	if err != nil {
		t.Fatal(err)
	}
	emitted, err := spec.ShareLink()
	if err != nil {
		t.Fatal(err)
	}
	want := "olcrtc://wbstream?seichannel<fps=60>@room-01#" + olcrtcTestKey + "$DE / olc free sub"
	if emitted != want {
		t.Errorf("emit with defaults dropped = %q, want %q", emitted, want)
	}
	// Other protocols have no emitter.
	if _, err := (OutboundSpec{Protocol: "vless"}).ShareLink(); !errors.Is(err, ErrUnsupported) {
		t.Errorf("ShareLink(vless) = %v, want ErrUnsupported", err)
	}
	// A spec whose key lost its shape is refused, not rendered.
	bad := spec
	bad.Password = "short"
	if _, err := bad.ShareLink(); err == nil {
		t.Error("ShareLink with a malformed key must fail")
	}
}

// TestParseOLCRTCSubscription parses the verbatim full example of
// docs/sub.md: globals are skipped as metadata, both servers import,
// and each ## block binds to its own preceding link with ##name
// outranking the MIMO comment.
func TestParseOLCRTCSubscription(t *testing.T) {
	body := `#name: Zarazaex Free RU
#update: 1778011200
#refresh: 10m
#color: #4A90E2
#icon: 🇷🇺
#used: 10mb/10gb
#available: 9.99gb

olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$RU / olcng free sub / IPv6
##name: RU-1
##icon: 🇷🇺
##color: #4A90E2
##used: 500mb/10gb
##available: 9.5gb
##ip: 203.0.113.10
##comment: basic free node

olcrtc://wbstream?datachannel@abc123xyz#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$DE / backup / IPv4
##name: DE-Backup
##icon: 🇩🇪
##color: #2EBD85
##comment: reserve route, wbstream+datachannel does not work in guest flow
`
	r, err := (LinkParser{}).Parse([]byte(body))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 2 || r.Report.Invalid != 0 || r.Report.Unsupported != 0 {
		t.Fatalf("servers = %d, report %+v (globals and ## blocks are metadata, not items)", len(r.Servers), r.Report)
	}
	first, second := r.Servers[0], r.Servers[1]
	if first.DisplayName != "RU-1" {
		t.Errorf("first name = %q, want ##name RU-1 over MIMO", first.DisplayName)
	}
	for k, v := range map[string]string{
		"olcrtc_meta_icon": "🇷🇺", "olcrtc_meta_color": "#4A90E2",
		"olcrtc_meta_used": "500mb/10gb", "olcrtc_meta_available": "9.5gb",
		"olcrtc_meta_ip": "203.0.113.10", "olcrtc_meta_comment": "basic free node",
		"fps": "60",
	} {
		if first.Options[k] != v {
			t.Errorf("first options[%s] = %q, want %q", k, first.Options[k], v)
		}
	}
	if second.DisplayName != "DE-Backup" {
		t.Errorf("second name = %q, want DE-Backup", second.DisplayName)
	}
	if second.Options["olcrtc_meta_comment"] != "reserve route, wbstream+datachannel does not work in guest flow" {
		t.Errorf("second comment = %q", second.Options["olcrtc_meta_comment"])
	}
	if second.Options["olcrtc_meta_ip"] != "" {
		t.Error("the first server's ##ip must not leak into the second server")
	}
	// A ##name takes the country flag from the new name, not the MIMO.
	third, err := (LinkParser{}).Parse([]byte(
		"olcrtc://jitsi?datachannel@room-01#" + olcrtcTestKey + "$plain name\n##name: 🇩🇪 Berlin\n"))
	if err != nil {
		t.Fatal(err)
	}
	if third.Servers[0].CountryCode != "🇩🇪" {
		t.Errorf("country = %q, want the ##name flag", third.Servers[0].CountryCode)
	}
}

// TestOLCRTCMetaBindingRules pins the binding edges: an orphan block
// is invalid, a block after a non-olcrtc server does not reach back
// past it, a block after a duplicate binds to the deduplicated entry,
// and unknown ## keys are preserved.
func TestOLCRTCMetaBindingRules(t *testing.T) {
	link := "olcrtc://jitsi?datachannel@room-01#" + olcrtcTestKey + "$MIMO name"

	r, err := (LinkParser{}).Parse([]byte("##name: Orphan\n" + link))
	if err != nil {
		t.Fatal(err)
	}
	if r.Report.Invalid != 1 || len(r.Servers) != 1 || r.Servers[0].DisplayName != "MIMO name" {
		t.Errorf("orphan ##: report %+v servers %+v", r.Report, r.Servers)
	}

	vless := "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443#V"
	r, err = (LinkParser{}).Parse([]byte(link + "\n" + vless + "\n##name: Wrong"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Report.Invalid != 1 {
		t.Errorf("## after a vless line must be invalid, report %+v", r.Report)
	}
	if r.Servers[0].DisplayName != "MIMO name" || r.Servers[1].DisplayName != "V" {
		t.Errorf("## leaked across servers: %+v", r.Servers)
	}

	r, err = (LinkParser{}).Parse([]byte(link + "\n" + link + "\n##name: Deduped\n##future: kept"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Report.SkippedDuplicates != 1 || len(r.Servers) != 1 {
		t.Fatalf("duplicates: report %+v", r.Report)
	}
	if r.Servers[0].DisplayName != "Deduped" || r.Servers[0].Options["olcrtc_meta_future"] != "kept" {
		t.Errorf("duplicate binding: %+v", r.Servers[0])
	}

	r, err = (LinkParser{}).Parse([]byte(link + "\n##broken line without colon"))
	if err != nil {
		t.Fatal(err)
	}
	if r.Report.Invalid != 1 {
		t.Errorf("malformed ## must be invalid, report %+v", r.Report)
	}
}

// TestOLCRTCMixedAndBase64Lists: olcrtc lines import alongside other
// protocols and inside base64-wrapped lists, like every other scheme.
func TestOLCRTCMixedAndBase64Lists(t *testing.T) {
	body := "vless://123e4567-e89b-12d3-a456-426614174000@example.com:443#V\n" +
		"olcrtc://jitsi?datachannel@room-01#" + olcrtcTestKey + "$Room"
	r, err := (LinkParser{}).Parse([]byte(body))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 2 || r.Servers[1].Protocol != "olcrtc" {
		t.Fatalf("mixed import: %+v", r.Servers)
	}
	if r.Servers[0].StableKey() == r.Servers[1].StableKey() {
		t.Error("stable keys must differ across protocols")
	}
	// Two olcrtc servers in one room via different providers are
	// distinct; the same provider/transport/room twice is a duplicate
	// even under another name.
	two := "olcrtc://jitsi?datachannel@room-01#" + olcrtcTestKey + "$A\n" +
		"olcrtc://wbstream?datachannel@room-01#" + olcrtcTestKey + "$B\n" +
		"olcrtc://jitsi?datachannel@room-01#" + olcrtcTestKey + "$C"
	r, err = (LinkParser{}).Parse([]byte(two))
	if err != nil {
		t.Fatal(err)
	}
	if len(r.Servers) != 2 || r.Report.SkippedDuplicates != 1 {
		t.Fatalf("provider identity: servers %d report %+v", len(r.Servers), r.Report)
	}
}
