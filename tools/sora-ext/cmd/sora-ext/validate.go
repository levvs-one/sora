package main

import (
	"flag"
	"os"
	"strings"

	"github.com/levvs-one/sora-client/tools/sora-ext/internal/validate"
)

func cmdValidate(args []string) int {
	fs := flag.NewFlagSet("validate", flag.ContinueOnError)
	if err := fs.Parse(reorderArgs(args, nil)); err != nil {
		return 1
	}
	path := "."
	if fs.NArg() > 0 {
		path = fs.Arg(0)
	}
	var r *validate.Result
	if strings.HasSuffix(strings.ToLower(path), ".soraext") {
		r = validate.ValidatePackage(path)
	} else {
		if st, err := os.Stat(path); err != nil || !st.IsDir() {
			// Maybe a bare manifest file.
			r = validate.ValidateManifestFile(path)
		} else {
			r = validate.ValidateProject(path)
		}
	}
	r.Render(os.Stdout)
	if !r.OK() {
		return 1
	}
	return 0
}
