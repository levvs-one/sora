package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"golang.org/x/sys/unix"
)

func prepareUpdateSnapshot(ctx context.Context, format, version, source, target, publicKey string) (err error) {
	if !releaseVersionPattern.MatchString(version) || len(version) > 64 || !filepath.IsAbs(source) || !filepath.IsAbs(target) {
		return fmt.Errorf("release: invalid update snapshot version or directories")
	}
	var names []string
	for _, pkg := range []string{"sora-core", "sora"} {
		switch format {
		case "deb":
			names = append(names, pkg+"_"+version+"_amd64.deb")
		case "rpm":
			names = append(names, pkg+"-"+version+"-1.x86_64.rpm")
		case "arch":
			names = append(names, pkg+"-"+version+"-1-x86_64.pkg.tar.zst")
		default:
			return fmt.Errorf("release: unsupported update snapshot format")
		}
	}
	input, err := os.OpenRoot(source)
	if err != nil {
		return err
	}
	defer func() { _ = input.Close() }()
	output, err := os.OpenRoot(target)
	if err != nil {
		return err
	}
	defer func() { _ = output.Close() }()
	directory, err := output.Open(".")
	if err != nil {
		return err
	}
	defer func() { _ = directory.Close() }()
	var stat unix.Stat_t
	if err := unix.Fstat(int(directory.Fd()), &stat); err != nil {
		return err
	}
	if int64(stat.Uid) != int64(os.Geteuid()) || stat.Mode&0o7777 != 0o700 {
		return fmt.Errorf("release: snapshot directory must be owned by this user with mode 0700")
	}
	entries, err := directory.Readdirnames(1)
	if (err != nil && !errors.Is(err, io.EOF)) || len(entries) != 0 {
		return fmt.Errorf("release: snapshot directory must be empty")
	}
	// The installed helper owns the destination; a caller only controls input.
	// No untrusted file is opened without no-follow/nonblocking flags and fstat.
	ctx, cancel := context.WithTimeout(ctx, 10*time.Minute)
	defer cancel()
	copied := []string{}
	defer func() {
		if err != nil {
			for _, name := range copied {
				_ = output.Remove(name)
			}
		}
	}()
	metadata := []string{"SHA256SUMS", "SHA256SUMS.minisig", "release.json"}
	for _, name := range metadata {
		limit := int64(1024 * 1024)
		if name == "SHA256SUMS.minisig" {
			limit = 8192
		}
		if err := copyUpdateSnapshotFile(ctx, input, output, name, limit); err != nil {
			return err
		}
		copied = append(copied, name)
	}
	manifest, err := verifyRelease(target, version, publicKey)
	if err != nil {
		return err
	}
	for _, name := range names {
		size, err := manifest.artifactSize(name, "linux/amd64", version)
		if err != nil {
			return err
		}
		if err := copyUpdateSnapshotFile(ctx, input, output, name, size); err != nil {
			return err
		}
		copied = append(copied, name)
		digest, err := releaseChecksum(manifest.payload, name)
		if err != nil {
			return err
		}
		if err := verifyReleaseArtifactFile(ctx, output, releaseArtifact{Name: name, Size: size, SHA256: digest}); err != nil {
			return err
		}
	}
	return ctx.Err()
}

func copyUpdateSnapshotFile(ctx context.Context, input, output *os.Root, name string, limit int64) (err error) {
	if err := ctx.Err(); err != nil {
		return err
	}
	if filepath.Base(name) != name || name == "." || name == ".." {
		return fmt.Errorf("release: snapshot input must be a single filename")
	}
	directory, err := input.Open(".")
	if err != nil {
		return err
	}
	defer func() { _ = directory.Close() }()
	// Root.OpenFile resolves in-root symlinks even with O_NOFOLLOW. For this
	// single-component name, openat binds the final no-follow check to open.
	descriptor, err := unix.Openat(int(directory.Fd()), name, unix.O_RDONLY|unix.O_CLOEXEC|unix.O_NOFOLLOW|unix.O_NONBLOCK, 0)
	if err != nil {
		return err
	}
	file := os.NewFile(uintptr(descriptor), name)
	if file == nil {
		_ = unix.Close(descriptor)
		return fmt.Errorf("release: snapshot input handle is unavailable")
	}
	defer func() { _ = file.Close() }()
	stop := context.AfterFunc(ctx, func() { _ = file.Close() })
	defer stop()
	before, err := file.Stat()
	if err != nil {
		return err
	}
	if !before.Mode().IsRegular() || before.Size() < 1 || before.Size() > limit {
		return fmt.Errorf("release: %s must be a nonempty regular file within its authenticated bound", name)
	}
	var stat unix.Stat_t
	if err := unix.Fstat(int(file.Fd()), &stat); err != nil || stat.Nlink != 1 {
		return fmt.Errorf("release: linked snapshot input rejected")
	}
	destination, err := output.OpenFile(name, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if err != nil {
		return err
	}
	defer func() {
		if closeErr := destination.Close(); err == nil {
			err = closeErr
		}
		if err != nil {
			_ = output.Remove(name)
		}
	}()
	count, err := io.Copy(destination, io.LimitReader(file, limit+1))
	if err := ctx.Err(); err != nil {
		return err
	}
	if err != nil {
		return err
	}
	after, err := file.Stat()
	if err != nil || count != before.Size() || after.Size() != before.Size() || !after.ModTime().Equal(before.ModTime()) || count > limit {
		return fmt.Errorf("release: snapshot input changed or exceeded its bound")
	}
	if err := unix.Fstat(int(file.Fd()), &stat); err != nil || stat.Nlink != 1 {
		return fmt.Errorf("release: snapshot input links changed")
	}
	return nil
}
