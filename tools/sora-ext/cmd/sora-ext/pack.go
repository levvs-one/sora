package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"github.com/levvs-one/sora-client/tools/sora-ext/internal/pack"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/validate"
)

func cmdPack(args []string) int {
	fs := flag.NewFlagSet("pack", flag.ContinueOnError)
	out := fs.String("o", "", "")
	if err := fs.Parse(reorderArgs(args, nil)); err != nil {
		return 1
	}
	if fs.NArg() < 1 {
		return errUsage("pack needs a project directory, e.g. sora-ext pack .")
	}
	dir := fs.Arg(0)
	// Never ship a broken package: validate first.
	r := validate.ValidateProject(dir)
	if !r.OK() {
		r.Render(os.Stdout)
		fmt.Fprintln(os.Stderr, "sora-ext: pack aborted - fix the errors above")
		return 1
	}
	files, err := pack.Collect(dir)
	if err != nil {
		return errOp("collect: %v", err)
	}
	outPath := *out
	if outPath == "" {
		outPath = filepath.Base(dir) + ".soraext"
		if outPath == "..soraext" || outPath == ".soraext" {
			outPath = "extension.soraext"
		}
	}
	size, err := pack.Write(outPath, files, "", "")
	if err != nil {
		return errOp("write: %v", err)
	}
	sum, err := pack.SHA256(outPath)
	if err != nil {
		return errOp("hash: %v", err)
	}
	fmt.Printf("packed %s: %d file(s), %d bytes, sha256 %s\n", outPath, len(files), size, sum)
	fmt.Printf("unsigned - next: sora-ext sign --key author.key %s\n", outPath)
	return 0
}
