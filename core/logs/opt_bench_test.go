package logs

import (
	"bytes"
	"fmt"
	"strings"
	"testing"
	"time"
)

// Benchmarks for the opt40 log-path pass (everything except the already
// optimized redactor). Baselines on this VM, B/op and allocs/op only
// (ns/op is not trustworthy here):
//
//	BenchmarkWriteDistinct10k          3,579,706 B/op, 21 allocs (unchanged: fill path)
//	BenchmarkQuerySnapshot100             24,624 B/op, 12 allocs -> 8,640 / 5
//	BenchmarkQueryContains               320,528 B/op, 20,005 allocs -> 1,344 / 5
//	BenchmarkMatching20k               7,978,621 B/op, 22 allocs -> 1,605,633 / 1
//	BenchmarkMatchingContains             24,176 B/op, 8 allocs -> 9,472 / 1
//	BenchmarkExportText1000              406,568 B/op, 8,015 allocs -> 262,433 / 23
//	BenchmarkExportCSV1000               395,032 B/op, 2,912 allocs -> 289,113 / 1,911
//	BenchmarkExportJSONLines1000         592,392 B/op, 3,015 allocs -> 510,449 / 3,014
//	BenchmarkParseLevel                        8 B/op, 1 alloc -> 0 / 0
//	BenchmarkFullLogWrite (eviction_test.go) 404 B/op -> 0 B/op
//
// ExportJSON was left alone: repeated runs land in a 657k-712k B/op band
// both before and after. HideDestinations (837 B/op, 18 allocs for a line
// with two destinations) was left alone: it runs only in the opt-in
// RecordDestinations=false mode, and its five ordered regexp passes are
// correctness-sensitive. The slog handler was measured at 176 B/op,
// 4 allocs both before and after removing its string concatenations
// (they never reached the heap), so that change was reverted.

var optSink int

func optMessages(n int) []string {
	msgs := make([]string, n)
	for i := range msgs {
		msgs[i] = fmt.Sprintf("dial tcp 10.0.0.1:443 to example-%d.org succeeded", i)
	}
	return msgs
}

func optFilledCenter(n int) *Center {
	c := New(Settings{CaptureLevel: LevelDebug, RecordDestinations: true, MaxEntries: 100000, MaxBytes: 1 << 30})
	msgs := optMessages(n)
	for i := 0; i < n; i++ {
		c.Write(t0.Add(time.Duration(i)*time.Second), LevelInfo, "xray", msgs[i])
	}
	return c
}

func BenchmarkWriteDistinct10k(b *testing.B) {
	msgs := optMessages(10000)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		c := New(Settings{CaptureLevel: LevelDebug, RecordDestinations: true, MaxEntries: 100000, MaxBytes: 1 << 30})
		for j, m := range msgs {
			c.Write(t0.Add(time.Duration(j)*time.Second), LevelInfo, "xray", m)
		}
		optSink += len(c.entries)
	}
}

func BenchmarkQuerySnapshot100(b *testing.B) {
	c := optFilledCenter(20000)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		p := c.Query(Filter{}, 0, 100)
		optSink += len(p.Entries)
	}
}

func BenchmarkQueryContains(b *testing.B) {
	c := optFilledCenter(20000)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		p := c.Query(Filter{Contains: "EXAMPLE-19999"}, 0, 10)
		optSink += len(p.Entries)
	}
}

func BenchmarkMatching20k(b *testing.B) {
	c := optFilledCenter(20000)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		out := c.Matching(Filter{})
		optSink += len(out)
	}
}

func BenchmarkMatchingContains(b *testing.B) {
	c := optFilledCenter(20000)
	b.ReportAllocs()
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		out := c.Matching(Filter{Contains: "example-42"})
		optSink += len(out)
	}
}

func optExportBench(format Format) func(b *testing.B) {
	return func(b *testing.B) {
		entries := optFilledCenter(1000).Matching(Filter{})
		b.ReportAllocs()
		b.ResetTimer()
		for i := 0; i < b.N; i++ {
			data, _, _, err := Export(entries, format, t0)
			if err != nil {
				b.Fatal(err)
			}
			optSink += len(data)
		}
	}
}

func BenchmarkExportText1000(b *testing.B)      { optExportBench(FormatText)(b) }
func BenchmarkExportCSV1000(b *testing.B)       { optExportBench(FormatCSV)(b) }
func BenchmarkExportJSONLines1000(b *testing.B) { optExportBench(FormatJSONLines)(b) }

func BenchmarkParseLevel(b *testing.B) {
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		l, ok := ParseLevel("INFO")
		if !ok {
			b.Fatal("bad")
		}
		optSink += int(l)
	}
}

// TestCompactionKeepsOrderAndDropped guards the Write-side compaction of
// the entry view into its backing allocation: 60k writes into a full
// center must not reallocate the backing, and order, sequence numbers and
// the dropped count must be exactly what the sliding view produced.
func TestCompactionKeepsOrderAndDropped(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug})
	for i := 0; i < DefaultMaxEntries; i++ {
		c.Write(time.Unix(int64(i)*60, 0), LevelInfo, SourceCore, "connection opened")
	}
	base := &c.backing[0]
	for i := 0; i < 60000; i++ {
		c.Write(time.Unix(int64(DefaultMaxEntries+i)*60, 0), LevelInfo, SourceCore, "connection opened")
		if &c.backing[0] != base {
			t.Fatalf("backing reallocated at write %d (len=%d cap=%d head=%d)", i, len(c.entries), cap(c.entries), c.head)
		}
	}
	if c.dropped != 60000 || c.entries[0].Seq != 60001 || c.entries[len(c.entries)-1].Seq != 80000 {
		t.Fatalf("dropped=%d first=%d last=%d", c.dropped, c.entries[0].Seq, c.entries[len(c.entries)-1].Seq)
	}
	p := c.Query(Filter{}, 0, 3)
	if len(p.Entries) != 3 || p.Entries[0].Seq != 80000 || p.Entries[2].Seq != 79998 {
		t.Fatalf("order after compaction wrong: %+v", p.Entries)
	}
}

// TestFoldContainsMatchesToLowerContains pins foldContains to the exact
// result of the strings.ToLower comparison it replaced, including the
// awkward Unicode folds and invalid UTF-8.
func TestFoldContainsMatchesToLowerContains(t *testing.T) {
	haystacks := []string{"", "hello", "HeLLo World", "Русский ТЕКСТ русский", "dial EXAMPLE-42.org ok", "İSTANBUL", "ſecret", "Kelvin", "á combined", "invalid \xff bytes here", "ﬀ ligature", "STRASSE straße"}
	needles := []string{"", "hello", "HELLO", "world", "РУССКИЙ", "русский", "example-42", "İ", "i", "ſ", "s", "k", "K", "combined", "bytes", "ﬀ", "ff", "strasse", "STRASSE", "xyz", "invalid \xff"}
	for _, h := range haystacks {
		for _, n := range needles {
			want := strings.Contains(strings.ToLower(h), strings.ToLower(n))
			if got := foldContains(h, n); want != got {
				t.Errorf("foldContains(%q,%q) = %v, ToLower comparison = %v", h, n, got, want)
			}
		}
	}
}

// TestParseLevelFastPathParity pins the ParseLevel fast path to the
// original lowercase-and-trim implementation for a spelling corpus.
func TestParseLevelFastPathParity(t *testing.T) {
	old := func(s string) (Level, bool) {
		switch strings.ToLower(strings.TrimSpace(s)) {
		case "trace", "debug", "dbg":
			return LevelDebug, true
		case "info", "information", "notice":
			return LevelInfo, true
		case "warn", "warning":
			return LevelWarning, true
		case "error", "err", "fatal", "panic", "critical":
			return LevelError, true
		}
		return 0, false
	}
	for _, s := range []string{"INFO", "Info", "info", " WaRn ", "WARNING", "Warning", "WaRnInG", "dbg", "DBG", "Dbg", "trace", "TRACE", "TrAcE", "information", "INFORMATION", "Information", "notice", "NOTICE", "err", "ERR", "fatal", "FATAL", "panic", "PANIC", "critical", "CRITICAL", "Critical", "", "nope", " info", "error ", "eRRoR", "Warn"} {
		wantL, wantOK := old(s)
		gotL, gotOK := ParseLevel(s)
		if wantL != gotL || wantOK != gotOK {
			t.Errorf("ParseLevel(%q) = %v,%v; original = %v,%v", s, gotL, gotOK, wantL, wantOK)
		}
	}
}

// TestExportTextParity pins the hand-written text entry writer to the
// exact bytes of the fmt.Fprintf rendering it replaced.
func TestExportTextParity(t *testing.T) {
	entries := []Entry{
		{Seq: 1, Time: t0, Level: LevelError, Source: "xray", Message: "plain", Repeat: 3},
		{Seq: 2, Time: t0.Add(123456789 * time.Nanosecond), Level: LevelDebug, Source: "a-very-long-source-name", Message: "m", Repeat: 1},
		{Seq: 3, Time: t0, Level: Level(99), Source: "", Message: "", Repeat: 2},
		{Seq: 4, Time: t0, Level: LevelWarning, Source: "core", Message: " spaced ", Repeat: 10},
	}
	var want bytes.Buffer
	for _, e := range entries {
		fmt.Fprintf(&want, "%s %-7s %-8s %s", e.Time.Format("2006-01-02 15:04:05.000"), strings.ToUpper(e.Level.String()), "["+e.Source+"]", e.Message)
		if e.Repeat > 1 {
			fmt.Fprintf(&want, " (x%d)", e.Repeat)
		}
		want.WriteByte('\n')
	}
	got, _, _, err := Export(entries, FormatText, t0)
	if err != nil || !bytes.Equal(got, want.Bytes()) {
		t.Errorf("text export parity:\nold=%q\nnew=%q err=%v", want.Bytes(), got, err)
	}
}
