package main

import (
	"archive/zip"
	"flag"
	"fmt"
	"io"
	"os"
	"regexp"
	"time"

	"github.com/levvs-one/sora-client/core/ext"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/keyutil"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/pack"
)

func cmdKeygen(args []string) int {
	fs := flag.NewFlagSet("keygen", flag.ContinueOnError)
	out := fs.String("o", "author", "")
	if err := fs.Parse(reorderArgs(args, map[string]bool{"force": true})); err != nil {
		return 1
	}
	kp, err := keyutil.Generate()
	if err != nil {
		return errOp("keygen: %v", err)
	}
	comment := "sora-ext signing key"
	if err := kp.WriteSecret(*out+".key", comment); err != nil {
		return errOp("write: %v", err)
	}
	if err := kp.WritePublic(*out+".pub", comment); err != nil {
		return errOp("write: %v", err)
	}
	fmt.Printf("secret: %s.key (keep offline, never commit)\n", *out)
	fmt.Printf("public: %s.pub\n", *out)
	fmt.Printf("\nPaste this line into sora-extension.json -> author.public_key:\n%s\n", kp.PublicKeyLine)
	return 0
}

func cmdSign(args []string) int {
	fs := flag.NewFlagSet("sign", flag.ContinueOnError)
	keyPath := fs.String("key", "", "")
	force := fs.Bool("force", false, "")
	if err := fs.Parse(reorderArgs(args, map[string]bool{"force": true})); err != nil {
		return 1
	}
	if *keyPath == "" {
		return errUsage("sign needs --key, e.g. sora-ext sign --key author.key ext.soraext")
	}
	if fs.NArg() < 1 {
		return errUsage("sign needs a .soraext file")
	}
	pkgPath := fs.Arg(0)
	key, err := keyutil.Load(*keyPath)
	if err != nil {
		return errOp("key: %v", err)
	}
	zr, err := zip.OpenReader(pkgPath)
	if err != nil {
		return errOp("open: %v", err)
	}
	files := map[string][]byte{}
	var checksums []byte
	for _, f := range zr.File {
		// signature.minisig is replaced below; checksums.txt is carried
		// over byte-for-byte so the new signature covers exactly what
		// pack generated.
		if f.Name == "signature.minisig" {
			if !*force {
				_ = zr.Close()
				return errUsage("already signed - use --force to re-sign")
			}
			continue
		}
		if f.Name == "checksums.txt" {
			rc, err := f.Open()
			if err != nil {
				_ = zr.Close()
				return errOp("read: %v", err)
			}
			checksums, err = io.ReadAll(rc)
			_ = rc.Close()
			if err != nil {
				_ = zr.Close()
				return errOp("read: %v", err)
			}
			continue
		}
		rc, err := f.Open()
		if err != nil {
			_ = zr.Close()
			return errOp("read: %v", err)
		}
		data, err := io.ReadAll(rc)
		_ = rc.Close()
		if err != nil {
			_ = zr.Close()
			return errOp("read: %v", err)
		}
		files[f.Name] = data
	}
	_ = zr.Close()
	if len(checksums) == 0 {
		return errOp("package has no checksums.txt - rebuild it with sora-ext pack")
	}
	sigText, err := ext.SignPayload(key, "sora-ext signature", "checksums.txt", time.Now().Unix(), checksums)
	if err != nil {
		return errOp("sign: %v", err)
	}
	if _, err := pack.Write(pkgPath, files, string(checksums), sigText); err != nil {
		return errOp("write: %v", err)
	}
	fmt.Printf("signed %s\n", pkgPath)
	return 0
}

// teamRoles are the documents the team key signs; the role is part of the
// signed trusted comment, so a catalog signature cannot pass as a
// revocation list and the other way round.
var teamRoles = map[string]bool{"catalog.json": true, "revocations.json": true}

var releaseRolePattern = regexp.MustCompile(`^release:v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*):SHA256SUMS$`)

func cmdSignFile(args []string) int {
	fs := flag.NewFlagSet("sign-file", flag.ContinueOnError)
	keyPath := fs.String("key", "", "")
	role := fs.String("role", "", "")
	if err := fs.Parse(reorderArgs(args, nil)); err != nil {
		return 1
	}
	if *keyPath == "" || (!teamRoles[*role] && !(len(*role) <= 84 && releaseRolePattern.MatchString(*role))) || fs.NArg() != 1 {
		return errUsage("usage: sora-ext sign-file --key team.key --role catalog.json|revocations.json|release:vVERSION:SHA256SUMS <file>")
	}
	key, err := keyutil.Load(*keyPath)
	if err != nil {
		return errOp("key: %v", err)
	}
	path := fs.Arg(0)
	payload, err := os.ReadFile(path)
	if err != nil {
		return errOp("read: %v", err)
	}
	sigText, err := ext.SignPayload(key, "sora team signature", *role, time.Now().Unix(), payload)
	if err != nil {
		return errOp("sign: %v", err)
	}
	if err := os.WriteFile(path+".minisig", []byte(sigText), 0o644); err != nil {
		return errOp("write: %v", err)
	}
	fmt.Printf("signed %s as %s\n", path, *role)
	return 0
}
