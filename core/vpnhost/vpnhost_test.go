//go:build !windows

package vpnhost

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/netip"
	"os"
	"path/filepath"
	"testing"
	"time"

	"golang.org/x/sys/unix"

	"github.com/levvs-one/sora-client/core/engine"
)

// app stands in for the Kotlin side: one request per connection.
func app(t *testing.T, handle func(*net.UnixConn, request)) *Client {
	t.Helper()
	name := fmt.Sprintf("sora-test-%d-%d", os.Getpid(), time.Now().UnixNano())
	listener, err := net.ListenUnix("unix", &net.UnixAddr{Name: "@" + name, Net: "unix"})
	if err != nil {
		t.Skipf("abstract sockets: %v", err)
	}
	t.Cleanup(func() { _ = listener.Close() })
	go func() {
		for {
			conn, err := listener.AcceptUnix()
			if err != nil {
				return
			}
			go func() {
				defer conn.Close()
				line, err := bufio.NewReader(conn).ReadBytes('\n')
				if err != nil {
					return
				}
				var r request
				if json.Unmarshal(line, &r) == nil {
					handle(conn, r)
				}
			}()
		}
	}()
	return New(name)
}

func TestOpenReceivesTheAdapter(t *testing.T) {
	path := filepath.Join(t.TempDir(), "tun")
	if err := os.WriteFile(path, []byte("adapter"), 0o600); err != nil {
		t.Fatal(err)
	}
	var asked request
	client := app(t, func(conn *net.UnixConn, r request) {
		asked = r
		file, err := os.Open(path)
		if err != nil {
			return
		}
		defer file.Close()
		rights := unix.UnixRights(int(file.Fd()))
		_, _, _ = conn.WriteMsgUnix([]byte("{}\n"), rights, nil)
	})
	tun := engine.Tun{IPv4: netip.MustParsePrefix("192.0.2.1/30"), IPv6: netip.MustParsePrefix("2001:db8:5340::1/126"), MTU: 1500}
	file, err := client.Open(context.Background(), tun)
	if err != nil {
		t.Fatal(err)
	}
	defer file.Close()
	got, err := io.ReadAll(file)
	if err != nil || string(got) != "adapter" {
		t.Fatalf("read %q, %v", got, err)
	}
	if asked.Op != "open" || asked.MTU != 1500 || len(asked.Addresses) != 2 || asked.DNS[0] != "192.0.2.2" {
		t.Fatalf("request: %+v", asked)
	}
}

func TestOpenReportsARefusal(t *testing.T) {
	client := app(t, func(conn *net.UnixConn, _ request) {
		_, _ = conn.Write([]byte(`{"error":"consent missing"}`))
	})
	_, err := client.Open(context.Background(), engine.Tun{})
	if err == nil || err.Error() != "vpnhost: consent missing" {
		t.Fatalf("err = %v", err)
	}
}

func TestWatchDeliversEvents(t *testing.T) {
	client := app(t, func(conn *net.UnixConn, r request) {
		if r.Op == "watch" {
			_, _ = conn.Write([]byte("{\"event\":\"network\"}\n{\"event\":\"revoked\"}\n"))
			time.Sleep(time.Second)
		}
	})
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	revoked, moved := make(chan struct{}), 0
	go client.Watch(ctx, func() { close(revoked) }, func() { moved++ })
	select {
	case <-revoked:
	case <-ctx.Done():
		t.Fatal("no revoke")
	}
	if moved != 1 {
		t.Fatalf("network events: %d", moved)
	}
}
