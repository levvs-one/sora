package engine

import (
	"testing"
	"time"
)

// The parrot watch is monthly (T050): the knowledge date must always be
// sane — if it drifts more than the interval into the future, the parse
// and the overdue logic below stop meaning anything.
func TestParrotReviewedAtIsSane(t *testing.T) {
	reviewed, err := time.Parse("2006-01-02", ParrotReviewedAt)
	if err != nil {
		t.Fatalf("ParrotReviewedAt %q does not parse: %v", ParrotReviewedAt, err)
	}
	if reviewed.After(time.Now().Add(48 * time.Hour)) {
		t.Fatalf("ParrotReviewedAt %q is implausibly far in the future", ParrotReviewedAt)
	}
}

func TestParrotReviewOverdue(t *testing.T) {
	reviewed, err := time.Parse("2006-01-02", ParrotReviewedAt)
	if err != nil {
		t.Fatal(err)
	}
	if ParrotReviewOverdue(reviewed.Add(24 * time.Hour)) {
		t.Fatal("a fresh review must not be overdue")
	}
	if !ParrotReviewOverdue(reviewed.Add(ParrotReviewInterval + time.Hour)) {
		t.Fatal("a review older than the monthly interval must be overdue")
	}
}

func TestParrotReviewIntervalIsMonthly(t *testing.T) {
	if ParrotReviewInterval != 30*24*time.Hour {
		t.Fatalf("the watch is monthly, not %v", ParrotReviewInterval)
	}
}
