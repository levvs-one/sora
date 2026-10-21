package guard

import (
	"bufio"
	"context"
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/session"
)

func TestStrictNftIntegration(t *testing.T) {
	switch os.Getenv("SORA_NFT_STAGE") {
	case "peer":
		server := &http.Server{Addr: ":8080", ReadHeaderTimeout: time.Second, Handler: http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(204) })}
		listener, err := (&net.ListenConfig{}).Listen(t.Context(), "tcp", server.Addr)
		if err != nil {
			t.Fatal(err)
		}
		fmt.Println("READY")
		if err := server.Serve(listener); err != nil {
			t.Fatal(err)
		}
		return
	case "holder":
		firewall, _ := NewNftables(999, nil)
		g, _ := New(Options{DataDir: os.Getenv("SORA_NFT_DIR"), EnginePorts: []uint16{7890}}, firewall)
		if err := g.Apply(t.Context(), session.Settings{StrictKillSwitch: true, Endpoints: []netip.AddrPort{netip.MustParseAddrPort("203.0.113.2:8080")}}); err != nil {
			t.Fatal(err)
		}
		fmt.Println("READY")
		<-t.Context().Done()
		return
	case "network":
		// All mutations are confined to the user + network namespace created below.
		if os.Getuid() != 0 {
			t.Fatal("expected isolated root")
		}
	default:
		for _, tool := range []string{"unshare", "nsenter", "ip", "nft"} {
			if _, err := exec.LookPath(tool); err != nil {
				if os.Getenv("SORA_NFT_REQUIRED") != "" {
					t.Fatal(tool + " unavailable")
				}
				t.Skip(tool + " unavailable")
			}
		}
		cmd := exec.CommandContext(t.Context(), "unshare", "-Urn", os.Args[0], "-test.run=^TestStrictNftIntegration$", "-test.v")
		cmd.Env = append(os.Environ(), "SORA_NFT_STAGE=network")
		output, err := cmd.CombinedOutput()
		// Some hosts (Ubuntu 24.04 runners among them) forbid unprivileged
		// user namespaces. CI runs this test again as root with
		// SORA_NFT_REQUIRED=1, where a skip would hide a real failure.
		if err != nil && strings.Contains(string(output), "uid_map") && os.Getenv("SORA_NFT_REQUIRED") == "" {
			t.Skipf("unprivileged user namespaces are not allowed here: %s", strings.TrimSpace(string(output)))
		}
		if err != nil {
			t.Fatalf("isolated nft integration: %v\n%s", err, output)
		}
		t.Log(string(output))
		return
	}
	run := func(args ...string) {
		t.Helper()
		output, err := exec.CommandContext(t.Context(), args[0], args[1:]...).CombinedOutput()
		if err != nil {
			t.Fatalf("%v: %v\n%s", args, err, output)
		}
	}
	start := func(stage string, args ...string) *exec.Cmd {
		t.Helper()
		cmd := exec.CommandContext(t.Context(), args[0], args[1:]...)
		cmd.Env = append(os.Environ(), "SORA_NFT_STAGE="+stage, "SORA_NFT_DIR="+t.TempDir())
		output, err := cmd.StdoutPipe()
		if err != nil {
			t.Fatal(err)
		}
		cmd.Stderr = os.Stderr
		if err := cmd.Start(); err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { _ = cmd.Process.Kill(); _ = cmd.Wait() })
		scanner := bufio.NewScanner(output)
		for scanner.Scan() {
			if scanner.Text() == "READY" {
				return cmd
			}
		}
		t.Fatal("child exited before readiness")
		return nil
	}
	run("ip", "link", "set", "lo", "up")
	peer := start("peer", "unshare", "-n", os.Args[0], "-test.run=^TestStrictNftIntegration$")
	run("ip", "link", "add", "test0", "type", "veth", "peer", "name", "peer0")
	run("ip", "link", "set", "peer0", "netns", fmt.Sprint(peer.Process.Pid))
	for _, address := range []string{"203.0.113.1/24", "192.168.50.1/24", "2001:db8::1/64", "fd00::1/64"} {
		run("ip", "addr", "add", address, "dev", "test0")
	}
	run("ip", "link", "set", "test0", "up")
	for _, address := range []string{"203.0.113.2/24", "192.168.50.2/24", "2001:db8::2/64", "fd00::2/64"} {
		run("nsenter", "-t", fmt.Sprint(peer.Process.Pid), "-n", "ip", "addr", "add", address, "dev", "peer0")
	}
	run("nsenter", "-t", fmt.Sprint(peer.Process.Pid), "-n", "ip", "link", "set", "peer0", "up")
	// DAD must complete before IPv6 reachability is tested.
	run("nsenter", "-t", fmt.Sprint(peer.Process.Pid), "-n", "ip", "link", "set", "lo", "up")
	client := &http.Client{Timeout: 500 * time.Millisecond, Transport: &http.Transport{DisableKeepAlives: true}}
	reaches := func(host string) bool {
		request, err := http.NewRequestWithContext(t.Context(), http.MethodGet, "http://"+net.JoinHostPort(host, "8080"), nil)
		if err != nil {
			t.Fatal(err)
		}
		res, err := client.Do(request)
		if err != nil {
			return false
		}
		_ = res.Body.Close()
		return res.StatusCode == 204
	}
	deadline := time.Now().Add(5 * time.Second)
	for !reaches("2001:db8::2") && time.Now().Before(deadline) {
		time.Sleep(50 * time.Millisecond)
	}
	for _, host := range []string{"203.0.113.2", "192.168.50.2", "2001:db8::2", "fd00::2"} {
		if !reaches(host) {
			t.Fatalf("baseline unreachable: %s", host)
		}
	}
	holder := start("holder", os.Args[0], "-test.run=^TestStrictNftIntegration$")
	dir := ""
	for _, value := range holder.Env {
		if strings.HasPrefix(value, "SORA_NFT_DIR=") {
			dir = strings.TrimPrefix(value, "SORA_NFT_DIR=")
		}
	}
	loopback := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(204) }))
	defer loopback.Close()
	verify := func() {
		t.Helper()
		req, err := http.NewRequestWithContext(t.Context(), http.MethodGet, loopback.URL, nil)
		if err != nil {
			t.Fatal(err)
		}
		response, err := client.Do(req)
		if err != nil {
			t.Fatalf("loopback blocked: %v", err)
		}
		_ = response.Body.Close()
		if !reaches("203.0.113.2") {
			t.Fatal("VPN endpoint blocked")
		}
		for _, host := range []string{"192.168.50.2", "2001:db8::2", "fd00::2"} {
			if reaches(host) {
				t.Fatalf("leak: %s", host)
			}
		}
	}
	verify()
	if err := holder.Process.Kill(); err != nil {
		t.Fatal(err)
	}
	verify()
	run("nft", "delete", "table", "inet", "sora")
	firewall, _ := NewNftables(999, nil)
	g, _ := New(Options{DataDir: dir, EnginePorts: []uint16{7890}}, firewall)
	if err := g.Recover(t.Context()); err != nil {
		t.Fatal(err)
	}
	verify()
	// Explicit LAN policy is live and retains the outside block.
	policy := g.Current()
	policy.AllowLAN = true
	if err := g.Apply(t.Context(), policy); err != nil {
		t.Fatal(err)
	}
	if !reaches("192.168.50.2") || !reaches("fd00::2") || reaches("2001:db8::2") {
		t.Fatal("LAN policy incorrect")
	}
	if err := g.Release(context.Background()); err != nil {
		t.Fatal(err)
	}
	if err := g.Release(context.Background()); err != nil {
		t.Fatal(err)
	}
	for _, host := range []string{"203.0.113.2", "192.168.50.2", "2001:db8::2", "fd00::2"} {
		if !reaches(host) {
			t.Fatalf("cleanup stranded %s", host)
		}
	}
	output, err := exec.CommandContext(t.Context(), "nft", "list", "tables").Output()
	if err != nil || strings.Contains(string(output), "sora") {
		t.Fatalf("cleanup left rules: %s, %v", output, err)
	}
	t.Log("real nft: IPv4/IPv6 blocked, endpoint and LAN policy allowed, SIGKILL protection retained, recovery reapplied, repeated Disconnect removed all rules")
}
