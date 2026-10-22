package parser

import (
	"encoding/base64"
	"strings"
	"testing"
)

const olcKey = "d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799"

func TestOLCRTCURIv1DocumentationExamples(t *testing.T) {
	for _, part := range []string{
		"wbstream?datachannel@room-01",
		"wbstream?vp8channel<vp8-fps=60&vp8-batch=64>@room-01",
		"wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01",
		"telemost?videochannel<video-w=1080&video-h=1080&video-fps=60&video-codec=qrcode>@room-01",
		"jitsi?datachannel@https://meet.example.org/myroom",
	} {
		t.Run(part, func(t *testing.T) {
			raw := "olcrtc://" + part + "#" + olcKey + "$RU / olc free sub / IPv6"
			for _, body := range []string{raw, base64.StdEncoding.EncodeToString([]byte(raw))} {
				result, err := (LinkParser{}).Parse([]byte(body))
				if err != nil || len(result.Servers) != 1 {
					t.Fatalf("%+v, %v", result, err)
				}
				o := result.Servers[0]
				if o.DisplayName != "RU / olc free sub / IPv6" || o.Password != olcKey || o.OLCRTC == nil {
					t.Fatalf("lost URI fields")
				}
			}
		})
	}
}

func TestOLCRTCMalformedAndEscapedURIs(t *testing.T) {
	for _, raw := range []string{
		"olcrtc://jitsi?datachannel@room#" + olcKey,
		"olcrtc://unknown?datachannel@room#" + olcKey,
		"olcrtc://wbstream?unknown@room#" + olcKey,
		"olcrtc://wbstream?datachannel@room#abc",
		"olcrtc://wbstream?datachannel@room#" + strings.Repeat("z", 64),
		"olcrtc://wbstream?datachannel@#" + olcKey,
		"olcrtc://wbstream?datachannel<x=y>@room#" + olcKey,
		"olcrtc://wbstream?vp8channel<vp8-fps=0>@room#" + olcKey,
		"olcrtc://wbstream?vp8channel<vp8-fps=30&vp8-fps=60>@room#" + olcKey,
		"olcrtc://wbstream?vp8channel<vp8-fps=30@room#" + olcKey,
		"olcrtc://telemost?videochannel<video-w=15>@room#" + olcKey,
		"olcrtc://telemost?videochannel<video-tile-rs=201>@room#" + olcKey,
		"olcrtc://telemost?videochannel<video-codec=tile&video-w=720>@room#" + olcKey,
		"olcrtc://wbstream?datachannel@room#" + olcKey + "$bad%00comment",
		"olcrtc://wbstream?datachannel@room#" + olcKey + "$bad%zz",
	} {
		result, err := (LinkParser{}).Parse([]byte(raw))
		if err == nil && (len(result.Servers) != 0 || result.Report.Invalid != 1) {
			t.Errorf("malformed URI accepted: %s", raw)
		}
	}
	o, err := parseLink("olcrtc://jitsi?datachannel@https%3A%2F%2Fmeet.example.org%2Froom#" + olcKey + "$Name%20%2B%20comment")
	if err != nil || o.OLCRTC.Room != "https://meet.example.org/room" || o.DisplayName != "Name + comment" {
		t.Fatalf("percent encoding: %v", err)
	}
}

func TestOLCRTCSubscriptionMetadataAndIdentity(t *testing.T) {
	first := "olcrtc://wbstream?vp8channel@room-01#" + olcKey + "$original comment"
	second := "olcrtc://wbstream?vp8channel@room-02#" + olcKey + "$second"
	body := "#name: Community\n#refresh: 10m\n" + first + "\n##name: RU-1\n##comment: local comment\n##ip: 203.0.113.10\n\n" + second
	for _, input := range []string{body, base64.RawStdEncoding.EncodeToString([]byte(body))} {
		result, err := (LinkParser{}).Parse([]byte(input))
		if err != nil || len(result.Servers) != 2 || result.Report.Invalid != 0 || result.Report.Unsupported != 0 {
			t.Fatalf("metadata parsed as servers: %+v %v", result.Report, err)
		}
		if result.Servers[0].DisplayName != "RU-1" || result.Servers[0].Options["olcrtc-meta-comment"] != "local comment" || result.Servers[1].DisplayName != "second" {
			t.Fatal("local metadata attached to wrong server")
		}
		if result.Servers[0].StableKey() == result.Servers[1].StableKey() {
			t.Fatal("different rooms collapsed")
		}
	}
	a, _ := parseLink(first)
	b := a
	b.Password = strings.Repeat("a", 64)
	if a.StableKey() != b.StableKey() {
		t.Fatal("identity contains secret")
	}
}
