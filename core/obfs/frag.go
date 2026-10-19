package obfs

import (
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"time"
)

// TLS record layer constants used by the splitter.
const (
	recordTypeHandshake  = 22
	handshakeClientHello = 1
	recordHeaderLen      = 5
)

// parseTLSRecords splits buf into individual TLS records. It returns an
// error if buf does not consist of complete, well-formed records.
func parseTLSRecords(buf []byte) ([][]byte, error) {
	var out [][]byte
	for len(buf) > 0 {
		if len(buf) < recordHeaderLen {
			return nil, errors.New("obfs: truncated TLS record header")
		}
		n := int(binary.BigEndian.Uint16(buf[3:5]))
		if recordHeaderLen+n > len(buf) {
			return nil, errors.New("obfs: truncated TLS record payload")
		}
		out = append(out, buf[:recordHeaderLen+n])
		buf = buf[recordHeaderLen+n:]
	}
	return out, nil
}

// isClientHelloRecord reports whether rec is a single TLS record whose
// first handshake message is a ClientHello.
func isClientHelloRecord(rec []byte) bool {
	return len(rec) > recordHeaderLen &&
		rec[0] == recordTypeHandshake &&
		rec[recordHeaderLen] == handshakeClientHello
}

// SplitClientHello splits a single TLS record carrying a ClientHello into
// 1+len(sizes) records. Each entry of sizes is the payload size of one
// leading fragment; the remainder of the original record becomes the final
// fragment. Only the record layer is touched: the inner handshake header
// stays intact in the first fragment, exactly as TLS fragmentation
// requires, so any peer reassembles the original ClientHello.
//
// An empty sizes slice returns the record unchanged. Sizes must each be in
// [1, MaxFragmentSize] and their sum must be smaller than the record
// payload so the trailing fragment is non-empty.
func SplitClientHello(record []byte, sizes []int) ([][]byte, error) {
	if len(record) < recordHeaderLen+1 {
		return nil, errors.New("obfs: record too short to be a ClientHello")
	}
	if record[0] != recordTypeHandshake {
		return nil, fmt.Errorf("obfs: record type %d is not a handshake", record[0])
	}
	if n := int(binary.BigEndian.Uint16(record[3:5])); recordHeaderLen+n != len(record) {
		return nil, errors.New("obfs: record length prefix does not match buffer")
	}
	if record[recordHeaderLen] != handshakeClientHello {
		return nil, errors.New("obfs: first handshake message is not a ClientHello")
	}
	payload := record[recordHeaderLen:]
	for i, s := range sizes {
		if s <= 0 {
			return nil, fmt.Errorf("obfs: fragment size [%d] = %d: must be positive", i, s)
		}
		if s > MaxFragmentSize {
			return nil, fmt.Errorf("obfs: fragment size [%d] = %d: exceeds %d", i, s, MaxFragmentSize)
		}
	}
	var total int
	for _, s := range sizes {
		total += s
	}
	if total >= len(payload) {
		return nil, fmt.Errorf("obfs: fragment sizes cover the whole ClientHello (%d >= %d)", total, len(payload))
	}

	frags := make([][]byte, 0, len(sizes)+1)
	off := 0
	for _, s := range sizes {
		frags = append(frags, makeRecord(record[1], record[2], payload[off:off+s]))
		off += s
	}
	frags = append(frags, makeRecord(record[1], record[2], payload[off:]))
	return frags, nil
}

// makeRecord builds one TLS record with the given legacy version bytes.
func makeRecord(verMajor, verMinor byte, payload []byte) []byte {
	rec := make([]byte, recordHeaderLen+len(payload))
	rec[0] = recordTypeHandshake
	rec[1] = verMajor
	rec[2] = verMinor
	binary.BigEndian.PutUint16(rec[3:5], uint16(len(payload)))
	copy(rec[recordHeaderLen:], payload)
	return rec
}

// WriteFragmented splits record per sizes and writes the fragments to w,
// sleeping delay (clamped to MaxFragDelay) between fragments. It is the
// building block behind the fragmenting conn wrapper.
func WriteFragmented(w io.Writer, record []byte, sizes []int, delay time.Duration) error {
	frags, err := SplitClientHello(record, sizes)
	if err != nil {
		return err
	}
	if delay > MaxFragDelay {
		delay = MaxFragDelay
	}
	for i, f := range frags {
		if i > 0 && delay > 0 {
			time.Sleep(delay)
		}
		if _, err := w.Write(f); err != nil {
			return err
		}
	}
	return nil
}
