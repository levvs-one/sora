package ext

// Detail-hunt D19: weak checks and lying security guarantees around
// per-extension tokens and permissions. Every fix here gets a positive and
// a negative case.
//
// Note: the zip-bomb, panel-CSP and rollback-manifest fixes live in
// package.go/store.go, which a sibling agent is actively developing; their
// tests land with that commit. The zip tests below pin the fail-closed
// property that already holds on this toolchain.

import (
	"bytes"
	"compress/flate"
	"context"
	"encoding/binary"
	"encoding/json"
	"hash/crc32"
	"testing"
)

// lyingFile is one zip entry whose headers declare a different uncompressed
// size than the content actually expands to.
type lyingFile struct {
	name     string
	content  []byte
	declared uint64 // uncompressed size written into the zip headers
}

// buildLyingZip assembles a raw zip (no zip64) by hand so the tests control
// the declared uncompressed sizes independently of the real content. CRCs
// and compressed sizes are honest - only the uncompressed size lies.
func buildLyingZip(t *testing.T, files []lyingFile) []byte {
	t.Helper()
	var buf bytes.Buffer
	put16 := func(v uint16) {
		var b [2]byte
		binary.LittleEndian.PutUint16(b[:], v)
		buf.Write(b[:])
	}
	put32 := func(v uint32) {
		var b [4]byte
		binary.LittleEndian.PutUint32(b[:], v)
		buf.Write(b[:])
	}
	type cent struct {
		name         string
		crc          uint32
		compSize     uint32
		declaredSize uint32
		localOff     uint32
	}
	var cents []cent
	for _, f := range files {
		var comp bytes.Buffer
		w, err := flate.NewWriter(&comp, flate.BestSpeed)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write(f.content); err != nil {
			t.Fatal(err)
		}
		if err := w.Close(); err != nil {
			t.Fatal(err)
		}
		compBytes := comp.Bytes()
		if uint64(len(compBytes)) > 0xffffffff || f.declared > 0xffffffff {
			t.Fatal("test file too large for a non-zip64 test archive")
		}
		crc := crc32.ChecksumIEEE(f.content)
		localOff := uint32(buf.Len())
		put32(0x04034b50) // local file header
		put16(20)         // version needed
		put16(0)          // flags: no data descriptor
		put16(8)          // deflate
		put16(0)
		put16(0) // mod time/date
		put32(crc)
		put32(uint32(len(compBytes)))
		put32(uint32(f.declared)) // the lie
		put16(uint16(len(f.name)))
		put16(0) // extra length
		buf.WriteString(f.name)
		buf.Write(compBytes)
		cents = append(cents, cent{f.name, crc, uint32(len(compBytes)), uint32(f.declared), localOff})
	}
	cdOff := uint32(buf.Len())
	for _, c := range cents {
		put32(0x02014b50) // central directory entry
		put16(20)
		put16(20) // made by / needed
		put16(0)
		put16(8) // flags / method
		put16(0)
		put16(0) // time/date
		put32(c.crc)
		put32(c.compSize)
		put32(c.declaredSize) // the lie, again
		put16(uint16(len(c.name)))
		put16(0)
		put16(0) // name/extra/comment lengths
		put16(0)
		put16(0) // disk start / internal attrs
		put32(0) // external attrs
		put32(c.localOff)
		buf.WriteString(c.name)
	}
	cdSize := uint32(buf.Len()) - cdOff
	put32(0x06054b50) // end of central directory
	put16(0)
	put16(0)
	put16(uint16(len(cents)))
	put16(uint16(len(cents)))
	put32(cdSize)
	put32(cdOff)
	put16(0)
	return buf.Bytes()
}

// lyingPackage wraps bomb files with the mandatory package files (honest
// sizes, valid manifest) so readArchive reaches the size checks.
func lyingPackage(t *testing.T, bombs []lyingFile) []byte {
	t.Helper()
	manRaw, err := json.Marshal(testManifest(t))
	if err != nil {
		t.Fatal(err)
	}
	files := []lyingFile{
		{name: manifestName, content: manRaw, declared: uint64(len(manRaw))},
		{name: checksumsName, content: []byte("x"), declared: 1},
		{name: signatureName, content: []byte("x"), declared: 1},
	}
	files = append(files, bombs...)
	return buildLyingZip(t, files)
}

func TestZipBombLyingTotalSize(t *testing.T) {
	// 9 files, each declared as 5 bytes in the headers but expanding to
	// 30 MiB: the headers claim 45 bytes total, the truth is 270 MiB, over
	// the 256 MiB content limit. This must fail closed - no partial package,
	// no 270 MiB in memory.
	big := make([]byte, 30<<20)
	var bombs []lyingFile
	for i := 0; i < 9; i++ {
		bombs = append(bombs, lyingFile{
			name:     "bomb-" + string(rune('a'+i)) + ".dat",
			content:  big,
			declared: 5,
		})
	}
	if _, err := OpenBytes(lyingPackage(t, bombs)); err == nil {
		t.Fatal("decompression bomb with lying header sizes must be rejected")
	}
}

func TestZipBombLyingSingleFile(t *testing.T) {
	// One file declared as 5 bytes, actually 33 MiB: over the 32 MiB
	// per-file cap. Must fail closed instead of materializing 32 MiB+1.
	big := make([]byte, 33<<20)
	if _, err := OpenBytes(lyingPackage(t, []lyingFile{{
		name: "bomb.dat", content: big, declared: 5,
	}})); err == nil {
		t.Fatal("a file expanding past the per-file cap must be rejected")
	}
}

func TestZipHonestDeclaredSizesAccepted(t *testing.T) {
	// Sanity: the hand-built archive itself is sound when sizes are honest.
	content := bytes.Repeat([]byte("a"), 1<<20)
	pkg, err := OpenBytes(lyingPackage(t, []lyingFile{{
		name: "honest.dat", content: content, declared: uint64(len(content)),
	}}))
	if err != nil {
		t.Fatalf("honest archive rejected: %v", err)
	}
	if len(pkg.Files["honest.dat"]) != len(content) {
		t.Fatal("honest file content mangled")
	}
}

func TestMintTokenEnforcesGranted(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "1.0.0") // grants: connections.read, notifications
	h := NewHost(s.Issuer(), Deps{
		VerifyControl: func(tok []byte) bool { return string(tok) == "control" },
		GrantedPermissions: func(id string) ([]string, bool) {
			inst, ok := s.Get(id)
			if !ok || !inst.Enabled {
				return nil, false
			}
			return inst.Granted, true
		},
	})
	ctx := context.Background()
	// Positive: a granted permission mints fine.
	if _, err := h.MintToken(ctx, mintReq("control", "com.example.hello", []string{"connections.read"})); err != nil {
		t.Fatalf("mint of a granted permission failed: %v", err)
	}
	// Negative: a permission the user never granted is refused.
	if _, err := h.MintToken(ctx, mintReq("control", "com.example.hello",
		[]string{"connections.read", "servers.read"})); err == nil {
		t.Fatal("mint of an ungranted permission must fail")
	}
	// Negative: unknown extension.
	if _, err := h.MintToken(ctx, mintReq("control", "com.example.nope",
		[]string{"notifications"})); err == nil {
		t.Fatal("mint for an unknown extension must fail")
	}
	// Negative: disabled extension.
	if err := s.SetEnabled("com.example.hello", false); err != nil {
		t.Fatal(err)
	}
	if _, err := h.MintToken(ctx, mintReq("control", "com.example.hello",
		[]string{"notifications"})); err == nil {
		t.Fatal("mint for a disabled extension must fail")
	}
}

func TestCheckRejectsUnknownRPC(t *testing.T) {
	issuer := NewTokenIssuer()
	tok, err := issuer.Mint("com.example.hello", []string{"notifications"})
	if err != nil {
		t.Fatal(err)
	}
	h := NewHost(issuer, Deps{})
	// Fail closed: an RPC name outside the permission map is denied, not
	// treated as "any valid token".
	if _, err := h.check([]byte(tok), "NopeRPC"); err == nil {
		t.Fatal("unknown RPC must be denied")
	}
	// The deliberate token-only RPC still works.
	if _, err := h.check([]byte(tok), "WatchExtensionEvents"); err != nil {
		t.Fatalf("WatchExtensionEvents must stay token-only: %v", err)
	}
}
