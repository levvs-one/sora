package logs

import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"encoding/csv"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"strconv"
	"strings"
	"time"
)

type Format int

const (
	FormatText Format = iota + 1
	FormatJSONLines
	FormatCSV
	FormatLog
	FormatJSON
	FormatXML
	FormatZIP
	FormatGZIP
)

const MaxExportBytes = 32 << 20

// Export preserves the original messages and their order in every format.
func Export(entries []Entry, format Format, at time.Time) (data []byte, name, mediaType string, err error) {
	var buf bytes.Buffer
	rows := make([]jsonEntry, 0, len(entries))
	for _, e := range entries {
		rows = append(rows, jsonEntry{e.Seq, e.Time.Format(time.RFC3339Nano), e.Level.String(), e.Source, e.Message, e.Repeat})
	}
	extension := ""
	switch format {
	case FormatText, FormatLog:
		for _, e := range entries {
			fmt.Fprintf(&buf, "%s %-7s %-8s %s", e.Time.Format("2006-01-02 15:04:05.000"), strings.ToUpper(e.Level.String()), "["+e.Source+"]", e.Message)
			if e.Repeat > 1 {
				fmt.Fprintf(&buf, " (x%d)", e.Repeat)
			}
			buf.WriteByte('\n')
		}
		extension, mediaType = "txt", "text/plain; charset=utf-8"
		if format == FormatLog {
			extension = "log"
		}
	case FormatJSONLines:
		enc := json.NewEncoder(&buf)
		for _, row := range rows {
			if err = enc.Encode(row); err != nil {
				return nil, "", "", err
			}
		}
		extension, mediaType = "jsonl", "application/x-ndjson"
	case FormatJSON:
		enc := json.NewEncoder(&buf)
		enc.SetIndent("", "  ")
		err = enc.Encode(struct {
			Format     string      `json:"format"`
			ExportedAt string      `json:"exported_at"`
			Entries    []jsonEntry `json:"entries"`
		}{"sora-log/1", at.Format(time.RFC3339), rows})
		extension, mediaType = "json", "application/json"
	case FormatXML:
		buf.WriteString(xml.Header)
		enc := xml.NewEncoder(&buf)
		enc.Indent("", "  ")
		err = enc.Encode(struct {
			XMLName    xml.Name    `xml:"sora-log"`
			Format     string      `xml:"format,attr"`
			ExportedAt string      `xml:"exported-at,attr"`
			Entries    []jsonEntry `xml:"entries>entry"`
		}{Format: "1", ExportedAt: at.Format(time.RFC3339), Entries: rows})
		extension, mediaType = "xml", "application/xml"
	case FormatCSV:
		w := csv.NewWriter(&buf)
		err = w.Write([]string{"sequence", "time", "level", "source", "message", "repeat"})
		for _, e := range entries {
			if err != nil {
				break
			}
			err = w.Write([]string{strconv.FormatUint(e.Seq, 10), e.Time.Format(time.RFC3339Nano), e.Level.String(), cell(e.Source), cell(e.Message), strconv.FormatUint(uint64(e.Repeat), 10)})
		}
		w.Flush()
		if err == nil {
			err = w.Error()
		}
		extension, mediaType = "csv", "text/csv; charset=utf-8"
	case FormatZIP:
		archive := zip.NewWriter(&buf)
		for _, item := range []struct {
			format Format
			name   string
		}{{FormatLog, "events.log"}, {FormatJSON, "events.json"}} {
			content, _, _, renderErr := Export(entries, item.format, at)
			if renderErr != nil {
				err = renderErr
				break
			}
			var file interface{ Write([]byte) (int, error) }
			file, err = archive.Create(item.name)
			if err != nil {
				break
			}
			if _, err = file.Write(content); err != nil {
				break
			}
		}
		closeErr := archive.Close()
		if err == nil {
			err = closeErr
		}
		extension, mediaType = "zip", "application/zip"
	case FormatGZIP:
		content, _, _, renderErr := Export(entries, FormatLog, at)
		if renderErr != nil {
			return nil, "", "", renderErr
		}
		writer := gzip.NewWriter(&buf)
		writer.Name = "events.log"
		writer.ModTime = at
		_, err = writer.Write(content)
		closeErr := writer.Close()
		if err == nil {
			err = closeErr
		}
		extension, mediaType = "gz", "application/gzip"
	default:
		return nil, "", "", fmt.Errorf("logs: unknown export format %d", format)
	}
	if err != nil {
		return nil, "", "", err
	}
	if buf.Len() > MaxExportBytes {
		return nil, "", "", fmt.Errorf("logs: the export is %d bytes, the limit is %d; narrow the filter", buf.Len(), MaxExportBytes)
	}
	return buf.Bytes(), "sora-log_" + at.Format("02_01_2006") + "." + extension, mediaType, nil
}

type jsonEntry struct {
	Seq     uint64 `json:"seq" xml:"sequence"`
	Time    string `json:"time" xml:"time"`
	Level   string `json:"level" xml:"level"`
	Source  string `json:"source" xml:"source"`
	Message string `json:"message" xml:"message"`
	Repeat  uint32 `json:"repeat" xml:"repeat"`
}

// Spreadsheet cells must not execute formulas from engine/server output.
func cell(s string) string {
	if s != "" && strings.ContainsRune("=+-@\t\r", rune(s[0])) {
		return "'" + s
	}
	return s
}
