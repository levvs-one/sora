// Benchmarks for the hot paths of core/probe: PathQuality.Observe,
// FreezeDetector feeding/verdicts, SNI normalization, the QUIC ban
// tracker, grease-Initial construction, dial-error classification and
// the serial-probe loop. Baseline for the [opt] probe pass; they must
// stay green alongside the correctness tests.
package probe

import (
	"context"
	"errors"
	"fmt"
	"net"
	"testing"
	"time"
)

func BenchmarkPathQualityObserve(b *testing.B) {
	q := &PathQuality{}
	now := time.Now()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		q.Observe(50*time.Millisecond, true, now)
		now = now.Add(time.Millisecond)
	}
}

func BenchmarkPathQualityObserveLoss(b *testing.B) {
	q := &PathQuality{}
	now := time.Now()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		q.Observe(0, false, now)
	}
}

func BenchmarkFreezeDetectorObserve(b *testing.B) {
	d := &FreezeDetector{}
	snis := []string{"example.com", "Example.COM.", "  cdn.example.com  ", "video.example.net."}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		d.Observe(FreezeSample{
			SNI:        snis[i%len(snis)],
			Concurrent: i % 8,
			Stalled:    i%5 == 0,
		})
	}
}

func BenchmarkFreezeDetectorObserveSteady(b *testing.B) {
	// Steady state: the per-SNI window is already at freezeMaxSamples,
	// so every Observe must evict the oldest sample. This is the mode
	// the passive prober actually lives in.
	d := &FreezeDetector{}
	for i := 0; i < freezeMaxSamples; i++ {
		d.Observe(FreezeSample{SNI: "example.com", Concurrent: 1, Stalled: false})
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		d.Observe(FreezeSample{SNI: "example.com", Concurrent: 1, Stalled: i%7 == 0})
	}
}

func BenchmarkFreezeDetectorVerdict(b *testing.B) {
	d := &FreezeDetector{}
	for i := 0; i < freezeMaxSamples; i++ {
		d.Observe(FreezeSample{SNI: "example.com", Concurrent: i % 8, Stalled: i%4 == 0})
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = d.Verdict("example.com")
	}
}

func BenchmarkNormalizeFreezeSNI(b *testing.B) {
	inputs := []string{"example.com", "Example.COM.", "  CDN.example.com.  ", "video.example.net"}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = normalizeFreezeSNI(inputs[i%len(inputs)])
	}
}

func BenchmarkBanKey(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = banKey(12345, "93.184.216.34:443")
	}
}

func BenchmarkBanTrackerBanned(b *testing.B) {
	t := NewBanTracker()
	t.NoteBlocked(12345, "93.184.216.34:443")
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = t.Banned(12345, "93.184.216.34:443")
	}
}

func BenchmarkGreaseInitial(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		pkt, err := greaseInitial()
		if err != nil {
			b.Fatal(err)
		}
		_ = pkt
	}
}

func BenchmarkClassifyDialErrorTimeout(b *testing.B) {
	err := &net.OpError{Op: "dial", Err: &net.DNSError{IsTimeout: true}}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = ClassifyDialError(err, true)
	}
}

func BenchmarkClassifyDialErrorNil(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = ClassifyDialError(errors.New("connection reset by peer"), true)
	}
}

func BenchmarkRunSeriesShort(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		res := RunSeries(context.Background(), SeriesOptions{
			Duration: 3 * time.Millisecond,
			Interval: time.Millisecond,
		}, func(ctx context.Context) error { return nil })
		if res.Attempts == 0 {
			b.Fatal("no attempts")
		}
	}
}

func BenchmarkQualityRegistryObserve(b *testing.B) {
	r := NewQualityRegistry()
	now := time.Now()
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		r.Observe("server-1", "tcp", 50*time.Millisecond, true, now)
	}
}

func BenchmarkFreezeConfidence(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = freezeConfidence(3, 2)
	}
}

func BenchmarkRotateFingerprint(b *testing.B) {
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = RotateFingerprint("Chrome")
	}
}

// [opt40] Observe with the OnFreeze hook attached — the production
// wiring (cmd/sora-core sets OnFreeze), which the hook-less Observe
// benches above do not model: with a hook, every Observe also runs
// the verdict check.

// A 200-server probe round: every dial lands on a distinct SNI, nothing
// is frozen, the hook never fires — but Observe still pays for a verdict
// on every sample.
func BenchmarkFreezeObserveHookCold200(b *testing.B) {
	d := &FreezeDetector{OnFreeze: func(FreezeVerdict) {}}
	snis := make([]string, 200)
	for i := range snis {
		snis[i] = fmt.Sprintf("srv-%d.example.com", i)
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		d.Observe(FreezeSample{SNI: snis[i%len(snis)], Concurrent: 6, Stalled: i%3 == 0})
	}
}

// Mass freeze: the SNI is frozen, the verdict pattern holds, but the
// 15-minute OnFreeze cooldown swallows every fire — Observe keeps
// building (and discarding) full evidence verdicts per dial.
func BenchmarkFreezeObserveHookFrozenCooldown(b *testing.B) {
	d := &FreezeDetector{OnFreeze: func(FreezeVerdict) {}}
	// Establish the freeze: sequential successes + stalled parallels.
	for i := 0; i < 3; i++ {
		d.Observe(FreezeSample{SNI: "example.com", Concurrent: 1, Stalled: false})
	}
	for i := 0; i < 4; i++ {
		d.Observe(FreezeSample{SNI: "example.com", Concurrent: 6, Stalled: true})
	}
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		// 4 stalled parallels per 1 sequential success keeps the
		// differential pattern alive inside the 128-sample window:
		// the verdict stays frozen the whole run.
		if i%5 == 4 {
			d.Observe(FreezeSample{SNI: "example.com", Concurrent: 1, Stalled: false, At: time.Now()})
		} else {
			d.Observe(FreezeSample{SNI: "example.com", Concurrent: 6, Stalled: true, At: time.Now()})
		}
	}
}
