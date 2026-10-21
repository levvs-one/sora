package subscription

import (
	"net/http"
	"testing"
	"time"
)

// The verbatim full example of olcrtc docs/sub.md (globals part is
// what parseInfo reads; the server lines and ## blocks are core/parser
// territory and are covered there).
const olcrtcSubBody = `#name: Zarazaex Free RU
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

func TestOLCRTCSubscriptionGlobals(t *testing.T) {
	info := parseInfo(http.Header{}, []byte(olcrtcSubBody))
	if info.Title != "Zarazaex Free RU" {
		t.Errorf("title = %q, want the #name global", info.Title)
	}
	if info.UpdateInterval != 10*time.Minute {
		t.Errorf("update interval = %s, want 10m from #refresh", info.UpdateInterval)
	}
	if !info.HasUsage {
		t.Fatal("usage must be reported from #used")
	}
	if info.Download != 10<<20 {
		t.Errorf("download (combined used) = %d, want 10 MiB", info.Download)
	}
	if info.Total != 10<<30 {
		t.Errorf("total = %d, want 10 GiB from the #used denominator", info.Total)
	}
}

func TestOLCRTCGlobalsYieldToPanelMetadata(t *testing.T) {
	header := http.Header{}
	header.Set("profile-title", "Panel Title")
	header.Set("profile-update-interval", "6")
	header.Set("subscription-userinfo", "upload=1; download=2; total=300; expire=0")
	info := parseInfo(header, []byte(olcrtcSubBody))
	if info.Title != "Panel Title" || info.UpdateInterval != 6*time.Hour {
		t.Errorf("panel metadata must win: %+v", info)
	}
	if info.Upload != 1 || info.Download != 2 || info.Total != 300 {
		t.Errorf("panel usage must win: %+v", info)
	}
}

func TestOLCRTCGlobalsNeedAnOLCRTCBody(t *testing.T) {
	// The same "#name:"/"#refresh:" lines in a non-olcrtc body are not
	// sub.md globals and must change nothing.
	body := "#name: Not A Subscription Name\n#refresh: 10m\nvless://123e4567-e89b-12d3-a456-426614174000@example.com:443#V\n"
	info := parseInfo(http.Header{}, []byte(body))
	if info.Title != "" || info.UpdateInterval != 0 || info.HasUsage {
		t.Errorf("non-olcrtc body picked up olcrtc globals: %+v", info)
	}
}

func TestOLCRTCAvailableFillsTotal(t *testing.T) {
	body := "#name: X\n#used: 10mb\n#available: 1.1gb\nolcrtc://jitsi?datachannel@room#" +
		"d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799\n"
	info := parseInfo(http.Header{}, []byte(body))
	gb := float64(uint64(1) << 30)
	if want := uint64(1.1 * gb); !info.HasUsage || info.Download != 10<<20 || info.Total != want {
		t.Errorf("available must fill a denominator-less total: %+v", info)
	}
}

func TestParseOLCRTCRefresh(t *testing.T) {
	for s, want := range map[string]time.Duration{
		"5s": 5 * time.Second, "10m": 10 * time.Minute,
		"6h": 6 * time.Hour, "1d": 24 * time.Hour,
	} {
		if got, ok := parseOLCRTCRefresh(s); !ok || got != want {
			t.Errorf("parseOLCRTCRefresh(%q) = %s, %v; want %s", s, got, ok, want)
		}
	}
	for _, s := range []string{"", "10", "10x", "0m", "-5m", "99999d", "m"} {
		if got, ok := parseOLCRTCRefresh(s); ok {
			t.Errorf("parseOLCRTCRefresh(%q) = %s, want rejection", s, got)
		}
	}
}

func TestParseHumanTraffic(t *testing.T) {
	gbFloat := float64(uint64(1) << 30)
	for s, want := range map[string]uint64{
		"10mb": 10 << 20, "9.99gb": uint64(9.99 * gbFloat),
		"500kb": 500 << 10, "1tb": 1 << 40, "2048": 2048, "0gb": 0,
	} {
		if got, ok := parseHumanTraffic(s); !ok || got != want {
			t.Errorf("parseHumanTraffic(%q) = %d, %v; want %d", s, got, ok, want)
		}
	}
	for _, s := range []string{"", "mb", "10xb", "-1gb", "1.1.1gb"} {
		if got, ok := parseHumanTraffic(s); ok {
			t.Errorf("parseHumanTraffic(%q) = %d, want rejection", s, got)
		}
	}
}
