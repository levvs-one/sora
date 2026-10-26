//go:build windows

package winws

import (
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"syscall"
	"testing"
	"unsafe"

	"github.com/gopacket/gopacket"
	"github.com/gopacket/gopacket/layers"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

// These are private generated packets, never packets from a real interface.
// Layout/flag positions follow the pinned v2.2.2 WINDIVERT_ADDRESS header.
type divertAddress struct {
	Timestamp int64
	Flags     uint32
	Reserved  uint32
	Data      [64]byte
}

func TestNativePinnedWinws(t *testing.T) {
	if os.Getenv("SORA_ISOLATED_ZAPRET_TEST") != "1" {
		t.Skip("requires the explicit disposable Windows driver CI fixture")
	}
	if os.Getenv("GITHUB_ACTIONS") != "true" || os.Getenv("RUNNER_OS") != "Windows" {
		t.Fatal("refusing native driver fixture outside disposable Windows CI")
	}
	dir := os.Getenv("SORA_WINWS_FIXTURE_DIR")
	if !filepath.IsAbs(dir) {
		t.Fatal("a private absolute fixture directory is required")
	}
	binary := filepath.Join(dir, "winws.exe")
	held, err := lockBundle(binary)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := held.Close(); err != nil {
			t.Error(err)
		}
	}()
	if file, err := os.OpenFile(binary, os.O_WRONLY, 0); err == nil {
		_ = file.Close()
		t.Fatal("verified executable still permits a write handle")
	}
	if err := checkDriverService(binary, false); err != nil {
		t.Fatal(err)
	}
	t.Log("native bundle locks, exact digests and cached driver trust passed")
	dll, err := windows.LoadDLL(filepath.Join(dir, "WinDivert.dll"))
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := dll.Release(); err != nil {
			t.Error(err)
		}
	}()
	eval, err := dll.FindProc("WinDivertHelperEvalFilter")
	if err != nil {
		t.Fatal(err)
	}
	if unsafe.Sizeof(divertAddress{}) != 80 {
		t.Fatal("incorrect pinned address ABI size")
	}
	strategies := []engine.BypassStrategy{
		{SplitPos: []string{"1", "midsld"}, Disorder: true},
		{SplitPos: []string{"1"}},
		{SplitPos: []string{"2"}, HostCase: true, DomainCase: true, MethodEOL: true},
	}
	for i, strategy := range strategies {
		t.Run(fmt.Sprintf("profile%d", i), func(t *testing.T) {
			args, err := Args(strategy)
			if err != nil {
				t.Fatal(err)
			}
			ctx := t.Context()
			if err := supervise.Check(ctx, supervise.Spec{Name: "Winws dry-run", Path: binary, Dir: dir,
				Args: append(slices.Clone(args), "--dry-run")}); err != nil {
				t.Fatal(err)
			}
			filterPath := filepath.Join(dir, fmt.Sprintf("profile-%d.filter", i))
			if err := supervise.Check(ctx, supervise.Spec{Name: "Winws filter", Path: binary, Dir: dir,
				Args: append(slices.Clone(args), "--wf-save="+filterPath)}); err != nil {
				t.Fatal(err)
			}
			raw, err := os.ReadFile(filterPath)
			if err != nil {
				t.Fatal(err)
			}
			if len(raw) == 0 || len(raw) > 16384 {
				t.Fatal("unexpected generated filter length")
			}
			evaluatePinnedScope(t, eval, string(raw))
		})
	}
	if t.Failed() {
		t.Fatal("generated native filter checks failed; refusing driver startup")
	}
	// Only this literal no-capture filter reaches the actual kernel driver.
	// The production start/readiness/query/stop APIs run unchanged.
	ctx := t.Context()
	runtime := &Engine{binary: binary, home: dir}
	child, err := runtime.start(ctx, []string{"--wf-raw=false"})
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := child.Stop(context.WithoutCancel(ctx), 0); err != nil {
			t.Error(err)
		}
		if !child.Exited() {
			t.Error("owned no-capture child survived stop")
		}
		if err := os.WriteFile(filepath.Join(dir, "winws.log"), []byte(child.Output().Last(80)), 0o600); err != nil {
			t.Error(err)
		}
	}()
	if err := waitReady(ctx, child); err != nil {
		t.Fatal(err)
	}
	if err := checkDriverService(binary, true); err != nil {
		t.Fatal(err)
	}
	t.Logf("production no-capture startup ready, loaded driver identity confirmed, owned PID=%d", child.PID())
}

func evaluatePinnedScope(t *testing.T, eval *windows.Proc, filter string) {
	t.Helper()
	// Positive/negative controls make an incorrect ABI/parser fail, rather than
	// accidentally treating an API error or an all-false matcher as containment.
	for _, control := range []struct {
		filter                   string
		outbound, loopback, want bool
	}{
		{"true", true, false, true}, {"false", true, false, false},
		{"outbound", true, false, true}, {"inbound", true, false, false},
		{"loopback", true, true, true}, {"loopback", true, false, false},
		{"ip", true, false, true}, {"ipv6", true, false, false},
	} {
		packet, addr := syntheticPacket(t, false, false, "8.8.8.8", 443, control.outbound, control.loopback, false)
		if got := evalPinned(t, eval, control.filter, packet, &addr); got != control.want {
			t.Fatalf("ABI control %q = %v, want %v", control.filter, got, control.want)
		}
	}
	for _, tc := range []struct {
		name, remote                             string
		port                                     uint16
		v6, udp, inbound, loopback, synACK, want bool
	}{
		{name: "public TCP80", remote: "8.8.8.8", port: 80, want: true},
		{name: "public TCP443", remote: "8.8.8.8", port: 443, want: true},
		{name: "unrelated port", remote: "8.8.8.8", port: 8443},
		{name: "UDP443", remote: "8.8.8.8", port: 443, udp: true},
		{name: "carrier NAT is not an upstream LAN exclusion", remote: "100.64.0.1", port: 443, want: true},
		{name: "private10", remote: "10.0.0.1", port: 443},
		{name: "private172", remote: "172.16.0.1", port: 443},
		{name: "private192", remote: "192.168.1.1", port: 80},
		{name: "linklocal", remote: "169.254.1.1", port: 443},
		{name: "loopback address", remote: "127.0.0.1", port: 443},
		{name: "loopback flag", remote: "8.8.8.8", port: 443, loopback: true},
		{name: "IPv6 TCP443", remote: "2606:4700:4700::1111", port: 443, v6: true, want: true},
		{name: "IPv6 unrelated", remote: "2606:4700:4700::1111", port: 22, v6: true},
		{name: "IPv6 UDP", remote: "2606:4700:4700::1111", port: 443, v6: true, udp: true},
		{name: "IPv6 ULA", remote: "fd00::1", port: 443, v6: true},
		{name: "IPv6 linklocal", remote: "fe80::1", port: 443, v6: true},
		{name: "IPv6 loopback", remote: "::1", port: 443, v6: true},
		{name: "inbound ordinary payload", remote: "8.8.8.8", port: 443, inbound: true},
		{name: "inbound SYNACK", remote: "8.8.8.8", port: 443, inbound: true, synACK: true, want: true},
		{name: "inbound unrelated SYNACK", remote: "8.8.8.8", port: 22, inbound: true, synACK: true},
		{name: "inbound private SYNACK", remote: "192.168.1.1", port: 443, inbound: true, synACK: true},
		{name: "IPv6 inbound SYNACK", remote: "2606:4700:4700::1111", port: 443, v6: true, inbound: true, synACK: true, want: true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			packet, addr := syntheticPacket(t, tc.v6, tc.udp, tc.remote, tc.port, !tc.inbound, tc.loopback, tc.synACK)
			if got := evalPinned(t, eval, filter, packet, &addr); got != tc.want {
				t.Fatalf("actual generated filter=%v, want %v\n%s", got, tc.want, filter)
			}
		})
	}
}

func evalPinned(t *testing.T, proc *windows.Proc, filter string, packet []byte, addr *divertAddress) bool {
	t.Helper()
	text, err := windows.BytePtrFromString(strings.TrimSpace(filter))
	if err != nil {
		t.Fatal(err)
	}
	result, _, callErr := proc.Call(uintptr(unsafe.Pointer(text)), uintptr(unsafe.Pointer(&packet[0])),
		uintptr(len(packet)), uintptr(unsafe.Pointer(addr)))
	if result == 0 && !errors.Is(callErr, syscall.Errno(0)) {
		t.Fatalf("filter evaluation API error: %v", callErr)
	}
	return result != 0
}

func syntheticPacket(t *testing.T, v6, udp bool, remote string, port uint16, outbound, loopback, synACK bool) ([]byte, divertAddress) {
	t.Helper()
	local := "192.0.2.10"
	if v6 {
		local = "2001:db8::10"
	}
	src, dst := net.ParseIP(local), net.ParseIP(remote)
	srcPort, dstPort := uint16(50123), port
	if !outbound {
		src, dst = dst, src
		srcPort, dstPort = dstPort, srcPort
	}
	protocol := layers.IPProtocolTCP
	if udp {
		protocol = layers.IPProtocolUDP
	}
	var network gopacket.NetworkLayer
	var outer gopacket.SerializableLayer
	if v6 {
		layer := &layers.IPv6{Version: 6, HopLimit: 64, NextHeader: protocol, SrcIP: src, DstIP: dst}
		network, outer = layer, layer
	} else {
		layer := &layers.IPv4{Version: 4, TTL: 64, Protocol: protocol, SrcIP: src, DstIP: dst}
		network, outer = layer, layer
	}
	var transport gopacket.SerializableLayer
	if udp {
		layer := &layers.UDP{SrcPort: layers.UDPPort(srcPort), DstPort: layers.UDPPort(dstPort)}
		if err := layer.SetNetworkLayerForChecksum(network); err != nil {
			t.Fatal(err)
		}
		transport = layer
	} else {
		layer := &layers.TCP{SrcPort: layers.TCPPort(srcPort), DstPort: layers.TCPPort(dstPort), ACK: true, SYN: synACK, Window: 65535}
		if err := layer.SetNetworkLayerForChecksum(network); err != nil {
			t.Fatal(err)
		}
		transport = layer
	}
	buf := gopacket.NewSerializeBuffer()
	if err := gopacket.SerializeLayers(buf, gopacket.SerializeOptions{FixLengths: true, ComputeChecksums: true}, outer, transport, gopacket.Payload([]byte("private synthetic fixture"))); err != nil {
		t.Fatal(err)
	}
	addr := divertAddress{}
	if outbound {
		addr.Flags |= 1 << 17
	}
	if loopback {
		addr.Flags |= 1 << 18
	}
	if v6 {
		addr.Flags |= 1 << 20
	}
	return slices.Clone(buf.Bytes()), addr
}
