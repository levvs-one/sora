// Package discovery advertises and finds sora-sync peers on the local
// network via mDNS. Devices meet at "_sora-sync._tcp"; the TXT record carries
// the device id so a joiner can pick the device whose QR it scanned.
package discovery

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"time"

	"github.com/hashicorp/mdns"
)

// ServiceName is the mDNS service type of sora-sync peers.
const ServiceName = "_sora-sync._tcp"

// Peer is a discovered device.
type Peer struct {
	// DeviceID comes from the TXT record.
	DeviceID string
	// Addr is a dialable TCP address of the peer.
	Addr string
	// Port is the peer's sync port.
	Port int
}

// Advertiser publishes this device on the LAN. Close stops it.
type Advertiser struct {
	server *mdns.Server
}

// Advertise publishes deviceID on port with the given TXT records.
func Advertise(deviceID string, port int) (*Advertiser, error) {
	if strings.TrimSpace(deviceID) == "" {
		return nil, errors.New("discovery: empty device id")
	}
	if port <= 0 || port > 65535 {
		return nil, fmt.Errorf("discovery: bad port %d", port)
	}
	host, err := os.Hostname()
	if err != nil {
		return nil, err
	}
	// mDNS wants a fully-qualified name.
	if !strings.HasSuffix(host, ".") {
		host += "."
	}
	ips := localIPs()
	service, err := mdns.NewMDNSService(
		"sora-sync-"+deviceID, ServiceName, "", host, port, ips,
		[]string{"id=" + deviceID, "v=1"},
	)
	if err != nil {
		return nil, fmt.Errorf("discovery: %w", err)
	}
	server, err := mdns.NewServer(&mdns.Config{Zone: service})
	if err != nil {
		return nil, fmt.Errorf("discovery: %w", err)
	}
	return &Advertiser{server: server}, nil
}

// Close stops advertising.
func (a *Advertiser) Close() error {
	if a == nil || a.server == nil {
		return nil
	}
	return a.server.Shutdown()
}

// localIPs returns the machine's non-loopback addresses for the mDNS
// announcement.
func localIPs() []net.IP {
	var out []net.IP
	interfaces, err := net.Interfaces()
	if err != nil {
		return nil
	}
	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		for _, a := range addrs {
			var ip net.IP
			switch v := a.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() || ip.IsLinkLocalUnicast() {
				continue
			}
			out = append(out, ip)
		}
	}
	return out
}

// Browse looks for sora-sync peers for up to timeout, calling found for each
// new device. It stops when ctx ends.
func Browse(ctx context.Context, timeout time.Duration, found func(Peer)) error {
	entries := make(chan *mdns.ServiceEntry, 16)
	params := mdns.DefaultParams(ServiceName)
	params.Timeout = timeout
	params.Entries = entries
	done := make(chan error, 1)
	go func() { done <- mdns.Query(params) }()
	seen := map[string]bool{}
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case err := <-done:
			return err
		case e := <-entries:
			id := txtValue(e.InfoFields, "id")
			if id == "" || seen[id] {
				continue
			}
			seen[id] = true
			addr := ""
			if e.AddrV4 != nil {
				addr = e.AddrV4.String()
			} else if e.AddrV6 != nil {
				addr = e.AddrV6.String()
			}
			if addr == "" {
				continue
			}
			found(Peer{DeviceID: id, Addr: addr, Port: e.Port})
		}
	}
}

// FindDevice browses until the device with id answers or timeout elapses.
func FindDevice(ctx context.Context, id string, timeout time.Duration) (Peer, error) {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	found := make(chan Peer, 1)
	go func() {
		_ = Browse(ctx, timeout, func(p Peer) {
			if p.DeviceID == id {
				select {
				case found <- p:
				default:
				}
			}
		})
	}()
	select {
	case p := <-found:
		return p, nil
	case <-ctx.Done():
		return Peer{}, fmt.Errorf("discovery: device %q not found on this network", id)
	}
}

func txtValue(fields []string, key string) string {
	for _, f := range fields {
		if v, ok := strings.CutPrefix(f, key+"="); ok {
			return v
		}
	}
	return ""
}
