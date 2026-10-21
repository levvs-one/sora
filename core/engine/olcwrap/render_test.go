package olcwrap

import (
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
)

const testKey = "d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799"

func TestRenderGoldenDatachannel(t *testing.T) {
	got, err := RenderYAML(Config{
		Provider: "jitsi", Transport: "datachannel",
		Room: "https://meet.example.org/myroom", KeyHex: testKey, DNS: "1.1.1.1:53",
	}, Listener{Port: 40001, User: "sora-u", Pass: "p4ss"})
	if err != nil {
		t.Fatal(err)
	}
	want := `mode: cnc
auth:
  provider: "jitsi"
room:
  id: "https://meet.example.org/myroom"
crypto:
  key: "` + testKey + `"
net:
  transport: "datachannel"
  dns: "1.1.1.1:53"
socks:
  host: "127.0.0.1"
  port: 40001
  user: "sora-u"
  pass: "p4ss"
`
	if string(got) != want {
		t.Fatalf("render:\n%s\nwant:\n%s", got, want)
	}
}

func TestRenderGoldenTransports(t *testing.T) {
	base := Config{KeyHex: testKey, DNS: "9.9.9.9:53", Room: "room-01"}
	lis := Listener{Port: 40002, User: "u", Pass: "p"}
	cases := []struct {
		name string
		cfg  Config
		want string
	}{
		{
			name: "vp8 with token",
			cfg:  Config{Provider: "wbstream", Transport: "vp8channel", AuthToken: "tok123", Params: map[string]string{"vp8-fps": "60", "vp8-batch": "1"}},
			want: "vp8:\n  fps: 60\n  batch_size: 1\n",
		},
		{
			name: "sei full dictionary",
			cfg:  Config{Provider: "wbstream", Transport: "seichannel", Params: map[string]string{"fps": "60", "batch": "64", "frag": "900", "ack-ms": "2000"}},
			want: "sei:\n  fps: 60\n  batch_size: 64\n  fragment_size: 900\n  ack_timeout_ms: 2000\n",
		},
		{
			name: "video qrcode",
			cfg:  Config{Provider: "telemost", Transport: "videochannel", Params: map[string]string{"video-w": "1080", "video-h": "1080", "video-fps": "60", "video-codec": "qrcode", "video-qr-recovery": "high", "video-qr-size": "256"}},
			want: "video:\n  width: 1080\n  height: 1080\n  fps: 60\n  codec: \"qrcode\"\n  qr_size: 256\n  qr_recovery: \"high\"\n",
		},
		{
			name: "video tile",
			cfg:  Config{Provider: "jitsi", Transport: "videochannel", Params: map[string]string{"video-codec": "tile", "video-tile-module": "4", "video-tile-rs": "20"}},
			want: "video:\n  codec: \"tile\"\n  tile_module: 4\n  tile_rs: 20\n",
		},
		{
			name: "unknown and deprecated params are not rendered",
			cfg:  Config{Provider: "jitsi", Transport: "seichannel", Params: map[string]string{"fps": "45", "future-knob": "7", "video-bitrate": "1000"}},
			want: "sei:\n  fps: 45\n",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			cfg := base
			cfg.Provider, cfg.Transport, cfg.AuthToken, cfg.Params = tc.cfg.Provider, tc.cfg.Transport, tc.cfg.AuthToken, tc.cfg.Params
			got, err := RenderYAML(cfg, lis)
			if err != nil {
				t.Fatal(err)
			}
			if !strings.HasSuffix(string(got), tc.want) {
				t.Fatalf("render:\n%s\nwant suffix:\n%s", got, tc.want)
			}
			if strings.Contains(string(got), "future-knob") || strings.Contains(string(got), "bitrate") {
				t.Fatalf("render leaked an unmapped parameter:\n%s", got)
			}
		})
	}
}

func TestRenderRefusesServerModeAndBadInts(t *testing.T) {
	lis := Listener{Port: 1, User: "u", Pass: "p"}
	if _, err := RenderYAML(Config{Mode: "srv", Provider: "jitsi", Transport: "datachannel", Room: "r", KeyHex: testKey, DNS: "1.1.1.1:53"}, lis); err == nil {
		t.Fatal("mode srv must be refused at render time")
	} else if e, ok := err.(*errs.Error); !ok || e.Key() != errs.KeyOlcrtcServerMode {
		t.Fatalf("mode srv error = %v, want key %s", err, errs.KeyOlcrtcServerMode)
	}
	if _, err := RenderYAML(Config{Provider: "jitsi", Transport: "seichannel", Room: "r", KeyHex: testKey, DNS: "1.1.1.1:53",
		Params: map[string]string{"fps": "fast"}}, lis); err == nil {
		t.Fatal("a non-integer known parameter must be refused, not rendered")
	}
}

func TestRenderQuotesRoomVerbatim(t *testing.T) {
	// A room carrying YAML-significant characters must survive as
	// one quoted scalar, never as document structure.
	got, err := RenderYAML(Config{Provider: "jitsi", Transport: "datachannel",
		Room: `room: #1 "quoted"`, KeyHex: testKey, DNS: "1.1.1.1:53"}, Listener{Port: 1, User: "u", Pass: "p"})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(got), `  id: "room: #1 \"quoted\""`) {
		t.Fatalf("room not quoted verbatim:\n%s", got)
	}
}
