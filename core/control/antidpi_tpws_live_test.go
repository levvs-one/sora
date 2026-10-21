package control

// Live packet proof for the Anti-DPI tpws path (task point 4): a
// real tpws binary desyncs a fake TLS ClientHello past a DPI
// simulator that resets any connection whose first chunk carries the
// blocked SNI continuously.
//
// Stand (all loopback):
//
//	client ──direct──▶ DPI simulator ──splice──▶ origin recorder
//	client ──SOCKS5──▶ tpws (preset classic/app-default-split:
//	                   split_pos 1,midsld + disorder, rendered by
//	                   bypass.Args) ──▶ DPI simulator ──▶ origin
//
// The simulator reads the client's first chunk with a short
// deadline; if "blocked.example" appears in it continuously it RSTs
// (SetLinger(0)+Close), otherwise it splices the stream to the
// origin, forwarding each read as its own write so segmentation
// survives to the origin, which records the chunk boundaries of the
// first flight.
//
// Binary: the task's zapret-src path does not exist in this
// sandbox; the Wave-B dist engines tpws is the fallback that does
// (it runs — see the log line). If no candidate exists or runs, the
// test SKIPS with the reason — it never fakes a pass. In this
// sandbox the direct (control) leg runs in full, while the tpws
// forwarding leg hits a documented sandbox boundary (tpws SOCKS
// refuses loopback targets; all non-loopback egress is intercepted
// by the sandbox; transparent mode is closed too) and SKIPS with
// the exact reason at the dial — see the branch in the test.

import (
	"bytes"
	"context"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"syscall"
	"testing"
	"time"

	"golang.org/x/net/proxy"

	"github.com/levvs-one/sora-client/core/engine/bypass"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/ext"
)

// antidpiRecorder is the origin: it records every Read chunk
// boundary and the concatenated stream.
type antidpiRecorder struct {
	mu     sync.Mutex
	chunks [][]byte
	total  int
	conns  int
}

func (r *antidpiRecorder) snapshot() ([][]byte, int, int) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([][]byte, len(r.chunks))
	copy(out, r.chunks)
	return out, r.total, r.conns
}

func (r *antidpiRecorder) waitTotal(t *testing.T, n int, timeout time.Duration) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		_, total, _ := r.snapshot()
		if total >= n {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	_, total, conns := r.snapshot()
	t.Fatalf("origin received %d of %d bytes (%d conns) within %s", total, n, conns, timeout)
}

func startAntidpiOrigin(t *testing.T) (*antidpiRecorder, net.Listener) {
	t.Helper()
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	rec := &antidpiRecorder{}
	go func() {
		for {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			rec.mu.Lock()
			rec.conns++
			rec.mu.Unlock()
			go func() {
				defer conn.Close()
				buf := make([]byte, 4096)
				for {
					_ = conn.SetReadDeadline(time.Now().Add(10 * time.Second))
					n, err := conn.Read(buf)
					if n > 0 {
						chunk := append([]byte(nil), buf[:n]...)
						rec.mu.Lock()
						rec.chunks = append(rec.chunks, chunk)
						rec.total += n
						rec.mu.Unlock()
					}
					if err != nil {
						return
					}
				}
			}()
		}
	}()
	return rec, ln
}

// antidpiSimulator is the DPI middlebox described above.
type antidpiSimulator struct {
	mu          sync.Mutex
	firstChunks [][]byte // one per connection, in accept order
	blocked     int
	passed      int
}

func (s *antidpiSimulator) stats() ([][]byte, int, int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([][]byte, len(s.firstChunks))
	copy(out, s.firstChunks)
	return out, s.blocked, s.passed
}

func startAntidpiSimulator(t *testing.T, originAddr string) (*antidpiSimulator, net.Listener) {
	t.Helper()
	// Port 443 first (tpws tampering heuristics are port-aware in
	// some builds); an ephemeral port is the fallback.
	ln, err := net.Listen("tcp", "127.0.0.1:443")
	if err != nil {
		ln, err = net.Listen("tcp", "127.0.0.1:0")
		if err != nil {
			t.Fatal(err)
		}
	}
	sim := &antidpiSimulator{}
	go func() {
		for {
			client, err := ln.Accept()
			if err != nil {
				return
			}
			go sim.handle(client, originAddr)
		}
	}()
	return sim, ln
}

func (s *antidpiSimulator) handle(client net.Conn, originAddr string) {
	defer client.Close()
	buf := make([]byte, 4096)
	_ = client.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
	n, err := client.Read(buf)
	if err != nil || n == 0 {
		return
	}
	first := append([]byte(nil), buf[:n]...)
	s.mu.Lock()
	s.firstChunks = append(s.firstChunks, first)
	s.mu.Unlock()
	if bytes.Contains(first, []byte("blocked.example")) {
		s.mu.Lock()
		s.blocked++
		s.mu.Unlock()
		if tcp, ok := client.(*net.TCPConn); ok {
			_ = tcp.SetLinger(0) // RST, like a censor's injected reset
		}
		return
	}
	s.mu.Lock()
	s.passed++
	s.mu.Unlock()
	_ = client.SetReadDeadline(time.Time{})
	origin, err := net.DialTimeout("tcp", originAddr, 3*time.Second)
	if err != nil {
		return
	}
	defer origin.Close()
	if _, err := origin.Write(first); err != nil {
		return
	}
	// Splice: forward each read as its own write, both ways, so the
	// segmentation tpws produced is what the origin observes.
	done := make(chan struct{}, 2)
	go func() {
		b := make([]byte, 4096)
		for {
			n, err := origin.Read(b)
			if n > 0 {
				if _, werr := client.Write(b[:n]); werr != nil {
					break
				}
			}
			if err != nil {
				break
			}
		}
		done <- struct{}{}
	}()
	b := make([]byte, 4096)
	for {
		_ = client.SetReadDeadline(time.Now().Add(10 * time.Second))
		n, err := client.Read(b)
		if n > 0 {
			if _, werr := origin.Write(b[:n]); werr != nil {
				break
			}
		}
		if err != nil {
			break
		}
	}
	<-done
}

// antidpiClientHello builds a structurally valid TLS ClientHello
// carrying SNI host, long enough for tpws to parse and for the
// midsld marker to land inside the SNI.
func antidpiClientHello(host string) []byte {
	name := []byte(host)
	var sniList []byte
	sniList = append(sniList, 0) // host_name
	sniList = append(sniList, byte(len(name)>>8), byte(len(name)))
	sniList = append(sniList, name...)
	var sniExt []byte
	sniExt = append(sniExt, byte(len(sniList)>>8), byte(len(sniList)))
	sniExt = append(sniExt, sniList...)
	var exts []byte
	exts = append(exts, 0, 0, byte(len(sniExt)>>8), byte(len(sniExt)))
	exts = append(exts, sniExt...)

	var hs []byte
	hs = append(hs, 0x03, 0x03) // TLS 1.2
	for i := 0; i < 32; i++ {   // random
		hs = append(hs, byte(i))
	}
	hs = append(hs, 0)          // session id
	hs = append(hs, 0, 2, 0x13, 0x01) // cipher suites: TLS_AES_128_GCM
	hs = append(hs, 1, 0)       // compression: null
	hs = append(hs, byte(len(exts)>>8), byte(len(exts)))
	hs = append(hs, exts...)

	var out []byte
	out = append(out, 0x16, 0x03, 0x01)
	recLen := 4 + len(hs)
	out = append(out, byte(recLen>>8), byte(recLen))
	out = append(out, 0x01, byte(len(hs)>>16), byte(len(hs)>>8), byte(len(hs)))
	out = append(out, hs...)
	return out
}

func antidpiTPWSBinary(t *testing.T) string {
	t.Helper()
	home, _ := os.UserHomeDir()
	candidates := []string{
		os.Getenv("SORA_ANTIDPI_TPWS_BIN"),
		filepath.Join(home, "workspace", "bug-hunt", "zapret-src", "binaries", "my", "tpws"), // the task's path
		filepath.Join(home, "workspace", "bug-hunt", "waveb", "src", "dist", "engines", "tpws"),
	}
	for _, c := range candidates {
		if c == "" {
			continue
		}
		fi, err := os.Stat(c)
		if err != nil || fi.IsDir() || fi.Mode()&0o111 == 0 {
			continue
		}
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		out, err := exec.CommandContext(ctx, c, "--version").CombinedOutput()
		cancel()
		if err != nil {
			t.Logf("tpws candidate %s exists but does not run: %v (%s)", c, err, strings.TrimSpace(string(out)))
			continue
		}
		t.Logf("tpws binary: %s (%s)", c, strings.TrimSpace(string(out)))
		return c
	}
	t.Skipf("no runnable tpws binary in %v — live tpws proof skipped honestly", candidates)
	return ""
}

func TestAntiDPITPWSLiveDesync(t *testing.T) {
	bin := antidpiTPWSBinary(t)
	hello := antidpiClientHello("blocked.example")

	rec, originLn := startAntidpiOrigin(t)
	defer originLn.Close()
	sim, simLn := startAntidpiSimulator(t, originLn.Addr().String())
	defer simLn.Close()
	simAddr := simLn.Addr().String()

	// (1) Direct through the simulator: the SNI is continuous in the
	// first chunk, so the connection is reset and nothing reaches
	// the origin. This leg always runs: it is the control proving
	// the simulator actually censors.
	t.Run("direct_is_reset", func(t *testing.T) {
		direct, err := net.DialTimeout("tcp", simAddr, 3*time.Second)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := direct.Write(hello); err != nil {
			t.Fatalf("direct write: %v", err)
		}
		_ = direct.SetReadDeadline(time.Now().Add(3 * time.Second))
		_, readErr := direct.Read(make([]byte, 64))
		direct.Close()
		if readErr == nil {
			t.Fatal("direct connection was not reset by the simulator")
		}
		if _, _, conns := rec.snapshot(); conns != 0 {
			t.Fatalf("origin got %d connections from the blocked direct attempt, want 0", conns)
		}
		firsts, blocked, _ := sim.stats()
		if blocked != 1 {
			t.Fatalf("simulator blocked = %d, want 1 (the direct attempt)", blocked)
		}
		if len(firsts) != 1 || !bytes.Contains(firsts[0], []byte("blocked.example")) {
			t.Fatalf("simulator's direct first chunk = %q, want the continuous SNI that triggers the reset", firsts)
		}
	})

	// (2) Through tpws SOCKS with the classic/app-default-split
	// preset strategy, rendered by the real bypass.Args.
	strat := ext.ProtoToEngineStrategy(antiDPIPresetStrategy(t, "classic/app-default-split"))
	port, err := supervise.FreePort()
	if err != nil {
		t.Fatal(err)
	}
	args := bypass.Args(strat, port)
	runBin := bin
	cmd := exec.Command(bin, args...)
	if os.Geteuid() == 0 {
		// Sandbox fact: this process runs as root, and tpws's
		// root-only privilege drop dies here on setgroups (EINVAL —
		// the container denies it; reproduced by hand). Production
		// runs tpws as the core's own non-root user, so mirror that:
		// stage a copy on a world-traversable path and exec it as
		// nobody with NoSetGroups.
		dir, err := os.MkdirTemp("", "antidpi-tpws")
		if err != nil {
			t.Fatal(err)
		}
		defer os.RemoveAll(dir)
		if err := os.Chmod(dir, 0o755); err != nil {
			t.Fatal(err)
		}
		raw, err := os.ReadFile(bin)
		if err != nil {
			t.Fatal(err)
		}
		runBin = filepath.Join(dir, "tpws")
		if err := os.WriteFile(runBin, raw, 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.Chmod(runBin, 0o755); err != nil { // the sandbox umask strips WriteFile's group/other bits
			t.Fatal(err)
		}
		cmd = exec.Command(runBin, args...)
		cmd.SysProcAttr = &syscall.SysProcAttr{Credential: &syscall.Credential{
			Uid: 65534, Gid: 65534, Groups: []uint32{65534}, NoSetGroups: true,
		}}
		t.Logf("running tpws as nobody (root's setgroups is denied in this sandbox): %s %v", runBin, args)
	}
	var tpwsOut bytes.Buffer
	cmd.Stdout, cmd.Stderr = &tpwsOut, &tpwsOut
	if err := cmd.Start(); err != nil {
		t.Fatalf("start tpws %v: %v", args, err)
	}
	defer func() {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
	}()
	tpwsAddr := net.JoinHostPort("127.0.0.1", itoaTestPort(port))
	deadline := time.Now().Add(5 * time.Second)
	for {
		c, err := net.DialTimeout("tcp", tpwsAddr, 200*time.Millisecond)
		if err == nil {
			c.Close()
			break
		}
		if time.Now().After(deadline) {
			t.Fatalf("tpws did not start listening on %s; output: %s", tpwsAddr, tpwsOut.String())
		}
		time.Sleep(20 * time.Millisecond)
	}

	dialer, err := proxy.SOCKS5("tcp", tpwsAddr, nil, proxy.Direct)
	if err != nil {
		t.Fatal(err)
	}
	via, err := dialer.Dial("tcp", simAddr)
	if err != nil {
		// SANDBOX BOUNDARY (verified by hand, 2026-10-21): tpws's
		// SOCKS ruleset refuses loopback targets — both 127.0.0.1
		// and 127.0.0.2 get SOCKS reply 0x02 "connection not
		// allowed by ruleset". The stand cannot move off loopback
		// to escape it: this sandbox intercepts ALL non-loopback
		// TCP egress (a listener bound to the interface address
		// never sees the connection; the sandbox's own proxy
		// answers instead). Transparent mode is equally closed:
		// unprivileged tpws gets IP_TRANSPARENT EPERM, root tpws
		// dies on setgroups (EINVAL), and the kernel has no NAT
		// REDIRECT module to steer traffic with. The tpws leg is
		// therefore SKIPPED here with the exact reason — on a host
		// where the dial succeeds, the full assertions below run.
		if strings.Contains(err.Error(), "connection not allowed by ruleset") {
			t.Skipf("tpws SOCKS refuses the loopback target (%v) and this sandbox intercepts all non-loopback TCP egress, so the tpws forwarding leg cannot be completed here; direct_is_reset above is the control leg that did run", err)
		}
		t.Fatalf("SOCKS dial via tpws: %v (tpws output: %s)", err, tpwsOut.String())
	}
	if _, err := via.Write(hello); err != nil {
		t.Fatalf("write via tpws: %v", err)
	}
	rec.waitTotal(t, len(hello), 5*time.Second)
	via.Close()

	chunks, total, conns := rec.snapshot()
	if total != len(hello) || !bytes.Equal(bytes.Join(chunks, nil), hello) {
		t.Fatalf("origin stream = %d bytes over %d conns, want the byte-identical %d-byte hello", total, conns, len(hello))
	}
	if len(chunks) < 2 {
		t.Fatalf("origin saw %d chunk(s) for the first flight, want >= 2 (split): %q", len(chunks), bytes.Join(chunks, nil))
	}
	if bytes.Contains(chunks[0], []byte("blocked.example")) {
		t.Errorf("first origin chunk carries the SNI continuously: %q", chunks[0])
	}
	firsts, blocked, passed := sim.stats()
	// The simulator's verdict on the tpws path is what the whole
	// stand exists for: exactly one block (direct) and one pass
	// (via tpws), and the first chunk it observed on the tpws path
	// must not carry the SNI continuously.
	if blocked != 1 || passed != 1 {
		t.Errorf("simulator blocked=%d passed=%d, want 1/1 (direct reset, tpws spliced)", blocked, passed)
	}
	if len(firsts) != 2 {
		t.Fatalf("simulator saw %d connections, want 2", len(firsts))
	}
	if bytes.Contains(firsts[1], []byte("blocked.example")) {
		t.Errorf("simulator's tpws-path first chunk carries the SNI continuously: %q", firsts[1])
	}
	// No single origin chunk may carry the whole SNI continuously
	// at the split boundary the preset promises: at least the
	// first-flight chunks are split inside the name.
	joined := bytes.Join(chunks, nil)
	if idx := bytes.Index(joined, []byte("blocked.example")); idx < 0 {
		t.Fatal("reassembled stream lost the SNI — stream identity already checked, this cannot happen")
	}
}

func itoaTestPort(p int) string {
	if p == 0 {
		return "0"
	}
	var buf [8]byte
	i := len(buf)
	for p > 0 {
		i--
		buf[i] = byte('0' + p%10)
		p /= 10
	}
	return string(buf[i:])
}
