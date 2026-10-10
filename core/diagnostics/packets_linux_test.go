//go:build linux

package diagnostics_test

import (
	"context"
	"io"
	"net"
	"os"
	"os/exec"
	"sync"
	"testing"
	"time"

	"golang.org/x/sys/unix"

	"github.com/levvs-one/sora-client/core/diagnostics"
)

func TestNativeLinuxOwnedTunCapture(t *testing.T) {
	if os.Getenv("SORA_ISOLATED_PACKET_TEST") != "1" {
		t.Skip("requires a private user/network namespace")
	}
	current, err := os.Readlink("/proc/self/ns/net")
	if err != nil {
		t.Fatal(err)
	}
	// PID 1's namespace link can be unreadable after entering a user
	// namespace. The launcher records its own namespace before unshare.
	host := os.Getenv("SORA_ORIGINAL_NETNS")
	if host == "" || current == host {
		t.Fatal("refusing to create a TUN in the host network namespace")
	}
	descriptor, err := unix.Open("/dev/net/tun", unix.O_RDWR|unix.O_CLOEXEC|unix.O_NONBLOCK, 0)
	if err != nil {
		t.Fatal(err)
	}
	file := os.NewFile(uintptr(descriptor), "sora0")
	defer func() { _ = file.Close() }()
	request, err := unix.NewIfreq("sora0")
	if err != nil {
		t.Fatal(err)
	}
	request.SetUint16(unix.IFF_TUN | unix.IFF_NO_PI)
	if err := unix.IoctlIfreq(descriptor, unix.TUNSETIFF, request); err != nil {
		t.Fatal(err)
	}
	for _, args := range [][]string{{"address", "add", "10.241.0.1/24", "dev", "sora0"}, {"link", "set", "sora0", "up"}} {
		if output, err := exec.CommandContext(context.Background(), "ip", args...).CombinedOutput(); err != nil {
			t.Fatalf("ip %v: %s, %v", args, output, err)
		}
	}
	reader := make(chan error, 1)
	go func() { _, err := io.Copy(io.Discard, file); reader <- err }()
	client, err := net.DialUDP("udp", nil, &net.UDPAddr{IP: net.ParseIP("10.241.0.2"), Port: 32145})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = client.Close() }()
	sending, cancelSending := context.WithCancel(context.Background())
	defer cancelSending()
	sent := make(chan struct{})
	go func() {
		defer close(sent)
		ticker := time.NewTicker(10 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-sending.Done():
				return
			case <-ticker.C:
				_, _ = client.Write([]byte("Sora isolated packet capture"))
			}
		}
	}()
	var captures sync.WaitGroup
	for range 2 {
		captures.Go(func() {
			data, err := diagnostics.CapturePackets(context.Background(), "sora0", 300*time.Millisecond)
			if err != nil {
				t.Error(err)
				return
			}
			checkPackets(t, data)
		})
	}
	captures.Wait()
	canceled, cancel := context.WithCancel(context.Background())
	cancel()
	started := time.Now()
	if _, err := diagnostics.CapturePackets(canceled, "sora0", 10*time.Second); err == nil {
		t.Error("cancelled capture succeeded")
	}
	if time.Since(started) > time.Second {
		t.Error("cancellation failed to unblock capture")
	}
	cancelSending()
	<-sent
	_ = file.Close()
	select {
	case <-reader:
	case <-time.After(time.Second):
		t.Fatal("TUN reader did not release")
	}
}
