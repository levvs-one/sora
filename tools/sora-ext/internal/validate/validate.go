// Package validate wraps core/ext validation with human-friendly errors:
// what is wrong, where (file:line:col with a source snippet), and how to
// fix it - the way Deno, rustc and VS Code report problems.
//
// Positions are recovered heuristically: the manifest is decoded as a token
// stream and every key is mapped to its byte offset, so a core/ext error
// mentioning a field can point at the exact line. The mapping is best-effort
// (documented where it can miss); the message and the fix hint are always
// accurate.
package validate

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/levvs-one/sora-client/core/ext"
)

// Issue is one validation problem.
type Issue struct {
	Code       string   // short code, e.g. "unknown-permission"
	Message    string   // the core/ext message, without the "ext: " prefix
	File       string   // file the issue is in ("" = the result subject)
	Line       int      // 1-based; 0 when the position is unknown
	Col        int      // 1-based; 0 when unknown
	Snippet    string   // the source line at Line
	Token      string   // the offending token, e.g. "net.fech"
	Suggestion string   // did-you-mean, "" when none
	Help       []string // how to fix it
	Warning    bool     // warnings don't fail the gate
}

// Result is the outcome of validating one file, project or package.
type Result struct {
	Subject  string // what was validated (path)
	Manifest *ext.Manifest
	Ext      *ext.ManifestExt
	Issues   []Issue // errors
	Warnings []Issue
}

// OK reports whether validation passed (warnings are fine).
func (r *Result) OK() bool { return len(r.Issues) == 0 }

// Render prints the result: a one-line success, or annotated errors.
func (r *Result) Render(w io.Writer) {
	if r.OK() && len(r.Warnings) == 0 {
		summary := "valid"
		if r.Manifest != nil {
			np, nc := len(r.Manifest.Permissions), len(r.Manifest.Capabilities)
			summary = fmt.Sprintf("valid: %s %s (%d permission(s), %d %s)",
				r.Manifest.ID, r.Manifest.Version, np, nc, plural(nc, "capability", "capabilities"))
		}
		_, _ = fmt.Fprintf(w, "✓ %s: %s\n", r.Subject, summary)
		return
	}
	for _, is := range r.Issues {
		renderIssue(w, r.Subject, is)
	}
	for _, wr := range r.Warnings {
		renderIssue(w, r.Subject, wr)
	}
	if !r.OK() {
		_, _ = fmt.Fprintf(w, "\n✗ %s: %d error(s)\n", r.Subject, len(r.Issues))
	} else {
		_, _ = fmt.Fprintf(w, "✓ %s: valid with %d warning(s)\n", r.Subject, len(r.Warnings))
	}
}

func plural(n int, one, many string) string {
	if n == 1 {
		return one
	}
	return many
}

func renderIssue(w io.Writer, subject string, is Issue) {
	kind := "error"
	if is.Warning {
		kind = "warning"
	}
	_, _ = fmt.Fprintf(w, "%s[%s]: %s\n", kind, is.Code, is.Message)
	loc := subject
	if is.File != "" {
		loc = is.File
	}
	if is.Line > 0 {
		_, _ = fmt.Fprintf(w, "  --> %s:%d:%d\n", loc, is.Line, is.Col)
		_, _ = fmt.Fprintf(w, "   |\n")
		_, _ = fmt.Fprintf(w, "%3d | %s\n", is.Line, is.Snippet)
		caret := "   | "
		if is.Col > 1 {
			caret += strings.Repeat(" ", is.Col-1)
		}
		mark := "^"
		if is.Token != "" {
			mark = strings.Repeat("^", len(is.Token))
			// The caret starts at the opening quote: cover both quotes.
			if is.Col > 0 && is.Col <= len(is.Snippet) && is.Snippet[is.Col-1] == '"' {
				mark = strings.Repeat("^", len(is.Token)+2)
			}
		}
		if is.Suggestion != "" {
			_, _ = fmt.Fprintf(w, "%s%s did you mean %q?\n", caret, mark, is.Suggestion)
		} else {
			_, _ = fmt.Fprintf(w, "%s%s\n", caret, mark)
		}
		_, _ = fmt.Fprintf(w, "   |\n")
	}
	for _, h := range is.Help {
		_, _ = fmt.Fprintf(w, "   = help: %s\n", h)
	}
}

// ValidateManifestFile validates one sora-extension.json file.
func ValidateManifestFile(path string) *Result {
	r := &Result{Subject: path}
	data, err := os.ReadFile(path)
	if err != nil {
		r.Issues = append(r.Issues, Issue{Code: "io", Message: fmt.Sprintf("cannot read: %v", err),
			Help: []string{"check the path and permissions"}})
		return r
	}
	pos := indexPositions(data)
	m, x, err := ext.ParseManifestFull(data)
	if err != nil {
		is := explain(data, pos, err)
		is.File = path
		r.Issues = append(r.Issues, is)
		return r
	}
	r.Manifest, r.Ext = m, x
	warnDangerous(r, m)
	warnUnenforced(r, m)
	return r
}

// ValidateProject validates a project directory: the manifest, the files
// it references, and - when present - checksums.txt and signature.minisig.
func ValidateProject(dir string) *Result {
	manifestPath := filepath.Join(dir, "sora-extension.json")
	r := ValidateManifestFile(manifestPath)
	r.Subject = dir
	if !r.OK() {
		return r
	}
	m, x := r.Manifest, r.Ext
	entries := map[string]string{}
	if m.UI != nil {
		for _, p := range m.UI.Panels {
			entries["ui.panels["+p.ID+"].entry"] = p.Entry
		}
	}
	if x != nil {
		if x.Background != nil {
			entries["background_task.entry"] = x.Background.Entry
		}
		if x.Theme != nil {
			entries["theme.entry"] = x.Theme.Entry
		}
		if x.NetworkHook != nil {
			entries["network_hook.entry"] = x.NetworkHook.Entry
		}
		if x.Routing != nil {
			entries["routing.entry"] = x.Routing.Entry
		}
	}
	names := make([]string, 0, len(entries))
	for n := range entries {
		names = append(names, n)
	}
	sort.Strings(names)
	for _, n := range names {
		p := filepath.Join(dir, filepath.FromSlash(entries[n]))
		if st, err := os.Stat(p); err != nil || st.IsDir() {
			r.Issues = append(r.Issues, Issue{
				Code:    "missing-entry",
				File:    manifestPath,
				Message: fmt.Sprintf("%s points at %q, which is not a file in the project", n, entries[n]),
				Help:    []string{"add the file, or fix the entry in sora-extension.json"},
			})
		}
	}
	checkProjectIntegrity(dir, manifestPath, r)
	return r
}

// ValidatePackage validates a .soraext file: structure plus signature.
func ValidatePackage(path string) *Result {
	r := &Result{Subject: path}
	data, err := os.ReadFile(path)
	if err != nil {
		r.Issues = append(r.Issues, Issue{Code: "io", Message: fmt.Sprintf("cannot read: %v", err),
			Help: []string{"check the path and permissions"}})
		return r
	}
	pkg, err := ext.OpenBytes(data)
	if err != nil {
		r.Issues = append(r.Issues, explain(nil, nil, err))
		return r
	}
	r.Manifest, r.Ext = pkg.Manifest, pkg.ManifestExt
	if err := pkg.Verify(); err != nil {
		r.Issues = append(r.Issues, explain(nil, nil, err))
		return r
	}
	warnDangerous(r, pkg.Manifest)
	warnUnenforced(r, pkg.Manifest)
	return r
}

// warnUnenforced tells the author the real enforcement state of the
// permissions they request: a permission that is inert or unimplemented in
// the current runtime grants nothing, and shipping an extension that
// depends on it today silently does nothing. It is a warning, not an
// error - the manifest is valid; the feature is just not wired yet.
func warnUnenforced(r *Result, m *ext.Manifest) {
	var inert, unimpl []string
	for _, p := range m.Permissions {
		row, ok := ext.EnforcementOf(p)
		if !ok {
			continue // unknown ids are already an error
		}
		switch row.Status {
		case ext.EnforcementInert:
			inert = append(inert, p)
		case ext.EnforcementUnimplemented:
			unimpl = append(unimpl, p)
		}
	}
	if len(inert) > 0 {
		r.Warnings = append(r.Warnings, Issue{Warning: true, Code: "inert-permissions",
			Message: fmt.Sprintf("inert permission(s): %s - no API exposes these, so granting them changes nothing yet",
				strings.Join(inert, ", ")),
			Help: []string{
				"do not build features that depend on them until the runtime lands (see docs/extensions/threat-model.md §4)",
				"if you only need the extension's own settings, they are permissionless by design - drop these"}})
	}
	if len(unimpl) > 0 {
		r.Warnings = append(r.Warnings, Issue{Warning: true, Code: "unimplemented-permissions",
			Message: fmt.Sprintf("unimplemented permission(s): %s - the runtime consumer is not built, so granting them changes nothing yet",
				strings.Join(unimpl, ", ")),
			Help: []string{
				"these are the permissions your extension will genuinely need; keep them in the manifest, but test nothing against them yet",
				"routing.rules and net.hooks are RiskDangerous: when they land they need catalog review and the strongest install consent"}})
	}
}

// checkProjectIntegrity compares checksums.txt / signature.minisig with the
// project files, when they exist.
func checkProjectIntegrity(dir, manifestPath string, r *Result) {
	checksumsPath := filepath.Join(dir, "checksums.txt")
	sigPath := filepath.Join(dir, "signature.minisig")
	checksums, cErr := os.ReadFile(checksumsPath)
	_, sErr := os.Stat(sigPath)
	if cErr != nil {
		if sErr == nil {
			r.Issues = append(r.Issues, Issue{Code: "integrity", File: checksumsPath,
				Message: "signature.minisig exists but checksums.txt is missing",
				Help:    []string{"run sora-ext pack to regenerate checksums.txt, then sign again"}})
		} else {
			r.Warnings = append(r.Warnings, Issue{Warning: true, Code: "integrity",
				Message: "no checksums.txt yet (sora-ext pack generates it)",
				Help:    []string{"harmless while developing; required before publish"}})
		}
		return
	}
	listed := parseChecksumsList(string(checksums))
	// Every content file (same skip rules as pack) must be listed exactly.
	_ = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}
		rel, _ := filepath.Rel(dir, path)
		rel = filepath.ToSlash(rel)
		base := filepath.Base(rel)
		if base == "checksums.txt" || base == "signature.minisig" ||
			strings.HasSuffix(base, ".soraext") || strings.HasPrefix(base, ".") {
			return nil
		}
		want, ok := listed[rel]
		if !ok {
			r.Warnings = append(r.Warnings, Issue{Warning: true, Code: "integrity",
				Message: fmt.Sprintf("%q is not covered by checksums.txt", rel),
				Help:    []string{"run sora-ext pack to regenerate checksums.txt"}})
			return nil
		}
		sum := sha256HexOfFile(path)
		if sum != want {
			r.Issues = append(r.Issues, Issue{Code: "integrity", File: checksumsPath,
				Message: fmt.Sprintf("%q changed since checksums.txt was generated", rel),
				Help:    []string{"run sora-ext pack to regenerate checksums.txt"}})
		}
		delete(listed, rel)
		return nil
	})
	for name := range listed {
		r.Issues = append(r.Issues, Issue{Code: "integrity", File: checksumsPath,
			Message: fmt.Sprintf("checksums.txt lists %q, which is not in the project", name),
			Help:    []string{"run sora-ext pack to regenerate checksums.txt"}})
	}
	if sErr == nil {
		sig, _ := os.ReadFile(sigPath)
		if err := ext.VerifyPackageSignature(r.Manifest.Author.PublicKey, string(sig), checksums); err != nil {
			is := explain(nil, nil, err)
			is.File = sigPath
			r.Issues = append(r.Issues, is)
		}
	} else {
		r.Warnings = append(r.Warnings, Issue{Warning: true, Code: "unsigned",
			Message: "not signed yet (run sora-ext keygen once, then sora-ext sign)",
			Help:    []string{"unsigned packages install only as sideloads with a warning; the catalog requires a signature"}})
	}
}

func warnDangerous(r *Result, m *ext.Manifest) {
	var dangerous []string
	for _, p := range m.Permissions {
		if perm, ok := ext.LookupPermission(p); ok && perm.Risk == ext.RiskDangerous {
			dangerous = append(dangerous, p)
		}
	}
	if len(dangerous) > 0 {
		r.Warnings = append(r.Warnings, Issue{Warning: true, Code: "dangerous-permissions",
			Message: fmt.Sprintf("requests dangerous permission(s): %s", strings.Join(dangerous, ", ")),
			Help: []string{
				"the install prompt requires explicit confirmation for these",
				"updates that add permissions re-prompt the user - request only what you need",
			}})
	}
}
