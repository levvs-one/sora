package control

import (
	"strings"
	"testing"
	"time"
)

func TestParrotReviewNoticeFresh(t *testing.T) {
	reviewed, err := time.Parse("2006-01-02", "2026-10-20")
	if err != nil {
		t.Fatal(err)
	}
	if got := parrotReviewNotice(reviewed.Add(24 * time.Hour)); got != "" {
		t.Fatalf("fresh knowledge must be silent, got %q", got)
	}
}

func TestParrotReviewNoticeOverdue(t *testing.T) {
	reviewed, err := time.Parse("2006-01-02", "2026-10-20")
	if err != nil {
		t.Fatal(err)
	}
	got := parrotReviewNotice(reviewed.Add(31 * 24 * time.Hour))
	if !strings.Contains(got, "monthly parrot watch") {
		t.Fatalf("overdue knowledge must name the watch, got %q", got)
	}
	if !strings.Contains(got, "HelloChrome_155") {
		t.Fatalf("the notice must say which parrot is trusted, got %q", got)
	}
}
