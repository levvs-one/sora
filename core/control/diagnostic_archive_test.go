package control

import (
	"archive/zip"
	"bytes"
	"errors"
	"io"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/logs"
)

func TestDiagnosticArchiveMergeBoundsInflatedContents(t *testing.T) {
	var content bytes.Buffer
	writer := zip.NewWriter(&content)
	entry, err := writer.Create("events.log")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := io.Copy(entry, strings.NewReader(strings.Repeat("x", logs.MaxExportBytes+1))); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	data, err := mergeDiagnosticArchive(content.Bytes(), nil)
	if !errors.Is(err, io.ErrShortBuffer) || data != nil {
		t.Fatalf("oversized compressed contents accepted: %d bytes, %v", len(data), err)
	}
}
