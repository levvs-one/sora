package diagnostics_test

import (
	"archive/zip"
	"bytes"
	"io"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/diagnostics"
	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/session"
)

func TestDiagnosticReportAndArchiveMaskUnknownQuotedCredentials(t *testing.T) {
	const line = `{"password":"fixture alpha beta", "token":"fixture gamma delta", "status":"running"}`
	source := &fakeSource{engine: []string{line}, events: []session.Event{{Kind: session.EventLog, LogLine: line}}}
	collector := newCollector(t, source, diagnostics.Options{Redactor: engine.NewRedactor()})
	lines, err := collector.Run(t.Context(), session.Status{})
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(strings.Join(lines, "\n"), "fixture") {
		t.Error("diagnostic report exposed an unregistered quoted credential")
	}
	data, err := collector.Export(t.Context(), session.Status{})
	if err != nil {
		t.Fatal(err)
	}
	archive, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		t.Fatal(err)
	}
	if len(archive.File) != 3 {
		t.Fatal("diagnostic archive did not include its three expected entries")
	}
	for _, file := range archive.File {
		entry, err := file.Open()
		if err != nil {
			t.Fatal(err)
		}
		content, err := io.ReadAll(entry)
		_ = entry.Close()
		if err != nil {
			t.Fatal(err)
		}
		if bytes.Contains(content, []byte("fixture")) {
			t.Fatalf("archive entry %s exposed an unregistered quoted credential", file.Name)
		}
	}
}
