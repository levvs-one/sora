package obfs

import (
	"encoding/binary"
	"errors"
	"fmt"
)

// extServerName is the TLS extension type for server_name (RFC 6066).
const extServerName = 0

// RewriteClientHelloSNI returns a copy of a single TLS ClientHello record
// with the server_name extension replaced by a single host_name entry for
// fake. All enclosing length prefixes (extension, extensions block,
// handshake message, record) are rebuilt, so the result is a well-formed
// record any TLS peer accepts.
//
// It returns an error if record is not exactly one ClientHello record,
// if the ClientHello carries no server_name extension, or if fake is not
// a valid hostname.
func RewriteClientHelloSNI(record []byte, fake string) ([]byte, error) {
	if !validHostname(fake) {
		return nil, fmt.Errorf("obfs: fake SNI %q is not a valid hostname", fake)
	}
	if len(record) < recordHeaderLen+1 {
		return nil, errors.New("obfs: record too short to be a ClientHello")
	}
	if record[0] != recordTypeHandshake {
		return nil, fmt.Errorf("obfs: record type %d is not a handshake", record[0])
	}
	if n := int(binary.BigEndian.Uint16(record[3:5])); recordHeaderLen+n != len(record) {
		return nil, errors.New("obfs: record holds more than one TLS record")
	}
	if record[recordHeaderLen] != handshakeClientHello {
		return nil, errors.New("obfs: first handshake message is not a ClientHello")
	}

	body := record[recordHeaderLen+4:] // skip the 4-byte handshake header
	extLenOff, extOff, extLen, err := findServerNameExt(body)
	if err != nil {
		return nil, err
	}

	// Build the replacement extension: list(2) + type(1) + len(2) + name.
	newData := make([]byte, 0, 5+len(fake))
	newData = append(newData, 0, 0) // list length placeholder
	newData = append(newData, 0)    // host_name
	var tmp [2]byte
	binary.BigEndian.PutUint16(tmp[:], uint16(len(fake)))
	newData = append(newData, tmp[:]...)
	newData = append(newData, fake...)
	binary.BigEndian.PutUint16(newData[0:2], uint16(3+len(fake)))

	newExt := make([]byte, 0, 4+len(newData))
	newExt = append(newExt, 0, byte(extServerName))
	binary.BigEndian.PutUint16(tmp[:], uint16(len(newData)))
	newExt = append(newExt, tmp[:]...)
	newExt = append(newExt, newData...)

	delta := len(newExt) - (4 + extLen)
	out := make([]byte, 0, len(record)+delta)
	out = append(out, record[:recordHeaderLen+4+extOff]...)
	out = append(out, newExt...)
	out = append(out, record[recordHeaderLen+4+extOff+4+extLen:]...)

	// Fix the enclosing lengths.
	extTotal := int(binary.BigEndian.Uint16(out[recordHeaderLen+4+extLenOff:]))
	binary.BigEndian.PutUint16(out[recordHeaderLen+4+extLenOff:], uint16(extTotal+delta))
	hsLen := int(out[recordHeaderLen+1])<<16 | int(out[recordHeaderLen+2])<<8 | int(out[recordHeaderLen+3])
	hsLen += delta
	out[recordHeaderLen+1] = byte(hsLen >> 16)
	out[recordHeaderLen+2] = byte(hsLen >> 8)
	out[recordHeaderLen+3] = byte(hsLen)
	recLen := len(out) - recordHeaderLen
	binary.BigEndian.PutUint16(out[3:5], uint16(recLen))
	return out, nil
}

// findServerNameExt locates the server_name extension inside a ClientHello
// body (without record/handshake headers). It returns the offset of the
// extensions-length field, the offset of the extension itself (both relative
// to body), and the extension's data length.
func findServerNameExt(body []byte) (extLenOff, extOff, extLen int, err error) {
	// legacy_version(2) + random(32) + session_id(1+len) +
	// cipher_suites(2+len) + compression(1+len) + extensions_len(2).
	p := 2 + 32
	if len(body) < p+1 {
		return 0, 0, 0, errors.New("obfs: truncated ClientHello (session id)")
	}
	p += 1 + int(body[p])
	if len(body) < p+2 {
		return 0, 0, 0, errors.New("obfs: truncated ClientHello (cipher suites)")
	}
	p += 2 + int(binary.BigEndian.Uint16(body[p:]))
	if len(body) < p+1 {
		return 0, 0, 0, errors.New("obfs: truncated ClientHello (compression)")
	}
	p += 1 + int(body[p])
	if len(body) < p+2 {
		return 0, 0, 0, errors.New("obfs: truncated ClientHello (extensions)")
	}
	extLenOff = p
	extTotal := int(binary.BigEndian.Uint16(body[p:]))
	p += 2
	if len(body) != p+extTotal {
		return 0, 0, 0, errors.New("obfs: ClientHello extensions length mismatch")
	}
	for e := p; e < p+extTotal; {
		if e+4 > len(body) {
			return 0, 0, 0, errors.New("obfs: truncated extension header")
		}
		typ := int(binary.BigEndian.Uint16(body[e:]))
		elen := int(binary.BigEndian.Uint16(body[e+2:]))
		if e+4+elen > len(body) {
			return 0, 0, 0, errors.New("obfs: truncated extension data")
		}
		if typ == extServerName {
			return extLenOff, e, elen, nil
		}
		e += 4 + elen
	}
	return 0, 0, 0, errors.New("obfs: ClientHello has no server_name extension")
}
