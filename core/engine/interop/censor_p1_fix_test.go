package interop_test

// CENSOR-P1 review fix, Low item: mihomo's xPaddingBytes used to be
// proven only by the render string — `mihomo -t` silently ignores
// unknown keys, so config acceptance cannot distinguish "the pin
// honours x-padding-bytes" from "the pin dropped it". This test
// proves the key on the wire instead: a byte-counting TCP tap sits
// between the mihomo client and a plaintext Xray XHTTP server, and
// the padding shows up in the captured client→server stream as a
// run of filler bytes whose length tracks the rendered range.
//
//   - With XPaddingBytes "1500-1500" rendered, the captured stream
//     contains a filler run of at least 1500 bytes (measured on the
//     pin, 2026-10-21: exactly 1500 per request, one run per
//     packet-up POST).
//   - The control leg renders no XPaddingBytes: the pinned
//     mihomo's built-in default range caps its padding at 1000, so
//     no run may reach 1500 there. The contrast is the proof: the
//     long run in the first leg comes from the rendered key, not
//     from XHTTP framing, and a pin that silently ignored the key
//     would fail the first leg exactly the way the control behaves.
//
// The server is told xPaddingBytes "100-2000" because Xray's
// XHTTP server checks the client's padding against its own range
// (the reason dropping a pinned range can get requests rejected,
// see mihomo/config.go).

import (
	"context"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/engine/xray"
)

// wireTap forwards TCP between the client engine and the real
// server, capturing the client→server byte stream for inspection.
type wireTap struct {
	listener net.Listener
	target   string

	mu       sync.Mutex
	captured []byte
}

func startWireTap(t *testing.T, target string) *wireTap {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	tap := &wireTap{listener: ln, target: target}
	t.Cleanup(func() { _ = ln.Close() })
	go func() {
		for {
			client, err := ln.Accept()
			if err != nil {
				return
			}
			go tap.serve(client)
		}
	}()
	return tap
}

func (tap *wireTap) port() int {
	return tap.listener.Addr().(*net.TCPAddr).Port
}

func (tap *wireTap) serve(client net.Conn) {
	server, err := net.DialTimeout("tcp", tap.target, 5*time.Second)
	if err != nil {
		_ = client.Close()
		return
	}
	go func() {
		_, _ = io.Copy(server, io.TeeReader(client, tap))
		_ = server.Close()
	}()
	go func() {
		_, _ = io.Copy(client, server)
		_ = client.Close()
	}()
}

// Write implements io.Writer for the TeeReader capture. The cap
// keeps a pathological run from growing the buffer without bound;
// the longest-run measurement only needs the head of the stream.
func (tap *wireTap) Write(p []byte) (int, error) {
	tap.mu.Lock()
	defer tap.mu.Unlock()
	if len(tap.captured) < 1<<20 {
		tap.captured = append(tap.captured, p...)
	}
	return len(p), nil
}

func (tap *wireTap) longestRun() int {
	tap.mu.Lock()
	defer tap.mu.Unlock()
	best, run := 0, 0
	var prev byte
	for i, b := range tap.captured {
		if i > 0 && b == prev {
			run++
		} else {
			run = 1
		}
		prev = b
		if run > best {
			best = run
		}
	}
	return best
}

// TestMihomoXHTTPPaddingOnTheWire is the wire proof described at
// the top of this file: the rendered x-padding-bytes changes the
// observable client→server bytes of a live mihomo XHTTP session.
func TestMihomoXHTTPPaddingOnTheWire(t *testing.T) {
	dir := os.Getenv("SORA_ENGINES_DIR")
	if dir == "" {
		t.Skip("set SORA_ENGINES_DIR to a directory with sing-box, xray and mihomo")
	}
	target := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { _, _ = io.WriteString(w, reply) }))
	defer target.Close()

	serverPort := port(t)
	svc := service{
		name: "vless-xhttp-padding",
		inbound: map[string]any{
			"protocol": "vless",
			"settings": map[string]any{"clients": []any{map[string]any{"id": uuid}}, "decryption": "none"},
			"streamSettings": map[string]any{
				"network":       "xhttp",
				"xhttpSettings": map[string]any{"path": "/x", "mode": "packet-up", "xPaddingBytes": "100-2000"},
			},
		},
	}
	svc.inbound["listen"], svc.inbound["port"], svc.inbound["tag"] = "127.0.0.1", serverPort, svc.name
	server, err := xray.Prober.Discover(context.Background(), dir, supervise.DiscoveryOptions{})
	if err != nil {
		t.Fatal(err)
	}
	startServer(t, server, []service{svc})

	run := func(t *testing.T, padding string) int {
		t.Helper()
		tap := startWireTap(t, net.JoinHostPort("127.0.0.1", strconv.Itoa(serverPort)))
		outbound := engine.Outbound{
			ID: svc.name, Name: svc.name, Protocol: engine.ProtocolVLESS,
			Server: "127.0.0.1", Port: uint16(tap.port()), UUID: uuid,
			Transport: engine.Transport{Type: "xhttp", Path: "/x", Mode: "packet-up", XPaddingBytes: padding},
		}
		body, err := runThroughEngine(t, dir, realityPlan(outbound), engine.KindMihomo, target)
		if err != nil {
			t.Fatalf("request through mihomo (padding %q): %v", padding, err)
		}
		if body != reply {
			t.Fatalf("padding %q: got %q", padding, body)
		}
		return tap.longestRun()
	}

	if longest := run(t, "1500-1500"); longest < 1500 {
		t.Errorf("rendered x-padding-bytes 1500-1500 must appear on the wire as a filler run of at least 1500 bytes, longest run is %d — the pin is ignoring the key", longest)
	}
	if longest := run(t, ""); longest >= 1500 {
		t.Errorf("control leg without rendered padding must stay below a 1500-byte filler run (the pin's built-in default caps at 1000), longest run is %d", longest)
	}
}
