// Package pack builds .soraext archives from project directories.
//
// The layout mirrors the existing example (examples/hello-panel): the zip
// holds every project file plus a generated checksums.txt; signing is a
// separate step (the sign command), because the key should stay offline.
package pack

import (
	"archive/zip"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/levvs-one/sora-client/core/ext"
)

// zipModTime keeps archives reproducible: a fixed timestamp unless
// SOURCE_DATE_EPOCH is set (the standard reproducible-builds knob).
func zipModTime() time.Time {
	if v := os.Getenv("SOURCE_DATE_EPOCH"); v != "" {
		if n, err := strconv.ParseInt(strings.TrimSpace(v), 10, 64); err == nil {
			return time.Unix(n, 0).UTC()
		}
	}
	return time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
}

// skipName reports whether a project file must not enter the package:
// build artifacts, VCS metadata and hidden files.
func skipName(rel string) bool {
	base := filepath.Base(rel)
	if base == "checksums.txt" || base == "signature.minisig" {
		return true // generated/signed at pack/sign time
	}
	if strings.HasSuffix(base, ".soraext") {
		return true
	}
	for _, part := range strings.Split(rel, "/") {
		if strings.HasPrefix(part, ".") {
			return true
		}
	}
	return false
}

// Collect reads dir and returns the package file set (slash-separated
// relative paths to contents). It refuses outright to pack key files
// (*.key): secret key material has no place in a distributable package.
// (2026-10-20 audit: the first shipped examples shipped their author.key
// secret inside the .soraext - pack must fail loudly instead of packing
// it silently.)
func Collect(dir string) (map[string][]byte, error) {
	files := map[string][]byte{}
	err := filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			if d.Name() == ".git" {
				return filepath.SkipDir
			}
			return nil
		}
		rel, err := filepath.Rel(dir, path)
		if err != nil {
			return err
		}
		rel = filepath.ToSlash(rel)
		if skipName(rel) {
			return nil
		}
		if strings.HasSuffix(filepath.Base(rel), ".key") {
			return fmt.Errorf("refusing to pack %q: *.key files are secret key material and must never ship inside a .soraext", rel)
		}
		if !d.Type().IsRegular() {
			return fmt.Errorf("refusing non-regular project file %q", rel)
		}
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		files[rel] = data
		return nil
	})
	if err != nil {
		return nil, err
	}
	if len(files) == 0 {
		return nil, fmt.Errorf("no files to pack in %s", dir)
	}
	return files, nil
}

// Checksums renders checksums.txt for files (paths sorted). It delegates
// to ext.MakeChecksums, the reference packager.
func Checksums(files map[string][]byte) string {
	strs := make(map[string]string, len(files))
	for n, b := range files {
		strs[n] = string(b)
	}
	return ext.MakeChecksums(strs)
}

// Write builds the .soraext at outPath from files. checksumsText is the
// checksums.txt content ("" = generate from files); sigText is the
// signature.minisig content, or "" for an unsigned package (the sign
// command adds it later).
func Write(outPath string, files map[string][]byte, checksumsText, sigText string) (int64, error) {
	names := make([]string, 0, len(files))
	for n := range files {
		names = append(names, n)
	}
	sort.Strings(names)

	f, err := os.Create(outPath)
	if err != nil {
		return 0, err
	}
	zw := zip.NewWriter(f)
	modTime := zipModTime()
	add := func(name string, data []byte) error {
		h := &zip.FileHeader{Name: name, Method: zip.Deflate}
		h.Modified = modTime
		w, err := zw.CreateHeader(h)
		if err != nil {
			return err
		}
		_, err = w.Write(data)
		return err
	}
	for _, n := range names {
		if err := add(n, files[n]); err != nil {
			_ = zw.Close()
			_ = f.Close()
			return 0, err
		}
	}
	if checksumsText == "" {
		checksumsText = Checksums(files)
	}
	if err := add("checksums.txt", []byte(checksumsText)); err != nil {
		_ = zw.Close()
		_ = f.Close()
		return 0, err
	}
	if sigText != "" {
		if err := add("signature.minisig", []byte(sigText)); err != nil {
			_ = zw.Close()
			_ = f.Close()
			return 0, err
		}
	}
	if err := zw.Close(); err != nil {
		_ = f.Close()
		return 0, err
	}
	st, err := f.Stat()
	if err != nil {
		_ = f.Close()
		return 0, err
	}
	size := st.Size()
	if err := f.Close(); err != nil {
		return 0, err
	}
	return size, nil
}

// SHA256 returns the hex sha256 of a file.
func SHA256(path string) (string, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:]), nil
}
