// Command sora-sync is the device-to-device sync daemon: it pairs devices
// over QR + mDNS + Noise_XX and keeps VPN documents (subscriptions, rules,
// settings) in sync without any cloud. The app talks to it over a
// token-authenticated localhost HTTP API; the token and the HTTP address
// live in the data directory.
package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"syscall"

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

func main() {
	dataDir := flag.String("data-dir", defaultDataDir(), "data directory")
	flag.Parse()

	log.SetPrefix("sora-sync: ")
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
