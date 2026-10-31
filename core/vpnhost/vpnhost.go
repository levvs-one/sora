// Package vpnhost talks to the Android app around the core. Android keeps the
// VPN adapter in the app's VpnService, so the core asks the app for it over a
// local socket and receives the descriptor as ancillary data.
package vpnhost

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"net/netip"
	"os"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

const (
	callTimeout = 15 * time.Second
	maxReply    = 4096
)

// Client reaches the app's socket in the abstract namespace. The app checks
// that the peer is its own user.
type Client struct {
	address *net.UnixAddr
}

// New names the socket the app listens on.
func New(name string) *Client {
	return &Client{address: &net.UnixAddr{Name: "@" + name, Net: "unix"}}
}

type request struct {
	Op        string   `json:"op"`
	Addresses []string `json:"addresses,omitempty"`
	DNS       []string `json:"dns,omitempty"`
	MTU       int      `json:"mtu,omitempty"`
}

type reply struct {
	Error string `json:"error,omitempty"`
	Event string `json:"event,omitempty"`
}

func (c *Client) dial(ctx context.Context) (*net.UnixConn, error) {
	conn, err := (&net.Dialer{}).DialContext(ctx, "unix", c.address.String())
	if err != nil {
		return nil, fmt.Errorf("vpnhost: reach the app: %w", err)
	}
	unixConn, ok := conn.(*net.UnixConn)
	if !ok {
		_ = conn.Close()
		return nil, errors.New("vpnhost: not a unix connection")
	}
	return unixConn, nil
}

func send(conn *net.UnixConn, r request) error {
	line, err := json.Marshal(r)
	if err != nil {
		return err
	}
	_, err = conn.Write(append(line, '\n'))
	return err
}

// Addresses lists what the adapter carries, as prefixes.
func addresses(t engine.Tun) []string {
	var out []string
	for _, prefix := range []netip.Prefix{t.IPv4, t.IPv6} {
		if prefix.IsValid() {
			out = append(out, prefix.String())
		}
	}
	return out
}

// resolver is the second address of the adapter's network, which the engines
// answer on, so every lookup enters the tunnel.
func resolver(t engine.Tun) []string {
	if !t.IPv4.IsValid() {
		return nil
	}
	return []string{t.IPv4.Addr().Next().String()}
}

// Open asks the app to bring the adapter up and returns its descriptor. The
// caller closes the file after handing it to an engine.
func (c *Client) Open(ctx context.Context, t engine.Tun) (*os.File, error) {
	ctx, cancel := context.WithTimeout(ctx, callTimeout)
	defer cancel()
	conn, err := c.dial(ctx)
	if err != nil {
		return nil, err
	}
	defer conn.Close()
	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
	}
	if err := send(conn, request{Op: "open", Addresses: addresses(t), DNS: resolver(t), MTU: t.MTU}); err != nil {
		return nil, fmt.Errorf("vpnhost: ask for the adapter: %w", err)
	}
	buf := make([]byte, maxReply)
	oob := make([]byte, rightsSpace)
	n, oobn, _, _, err := conn.ReadMsgUnix(buf, oob)
	if err != nil {
		return nil, fmt.Errorf("vpnhost: read the adapter: %w", err)
	}
	var answer reply
	if err := json.Unmarshal(buf[:n], &answer); err != nil {
		return nil, fmt.Errorf("vpnhost: read the answer: %w", err)
	}
	if answer.Error != "" {
		return nil, fmt.Errorf("vpnhost: %s", answer.Error)
	}
	// The app keeps its copy until this byte arrives.
	file, err := receivedFile(oob[:oobn])
	_, _ = conn.Write([]byte{0})
	return file, err
}

// Release tells the app the session no longer needs the adapter.
func (c *Client) Release(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, callTimeout)
	defer cancel()
	conn, err := c.dial(ctx)
	if err != nil {
		return err
	}
	defer conn.Close()
	if deadline, ok := ctx.Deadline(); ok {
		_ = conn.SetDeadline(deadline)
	}
	return send(conn, request{Op: "release"})
}

// Watch calls onRevoke when the system takes the VPN away, and onNetwork when
// the device moves to another network, until ctx ends. It reconnects while the
// app restarts.
func (c *Client) Watch(ctx context.Context, onRevoke, onNetwork func()) {
	for ctx.Err() == nil {
		if err := c.watch(ctx, onRevoke, onNetwork); err != nil {
			select {
			case <-ctx.Done():
			case <-time.After(time.Second):
			}
		}
	}
}

func (c *Client) watch(ctx context.Context, onRevoke, onNetwork func()) error {
	conn, err := c.dial(ctx)
	if err != nil {
		return err
	}
	defer conn.Close()
	stop := context.AfterFunc(ctx, func() { _ = conn.Close() })
	defer stop()
	if err := send(conn, request{Op: "watch"}); err != nil {
		return err
	}
	lines := bufio.NewScanner(conn)
	for lines.Scan() {
		var event reply
		if json.Unmarshal(lines.Bytes(), &event) != nil {
			continue
		}
		switch event.Event {
		case "revoked":
			onRevoke()
		case "network":
			onNetwork()
		}
	}
	if err := lines.Err(); err != nil {
		return err
	}
	return errors.New("vpnhost: the app closed the watch")
}
