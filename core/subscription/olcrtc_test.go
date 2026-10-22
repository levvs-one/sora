package subscription

import (
	"encoding/base64"
	"net/http"
	"testing"
	"time"
)

func TestOLCRTCSubscriptionV1Metadata(t *testing.T) {
	body := "#name: Zarazaex Free RU\n#update: 1778011200\n#refresh: 10m\n#color: #4A90E2\n#icon: RU\n#used: 10mb/10gb\n#available: 9.99gb\n\nolcrtc://wbstream?vp8channel@room#key$comment\n##name: node\n"
	for _, raw := range []string{body, base64.StdEncoding.EncodeToString([]byte(body))} {
		info := parseInfo(http.Header{}, []byte(raw))
		if info.Title != "Zarazaex Free RU" || info.UpdateInterval != 10*time.Minute || !info.HasUsage || info.Download != 10000000 || info.Total != 10000000000 {
			t.Fatalf("metadata: %+v", info)
		}
		info = parseInfo(http.Header{"Profile-Title": []string{"Header"}, "Profile-Update-Interval": []string{"2"}}, []byte(raw))
		if info.Title != "Header" || info.UpdateInterval != 2*time.Hour {
			t.Fatal("body overrode response headers")
		}
	}
	for _, raw := range []string{"NaNgb", "Infmb", "-1gb", "1e100tb"} {
		if _, ok := volume(raw); ok {
			t.Fatal("invalid usage accepted")
		}
	}
}
