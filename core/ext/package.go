package ext

import (
	"archive/zip"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"os"
	"path"
	"sort"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// Package format limits. A .soraext is a modest UI bundle, not an app.
const (
	maxPackageBytes      = 64 << 20  // 64 MiB archive
	maxUncompressedBytes = 256 << 20 // 256 MiB total content
	maxPackageFiles      = 4096
	maxSingleFile        = 32 << 20 // 32 MiB per file
	manifestName         = "sora-extension.json"
	checksumsName        = "checksums.txt"
	signatureName        = "signature.minisig"
)

// Package is an opened, not yet trusted .soraext archive.
type Package struct {
	// Files maps archive-relative paths to contents. It always contains the
	// manifest, checksums.txt and signature.minisig when opened successfully.
	Files map[string][]byte
	// Manifest is the parsed sora-extension.json.
	Manifest *Manifest
	// ManifestExt holds the optional v2-runtime manifest fields
	// (background_task, network_hosts); nil when the manifest declares
	// none. Needed to restore them on rollback (see Store.Rollback).
	ManifestExt *ManifestExt
}

// Open reads a .soraext file with strict limits and structural checks.
// It does NOT verify the signature; call Verify next.
func Open(path string) (*Package, error) {
	return openArchive(path)
}

// OpenBytes is Open for an in-memory archive (downloads, tests).
func OpenBytes(data []byte) (*Package, error) {
	if len(data) > maxPackageBytes {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
			"ext: the package exceeds %d bytes", maxPackageBytes)
	}
	zr, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
			"ext: the package is not a zip archive: %v", err)
	}
	return readArchive(zr)
}

func openArchive(p string) (*Package, error) {
	// Reject an oversized file before touching the zip parser: the archive
	// limit applies to the container too, not just in-memory downloads.
	if fi, err := os.Stat(p); err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
			"ext: cannot stat the package: %v", err)
	} else if fi.Size() > maxPackageBytes {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
			"ext: the package exceeds %d bytes", maxPackageBytes)
	}
	zr, err := zip.OpenReader(p)
	if err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
			"ext: the package is not a zip archive: %v", err)
	}
	defer zr.Close()
	return readArchive(&zr.Reader)
}

func readArchive(zr *zip.Reader) (*Package, error) {
	if len(zr.File) > maxPackageFiles {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
			"ext: the package has too many files (%d)", len(zr.File))
	}
	files := make(map[string][]byte, len(zr.File))
	var total int64
	for _, f := range zr.File {
		name := f.Name
		// Zip-slip and layout rules: relative, forward slashes, no
		// traversal, no absolute paths, no directories escaping the root.
		if !isSafeArchivePath(name) {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: the package contains an unsafe path %q", name)
		}
		if f.UncompressedSize64 > maxSingleFile {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: file %q exceeds %d bytes", name, maxSingleFile)
		}
		if f.FileInfo().IsDir() {
			continue
		}
		// The header-declared UncompressedSize64 above is a fast path, and the
		// stdlib itself refuses to decompress past the declared size (fail
		// closed on a lying header). The accounting below still counts the
		// bytes that actually came out of the decompressor — the honest
		// memory metric — so the total limit bounds real allocations no
		// matter which layer stops a bomb first.
		rc, err := f.Open()
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: cannot read %q: %v", name, err)
		}
		data, err := io.ReadAll(io.LimitReader(rc, maxSingleFile+1))
		rc.Close()
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: cannot read %q: %v", name, err)
		}
		// Second layer behind the stdlib's own declared-size cap: a file
		// that expands past the per-file cap is rejected, never truncated.
		if int64(len(data)) > maxSingleFile {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: file %q expands beyond %d bytes", name, maxSingleFile)
		}
		// The total limit is enforced on actual bytes, not on declared
		// sizes: many small-declared files must not smuggle a huge payload.
		total += int64(len(data))
		if total > maxUncompressedBytes {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: the package content exceeds %d bytes", maxUncompressedBytes)
		}
		if _, dup := files[name]; dup {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: duplicate path %q", name)
		}
		files[name] = data
	}
	for _, need := range []string{manifestName, checksumsName, signatureName} {
		if _, ok := files[need]; !ok {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: the package is missing %q", need)
		}
	}
	m, x, err := ParseManifestFull(files[manifestName])
	if err != nil {
		return nil, err
	}
	return &Package{Files: files, Manifest: m, ManifestExt: x}, nil
}

func isSafeArchivePath(name string) bool {
	if name == "" || len(name) > 512 {
		return false
	}
	// The package format mandates forward slashes (§1). A backslash is
	// never legitimate in an archive path, and on the Windows extractor
	// it is a separator: "..\..\evil" or "C:\evil" would escape the
	// target directory there. Colons are rejected for the same reason
	// (drive letters, NTFS alternate data streams like "panel.html:evil").
	if strings.ContainsAny(name, "\\:") {
		return false
	}
	if !strings.HasPrefix(name, "./") && (path.IsAbs(name) || strings.HasPrefix(name, "/")) {
		return false
	}
	clean := path.Clean(name)
	if clean == "." || clean == "/" || strings.HasPrefix(clean, "..") {
		return false
	}
	for _, part := range strings.Split(clean, "/") {
		if part == "" || part == "." || part == ".." {
			return false
		}
	}
	return true
}

// Verify checks the package integrity and authenticity:
//  1. every file's sha256 matches checksums.txt,
//  2. checksums.txt covers every content file exactly once (no extras, no
//     missing — except the signature itself, which cannot checksum itself),
//  3. signature.minisig is a valid author signature over checksums.txt.
//
// The signature is checked against the manifest's self-attested author key;
// for catalog installs use VerifyWithKey with the catalog-pinned key
// instead (see Store.Install). On success the package is trusted to match
// what the author signed.
func (p *Package) Verify() error {
	return p.VerifyWithKey(p.Manifest.Author.PublicKey)
}

// VerifyWithKey is Verify against an explicit author key line. Catalog
// installs must pass the catalog-pinned key: the manifest's embedded key
// is self-attested, so verifying against it would let a package smuggle
// in its own trust anchor (D1).
func (p *Package) VerifyWithKey(authorKeyLine string) error {
	checksumsRaw, ok := p.Files[checksumsName]
	if !ok {
		return errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid, "ext: the package is missing %q", checksumsName)
	}
	sigText, ok := p.Files[signatureName]
	if !ok {
		return errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid, "ext: the package is missing %q", signatureName)
	}
	listed, err := parseChecksums(string(checksumsRaw))
	if err != nil {
		return err
	}
	// Every content file must be listed; nothing extra may be listed.
	// checksums.txt and signature.minisig are exempt: neither can checksum
	// itself, and checksums.txt is authenticated by the signature's trusted
	// comment (which carries its sha256).
	for name, data := range p.Files {
		if name == signatureName || name == checksumsName {
			continue
		}
		want, ok := listed[name]
		if !ok {
			return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
				"ext: file %q is not covered by checksums.txt — the package was modified", name)
		}
		sum := sha256.Sum256(data)
		if hex.EncodeToString(sum[:]) != want {
			return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
				"ext: file %q does not match checksums.txt — the package was modified", name)
		}
	}
	for name := range listed {
		if name == signatureName || name == checksumsName {
			continue
		}
		if _, ok := p.Files[name]; !ok {
			return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
				"ext: checksums.txt lists %q which is missing — the package was modified", name)
		}
	}
	if err := VerifyPackageSignature(authorKeyLine, string(sigText), checksumsRaw); err != nil {
		return err
	}
	return nil
}

// parseChecksums parses "sha256hex  path" lines.
func parseChecksums(text string) (map[string]string, error) {
	out := map[string]string{}
	for i, line := range strings.Split(strings.ReplaceAll(strings.TrimSpace(text), "\r\n", "\n"), "\n") {
		if strings.TrimSpace(line) == "" {
			continue
		}
		fields := strings.Fields(line)
		if len(fields) != 2 || len(fields[0]) != 64 {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: checksums.txt line %d is malformed", i+1)
		}
		if _, err := hex.DecodeString(fields[0]); err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: checksums.txt line %d has a bad sha256", i+1)
		}
		if !isSafeArchivePath(fields[1]) {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: checksums.txt line %d has an unsafe path", i+1)
		}
		if _, dup := out[fields[1]]; dup {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: checksums.txt lists %q twice", fields[1])
		}
		out[fields[1]] = strings.ToLower(fields[0])
	}
	if len(out) == 0 {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid, "ext: checksums.txt is empty")
	}
	return out, nil
}

// MakeChecksums builds the canonical checksums.txt for files (paths sorted).
// It is the reference packager used by tests and docs.
func MakeChecksums(files map[string]string) string {
	names := make([]string, 0, len(files))
	for n := range files {
		names = append(names, n)
	}
	sort.Strings(names)
	var b strings.Builder
	for _, n := range names {
		sum := sha256.Sum256([]byte(files[n]))
		b.WriteString(hex.EncodeToString(sum[:]) + "  " + n + "\n")
	}
	return b.String()
}
