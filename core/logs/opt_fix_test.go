package logs

import (
	"bytes"
	"fmt"
	"strings"
	"testing"
	"time"
)

// Follow-up fixes to the opt40 log-path pass, each pinned by the test
// that caught the regression it repairs.

// TestExportTextParityUnicodeSource extends TestExportTextParity to
// short non-ASCII source names: fmt's %-8s pads by rune count, and the
// hand-written writer must too, or the column shifts by the byte/rune
// difference.
func TestExportTextParityUnicodeSource(t *testing.T) {
	entries := []Entry{
		{Seq: 1, Time: t0, Level: LevelInfo, Source: "ü", Message: "short unicode source", Repeat: 1},
		{Seq: 2, Time: t0, Level: LevelInfo, Source: "éé", Message: "short unicode source", Repeat: 1},
		{Seq: 3, Time: t0, Level: LevelError, Source: "ЖЖЖ", Message: "cyrillic source", Repeat: 2},
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
		t.Errorf("text export parity (unicode sources):\nold=%q\nnew=%q err=%v", want.Bytes(), got, err)
	}
}

// TestQueryNoMatchKeepsNilEntries locks the result shape Query had
// before its page was pre-sized: no matches means a nil slice, not an
// allocated empty one.
func TestQueryNoMatchKeepsNilEntries(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug})
	c.Write(t0, LevelInfo, SourceCore, "something")
	p := c.Query(Filter{Contains: "absent"}, 0, 10)
	if p.Entries != nil {
		t.Fatalf("no-match query entries = %#v, want nil", p.Entries)
	}
	empty := New(Settings{CaptureLevel: LevelDebug}).Query(Filter{}, 0, 10)
	if empty.Entries != nil {
		t.Fatalf("empty-center query entries = %#v, want nil", empty.Entries)
	}
}

// TestCompactionSmallSlackStillGrows guards the compaction thresholds:
// with a bound whose fill leaves a one-entry slide (MaxEntries 1023
// fills a 1024-entry allocation), compacting on every write would copy
// the whole log per write to save one allocation. The center must fall
// back to append growth there, widen the slide, and stay correct.
func TestCompactionSmallSlackStillGrows(t *testing.T) {
	c := New(Settings{CaptureLevel: LevelDebug, RecordDestinations: true, MaxEntries: 1023, MaxBytes: 1 << 30})
	for i := 0; i < 1023; i++ {
		c.Write(time.Unix(int64(i)*61, 0), LevelInfo, "xray", fmt.Sprintf("line %d", i))
	}
	for i := 0; i < 5000; i++ {
		c.Write(time.Unix(int64(1023+i)*61, 0), LevelInfo, "xray", fmt.Sprintf("line %d", 1023+i))
	}
	if len(c.entries) != 1023 || c.dropped != 5000 {
		t.Fatalf("len=%d dropped=%d, want 1023/5000", len(c.entries), c.dropped)
	}
	if c.entries[0].Seq != 5001 || c.entries[len(c.entries)-1].Seq != 6023 {
		t.Fatalf("order wrong: first=%d last=%d", c.entries[0].Seq, c.entries[len(c.entries)-1].Seq)
	}
}
