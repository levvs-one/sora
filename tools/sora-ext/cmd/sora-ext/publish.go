package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/levvs-one/sora-client/core/ext"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/pack"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/validate"
)

// cmdPublish is the pre-publish gate: validation must pass, the artifact
// must be signed, and dangerous permissions need explicit acknowledgement.
// It never uploads anything - it prints the artifact hash and a
// catalog-entry snippet ready to submit.
func cmdPublish(args []string) int {
	fs := flag.NewFlagSet("publish", flag.ContinueOnError)
	ackDangerous := fs.Bool("ack-dangerous", false, "")
	if err := fs.Parse(reorderArgs(args, map[string]bool{"ack-dangerous": true})); err != nil {
		return 1
	}
	path := "."
	if fs.NArg() > 0 {
		path = fs.Arg(0)
	}
	var r *validate.Result
	var artifactPath string
	if strings.HasSuffix(strings.ToLower(path), ".soraext") {
		artifactPath = path
		r = validate.ValidatePackage(path)
	} else {
		r = validate.ValidateProject(path)
	}
	r.Render(os.Stdout)
	if !r.OK() {
		fmt.Fprintln(os.Stderr, "sora-ext: publish blocked - fix the errors above")
		return 1
	}
	m := r.Manifest
	// Signed?
	if artifactPath == "" {
		sigPath := filepath.Join(path, "signature.minisig")
		if _, err := os.Stat(sigPath); err != nil {
			fmt.Fprintln(os.Stderr, "sora-ext: publish blocked - not signed.")
			fmt.Fprintln(os.Stderr, "  pack and sign first: sora-ext pack . && sora-ext sign --key author.key <out.soraext>")
			return 1
		}
	} else {
		// ValidatePackage already verified the signature via pkg.Verify.
		artifactPath = path
	}
	// Dangerous permissions need explicit acknowledgement.
	var dangerous []string
	for _, p := range m.Permissions {
		if perm, ok := ext.LookupPermission(p); ok && perm.Risk == ext.RiskDangerous {
			dangerous = append(dangerous, p)
		}
	}
	if len(dangerous) > 0 && !*ackDangerous {
		_, _ = fmt.Fprintf(os.Stderr, "sora-ext: publish blocked - dangerous permission(s): %s\n", strings.Join(dangerous, ", "))
		fmt.Fprintln(os.Stderr, "  these prompt the user for explicit confirmation at install.")
		fmt.Fprintln(os.Stderr, "  re-run with --ack-dangerous if you really need them.")
		return 1
	}
	// Report.
	var size int64
	var sum string
	target := artifactPath
	if target == "" {
		// Project dir: report what pack would produce (unsigned size hint).
		files, err := pack.Collect(path)
		if err != nil {
			return errOp("collect: %v", err)
		}
		for _, b := range files {
			size += int64(len(b))
		}
		fmt.Printf("\nproject %s is publish-ready (pack it to get the final artifact):\n", path)
	} else {
		st, err := os.Stat(target)
		if err != nil {
			return errOp("stat: %v", err)
		}
		size = st.Size()
		sum, err = pack.SHA256(target)
		if err != nil {
			return errOp("hash: %v", err)
		}
		fmt.Printf("\n%s is publish-ready:\n", target)
	}
	fmt.Printf("  id:          %s\n", m.ID)
	fmt.Printf("  version:     %s\n", m.Version)
	fmt.Printf("  min app:     %s\n", m.MinAppVersion)
	fmt.Printf("  permissions: %s\n", strings.Join(m.Permissions, ", "))
	if sum != "" {
		fmt.Printf("  sha256:      %s\n", sum)
	}
	fmt.Printf("  size:        %d bytes\n", size)
	entry := map[string]any{
		"id": m.ID, "name": m.Name, "version": m.Version,
		"description": m.Description, "author": m.Author.Name,
		"author_identity": m.Author.Identity, "author_key": m.Author.PublicKey,
		"permissions": m.Permissions, "min_app_version": m.MinAppVersion,
		"sha256": sum, "size": size,
	}
	out, _ := json.MarshalIndent(entry, "  ", "  ")
	fmt.Printf("\n  catalog entry (fill in icon_url/download_url, then submit):\n  %s\n", out)
	return 0
}
