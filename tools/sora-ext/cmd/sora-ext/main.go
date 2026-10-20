// Command sora-ext is the developer CLI for Sora extensions.
//
// It covers the whole extension authoring loop: scaffold a project, serve it
// with live reload while developing, validate it with human-friendly errors,
// pack and sign it, and run the pre-publish gate. It is stdlib-only plus
// core/ext (the reference implementation it wraps).
//
// Exit codes: 0 success, 1 the command failed (usage or validation), 2 an
// operational error (I/O, network, unexpected).
package main

import (
	"fmt"
	"os"
	"strings"
)

const toolVersion = "0.1.0"

// command is one CLI subcommand.
type command struct {
	name  string
	short string
	run   func(args []string) int
}

var commands = []command{
	{"scaffold", "Create a new extension project", cmdScaffold},
	{"validate", "Validate a project dir or .soraext (pre-publish gate)", cmdValidate},
	{"pack", "Build a .soraext package from a project dir", cmdPack},
	{"sign", "Sign a .soraext with the author's minisign key", cmdSign},
	{"keygen", "Generate a minisign keypair for signing extensions", cmdKeygen},
	{"publish", "Pre-publish gate: validate + policy checks", cmdPublish},
	{"dev", "Dev mode: serve with live reload and re-validation", cmdDev},
	{"serve", "Serve a project with a mocked window.soraExt", cmdServe},
}

func main() {
	os.Exit(dispatch(os.Args[1:]))
}

func dispatch(args []string) int {
	if len(args) == 0 {
		printUsage()
		return 1
	}
	switch args[0] {
	case "-h", "--help", "help":
		if len(args) > 1 {
			return helpFor(args[1])
		}
		printUsage()
		return 0
	case "-v", "--version", "version":
		fmt.Printf("sora-ext %s\n", toolVersion)
		return 0
	}
	for _, c := range commands {
		if c.name == args[0] {
			return c.run(args[1:])
		}
	}
	_, _ = fmt.Fprintf(os.Stderr, "sora-ext: unknown command %q\n\n", args[0])
	printUsage()
	return 1
}

func printUsage() {
	fmt.Printf(`sora-ext %s - developer tools for Sora extensions

Usage:
  sora-ext <command> [options]

Commands:
`, toolVersion)
	for _, c := range commands {
		fmt.Printf("  %-10s %s\n", c.name, c.short)
	}
	fmt.Printf(`
Run 'sora-ext help <command>' for details.
Docs: docs/extensions-quickstart.md
`)
}

func helpFor(name string) int {
	for _, c := range commands {
		if c.name == name {
			fmt.Printf("sora-ext %s - %s\n\n", c.name, c.short)
			printCommandHelp(c.name)
			return 0
		}
	}
	_, _ = fmt.Fprintf(os.Stderr, "sora-ext: unknown command %q\n", name)
	return 1
}

// reorderArgs moves flag tokens before positional arguments so flags may
// appear anywhere on the command line (Go's flag package stops parsing at
// the first positional, which would silently swallow --author "Jane Doe"
// after the id). boolFlags names the flags that take no value.
func reorderArgs(args []string, boolFlags map[string]bool) []string {
	var flags, positional []string
	i := 0
	for i < len(args) {
		tok := args[i]
		if tok == "--" {
			positional = append(positional, args[i+1:]...)
			break
		}
		if len(tok) > 1 && strings.HasPrefix(tok, "-") {
			name := strings.TrimLeft(tok, "-")
			if eq := strings.Index(name, "="); eq >= 0 {
				name = name[:eq]
			}
			flags = append(flags, tok)
			if !strings.Contains(tok, "=") && !boolFlags[name] && i+1 < len(args) {
				i++
				flags = append(flags, args[i])
			}
		} else {
			positional = append(positional, tok)
		}
		i++
	}
	return append(flags, positional...)
}

// errUsage reports a command-line usage error and returns exit code 1.
func errUsage(format string, args ...any) int {
	_, _ = fmt.Fprintf(os.Stderr, "sora-ext: "+format+"\n", args...)
	return 1
}

// errOp reports an operational failure and returns exit code 2.
func errOp(format string, args ...any) int {
	_, _ = fmt.Fprintf(os.Stderr, "sora-ext: error: "+format+"\n", args...)
	return 2
}
