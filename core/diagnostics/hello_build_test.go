package diagnostics

import (
	"encoding/binary"
	"testing"
)

// Byte-by-byte ClientHello construction for AnalyzeHello tests: the
// expectations in hello_test.go are derived from these exact bytes.

type helloExt struct {
	typ  uint16
	data []byte
}

type helloSpec struct {
	ciphers    []uint16
	extensions []helloExt
}

func buildHello(t *testing.T, spec helloSpec) []byte {
	t.Helper()
	var body []byte
	body = append(body, 0x03, 0x03)          // legacy version 771
	body = append(body, make([]byte, 32)...) // random
	body = append(body, 0)                   // session id len
	var cs []byte
	for _, c := range spec.ciphers {
		cs = binary.BigEndian.AppendUint16(cs, c)
	}
	body = binary.BigEndian.AppendUint16(body, uint16(len(cs)))
	body = append(body, cs...)
	body = append(body, 1, 0) // compression: null only
	var exts []byte
	for _, e := range spec.extensions {
		exts = binary.BigEndian.AppendUint16(exts, e.typ)
		exts = binary.BigEndian.AppendUint16(exts, uint16(len(e.data)))
		exts = append(exts, e.data...)
	}
	body = binary.BigEndian.AppendUint16(body, uint16(len(exts)))
	body = append(body, exts...)
	var hs []byte
	hs = append(hs, 1) // client_hello
	hs = append(hs, byte(len(body)>>16), byte(len(body)>>8), byte(len(body)))
	hs = append(hs, body...)
	var rec []byte
	rec = append(rec, 22, 0x03, 0x01)
	rec = binary.BigEndian.AppendUint16(rec, uint16(len(hs)))
	rec = append(rec, hs...)
	return rec
}

func sniData(name string) []byte {
	var entry []byte
	entry = append(entry, 0)
	entry = binary.BigEndian.AppendUint16(entry, uint16(len(name)))
	entry = append(entry, name...)
	out := binary.BigEndian.AppendUint16(nil, uint16(len(entry)))
	return append(out, entry...)
}

func u16List(vals ...uint16) []byte {
	var list []byte
	for _, v := range vals {
		list = binary.BigEndian.AppendUint16(list, v)
	}
	out := binary.BigEndian.AppendUint16(nil, uint16(len(list)))
	return append(out, list...)
}

func alpnData(protos ...string) []byte {
	var list []byte
	for _, p := range protos {
		list = append(list, byte(len(p)))
		list = append(list, p...)
	}
	out := binary.BigEndian.AppendUint16(nil, uint16(len(list)))
	return append(out, list...)
}

func keyShareData(groups ...uint16) []byte {
	var shares []byte
	for _, g := range groups {
		shares = binary.BigEndian.AppendUint16(shares, g)
		shares = binary.BigEndian.AppendUint16(shares, 32)
		shares = append(shares, make([]byte, 32)...)
	}
	out := binary.BigEndian.AppendUint16(nil, uint16(len(shares)))
	return append(out, shares...)
}
