package desync

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/profiles"
)

var testFP = profiles.Fingerprint{SSID: "Home", Gateway: "192.168.1.1", ASN: "AS123"}

// winnerProbe scores exactly the registry's sni_block/fake-autottl-badseq
// genome (after marker resolution — it carries no marker, so verbatim).
func winnerProbe() (Params, ProbeFunc) {
	prof, _ := LookupProfile("sni_block/fake-autottl-badseq")
	return prof.Params, func(ctx context.Context, p Params) ProbeReport {
		return ProbeReport{
			BlockedOK: p.ID() == prof.Params.ID(),
			ControlOK: true, ControlLatency: 100 * time.Millisecond,
			ControlBaseline: 100 * time.Millisecond,
		}
	}
}

type fakeBinder struct {
	calls []string
	err   error
}

func (b *fakeBinder) BindDesyncProfile(_ context.Context, _ profiles.Fingerprint, profileID string, _ Params) error {
	b.calls = append(b.calls, profileID)
	return b.err
}

func newTestService(t *testing.T, binder ProfileBinder) *Service {
	t.Helper()
	store, err := NewBindingStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	svc, err := NewService(store, binder)
	if err != nil {
		t.Fatal(err)
	}
	return svc
}

func TestServiceTuneBindsWinner(t *testing.T) {
	binder := &fakeBinder{}
	svc := newTestService(t, binder)
	want, probe := winnerProbe()
	res, err := svc.Tune(context.Background(), testFP, "nfqws", probe)
	if err != nil {
		t.Fatalf("Tune: %v", err)
	}
	if res.Best.Params.ID() != want.ID() {
		t.Fatalf("winner = %s, want %s", res.Best.Params.ID(), want.ID())
	}
	if len(binder.calls) != 1 || binder.calls[0] != "sni_block/fake-autottl-badseq" {
		t.Fatalf("binder calls = %v, want the registry profile bound to F5", binder.calls)
	}
	b, ok := svc.Store.Lookup(testFP)
	if !ok || b.ProfileID != "sni_block/fake-autottl-badseq" || b.RegistryVersion != RegistryVersion {
		t.Fatalf("binding = %+v ok=%v", b, ok)
	}
	rot, _, ok := svc.Current(testFP)
	if !ok || rot.Empty() {
		t.Fatal("Current must serve the bound winner as a rotation ring")
	}
	cur, _ := rot.Current()
	if cur.Params.ID() != want.ID() {
		t.Fatalf("ring current = %s, want the winner", cur.Params.ID())
	}
}

func TestServiceTuneResolvesMarkersBeforeProbing(t *testing.T) {
	svc := newTestService(t, nil)
	var probed []Params
	probe := func(ctx context.Context, p Params) ProbeReport {
		probed = append(probed, p)
		return ProbeReport{ControlOK: true}
	}
	_, _ = svc.Tune(context.Background(), testFP, "nfqws", probe)
	for _, p := range probed {
		if p.SplitPos == "midsni" {
			t.Fatal("an unresolved marker reached the probe: resolution is the Service's job")
		}
	}
	// The marker profiles resolve against the blocked canary's SNI:
	// youtube.com is 11 bytes, so the mid-SNI cut is sniext+(9+11/2).
	found := false
	for _, p := range probed {
		if p.SplitPos == "sniext+14" {
			found = true
		}
	}
	if !found {
		t.Fatal("no candidate carried the canary-resolved mid-SNI position")
	}
}

func TestServiceRateLimit(t *testing.T) {
	svc := newTestService(t, nil)
	now := time.Now()
	svc.Now = func() time.Time { return now }
	_, probe := winnerProbe()
	if _, err := svc.Tune(context.Background(), testFP, "nfqws", probe); err != nil {
		t.Fatal(err)
	}
	_, err := svc.Tune(context.Background(), testFP, "nfqws", probe)
	if !errors.Is(err, ErrRateLimited) {
		t.Fatalf("second immediate tune = %v, want ErrRateLimited", err)
	}
	// A different network is a different budget.
	other := profiles.Fingerprint{SSID: "Cafe", Gateway: "10.0.0.1", ASN: "AS9"}
	if _, err := svc.Tune(context.Background(), other, "nfqws", probe); err != nil {
		t.Fatalf("tune on another network: %v", err)
	}
	// After the interval the same network may tune again.
	now = now.Add(DefaultMinInterval + time.Second)
	if _, err := svc.Tune(context.Background(), testFP, "nfqws", probe); err != nil {
		t.Fatalf("tune after the interval: %v", err)
	}
}

func TestServiceNoWinnerBindsNothing(t *testing.T) {
	binder := &fakeBinder{}
	svc := newTestService(t, binder)
	probe := func(ctx context.Context, p Params) ProbeReport { return ProbeReport{ControlOK: true} }
	_, err := svc.Tune(context.Background(), testFP, "nfqws", probe)
	if !errors.Is(err, ErrNoWorking) {
		t.Fatalf("err = %v, want ErrNoWorking", err)
	}
	if len(binder.calls) != 0 {
		t.Fatal("a failed tune must not bind anything to F5")
	}
	if _, ok := svc.Store.Lookup(testFP); ok {
		t.Fatal("a failed tune must not persist a binding")
	}
}

func TestServicePassiveSignalsDriveRetune(t *testing.T) {
	svc := newTestService(t, nil)
	if ok, _ := svc.ShouldRetune(testFP, testFP); ok {
		t.Fatal("no signals: no retune")
	}
	for i := 0; i < MinSamples; i++ {
		svc.Observe(testFP, SignalInjectedRST)
	}
	ok, reason := svc.ShouldRetune(testFP, testFP)
	if !ok || reason == "" {
		t.Fatal("a window of injected RSTs must call for a retune, with a reason")
	}
	mobile := profiles.Fingerprint{SSID: "", Gateway: "10.0.0.1", ASN: "AS456"}
	if ok, _ := svc.ShouldRetune(testFP, mobile); !ok {
		t.Fatal("a network change must call for a retune")
	}
}

func TestBindingStoreFailClosedOnCorruption(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, bindingFileName)
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte("{not json"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := NewBindingStore(dir); err == nil {
		t.Fatal("a corrupt bindings file must fail closed, not silently reset")
	}
	if err := os.WriteFile(path, []byte(`{"version": 99, "entries": {}}`), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := NewBindingStore(dir); err == nil || !strings.Contains(err.Error(), "version") {
		t.Fatalf("a foreign-version bindings file must be refused, got %v", err)
	}
}

func TestBindingStoreSurvivesRestart(t *testing.T) {
	dir := t.TempDir()
	want, _ := winnerProbe()
	store, err := NewBindingStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	b := Binding{Winner: want, Score: 0.9, At: time.Now(), RegistryVersion: RegistryVersion, GenePoolVersion: GenePoolVersion}
	if err := store.Bind(testFP, b); err != nil {
		t.Fatal(err)
	}
	reopened, err := NewBindingStore(dir)
	if err != nil {
		t.Fatal(err)
	}
	got, ok := reopened.Lookup(testFP)
	if !ok || got.Winner.ID() != want.ID() || got.Score != 0.9 {
		t.Fatalf("after restart: %+v ok=%v", got, ok)
	}
	// The file is owner-only: bindings name the user's networks.
	fi, err := os.Stat(filepath.Join(dir, bindingFileName))
	if err != nil {
		t.Fatal(err)
	}
	if fi.Mode().Perm() != 0o600 {
		t.Fatalf("bindings file mode = %v, want 0600", fi.Mode().Perm())
	}
}

func TestCurrentRefusesStaleRegistryVersion(t *testing.T) {
	svc := newTestService(t, nil)
	want, _ := winnerProbe()
	stale := Binding{Winner: want, Score: 1, RegistryVersion: RegistryVersion + 1}
	if err := svc.Store.Bind(testFP, stale); err != nil {
		t.Fatal(err)
	}
	if _, _, ok := svc.Current(testFP); ok {
		t.Fatal("a winner recorded under another registry version must be re-validated, not served")
	}
}

func TestCanaryAllowlist(t *testing.T) {
	if !IsCanary(BlockedCanary) || !IsCanary(ControlCanary) {
		t.Fatal("the sanctioned canaries must pass the allowlist")
	}
	if IsCanary(Canary{Host: "example.org", Port: 443, SNI: "example.org"}) {
		t.Fatal("an arbitrary target passed the canary allowlist")
	}
}
