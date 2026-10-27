//go:build linux

package main

import (
	"bytes"
	"context"
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"os/signal"
	"slices"
	"strconv"
	"syscall"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/encoding/protojson"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func main() {
	if os.Args[1] == "zapret-target" {
		requireIsolatedNetwork()
		serveZapretTargets(os.Args[2])
		return
	}
	if os.Args[1] == "dns-server" {
		dnsServer()
		return
	}
	if os.Args[1] == "dns" {
		dnsQuery(os.Args[2], os.Args[3], os.Args[4])
		return
	}
	if os.Args[2] == "byedpi" || os.Args[2] == "zapret" {
		requireIsolatedNetwork()
	}
	seconds := 0
	if os.Args[2] == "hold" {
		var err error
		seconds, err = strconv.Atoi(os.Args[3])
		must(err)
	}
	timeout := time.Duration(seconds)*time.Second + 30*time.Second
	if os.Args[2] == "byedpi" || os.Args[2] == "zapret" {
		timeout = 90 * time.Second
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	conn, err := grpc.NewClient("passthrough:///core", grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, "unix", os.Args[1])
		}))
	must(err)
	defer conn.Close()
	c := corev1.NewCoreControlClient(conn)
	api := &corev1.ApiVersion{Major: 1, Minor: 7, MinSupportedMinor: 1}
	h, err := c.Handshake(ctx, &corev1.HandshakeRequest{ClientVersion: api})
	must(err)
	auth := h.GetControlAuthenticator()
	switch os.Args[2] {
	case "connect":
		// Xray JSON exercises provider-profile rendering, the owner's import path.
		payload := `vless://b831381d-6324-4d53-ad4f-8cda48b30811@198.51.100.2:10080?security=none&type=tcp#upstream`
		if os.Args[3] == "xray" {
			payload = `{"remarks":"upstream","outbounds":[{"tag":"proxy","protocol":"vless","settings":{"vnext":[{"address":"198.51.100.2","port":10080,"users":[{"id":"b831381d-6324-4d53-ad4f-8cda48b30811","encryption":"none"}]}]}}]}`
		}
		imported, err := c.ParseImport(ctx, &corev1.ParseImportRequest{ApiVersion: api, Payload: []byte(payload)})
		must(err)
		wire(imported.GetError())
		p := imported.GetSessionPlan()
		p.Engines = []string{os.Args[3]}
		p.NetworkControlAllowed = true
		p.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_SYSTEM
		if os.Args[4] == "proxy" {
			p.TunnelMode = corev1.TunnelMode_TUNNEL_MODE_APPLICATION
		} else if os.Args[3] == "xray" {
			p.TunStack = os.Getenv("SORA_XRAY_TUN_STACK")
		}
		p.Routing = &corev1.RoutingOptions{ProxyTarget: p.GetOutbounds()[0].GetId()}
		p.DnsPolicy = &corev1.DnsPolicy{Servers: []string{"192.168.0.1"}}
		r, err := c.Connect(ctx, &corev1.ConnectRequest{ApiVersion: api, ControlAuthenticator: auth, SessionPlan: p, KillSwitch: len(os.Args) > 5 && os.Args[5] == "kill"})
		must(err)
		wire(r.GetError())
		fmt.Println(r.GetStatus().GetConnection().GetValue())
	case "byedpi":
		probeByeDPI(ctx, c, api, auth, os.Args[3])
	case "zapret":
		probeZapret(ctx, c, api, auth, os.Args[3], os.Args[4])
	case "disconnect":
		r, err := c.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: api, ControlAuthenticator: auth})
		must(err)
		wire(r.GetError())
	case "hold":
		start := time.Now()
		ticker := time.NewTicker(time.Second)
		defer ticker.Stop()
		for {
			r, err := c.GetStatus(ctx, &corev1.GetStatusRequest{ApiVersion: api})
			must(err)
			wire(r.GetError())
			if r.GetStatus().GetConnection().GetValue() != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
				panic(fmt.Sprint(r))
			}
			if time.Since(start) >= time.Duration(seconds)*time.Second {
				break
			}
			select {
			case <-ctx.Done():
				panic(ctx.Err())
			case <-ticker.C:
			}
		}
		// State events reveal a restart even if polling missed its short outage.
		watchCtx, stopWatch := context.WithTimeout(ctx, 2*time.Second)
		defer stopWatch()
		watchDeadline, _ := watchCtx.Deadline()
		events, err := c.WatchEvents(watchCtx, &corev1.WatchEventsRequest{ApiVersion: api})
		must(err)
		connected := false
		for {
			event, err := events.Recv()
			if err != nil {
				// The server can finish first at the same deadline and return
				// EOF before the client's context cancellation is scheduled.
				if watchCtx.Err() != nil || status.Code(err) == codes.DeadlineExceeded || errors.Is(err, io.EOF) && !time.Now().Before(watchDeadline) {
					break
				}
				must(err)
			}
			if state := event.GetStateChanged(); state != nil {
				value := state.GetState().GetValue()
				if connected && value != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
					panic(fmt.Sprint(event))
				}
				connected = connected || value == corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED
			}
			if event.GetError() != nil {
				panic(fmt.Sprint(event))
			}
		}
		if !connected {
			panic("no connected event")
		}
		fmt.Printf("connected for %s\n", time.Since(start).Round(time.Second))
	case "logs":
		r, err := c.QueryLogs(ctx, &corev1.QueryLogsRequest{ApiVersion: api, ControlAuthenticator: auth, Limit: 1000})
		must(err)
		wire(r.GetError())
		for _, entry := range r.GetEntries() {
			fmt.Println(entry.GetLevel(), entry.GetSource(), entry.GetMessage())
		}
	}
}

func requireIsolatedNetwork() {
	current, err := os.Readlink("/proc/self/ns/net")
	parent := os.Getenv("SORA_PARENT_NETNS")
	if err != nil || parent == "" || current == parent || os.Getenv("SORA_BYPASS_ISOLATED") != "1" {
		panic("bypass core test requires a separate network namespace")
	}
}

func linuxBypassProfile(descriptor, name string) *corev1.BypassStrategy {
	raw, err := os.ReadFile(descriptor) //nolint:gosec // The descriptor is staged inside the isolated fixture.
	must(err)
	var root, platforms, variant, profiles map[string]json.RawMessage
	must(json.Unmarshal(raw, &root))
	must(json.Unmarshal(root["platforms"], &platforms))
	must(json.Unmarshal(platforms["linux"], &variant))
	must(json.Unmarshal(variant["profiles"], &profiles))
	strategy := new(corev1.BypassStrategy)
	must(protojson.Unmarshal(profiles[name], strategy))
	return strategy
}

type zapretTargets struct {
	HTTP, HTTPS string
	Certificate []byte
}

// serveZapretTargets runs in the fixture's separate peer network namespace.
func serveZapretTargets(metadata string) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.Copy(w, io.LimitReader(r.Body, 4096))
	})
	newServer := func(secure bool) *httptest.Server {
		server := httptest.NewUnstartedServer(handler)
		must(server.Listener.Close())
		var listenConfig net.ListenConfig
		listener, err := listenConfig.Listen(context.Background(), "tcp", "198.18.0.2:0")
		must(err)
		server.Listener = listener
		if secure {
			server.StartTLS()
		} else {
			server.Start()
		}
		return server
	}
	plain, secure := newServer(false), newServer(true)
	defer plain.Close()
	defer secure.Close()
	data, err := json.Marshal(zapretTargets{HTTP: plain.URL, HTTPS: secure.URL, Certificate: secure.Certificate().Raw})
	must(err)
	must(os.WriteFile(metadata+".tmp", data, 0600)) //nolint:gosec // Only the private test directory is used.
	must(os.Rename(metadata+".tmp", metadata))      //nolint:gosec // Both paths are in the private test directory.
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	<-ctx.Done()
}

// probeByeDPI drives the real core through its authenticated local control socket.
func probeByeDPI(ctx context.Context, client corev1.CoreControlClient, api *corev1.ApiVersion, auth []byte, descriptor string) {
	about, err := client.GetAbout(ctx, &corev1.GetAboutRequest{ApiVersion: api})
	must(err)
	wire(about.GetError())
	if !slices.Contains(about.GetAbout().GetContract().GetCapabilities(), "serverless-bydpi") {
		panic("ByeDPI capability missing")
	}
	strategy := linuxBypassProfile(descriptor, "TCP+TLS")
	endpoint := about.GetAbout().GetLocalProxy()
	proxy, err := url.Parse(fmt.Sprintf("http://%s:%d", endpoint.GetHost(), endpoint.GetPort()))
	must(err)
	for _, kind := range []string{"sing-box", "xray", "mihomo"} {
		plan := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
			Engines: []string{kind}, NetworkControlAllowed: true,
			Outbounds: []*corev1.OutboundSpec{{Id: "sora:bypass", DisplayName: "ByeDPI", Protocol: "byedpi", Bypass: strategy}},
			Routing:   &corev1.RoutingOptions{ProxyTarget: "sora:bypass"}}
		connected, err := client.Connect(ctx, &corev1.ConnectRequest{ApiVersion: api, ControlAuthenticator: auth, SessionPlan: plan})
		must(err)
		wire(connected.GetError())
		if connected.GetStatus().GetConnection().GetValue() != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
			panic(kind + ": core did not reach connected state")
		}
		for _, secure := range []bool{false, true} {
			target := httptest.NewUnstartedServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				_, _ = io.Copy(w, io.LimitReader(r.Body, 4096))
			}))
			if secure {
				target.StartTLS()
			} else {
				target.Start()
			}
			httpClient := target.Client()
			transport := httpClient.Transport.(*http.Transport)
			transport.Proxy = http.ProxyURL(proxy)
			httpClient.Timeout = 5 * time.Second
			payload := []byte("actual Sora core ByeDPI fixture")
			request, err := http.NewRequestWithContext(ctx, http.MethodPost, target.URL, bytes.NewReader(payload))
			must(err)
			response, err := httpClient.Do(request)
			must(err)
			body, err := io.ReadAll(io.LimitReader(response.Body, 4096))
			must(err)
			must(response.Body.Close())
			if response.StatusCode != http.StatusOK || !bytes.Equal(body, payload) {
				panic(kind + ": HTTP/TLS payload mismatch")
			}
			transport.CloseIdleConnections()
			target.Close()
		}
		stopped, err := client.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: api, ControlAuthenticator: auth})
		must(err)
		wire(stopped.GetError())
		fmt.Println(kind + ": actual core authenticated connect + HTTP/TLS + disconnect PASS")
	}
}

// probeZapret connects to targets in the isolated peer namespace through the real core.
func probeZapret(ctx context.Context, client corev1.CoreControlClient, api *corev1.ApiVersion, auth []byte, descriptor, metadata string) {
	about, err := client.GetAbout(ctx, &corev1.GetAboutRequest{ApiVersion: api})
	must(err)
	wire(about.GetError())
	if !slices.Contains(about.GetAbout().GetContract().GetCapabilities(), "serverless") {
		panic("Zapret capability missing")
	}
	raw, err := os.ReadFile(metadata) //nolint:gosec // The metadata is generated in the isolated fixture.
	must(err)
	var targets zapretTargets
	must(json.Unmarshal(raw, &targets))
	certificate, err := x509.ParseCertificate(targets.Certificate)
	must(err)
	roots := x509.NewCertPool()
	roots.AddCert(certificate)
	endpoint := about.GetAbout().GetLocalProxy()
	proxy, err := url.Parse(fmt.Sprintf("http://%s:%d", endpoint.GetHost(), endpoint.GetPort()))
	must(err)
	for _, kind := range []string{"sing-box", "xray", "mihomo"} {
		for _, profile := range []string{"TCP+TLS", "TLS", "HTTP"} {
			strategy := linuxBypassProfile(descriptor, profile)
			plan := &corev1.SessionPlan{TunnelMode: corev1.TunnelMode_TUNNEL_MODE_APPLICATION,
				Engines: []string{kind}, NetworkControlAllowed: true,
				Outbounds: []*corev1.OutboundSpec{{Id: "sora:bypass", DisplayName: "Zapret", Protocol: "bypass", Bypass: strategy}},
				Routing:   &corev1.RoutingOptions{ProxyTarget: "sora:bypass"}}
			connected, err := client.Connect(ctx, &corev1.ConnectRequest{ApiVersion: api, ControlAuthenticator: auth, SessionPlan: plan})
			must(err)
			wire(connected.GetError())
			if connected.GetStatus().GetConnection().GetValue() != corev1.ConnectionStateValue_CONNECTION_STATE_VALUE_CONNECTED {
				panic(kind + "/" + profile + ": core did not reach connected state")
			}
			transport := &http.Transport{Proxy: http.ProxyURL(proxy), TLSClientConfig: &tls.Config{
				RootCAs: roots, ServerName: "example.com", MinVersion: tls.VersionTLS12,
			}}
			httpClient := &http.Client{Timeout: 5 * time.Second, Transport: transport}
			for _, target := range []string{targets.HTTP, targets.HTTPS} {
				payload := []byte("actual Sora core Zapret fixture")
				request, err := http.NewRequestWithContext(ctx, http.MethodPost, target, bytes.NewReader(payload))
				must(err)
				response, err := httpClient.Do(request)
				must(err)
				body, err := io.ReadAll(io.LimitReader(response.Body, 4096))
				must(err)
				must(response.Body.Close())
				if response.StatusCode != http.StatusOK || !bytes.Equal(body, payload) {
					panic(fmt.Sprintf("%s/%s target=%s status=%d body=%q", kind, profile, target, response.StatusCode, body))
				}
			}
			transport.CloseIdleConnections()
			stopped, err := client.Disconnect(ctx, &corev1.DisconnectRequest{ApiVersion: api, ControlAuthenticator: auth})
			must(err)
			wire(stopped.GetError())
			fmt.Printf("%s/%s: actual core Zapret authenticated connect + HTTP/TLS + disconnect PASS\n", kind, profile)
		}
	}
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
func wire(err *corev1.SoraError) {
	if err != nil {
		panic(fmt.Sprint(err))
	}
}
