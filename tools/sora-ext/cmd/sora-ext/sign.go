package main

import (
	"archive/zip"
	"flag"
	"fmt"
	"io"
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
	seed, err := keyutil.LoadSeed(*keyPath)
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
				zr.Close()
				return errUsage("already signed — use --force to re-sign")
			}
			continue
		}
		if f.Name == "checksums.txt" {
			rc, err := f.Open()
			if err != nil {
				zr.Close()
				return errOp("read: %v", err)
			}
			checksums, err = io.ReadAll(rc)
			rc.Close()
			if err != nil {
				zr.Close()
				return errOp("read: %v", err)
			}
			continue
		}
		rc, err := f.Open()
		if err != nil {
			zr.Close()
			return errOp("read: %v", err)
		}
		data, err := io.ReadAll(rc)
		rc.Close()
		if err != nil {
			zr.Close()
			return errOp("read: %v", err)
		}
		files[f.Name] = data
	}
	zr.Close()
	if len(checksums) == 0 {
		return errOp("package has no checksums.txt — rebuild it with sora-ext pack")
	}
	sigText, err := ext.SignPayload(seed, "sora-ext signature", "checksums.txt", time.Now().Unix(), checksums)
	if err != nil {
		return errOp("sign: %v", err)
	}
	if _, err := pack.Write(pkgPath, files, string(checksums), sigText); err != nil {
		return errOp("write: %v", err)
	}
	fmt.Printf("signed %s\n", pkgPath)
	return 0
}
