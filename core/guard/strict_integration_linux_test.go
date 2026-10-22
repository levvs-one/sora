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
	"syscall"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/session"
)

func TestStrictNftIntegration(t *testing.T) {
	switch os.Getenv("SORA_NFT_STAGE") {
	case "other-user", "other-user-baseline":
		for _, host := range []string{"203.0.113.2", "2001:db8::2"} {
			tcp, udp := strictHTTPReachable(t.Context(), host), strictUDPReachable(t.Context(), host)
			if os.Getenv("SORA_NFT_STAGE") == "other-user-baseline" {
				if !tcp || !udp {
					t.Fatalf("another UID cannot reach baseline endpoint %s: TCP=%v UDP=%v", host, tcp, udp)
				}
			} else if tcp || udp {
				t.Fatalf("another UID reached endpoint %s", host)
			}
		}
		return
	case "peer":
		packet, err := (&net.ListenConfig{}).ListenPacket(t.Context(), "udp", ":8080")
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = packet.Close() }()
		go func() {
			buf := make([]byte, 128)
			for {
				n, addr, err := packet.ReadFrom(buf)
				if err != nil {
					return
				}
				if _, err := packet.WriteTo(buf[:n], addr); err != nil {
					return
				}
			}
		}()
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
		firewall, _ := NewNftables(0, nil)
		g, _ := New(Options{DataDir: os.Getenv("SORA_NFT_DIR"), EnginePorts: []uint16{7890}}, firewall)
		if err := g.Apply(t.Context(), session.Settings{StrictKillSwitch: true, Endpoints: []session.Endpoint{{Address: netip.MustParseAddrPort("203.0.113.2:8080"), Protocol: "tcp"}, {Address: netip.MustParseAddrPort("[2001:db8::2]:8080"), Protocol: "udp"}}}); err != nil {
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
		args := []string{"-Urn"}
		if os.Getuid() == 0 {
			// Keep all UID mappings for the root-only cross-account regression.
			args = []string{"-n"}
		}
		args = append(args, os.Args[0], "-test.run=^TestStrictNftIntegration$", "-test.v")
		cmd := exec.CommandContext(t.Context(), "unshare", args...)
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
	reaches := func(host string) bool { return strictHTTPReachable(t.Context(), host) }
	deadline := time.Now().Add(5 * time.Second)
	for !reaches("2001:db8::2") && time.Now().Before(deadline) {
		time.Sleep(50 * time.Millisecond)
	}
	for _, host := range []string{"203.0.113.2", "192.168.50.2", "2001:db8::2", "fd00::2"} {
		if !reaches(host) || !strictUDPReachable(t.Context(), host) {
			t.Fatalf("baseline unreachable: %s", host)
		}
	}
	checkOtherUID := func(stage string) {
		t.Helper()
		t.Run(stage, func(t *testing.T) {
			cmd := exec.CommandContext(t.Context(), os.Args[0], "-test.run=^TestStrictNftIntegration$", "-test.v")
			cmd.Env = append(os.Environ(), "SORA_NFT_STAGE="+stage)
			cmd.SysProcAttr = &syscall.SysProcAttr{Credential: &syscall.Credential{Uid: 999, Gid: 999, NoSetGroups: true}}
			output, err := cmd.CombinedOutput()
			if err != nil {
				if len(output) == 0 && os.Getenv("SORA_NFT_REQUIRED") == "" {
					t.Skipf("another UID is unavailable in this user namespace: %v", err)
				}
				t.Fatalf("UID restriction: %v\n%s", err, output)
			}
			t.Log(string(output))
		})
	}
	checkOtherUID("other-user-baseline")
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
		if !reaches("203.0.113.2") || !strictUDPReachable(t.Context(), "2001:db8::2") {
			t.Fatal("engine VPN endpoint blocked")
		}
		if strictUDPReachable(t.Context(), "203.0.113.2") || reaches("2001:db8::2") {
			t.Fatal("endpoint allowed the wrong transport")
		}
		checkOtherUID("other-user")
		for _, host := range []string{"192.168.50.2", "fd00::2"} {
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
	firewall, _ := NewNftables(0, nil)
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

	// Carrier addresses are discovered after joining a room. Only the service
	// account receives the dynamic exception, and a protocol change removes it.
	policy.AllowLAN = false
	policy.OLCRTC = true
	if err := g.Apply(t.Context(), policy); err != nil {
		t.Fatal(err)
	}
	if !reaches("2001:db8::2") || !strictUDPReachable(t.Context(), "203.0.113.2") {
		t.Fatal("olcrtc dynamic ICE traffic blocked")
	}
	checkOtherUID("other-user")
	policy.OLCRTC = false
	if err := g.Apply(t.Context(), policy); err != nil {
		t.Fatal(err)
	}
	if reaches("2001:db8::2") || strictUDPReachable(t.Context(), "203.0.113.2") {
		t.Fatal("olcrtc exception survived a protocol change")
	}
	t.Log("real nft: olcrtc dynamic ICE allowed for service UID only; exception removed on protocol change")
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
	t.Log("real nft: IPv4/IPv6 blocked, engine UID and endpoint transports restricted, LAN policy allowed, SIGKILL protection retained, recovery reapplied, repeated Disconnect removed all rules")
}

func strictHTTPReachable(ctx context.Context, host string) bool {
	client := &http.Client{Timeout: 500 * time.Millisecond, Transport: &http.Transport{DisableKeepAlives: true}}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+net.JoinHostPort(host, "8080"), nil)
	if err != nil {
		return false
	}
	response, err := client.Do(request)
	if err != nil {
		return false
	}
	_ = response.Body.Close()
	return response.StatusCode == 204
}

func strictUDPReachable(ctx context.Context, host string) bool {
	conn, err := (&net.Dialer{}).DialContext(ctx, "udp", net.JoinHostPort(host, "8080"))
	if err != nil {
		return false
	}
	defer func() { _ = conn.Close() }()
	if err := conn.SetDeadline(time.Now().Add(500 * time.Millisecond)); err != nil {
		return false
	}
	if _, err := conn.Write([]byte("endpoint probe")); err != nil {
		return false
	}
	buf := make([]byte, 128)
	n, err := conn.Read(buf)
	return err == nil && string(buf[:n]) == "endpoint probe"
}
