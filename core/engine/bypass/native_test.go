package bypass

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"runtime"
	"strconv"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

func TestNativeWindowsProxyCarriesHTTPAndTLS(t *testing.T) {
	binary := os.Getenv("SORA_BYPASS_BIN")
	if runtime.GOOS != "windows" || binary == "" {
		t.Skip("set SORA_BYPASS_BIN to the pinned native Windows ByeDPI build")
	}
	for _, secure := range []bool{false, true} {
		t.Run(map[bool]string{false: "HTTP", true: "TLS"}[secure], func(t *testing.T) {
			handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				data, err := io.ReadAll(io.LimitReader(r.Body, 64*1024))
				if err != nil {
					t.Error(err)
					return
				}
				if _, err := w.Write(data); err != nil {
					t.Error(err)
				}
			})
			server := httptest.NewUnstartedServer(handler)
			if secure {
				server.StartTLS()
			} else {
				server.Start()
			}
			t.Cleanup(server.Close)
			wrapper := Wrap(nil, binary, t.TempDir(), nil)
			proxy, err := wrapper.start(engine.BypassStrategy{SplitPos: []string{"1"}, Disorder: true, TLSRecord: "1", HostCase: true})
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(proxy.stop)
			address, err := url.Parse("socks5://127.0.0.1:" + strconv.Itoa(proxy.port))
			if err != nil {
				t.Fatal(err)
			}
			client := server.Client()
			transport := client.Transport.(*http.Transport)
			transport.Proxy = http.ProxyURL(address)
			client.Timeout = 5 * time.Second
			t.Cleanup(transport.CloseIdleConnections)
			payload := bytes.Repeat([]byte("Sora native DPI transport test\n"), 512)
			request, err := http.NewRequestWithContext(t.Context(), http.MethodPost, server.URL, bytes.NewReader(payload))
			if err != nil {
				t.Fatal(err)
			}
			response, err := client.Do(request)
			if err != nil {
				t.Fatal(err)
			}
			defer func() { _ = response.Body.Close() }()
			data, err := io.ReadAll(io.LimitReader(response.Body, 64*1024))
			if err != nil || response.StatusCode != http.StatusOK || !bytes.Equal(data, payload) {
				t.Fatalf("proxy changed the exchange: status=%d bytes=%d err=%v", response.StatusCode, len(data), err)
			}
			wrapper.procs[key(engine.BypassStrategy{SplitPos: []string{"1"}})] = proxy
			bad := &engine.Plan{Outbounds: []engine.Outbound{{ID: "bad", Protocol: engine.ProtocolBypass,
				Bypass: &engine.BypassStrategy{SplitPos: []string{"midsld"}}}}}
			if err := wrapper.Apply(t.Context(), bad); err == nil {
				t.Fatal("unsupported strategy was accepted")
			}
			transport.CloseIdleConnections()
			again, err := http.NewRequestWithContext(t.Context(), http.MethodGet, server.URL, nil)
			if err != nil {
				t.Fatal(err)
			}
			check, err := client.Do(again)
			if err != nil {
				t.Fatalf("rejected plan stopped the existing proxy: %v", err)
			}
			if err := check.Body.Close(); err != nil {
				t.Fatal(err)
			}
		})
	}
}
