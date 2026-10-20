//go:build linux

package bypass

import (
	"context"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
)

// Integration test for the nfqws executor against the real kernel
// path: real nftables, the real sora_nfqws table, and (for the
// delivery subtest) a real nfqws binary consuming the queue.
//
// Gated: it mutates host firewall state, so it runs only when
// SORA_NFQWS_IT=1, as root, with SORA_NFQWS_BIN pointing at an nfqws
// binary (build one with packaging/zapret/build.sh). It cleans the
// table up after itself either way.
func TestNFQWSExecutorIntegration(t *testing.T) {
	if os.Getenv("SORA_NFQWS_IT") != "1" {
		t.Skip("set SORA_NFQWS_IT=1 to run the nfqws integration test")
	}
	if os.Geteuid() != 0 {
		t.Skip("the integration test installs nftables rules; run as root")
	}
	bin := os.Getenv("SORA_NFQWS_BIN")
	if bin == "" {
		t.Skip("set SORA_NFQWS_BIN to a built nfqws binary")
	}
	// Environment probes: this test needs a kernel that can queue
	// (nfnetlink_queue) and UDP delivery to the host's own address.
	// Sandboxes without them skip with the reason instead of failing:
	// the executor's contract is verified wherever the platform can
	// run it at all.
	if !kernelCanQueue(t) {
		t.Skip("kernel lacks nfnetlink_queue: nft rejects queue rules in this environment")
	}
	host := hostIPv4(t)
	assets := fakeAssets(t)

	// Whatever happens, the table must not outlive the test.
	t.Cleanup(func() {
		_ = exec.Command("/usr/sbin/nft", "delete", "table", "inet", nftTable).Run()
	})

	listener, err := net.ListenUDP("udp", &net.UDPAddr{IP: net.IPv4zero, Port: 443})
	if err != nil {
		t.Fatalf("listen udp/443: %v", err)
	}
	defer listener.Close()
	dst := &net.UDPAddr{IP: net.ParseIP(host), Port: 443}

	initial, err := os.ReadFile(filepath.Join(assets, "fake", defaultQUICFake))
	if err != nil {
		t.Fatal(err)
	}
	// Baseline probe at the parent level: if the environment cannot
	// deliver UDP to the host's own address at all, no subtest below
	// can mean anything.
	{
		conn, err := net.DialUDP("udp", nil, dst)
		if err != nil {
			t.Skipf("cannot dial the host's own address: %v", err)
		}
		_, werr := conn.Write(initial)
		_ = conn.Close()
		_ = listener.SetReadDeadline(time.Now().Add(2 * time.Second))
		buf := make([]byte, 4096)
		n, _, rerr := listener.ReadFromUDP(buf)
		if werr != nil || rerr != nil || n == 0 {
			t.Skipf("UDP to the host's own address is not delivered in this environment (write: %v, read: %v)", werr, rerr)
		}
	}
	strategy := engine.BypassStrategy{
		Desync: []string{"fake"}, FakeQUIC: "quic", FilterUDP: "443", FilterL7: "quic",
	}
	plan := nfqPlan(strategy)

	send := func() {
		conn, err := net.DialUDP("udp", nil, dst)
		if err != nil {
			t.Fatalf("dial: %v", err)
		}
		defer conn.Close()
		if _, err := conn.Write(initial); err != nil {
			t.Fatalf("write: %v", err)
		}
	}
	recv := func(timeout time.Duration) bool {
		_ = listener.SetReadDeadline(time.Now().Add(timeout))
		buf := make([]byte, 4096)
		n, _, err := listener.ReadFromUDP(buf)
		return err == nil && n > 0
	}

	t.Run("baseline without interception arrives", func(t *testing.T) {
		send()
		if !recv(2 * time.Second) {
			t.Fatal("baseline datagram did not arrive although the parent probe delivered one")
		}
	})

	t.Run("undrained queue holds the packet, removal frees it", func(t *testing.T) {
		// A fake nfqws (a sleeper) never drains the queue: if the
		// datagram now vanishes, the steering rules are really
		// installed — the executor's failure mode without a consumer
		// is the blackhole the lifecycle rules exist to prevent.
		e := Wrap(stubEngine{}, Binaries{NFQWS: fakeNFQWS(t), Assets: assets}, t.TempDir(), nil)
		if err := e.Apply(context.Background(), plan); err != nil {
			t.Fatalf("apply: %v", err)
		}
		send()
		if recv(1500 * time.Millisecond) {
			t.Fatal("datagram arrived although the queue has no consumer; steering is not real")
		}
		if err := e.Close(); err != nil {
			t.Fatalf("close: %v", err)
		}
		if tableExists(t) {
			t.Fatal("the sora_nfqws table survived Close")
		}
		send()
		if !recv(2 * time.Second) {
			t.Fatal("datagram did not arrive after the rules were removed")
		}
	})

	t.Run("real nfqws delivers the QUIC Initial", func(t *testing.T) {
		e := Wrap(stubEngine{}, Binaries{NFQWS: bin, Assets: assets}, t.TempDir(), nil)
		if err := e.Apply(context.Background(), plan); err != nil {
			t.Fatalf("apply with real nfqws: %v", err)
		}
		defer func() { _ = e.Close() }()
		out, err := exec.Command("/usr/sbin/nft", "list", "table", "inet", nftTable).CombinedOutput()
		if err != nil || !strings.Contains(string(out), "queue num 200") {
			t.Fatalf("table state: %v\n%s", err, out)
		}
		send()
		if !recv(3 * time.Second) {
			t.Fatal("the QUIC Initial did not arrive through the real nfqws")
		}
		if err := e.Close(); err != nil {
			t.Fatalf("close: %v", err)
		}
		if tableExists(t) {
			t.Fatal("the sora_nfqws table survived Close")
		}
	})
}

func tableExists(t *testing.T) bool {
	t.Helper()
	return exec.Command("/usr/sbin/nft", "list", "table", "inet", nftTable).Run() == nil
}

// kernelCanQueue probes NFQUEUE support with a throwaway table whose
// single rule queues one port nobody uses, then removes it.
func kernelCanQueue(t *testing.T) bool {
	t.Helper()
	probe := "add table inet sora_nfqws_probe\n" +
		"add chain inet sora_nfqws_probe output { type filter hook output priority -150; policy accept; }\n" +
		"add rule inet sora_nfqws_probe output udp dport 64535 queue num 65535\n"
	cmd := exec.Command("/usr/sbin/nft", "-f", "-")
	cmd.Stdin = strings.NewReader(probe)
	err := cmd.Run()
	_ = exec.Command("/usr/sbin/nft", "delete", "table", "inet", "sora_nfqws_probe").Run()
	return err == nil
}

func hostIPv4(t *testing.T) string {
	t.Helper()
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		t.Fatal(err)
	}
	for _, a := range addrs {
		if ipnet, ok := a.(*net.IPNet); ok && !ipnet.IP.IsLoopback() && ipnet.IP.To4() != nil {
			return ipnet.IP.String()
		}
	}
	t.Fatal("no non-loopback IPv4 address")
	return ""
}

// fakeAssets assembles the shipped zapret assets layout (fake/
// payloads) in a temp dir from the vendored zapret tree.
func fakeAssets(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	src := filepath.Join("..", "..", "..", "third_party", "zapret", "files", "fake")
	entries, err := os.ReadDir(src)
	if err != nil {
		t.Skipf("vendored fake payloads unavailable: %v", err)
	}
	dst := filepath.Join(root, "fake")
	if err := os.MkdirAll(dst, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		data, err := os.ReadFile(filepath.Join(src, entry.Name()))
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(dst, entry.Name()), data, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

// TestNFTInterceptorAgainstRealKernel exercises the interceptor
// against the host's real nftables as far as this kernel allows: the
// sweep must remove a table a crashed predecessor left behind, and a
// Sync the kernel rejects (no nfnetlink_queue here) must leave no
// partial table — the batch is atomic. Gated on root + a real nft so
// ordinary test runs never touch host state.
func TestNFTInterceptorAgainstRealKernel(t *testing.T) {
	if os.Geteuid() != 0 {
		t.Skip("touches real nftables; run as root")
	}
	if _, err := os.Stat("/usr/sbin/nft"); err != nil {
		t.Skip("no /usr/sbin/nft on this host")
	}
	icept, err := newInterceptor()
	if err != nil {
		t.Fatalf("newInterceptor: %v", err)
	}
	ctx := context.Background()
	t.Cleanup(func() { _ = icept.Sweep(ctx) })

	// Plant the stale table a crashed core would have left.
	plant := exec.Command("/usr/sbin/nft", "-f", "-")
	plant.Stdin = strings.NewReader("add table inet " + nftTable + "\n")
	if out, err := plant.CombinedOutput(); err != nil {
		t.Fatalf("planting the stale table: %v (%s)", err, out)
	}
	if !tableExists(t) {
		t.Fatal("the stale table was not planted")
	}
	if err := icept.Sweep(ctx); err != nil {
		t.Fatalf("sweep: %v", err)
	}
	if tableExists(t) {
		t.Fatal("the sweep left the stale table behind")
	}

	// A Sync this kernel cannot serve must fail and leave nothing.
	err = icept.Sync(ctx, []QueueSpec{{Queue: queueBase, UDPPorts: "443"}})
	if err == nil {
		// The kernel could queue after all: the full integration
		// test above is the one that verifies delivery; here just
		// confirm the table landed and clean it.
		if !tableExists(t) {
			t.Fatal("sync succeeded but no table exists")
		}
		return
	}
	if tableExists(t) {
		t.Fatalf("a rejected sync left a partial table behind: %v", err)
	}
}

// TestNFQWSExecutorRealBinaryStartupFailure runs the executor against
// the real nfqws binary with a fake interceptor. On a host without
// nfnetlink_queue the binary dies opening the queue; the executor
// must catch that inside the startup window and fail closed with the
// binary's own words — never report a running filter. On a host with
// queue support the binary would stay up; this test then skips
// itself (the full integration test owns that path).
func TestNFQWSExecutorRealBinaryStartupFailure(t *testing.T) {
	if os.Getenv("SORA_NFQWS_IT") != "1" {
		t.Skip("set SORA_NFQWS_IT=1 to run the nfqws integration test")
	}
	bin := os.Getenv("SORA_NFQWS_BIN")
	if bin == "" {
		t.Skip("set SORA_NFQWS_BIN to a built nfqws binary")
	}
	// Probe: can the binary open a queue at all here?
	probe := exec.Command(bin, "--qnum=65535", "--filter-udp=64535", "--dpi-desync=fake")
	out, err := probe.CombinedOutput()
	if err == nil || probe.ProcessState == nil {
		t.Skip("the probe did not run")
	}
	if probe.ProcessState.ExitCode() == 0 {
		t.Skip("nfqws stayed up; queue support exists here")
	}
	_ = out

	e, _ := nfqEngine(t, Binaries{NFQWS: bin, Assets: fakeAssets(t)})
	strategy := engine.BypassStrategy{
		Desync: []string{"fake"}, FakeQUIC: "quic", FilterUDP: "443", FilterL7: "quic",
	}
	err = e.Apply(context.Background(), nfqPlan(strategy))
	if err == nil {
		_ = e.Close()
		t.Skip("nfqws started under the executor; queue support exists here")
	}
	if !strings.Contains(err.Error(), "nfqws") {
		t.Fatalf("the failure must name nfqws and carry its output, got %v", err)
	}
	if len(e.filters) != 0 {
		t.Fatal("a filter stayed registered after the binary died at startup")
	}
}
