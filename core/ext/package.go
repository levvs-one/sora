package ext

import (
	"archive/zip"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"io"
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
	// none. Package verification checks each declared entry.
	ManifestExt *ManifestExt
}

// OpenBytes reads an in-memory archive for CLI validation and tests.
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

func readArchive(zr *zip.Reader) (*Package, error) {
	if len(zr.File) > maxPackageFiles {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
			"ext: the package has too many files (%d)", len(zr.File))
	}
	files := make(map[string][]byte, len(zr.File))
	var total int64
	for _, f := range zr.File {
		// Directory entries carry no content and are not extracted; skip
		// them before the path check, exactly like the app-side opener.
		// A malicious directory name escapes nothing, because nothing is
		// ever written for it.
		if f.FileInfo().IsDir() {
			continue
		}
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
		// The header-declared UncompressedSize64 above is a fast path, and the
		// stdlib itself refuses to decompress past the declared size (fail
		// closed on a lying header). The accounting below still counts the
		// bytes that actually came out of the decompressor (the real
		// memory metric), so the total limit bounds real allocations no
		// matter which layer stops a bomb first.
		rc, err := f.Open()
		if err != nil {
			return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: cannot read %q: %v", name, err)
		}
		data, err := readZipFile(rc, f.UncompressedSize64)
		_ = rc.Close()
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

// readZipFile reads one archive member with the same limit semantics as
// io.ReadAll(io.LimitReader(rc, maxSingleFile+1)): at most maxSingleFile+1
// bytes, never truncated silently (the caller rejects len > maxSingleFile).
// The header-declared size only pre-sizes the buffer (see readAllLimited).
// A lying header is harmless: a smaller declaration just falls back to
// buffer growth, and a larger one wastes a bounded pre-allocation (the
// header was already checked against maxSingleFile before this runs).
func readZipFile(rc io.Reader, declared uint64) ([]byte, error) {
	var hint int64
	if declared > 0 && declared <= maxSingleFile {
		hint = int64(declared)
	}
	return readAllLimited(rc, maxSingleFile+1, hint)
}

// readAllLimited reads r to EOF, returning at most limit bytes. hint, when
// positive, is the expected total size and pre-sizes the single backing
// array. io.ReadAll's doubling growth allocates ~2x the content in total
// (measured: a 4 MiB member cost 10.0 MB of allocations to open); reading
// into a pre-sized array costs ~1x. The array is sized hint+1 so the read
// that confirms EOF still has a window and never triggers a speculative
// doubling - the trap a bytes.Buffer hits at an exact fit (its ReadFrom
// grows to 2x before probing for EOF). A wrong hint degrades to the same
// doubling growth as io.ReadAll, never to a wrong result, and limit is
// enforced regardless of the hint.
func readAllLimited(r io.Reader, limit int64, hint int64) ([]byte, error) {
	size := int64(512)
	if hint > 0 && hint < limit {
		size = hint + 1
	}
	data := make([]byte, 0, size)
	for int64(len(data)) < limit {
		if len(data) == cap(data) {
			newCap := int64(cap(data)) * 2
			if newCap > limit {
				newCap = limit
			}
			grown := make([]byte, len(data), newCap)
			copy(grown, data)
			data = grown
		}
		window := data[len(data):cap(data)]
		if remain := limit - int64(len(data)); int64(len(window)) > remain {
			window = window[:remain]
		}
		n, err := r.Read(window)
		data = data[:len(data)+n]
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
	}
	return data, nil
}

// isHexDigest reports whether s is exactly 64 hex characters (a sha256
// digest in text form), without the allocation hex.DecodeString spends on
// a decoded copy the callers here only validate and discard.
func isHexDigest(s string) bool {
	if len(s) != 64 {
		return false
	}
	for i := 0; i < len(s); i++ {
		c := s[i]
		if (c < '0' || c > '9') && (c < 'a' || c > 'f') && (c < 'A' || c > 'F') {
			return false
		}
	}
	return true
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
	// Only the canonical name is accepted: "./panel.html", "a//b" and
	// "a/./b" all clean to a different string, and an alias like that is
	// never legitimate - the archive would store "panel.html" under a key
	// the manifest entry (and the panel CSP injector, and the rollback
	// re-verification against the on-disk layout) never matches, so the
	// file the user consented to and the file that gets served silently
	// diverge. The app-side opener has always rejected these by segment;
	// this makes Go agree.
	if clean != name {
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
//  0. every file the manifest declares by pointer (panels, worker script,
//     capability-contract assets) is present in the package,
//  1. every file's sha256 matches checksums.txt,
//  2. checksums.txt covers every content file exactly once (no extras, no
//     missing - except the signature itself, which cannot checksum itself),
//  3. signature.minisig is a valid author signature over checksums.txt.
//
// The signature is checked against the manifest's self-attested author key;
// for catalog installs use VerifyWithKey with the catalog-pinned key
// instead. On success the package is trusted to match
// what the author signed.
func (p *Package) Verify() error {
	return p.VerifyWithKey(p.Manifest.Author.PublicKey)
}

// declaredEntry is one file the manifest points at: a panel, the worker
// script, or a capability-contract asset (theme / network-hook / routing).
type declaredEntry struct {
	field string // manifest field, for the error message
	entry string
}

// declaredEntries lists every file the manifest pair declares by pointer.
// Installing a package whose declared file is absent would leave the user
// with an extension whose panel 404s, whose worker never starts, or whose
// contract asset is silently missing - the project-side CLI check
// (sora-ext validate, "missing-entry") has always refused that; Verify
// closes the same hole for the package itself, which is the only artifact
// sideload and catalog installs ever see.
func (p *Package) declaredEntries() []declaredEntry {
	var out []declaredEntry
	if p.Manifest != nil && p.Manifest.UI != nil {
		for _, panel := range p.Manifest.UI.Panels {
			out = append(out, declaredEntry{"ui.panels[" + panel.ID + "].entry", panel.Entry})
		}
	}
	if x := p.ManifestExt; x != nil {
		if x.Background != nil {
			out = append(out, declaredEntry{"background_task.entry", x.Background.Entry})
		}
		if x.Theme != nil {
			out = append(out, declaredEntry{"theme.entry", x.Theme.Entry})
		}
		if x.NetworkHook != nil {
			out = append(out, declaredEntry{"network_hook.entry", x.NetworkHook.Entry})
		}
		if x.Routing != nil {
			out = append(out, declaredEntry{"routing.entry", x.Routing.Entry})
		}
	}
	return out
}

// checkDeclaredEntries fails verification when a declared entry file is
// absent from the package.
func (p *Package) checkDeclaredEntries() error {
	for _, d := range p.declaredEntries() {
		if _, ok := p.Files[d.entry]; !ok {
			return errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid,
				"ext: the manifest declares %s %q, which is missing from the package", d.field, d.entry)
		}
	}
	return nil
}

// VerifyWithKey is Verify against an explicit author key line. Catalog
// installs must pass the catalog-pinned key: the manifest's embedded key
// is self-attested, so verifying against it would let a package smuggle
// in its own trust anchor (D1).
func (p *Package) VerifyWithKey(authorKeyLine string) error {
	if err := p.checkDeclaredEntries(); err != nil {
		return err
	}
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
				"ext: file %q is not covered by checksums.txt - the package was modified", name)
		}
		sum := sha256.Sum256(data)
		// Compare the hex form in place: hex.EncodeToString would allocate
		// a 64-byte string per file just to be compared and thrown away
		// (~500 allocs on a 500-file package). parseChecksums guarantees
		// want is exactly 64 lowercase hex characters.
		var enc [64]byte
		hex.Encode(enc[:], sum[:])
		match := true
		for i := range enc {
			if enc[i] != want[i] {
				match = false
				break
			}
		}
		if !match {
			return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
				"ext: file %q does not match checksums.txt - the package was modified", name)
		}
	}
	for name := range listed {
		if name == signatureName || name == checksumsName {
			continue
		}
		if _, ok := p.Files[name]; !ok {
			return errs.Newf(errs.CodeUnauthenticated, KeySignatureInvalid,
				"ext: checksums.txt lists %q which is missing - the package was modified", name)
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
		if !isHexDigest(fields[0]) {
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
