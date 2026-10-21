package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"text/template"

	"github.com/levvs-one/sora-client/tools/sora-ext/internal/keyutil"
	exttemplates "github.com/levvs-one/sora-client/tools/sora-ext/templates"
)

type scaffoldVars struct {
	ID             string
	Name           string
	Description    string
	AuthorName     string
	AuthorIdentity string
	PublicKey      string
	PanelTitle     string
}

func printCommandHelp(name string) {
	switch name {
	case "scaffold":
		fmt.Print(`Usage:
  sora-ext scaffold <id> [options]

Creates a new extension project: manifest, entry files, README and a
fresh signing keypair (the secret stays in .sora/author.key, excluded from packages and Git).

Options:
  --template panel|theme|nethook|routing|background   (default panel)
  --name NAME            Display name (default: derived from id)
  --author NAME          Author display name (default: "Your Name")
  --identity ID          Verifiable handle, e.g. github:you
  --description TEXT     One-line description
  --public-key KEY       Reuse an existing minisign public key line
                         (default: generate a fresh keypair)
  --dir DIR              Project dir (default: ./<last id label>)

Example:
  sora-ext scaffold com.example.stats --template panel --author "Jane Doe" --identity github:janedoe
`)
	case "validate":
		fmt.Print(`Usage:
  sora-ext validate [path]

Validates a project directory (default: .) or a .soraext package:
manifest, referenced files, checksums.txt, signature. Errors point at
file:line:col with a fix hint. This is the pre-publish gate - publish
runs it too.
`)
	case "pack":
		fmt.Print(`Usage:
  sora-ext pack <dir> [-o out.soraext]

Builds a .soraext from a project dir: collects files, writes
checksums.txt into the archive. The package is unsigned - run
sora-ext sign next.
`)
	case "sign":
		fmt.Print(`Usage:
  sora-ext sign --key author.key <package.soraext> [--force]

Signs checksums.txt inside the package with the author's minisign key
and stores the result as signature.minisig.
`)
	case "keygen":
		fmt.Print(`Usage:
  sora-ext keygen [-o name]

Generates a minisign keypair: name.key (secret, keep offline) and
name.pub (public). Prints the public key line for the manifest.
`)
	case "sign-file":
		fmt.Print(`Usage:
  sora-ext sign-file --key team.key --role catalog.json|revocations.json <file>

Signs a team document with the trusted comment the app and the core check
(timestamp, role and sha256) and writes <file>.minisig next to it.
`)
	case "publish":
		fmt.Print(`Usage:
  sora-ext publish [path] [--ack-dangerous]

Pre-publish gate: validate must pass, the package must be signed, and
dangerous permissions need --ack-dangerous. Prints the artifact hash
and a catalog-entry snippet ready to submit.
`)
	case "dev":
		fmt.Print(`Usage:
  sora-ext dev [dir] [--port 8377]

Dev mode: serves the project on 127.0.0.1 with live reload, re-runs
validation on every change, and prints the URL to open in the app
(Extensions → Connect dev server). Never exposes anything off-device.
`)
	case "serve":
		fmt.Print(`Usage:
  sora-ext serve [dir] [--port 8378] [--fixtures fixtures.json]

Serves the project on 127.0.0.1 with a mocked window.soraExt injected,
so panels can be tested in a desktop browser without the app.
POST /__soraext__/event fires mock events; GET /__soraext__/calls shows
the API call log.
`)
	}
}

func cmdScaffold(args []string) int {
	fs := flag.NewFlagSet("scaffold", flag.ContinueOnError)
	tmplName := fs.String("template", "panel", "")
	name := fs.String("name", "", "")
	author := fs.String("author", "Your Name", "")
	identity := fs.String("identity", "", "")
	description := fs.String("description", "", "")
	publicKey := fs.String("public-key", "", "")
	dir := fs.String("dir", "", "")
	if err := fs.Parse(reorderArgs(args, nil)); err != nil {
		return 1
	}
	if fs.NArg() < 1 {
		return errUsage("scaffold needs an extension id, e.g. sora-ext scaffold com.example.stats")
	}
	return scaffoldRun(fs.Arg(0), *tmplName, *name, *author, *identity, *description, *publicKey, *dir)
}

func scaffoldRun(id, tmplName, name, author, identity, description, publicKey, dir string) int {
	templates := map[string][]string{
		"panel": {"sora-extension.json.tmpl", "panel.html.tmpl", "README.md.tmpl"},
		// Themes are data, not code (spec-theme-runtime.md): there is
		// deliberately no theme.css template - CSS is an executable
		// surface the runtime refuses.
		"theme":      {"sora-extension.json.tmpl", "theme.json.tmpl", "README.md.tmpl"},
		"nethook":    {"sora-extension.json.tmpl", "hook.json.tmpl", "README.md.tmpl"},
		"routing":    {"sora-extension.json.tmpl", "routing.json.tmpl", "README.md.tmpl"},
		"background": {"sora-extension.json.tmpl", "worker.js.tmpl", "README.md.tmpl"},
	}
	files, ok := templates[tmplName]
	if !ok {
		return errUsage("unknown template %q (panel|theme|nethook|routing|background)", tmplName)
	}
	labels := strings.Split(id, ".")
	slug := labels[len(labels)-1]
	if name == "" {
		name = titleCase(strings.ReplaceAll(slug, "-", " "))
	}
	if description == "" {
		description = "A Sora extension."
	}
	if dir == "" {
		dir = slug
	}
	if st, err := os.Stat(dir); err == nil && st.IsDir() {
		if entries, _ := os.ReadDir(dir); len(entries) > 0 {
			return errUsage("directory %q already exists and is not empty", dir)
		}
	}
	keyComment := "sora-ext key for " + id
	pubLine := publicKey
	var keyPath string
	if pubLine == "" {
		kp, err := keyutil.Generate()
		if err != nil {
			return errOp("keygen: %v", err)
		}
		keyPath = filepath.Join(dir, ".sora", "author.key")
		pubPath := filepath.Join(dir, "author.pub")
		if err := kp.WriteSecret(keyPath, keyComment); err != nil {
			return errOp("write key: %v", err)
		}
		if err := kp.WritePublic(pubPath, keyComment); err != nil {
			return errOp("write key: %v", err)
		}
		pubLine = kp.PublicKeyLine
	}
	vars := scaffoldVars{
		ID: id, Name: name, Description: description,
		AuthorName: author, AuthorIdentity: identity,
		PublicKey: pubLine, PanelTitle: name,
	}
	// README and shared d.ts are copied verbatim; the manifest is a template.
	shared := map[string]string{
		"panel": "sora-ext.d.ts",
	}
	for _, f := range files {
		src := tmplName + "/" + f
		data, err := exttemplates.FS.ReadFile(src)
		if err != nil {
			return errOp("template %s: %v", src, err)
		}
		dstName := strings.TrimSuffix(f, ".tmpl")
		dst := filepath.Join(dir, dstName)
		var out []byte
		if strings.HasSuffix(f, ".tmpl") {
			t, err := template.New(f).Parse(string(data))
			if err != nil {
				return errOp("template %s: %v", src, err)
			}
			var b strings.Builder
			if err := t.Execute(&b, vars); err != nil {
				return errOp("template %s: %v", src, err)
			}
			out = []byte(b.String())
		} else {
			out = data
		}
		if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
			return errOp("%v", err)
		}
		if err := os.WriteFile(dst, out, 0o644); err != nil {
			return errOp("%v", err)
		}
	}
	// Every template ships the TypeScript definitions next to the code.
	if dts, ok := shared[tmplName]; ok {
		data, err := exttemplates.FS.ReadFile("shared/" + dts)
		if err != nil {
			return errOp("shared template: %v", err)
		}
		if err := os.WriteFile(filepath.Join(dir, dts), data, 0o644); err != nil {
			return errOp("%v", err)
		}
	}
	if err := os.WriteFile(filepath.Join(dir, ".gitignore"), []byte(".sora/\n*.soraext\n"), 0o644); err != nil {
		return errOp("write gitignore: %v", err)
	}
	fmt.Printf("created %s/ (%s template)\n", dir, tmplName)
	if keyPath != "" {
		fmt.Printf("signing key: %s (secret - keep offline, never commit)\n", keyPath)
		fmt.Printf("public key:  %s\n", filepath.Join(dir, "author.pub"))
	}
	fmt.Printf(`
next steps:
  cd %s
  sora-ext dev            # live-reload dev server
  sora-ext validate       # check the manifest
  sora-ext pack . -o %s.soraext
  sora-ext sign --key .sora/author.key %s.soraext
  sora-ext publish %s.soraext
`, dir, slug, slug, slug)
	return 0
}

func titleCase(s string) string {
	words := strings.Fields(s)
	for i, w := range words {
		if len(w) > 0 {
			words[i] = strings.ToUpper(w[:1]) + w[1:]
		}
	}
	return strings.Join(words, " ")
}
