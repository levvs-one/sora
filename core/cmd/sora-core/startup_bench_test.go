//go:build !windows

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/protobuf/proto"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/profiles"
	"github.com/levvs-one/sora-client/core/secret"
)

// BenchmarkNewCold measures full App construction on a fresh data dir with
// no engines installed: the cold path a first service start takes.
func BenchmarkNewCold(b *testing.B) {
	ctx := context.Background()
	for i := 0; i < b.N; i++ {
		dir, err := os.MkdirTemp("", "sora-bench-")
		if err != nil {
			b.Fatal(err)
		}
		app, err := New(ctx, Options{
			DataDir:    dir,
			EnginesDir: filepath.Join(dir, "engines"),
			Socket:     filepath.Join(dir, "core.sock"),
		})
		if err != nil {
			b.Fatal(err)
		}
		if err := app.Close(); err != nil {
			b.Fatal(err)
		}
		_ = os.RemoveAll(dir)
	}
}

// BenchmarkNewWarmPopulated measures App construction over an existing
// data dir carrying real user state: 20 subscriptions x 500 stored
// servers in the vault, 100 network profiles, and a ~9k-entry ASN table.
// Subscription server lists and the ASN table both load lazily on first
// use, so construction must stay close to the empty-dir cost; the eager
// version measured ~2-4x this and ~7.2 MB/op (vs ~0.84 MB/op) on the
// audit VM.
func BenchmarkNewWarmPopulated(b *testing.B) {
	ctx := context.Background()
	dir, err := os.MkdirTemp("", "sora-bench-warm-")
	if err != nil {
		b.Fatal(err)
	}
	b.Cleanup(func() { _ = os.RemoveAll(dir) })
	opts := Options{
		DataDir:    dir,
		EnginesDir: filepath.Join(dir, "engines"),
		Socket:     filepath.Join(dir, "core.sock"),
		Log:        slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelError})),
	}
	app, err := New(ctx, opts)
	if err != nil {
		b.Fatal(err)
	}
	if err := app.Close(); err != nil {
		b.Fatal(err)
	}
	populateBenchSubscriptions(b, dir, 20, 500)
	ps, err := profiles.NewStore(dir)
	if err != nil {
		b.Fatal(err)
	}
	for i := 0; i < 100; i++ {
		if _, err := ps.Save(profiles.Profile{Name: fmt.Sprintf("p%d", i), Triggers: profiles.Triggers{SSIDs: []string{fmt.Sprintf("ssid-%d", i)}}}); err != nil {
			b.Fatal(err)
		}
	}
	asn := map[string]string{}
	for i := 0; i < 9000; i++ {
		asn[fmt.Sprintf("10.%d.%d.0/24", i/250, i%250)] = "AS12345"
	}
	asnRaw, _ := json.Marshal(asn)
	if err := os.WriteFile(filepath.Join(dir, "asn.json"), asnRaw, 0o600); err != nil {
		b.Fatal(err)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		app, err := New(ctx, opts)
		if err != nil {
			b.Fatal(err)
		}
		if err := app.Close(); err != nil {
			b.Fatal(err)
		}
	}
}

// populateBenchSubscriptions writes nSubs subscription records, each
// with an nServers-outbound stored list, into dir's vault in the exact
// chunked format subscriptionBook persists.
func populateBenchSubscriptions(b *testing.B, dir string, nSubs, nServers int) {
	b.Helper()
	log := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelError}))
	store, err := secret.Open(filepath.Join(dir, "secrets"), secret.Options{Protector: protectorFor(Options{}, log)})
	if err != nil {
		b.Fatal(err)
	}
	defer func() { _ = store.Close() }()
	for s := 0; s < nSubs; s++ {
		id := fmt.Sprintf("%016x", s+1)
		outs := make([]*corev1.OutboundSpec, 0, nServers)
		for i := 0; i < nServers; i++ {
			outs = append(outs, &corev1.OutboundSpec{Id: fmt.Sprintf("srv-%d-%d", s, i)})
		}
		raw, err := proto.Marshal(&corev1.FetchSubscriptionResponse{Outbounds: outs})
		if err != nil {
			b.Fatal(err)
		}
		parts := 0
		puts := map[string][]byte{}
		for start := 0; start < len(raw); start += 60 << 10 {
			end := start + 60<<10
			if end > len(raw) {
				end = len(raw)
			}
			puts[fmt.Sprintf("u1_%s_l%d", id, parts)] = raw[start:end]
			parts++
		}
		recRaw, _ := json.Marshal(map[string]any{
			"v": 1, "id": id, "url": "https://example.com/sub", "auto": true,
			"created": time.Now().UTC(), "list_parts": parts,
		})
		puts["u1_"+id+"_rec"] = recRaw
		if err := store.Apply(puts, nil); err != nil {
			b.Fatal(err)
		}
	}
}
