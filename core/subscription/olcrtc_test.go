package subscription_test

import (
	"context"
	"net/http"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/subscription"
)

// TestFetchOLCRTCSubscription: a sub.md body is fetched like any other
// subscription (plain text, no wrapper) and its globals surface in
// Result.Info while the body reaches the importer byte-for-byte.
func TestFetchOLCRTCSubscription(t *testing.T) {
	const subBody = "#name: Zarazaex Free RU\n#refresh: 10m\n#used: 10mb/10gb\n\n" +
		"olcrtc://wbstream?seichannel<fps=60&batch=64&frag=900&ack-ms=2000>@room-01#" +
		"d823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799$RU / olcng free sub / IPv6\n" +
		"##name: RU-1\n##comment: basic free node\n"
	fetcher, url := newServer(t, func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(subBody))
	})
	got, err := fetcher.Fetch(context.Background(), url, subscription.FetchOptions{})
	if err != nil {
		t.Fatalf("Fetch() error = %v", err)
	}
	if string(got.Body) != subBody {
		t.Errorf("body must pass through verbatim:\n%q", got.Body)
	}
	info := got.Info
	if info.Title != "Zarazaex Free RU" || info.UpdateInterval != 10*time.Minute {
		t.Errorf("info = %+v, want the sub.md name and refresh", info)
	}
	if !info.HasUsage || info.Download != 10<<20 || info.Total != 10<<30 {
		t.Errorf("info usage = %+v, want 10 MiB used of 10 GiB", info)
	}
}
