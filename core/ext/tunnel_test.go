package ext

import (
	"context"
	"encoding/binary"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/txthinking/socks5"
	"golang.org/x/net/dns/dnsmessage"
)

func testTunnel(t *testing.T, dial func(string) (net.Conn, error)) TunnelProxy {
	t.Helper()
	ln, err := (&net.ListenConfig{}).Listen(t.Context(), "tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	p := TunnelProxy{Addr: ln.Addr().String(), Username: "extension-session-user", Password: "extension-session-password"}
	s := &socks5.Server{Method: socks5.MethodUsernamePassword, UserName: p.Username, Password: p.Password,
		SupportedCommands: []byte{socks5.CmdConnect}}
	var wg sync.WaitGroup
	wg.Go(func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			wg.Go(func() {
				defer func() { _ = conn.Close() }()
				_ = conn.SetDeadline(time.Now().Add(5 * time.Second))
				if s.Negotiate(conn) != nil {
					return
				}
				r, err := s.GetRequest(conn)
				if err != nil {
					return
				}
				upstream, err := dial(r.Address())
				if err != nil {
					return
				}
				defer func() { _ = upstream.Close() }()
				if _, err := socks5.NewReply(socks5.RepSuccess, socks5.ATYPIPv4, []byte{127, 0, 0, 1}, []byte{0, 0}).WriteTo(conn); err != nil {
					return
				}
				done := make(chan struct{})
				go func() {
					_, _ = io.Copy(upstream, conn)
					_ = upstream.Close()
					close(done)
				}()
				_, _ = io.Copy(conn, upstream)
				_ = conn.Close()
				<-done
			})
		}
	})
	t.Cleanup(func() { _ = ln.Close(); wg.Wait() })
	return p
}

func mustReq(t *testing.T, method, target string) *http.Request {
	t.Helper()
	req, err := http.NewRequestWithContext(t.Context(), method, target, nil)
	if err != nil {
		t.Fatal(err)
	}
	return req
}

func TestProxyRoundTripperRequiresPrivateAddressAndLogin(t *testing.T) {
	for _, p := range []TunnelProxy{
		{}, {Addr: "127.0.0.1:1234"}, {Addr: "localhost:1234", Username: "u", Password: "p"},
		{Addr: "203.0.113.1:1234", Username: "u", Password: "p"},
		{Addr: "127.0.0.1:1234", Password: "p"},
	} {
		if _, err := ProxyRoundTripper(p); err == nil {
			t.Fatal("accepted an untrusted proxy or a missing login")
		}
	}
}

func TestTunnelTransportAuthenticatesAndFollowsSessions(t *testing.T) {
	origin := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Proxy-Authorization") != "" {
			t.Error("proxy credential reached origin")
		}
		_, _ = io.WriteString(w, "via-vpn")
	}))
	defer origin.Close()
	var counts [2]atomic.Int64
	var proxies [2]TunnelProxy
	for i := range proxies {
		proxies[i] = testTunnel(t, func(addr string) (net.Conn, error) {
			counts[i].Add(1)
			return (&net.Dialer{}).DialContext(t.Context(), "tcp", addr)
		})
	}
	current := 0
	tr := &TunnelTransport{Lookup: func() (TunnelProxy, bool) { return proxies[current], true }}
	for i := range proxies {
		current = i
		resp, err := tr.RoundTrip(mustReq(t, "GET", origin.URL))
		if err != nil {
			t.Fatal(err)
		}
		body, _ := io.ReadAll(resp.Body)
		_ = resp.Body.Close()
		if string(body) != "via-vpn" || counts[i].Load() != 1 {
			t.Fatal("request did not use the current tunnel")
		}
	}
	tr.cached.CloseIdleConnections()
	bad := proxies[1]
	bad.Password = "wrong-password"
	rt, err := ProxyRoundTripper(bad)
	if err != nil {
		t.Fatal(err)
	}
	if resp, err := rt.RoundTrip(mustReq(t, "GET", origin.URL)); err == nil {
		_ = resp.Body.Close()
		t.Fatal("wrong proxy password succeeded")
	}
}

func TestTunnelDNSStaysInsideProxy(t *testing.T) {
	var dnsQueries, destinations atomic.Int64
	origin := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Host != "example.com" || r.TLS.ServerName != "example.com" {
			t.Error("transport lost original HTTPS identity")
		}
		_, _ = io.WriteString(w, "resolved-inside-vpn")
	}))
	defer origin.Close()
	p := testTunnel(t, func(addr string) (net.Conn, error) {
		if addr == "1.1.1.1:53" {
			dnsQueries.Add(1)
			client, server := net.Pipe()
			go func() {
				defer func() { _ = server.Close() }()
				var size [2]byte
				if _, err := io.ReadFull(server, size[:]); err != nil {
					return
				}
				packet := make([]byte, binary.BigEndian.Uint16(size[:]))
				if _, err := io.ReadFull(server, packet); err != nil {
					return
				}
				var query dnsmessage.Message
				if err := query.Unpack(packet); err != nil || len(query.Questions) != 1 {
					return
				}
				question := query.Questions[0]
				if question.Name.String() != "example.com." {
					t.Error("unexpected DNS search suffix")
				}
				answer := dnsmessage.Message{Header: dnsmessage.Header{ID: query.ID, Response: true}, Questions: query.Questions}
				if question.Type == dnsmessage.TypeA {
					answer.Answers = []dnsmessage.Resource{{Header: dnsmessage.ResourceHeader{Name: question.Name,
						Type: dnsmessage.TypeA, Class: dnsmessage.ClassINET, TTL: 30},
						Body: &dnsmessage.AResource{A: [4]byte{203, 0, 113, 9}}}}
				}
				packet, err := answer.Pack()
				if err != nil {
					return
				}
				binary.BigEndian.PutUint16(size[:], uint16(len(packet)))
				_, _ = server.Write(append(size[:], packet...))
			}()
			return client, nil
		}
		if addr != "203.0.113.9:443" {
			return nil, errors.New("engine received a domain or an unexpected address")
		}
		destinations.Add(1)
		return (&net.Dialer{}).DialContext(t.Context(), "tcp", strings.TrimPrefix(origin.URL, "https://"))
	})
	rt, err := ProxyRoundTripper(p)
	if err != nil {
		t.Fatal(err)
	}
	rt.TLSClientConfig = origin.Client().Transport.(*http.Transport).TLSClientConfig
	defer rt.CloseIdleConnections()
	resp, err := rt.RoundTrip(mustReq(t, "GET", "https://example.com/"))
	if err != nil {
		t.Fatal(err)
	}
	body, _ := io.ReadAll(resp.Body)
	_ = resp.Body.Close()
	if string(body) != "resolved-inside-vpn" || dnsQueries.Load() == 0 || destinations.Load() != 1 {
		t.Fatalf("DNS or HTTPS escaped the proxy: %q, dns=%d, https=%d", body, dnsQueries.Load(), destinations.Load())
	}
}

func TestFetcherFailsClosedWithoutTunnel(t *testing.T) {
	for _, lookup := range []func() (TunnelProxy, bool){nil, func() (TunnelProxy, bool) { return TunnelProxy{}, false }} {
		f, err := NewFetcherForExtensionWithTransport("com.example.hello",
			&ManifestExt{NetworkHosts: []string{"example.com"}}, FetchLimits{}, &TunnelTransport{Lookup: lookup}, NewLogHub())
		if err != nil {
			t.Fatal(err)
		}
		_, err = f.Fetch(context.Background(), FetchRequest{Method: "GET", URL: "https://example.com/api"})
		if k := errKey(t, err); k != KeyNetFetchNoTunnel || f.Stats().Denied != 1 {
			t.Fatalf("error=%q, denied=%d", k, f.Stats().Denied)
		}
	}
}
