package logs

import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"encoding/json"
	"encoding/xml"
	"io"
	"strings"
	"testing"
)

func TestStructuredAndCompressedExportsPreserveRecords(t *testing.T) {
	entries := []Entry{{Seq: 7, Time: t0, Level: LevelError, Source: "xray", Message: "Русский < & \"quote\"\nsecond line", Repeat: 2}}
	raw, _, _, err := Export(entries, FormatLog, t0)
	if err != nil {
		t.Fatal(err)
	}
	for _, format := range []Format{FormatJSON, FormatXML, FormatZIP, FormatGZIP} {
		data, name, media, err := Export(entries, format, t0)
		if err != nil || !strings.HasPrefix(name, "sora-log_06_10_2026.") || media == "" {
			t.Fatalf("format %v = %s %s, %v", format, name, media, err)
		}
		switch format {
		case FormatJSON:
			var doc struct {
				Entries []jsonEntry `json:"entries"`
			}
			if err := json.Unmarshal(data, &doc); err != nil || len(doc.Entries) != 1 || doc.Entries[0].Message != entries[0].Message || doc.Entries[0].Repeat != 2 {
				t.Fatalf("JSON = %s, %v", data, err)
			}
		case FormatXML:
			var doc struct {
				Entries []jsonEntry `xml:"entries>entry"`
			}
			if err := xml.Unmarshal(data, &doc); err != nil || len(doc.Entries) != 1 || doc.Entries[0].Message != entries[0].Message {
				t.Fatalf("XML = %s, %v", data, err)
			}
		case FormatZIP:
			archive, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
			if err != nil || len(archive.File) != 2 {
				t.Fatalf("ZIP = %v, %v", archive, err)
			}
			reader, err := archive.File[0].Open()
			if err != nil {
				t.Fatal(err)
			}
			content, err := io.ReadAll(reader)
			_ = reader.Close()
			if err != nil || !bytes.Equal(content, raw) {
				t.Fatalf("ZIP log = %q, %v", content, err)
			}
		case FormatGZIP:
			reader, err := gzip.NewReader(bytes.NewReader(data))
			if err != nil {
				t.Fatal(err)
			}
			content, err := io.ReadAll(reader)
			_ = reader.Close()
			if err != nil || !bytes.Equal(content, raw) {
				t.Fatalf("GZ = %q, %v", content, err)
			}
		}
	}
}
