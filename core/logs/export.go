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

// Format identifies a journal serialization format.
type Format int

// Stable export identifiers preserve older RPC format meanings.
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

// MaxExportBytes bounds an export and its uncompressed diagnostic contents.
const MaxExportBytes = 32 << 20

// jsonEntryOf renders one entry for the structured formats. The text,
// CSV, ZIP, and GZIP paths never build these rows: formatting a timestamp
// string and a row struct for every entry and then discarding them cost
// roughly a quarter of a plain text export.
func jsonEntryOf(e Entry) jsonEntry {
	return jsonEntry{e.Seq, e.Time.Format(time.RFC3339Nano), e.Level.String(), e.Source, e.Message, e.Repeat}
}

func jsonRows(entries []Entry) []jsonEntry {
	rows := make([]jsonEntry, 0, len(entries))
	for _, e := range entries {
		rows = append(rows, jsonEntryOf(e))
	}
	return rows
}

// levelUpper is Level.String in upper case, from a switch instead of a
// strings.ToUpper copy per exported entry.
func levelUpper(l Level) string {
	switch l {
	case LevelDebug:
		return "DEBUG"
	case LevelInfo:
		return "INFO"
	case LevelWarning:
		return "WARNING"
	case LevelError:
		return "ERROR"
	}
	return "UNKNOWN"
}

// writeTextEntry renders one entry exactly as the previous
// fmt.Fprintf("%s %-7s %-8s %s") form did, without the format machinery
// (several allocations per entry) or the concatenated bracket copy.
func writeTextEntry(buf *bytes.Buffer, e Entry) {
	buf.Write(e.Time.AppendFormat(buf.AvailableBuffer(), "2006-01-02 15:04:05.000"))
	buf.WriteByte(' ')
	level := levelUpper(e.Level)
	buf.WriteString(level)
	for i := len(level); i < 7; i++ {
		buf.WriteByte(' ')
	}
	buf.WriteByte(' ')
	buf.WriteByte('[')
	buf.WriteString(e.Source)
	buf.WriteByte(']')
	for i := len(e.Source) + 2; i < 8; i++ {
		buf.WriteByte(' ')
	}
	buf.WriteByte(' ')
	buf.WriteString(e.Message)
	if e.Repeat > 1 {
		buf.WriteString(" (x")
		buf.Write(strconv.AppendUint(buf.AvailableBuffer(), uint64(e.Repeat), 10))
		buf.WriteByte(')')
	}
	buf.WriteByte('\n')
}

// Export preserves the original messages and their order in every format.
func Export(entries []Entry, format Format, at time.Time) (data []byte, name, mediaType string, err error) {
	var buf bytes.Buffer
	extension := ""
	switch format {
	case FormatText, FormatLog:
		for _, e := range entries {
			writeTextEntry(&buf, e)
		}
		extension, mediaType = "txt", "text/plain; charset=utf-8"
		if format == FormatLog {
			extension = "log"
		}
	case FormatJSONLines:
		enc := json.NewEncoder(&buf)
		for _, e := range entries {
			if err = enc.Encode(jsonEntryOf(e)); err != nil {
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
		}{"sora-log/1", at.Format(time.RFC3339), jsonRows(entries)})
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
		}{Format: "1", ExportedAt: at.Format(time.RFC3339), Entries: jsonRows(entries)})
		extension, mediaType = "xml", "application/xml"
	case FormatCSV:
		w := csv.NewWriter(&buf)
		row := make([]string, 6)
		err = w.Write([]string{"sequence", "time", "level", "source", "message", "repeat"})
		for _, e := range entries {
			if err != nil {
				break
			}
			row[0] = strconv.FormatUint(e.Seq, 10)
			row[1] = e.Time.Format(time.RFC3339Nano)
			row[2] = e.Level.String()
			row[3] = cell(e.Source)
			row[4] = cell(e.Message)
			row[5] = strconv.FormatUint(uint64(e.Repeat), 10)
			err = w.Write(row)
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
