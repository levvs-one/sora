package subscription

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

func TestPublicSubscriptionCannotRedirectThroughProxyToPrivateTarget(t *testing.T) {
	for _, test := range []struct {
		name, target string
		allowed      bool
	}{
		{"private", "192.168.0.10", false},
		{"loopback", "127.0.0.1", false},
		{"mapped", "[::ffff:192.168.0.10]", false},
		{"nat64-private", "[64:ff9b::c0a8:a]", false},
		{"cloud-cgnat", "100.100.100.200", false},
		{"localhost", "localhost.", false},
		{"decimal", "2130706433", false},
		{"octal", "0177.0.0.1", false},
		{"hex", "0x7f000001", false},
		{"mixed", "0x7f.0.0.1", false},
		{"unicode-ip", "１２７.０.０.１", false},
		{"public", "93.184.216.34", true},
	} {
		t.Run(test.name, func(t *testing.T) {
			var privateRequests, redirectRequests, connects atomic.Int32
			provider := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
				if request.URL.Path == "/private" {
					privateRequests.Add(1)
					_, _ = io.WriteString(w, "internal service response")
					return
				}
				redirectRequests.Add(1)
				http.Redirect(w, request, "https://"+test.target+"/private", http.StatusFound)
			}))
			defer provider.Close()
			proxy := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
				if request.Method != http.MethodConnect || (request.Host != "example.com:443" && request.Host != "93.184.216.34:443") {
					t.Errorf("unexpected proxy request %s %s", request.Method, request.Host)
					http.Error(w, "refused", http.StatusForbidden)
					return
				}
				connects.Add(1)
				// Both simulated destinations are this TLS fixture. No external or
				// real private-network address is ever dialled by this test.
				upstream, err := (&net.Dialer{}).DialContext(request.Context(), "tcp", provider.Listener.Addr().String())
				if err != nil {
					http.Error(w, "fixture unavailable", http.StatusBadGateway)
					return
				}
				defer func() { _ = upstream.Close() }()
				client, _, err := w.(http.Hijacker).Hijack()
				if err != nil {
					return
				}
				defer func() { _ = client.Close() }()
				_, _ = io.WriteString(client, "HTTP/1.1 200 Connection Established\r\n\r\n")
				go func() { _, _ = io.Copy(upstream, client); _ = upstream.Close() }()
				_, _ = io.Copy(client, upstream)
			}))
			defer proxy.Close()
			fetcher := New(Options{})
			defer fetcher.localClient.CloseIdleConnections()
			transport := fetcher.client.Transport.(*http.Transport)
			defer transport.CloseIdleConnections()
			publicProxy, err := url.Parse("http://93.184.216.34:3128")
			if err != nil {
				t.Fatal(err)
			}
			transport.Proxy = http.ProxyURL(publicProxy)
			transport.TLSClientConfig = provider.Client().Transport.(*http.Transport).TLSClientConfig.Clone()
			transport.TLSClientConfig.ServerName = "example.com" // the fixture identity, never production TLS settings
			transport.DialContext = func(ctx context.Context, network, address string) (net.Conn, error) {
				if address != publicProxy.Host {
					return nil, fmt.Errorf("unexpected fixture address")
				}
				allowPrivate, _ := ctx.Value(privateKey{}).(bool)
				if err := checkDial(allowPrivate, address); err != nil {
					return nil, err
				}
				return (&net.Dialer{}).DialContext(ctx, network, proxy.Listener.Addr().String())
			}
			result, err := fetcher.Fetch(t.Context(), "https://example.com/sub?token=fixture-bearer", FetchOptions{})
			if redirectRequests.Load() != 1 {
				t.Fatal("fixture did not reach the redirect through the proxy")
			}
			if test.allowed {
				if err != nil || connects.Load() != 2 || privateRequests.Load() != 1 || string(result.Body) != "internal service response" {
					t.Fatalf("public proxy destination failed: requests=%d, bytes=%d, error=%v", privateRequests.Load(), len(result.Body), err)
				}
				return
			}
			if err == nil || errs.KeyOf(err) != errs.KeySubscriptionRedirect || connects.Load() != 1 || privateRequests.Load() != 0 {
				t.Fatalf("proxy bypassed target policy: private requests=%d, bytes=%d, error=%v", privateRequests.Load(), len(result.Body), err)
			}
			if strings.Contains(err.Error(), "fixture-bearer") {
				t.Fatal("target refusal disclosed the subscription bearer")
			}
		})
	}
}

func TestLocalSubscriptionCannotWarmAPrivateConnectionForPublicFetch(t *testing.T) {
	for _, http2 := range []bool{false, true} {
		t.Run(fmt.Sprintf("HTTP2=%v", http2), func(t *testing.T) {
			var privateRequests atomic.Int32
			provider := httptest.NewUnstartedServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
				if http2 && request.ProtoMajor != 2 {
					t.Error("HTTP/2 fixture was not negotiated")
				}
				if request.URL.Path == "/local" {
					http.Redirect(w, request, "https://example.com/private", http.StatusFound)
					return
				}
				privateRequests.Add(1)
				_, _ = io.WriteString(w, "internal service response")
			}))
			provider.EnableHTTP2 = http2
			provider.StartTLS()
			defer provider.Close()
			client := provider.Client()
			transport := client.Transport.(*http.Transport)
			transport.ForceAttemptHTTP2 = http2
			defer transport.CloseIdleConnections()
			transport.DialContext = func(ctx context.Context, network, address string) (net.Conn, error) {
				if address != "example.com:443" && address != provider.Listener.Addr().String() {
					return nil, fmt.Errorf("unexpected fixture address")
				}
				allowPrivate, _ := ctx.Value(privateKey{}).(bool)
				if err := checkDial(allowPrivate, provider.Listener.Addr().String()); err != nil {
					return nil, err
				}
				return (&net.Dialer{}).DialContext(ctx, network, provider.Listener.Addr().String())
			}
			fetcher := New(Options{HTTPClient: client})
			defer fetcher.localClient.CloseIdleConnections()
			if _, err := fetcher.Fetch(t.Context(), provider.URL+"/local", FetchOptions{}); err != nil {
				t.Fatal(err)
			}
			if privateRequests.Load() != 1 {
				t.Fatal("explicit local-origin fixture did not establish its connection")
			}
			result, err := fetcher.Fetch(t.Context(), "https://example.com/private", FetchOptions{})
			if err == nil || privateRequests.Load() != 1 {
				t.Fatalf("public fetch reused a local-origin connection: private requests=%d, bytes=%d, error=%v", privateRequests.Load(), len(result.Body), err)
			}
		})
	}
}

func TestSubscriptionDeadlineStopsAStalledResponseBody(t *testing.T) {
	var started atomic.Bool
	provider := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, request *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.(http.Flusher).Flush()
		started.Store(true)
		<-request.Context().Done()
	}))
	defer provider.Close()
	fetcher := New(Options{HTTPClient: provider.Client(), Timeout: time.Second})
	defer fetcher.client.CloseIdleConnections()
	defer fetcher.localClient.CloseIdleConnections()
	start := time.Now()
	if _, err := fetcher.Fetch(t.Context(), provider.URL+"/sub?token=fixture-bearer", FetchOptions{}); err == nil {
		t.Fatal("stalled body passed its retrieval deadline")
	} else if strings.Contains(err.Error(), "fixture-bearer") {
		t.Fatal("deadline failure disclosed the bearer")
	}
	if !started.Load() || time.Since(start) > 3*time.Second {
		t.Fatal("fixture did not exercise cancellation of a stalled response body")
	}
}
