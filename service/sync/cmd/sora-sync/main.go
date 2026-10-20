// Command sora-sync is the device-to-device sync daemon: it pairs devices
// over QR + mDNS + Noise_XX and keeps VPN documents (subscriptions, rules,
// settings) in sync without any cloud. The app talks to it over a
// token-authenticated localhost HTTP API; the token and the HTTP address
// live in the data directory.
package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/levvs-one/sora-client/sync/api"
)

func defaultDataDir() string {
	switch runtime.GOOS {
	case "windows":
		if local := os.Getenv("LOCALAPPDATA"); local != "" {
			return filepath.Join(local, "sora-sync")
		}
	case "darwin":
		if home, err := os.UserHomeDir(); err == nil {
			return filepath.Join(home, "Library", "Application Support", "sora-sync")
		}
	default:
		if xdg := os.Getenv("XDG_DATA_HOME"); xdg != "" {
			return filepath.Join(xdg, "sora-sync")
		}
		if home, err := os.UserHomeDir(); err == nil {
			return filepath.Join(home, ".local", "share", "sora-sync")
		}
	}
	return "sora-sync-data"
}

// liveInstance reports the address of a sora-sync daemon already serving
// dataDir, or "" when none answers. It reads http_addr and probes
// /v1/status with the data directory's bearer token; a stale http_addr
// from a crashed daemon simply fails the probe and the new daemon takes
// over and rewrites the file.
func liveInstance(dataDir string) string {
	addrRaw, err := os.ReadFile(filepath.Join(dataDir, "http_addr"))
	if err != nil {
		return ""
	}
	addr := strings.TrimSpace(string(addrRaw))
	host, _, err := net.SplitHostPort(addr)
	if err != nil || host != "127.0.0.1" {
		return ""
	}
	tokenRaw, err := os.ReadFile(filepath.Join(dataDir, "api_token"))
	if err != nil {
		return ""
	}
	token := strings.TrimSpace(string(tokenRaw))
	if token == "" {
		return ""
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://"+addr+"/v1/status", nil)
	if err != nil {
		return ""
	}
	req.Header.Set("Authorization", "Bearer "+token)
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return ""
	}
	defer func() { _ = resp.Body.Close() }()
	_, _ = io.Copy(io.Discard, resp.Body)
	if resp.StatusCode != http.StatusOK {
		return ""
	}
	return addr
}

func main() {
	dataDir := flag.String("data-dir", defaultDataDir(), "data directory")
	flag.Parse()
	log.SetPrefix("sora-sync: ")

	// One instance per data directory. The lock is taken BEFORE probing for
	// a live daemon: probing first and locking later would let two daemons
	// started at once both conclude "no live instance" and race to steal
	// each other's http_addr file (the old TOCTOU). The OS lock is held
	// for the process lifetime - a second daemon blocks on LOCK_NB here,
	// and process death releases it, so no stale lock can wedge restarts.
	if err := os.MkdirAll(*dataDir, 0o700); err != nil {
		log.Fatalf("data dir: %v", err)
	}
	lockFile, err := takeDataDirLock(*dataDir)
	if err != nil {
		// The lock is held: either a live daemon (the normal case) or a
		// process that died mid-startup. Probe to tell them apart so the
		// error names the actual situation.
		if addr := liveInstance(*dataDir); addr != "" {
			log.Fatalf("another sora-sync already serves %s at %s; not starting a second instance", *dataDir, addr)
		}
		log.Fatalf("cannot lock data dir %s: %v", *dataDir, err)
	}
	defer func() { _ = lockFile.Close() }() // held until process exit

	d, err := api.New(*dataDir)
	if err != nil {
		log.Fatalf("init: %v", err)
	}
	// The sync listener is best-effort: without LAN multicast the daemon
	// still serves its API and pairing can be retried.
	if err := d.StartSyncListener(); err != nil {
		log.Printf("sync listener: %v", err)
	}
	addr, err := d.ServeHTTP()
	if err != nil {
		log.Fatalf("http api: %v", err)
	}
	if err := os.WriteFile(filepath.Join(*dataDir, "http_addr"), []byte(addr+"\n"), 0o600); err != nil {
		log.Fatalf("http_addr: %v", err)
	}
	id := d.Identity()
	fmt.Printf("device %s (%s) ready at %s\n", id.ID, id.Name, addr)

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)
	<-sig
	log.Print("shutting down")
	d.Shutdown()
}
