package probe

import (
	"context"
	"errors"
	"testing"
	"time"
)

func fastSeries() SeriesOptions {
	return SeriesOptions{Duration: 350 * time.Millisecond, Interval: 100 * time.Millisecond}
}

func TestSeriesClean(t *testing.T) {
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error { return nil })
	if !res.Clean {
		t.Fatalf("result = %+v, want clean", res)
	}
	if res.TwoStage {
		t.Fatal("clean series flagged two-stage")
	}
	if res.Attempts < 3 {
		t.Fatalf("attempts = %d, want several in the window", res.Attempts)
	}
}

func TestSeriesBlockedFromStart(t *testing.T) {
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error {
		return errors.New("blocked")
	})
	if res.Clean {
		t.Fatal("all-failed series reported clean")
	}
	if res.TwoStage {
		t.Fatal("failed-from-start is not two-stage: nothing turned mid-series")
	}
	if res.Failures != res.Attempts {
		t.Fatalf("failures = %d, attempts = %d", res.Failures, res.Attempts)
	}
	if res.FirstFailure.IsZero() {
		t.Fatal("first failure not recorded")
	}
}

func TestSeriesTwoStage(t *testing.T) {
	calls := 0
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error {
		calls++
		if calls <= 2 {
			return nil
		}
		return errors.New("blocked")
	})
	if res.Clean {
		t.Fatal("series with failures reported clean")
	}
	if !res.TwoStage {
		t.Fatalf("result = %+v, want the two-stage signature", res)
	}
}

func TestSeriesFlakyIsNotTwoStage(t *testing.T) {
	calls := 0
	res := RunSeries(context.Background(), fastSeries(), func(ctx context.Context) error {
		calls++
		if calls%2 == 0 {
			return errors.New("blip")
		}
		return nil
	})
	if res.TwoStage {
		t.Fatal("interleaved failures flagged as two-stage")
	}
	if res.Clean {
		t.Fatal("flaky series reported clean")
	}
}

func TestSeriesContextCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	start := time.Now()
	res := RunSeries(ctx, SeriesOptions{Duration: time.Hour, Interval: time.Hour}, func(ctx context.Context) error {
		return ctx.Err()
	})
	if time.Since(start) > 5*time.Second {
		t.Fatal("cancelled series did not return promptly")
	}
	if res.Clean {
		t.Fatal("cancelled series reported clean")
	}
	// Partial evidence, not an error: the caller still gets the attempts.
	if res.Attempts == 0 {
		t.Fatal("cancelled series returned zero attempts")
	}
}

func TestSeriesDefaults(t *testing.T) {
	o := SeriesOptions{}.normalized()
	if o.Duration != DefaultSeriesDuration || o.Interval != DefaultSeriesInterval || o.AttemptTimeout != DefaultSeriesInterval {
		t.Fatalf("defaults = %+v", o)
	}
}
