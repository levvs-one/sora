package main

import (
	"flag"
	"fmt"
	"os"
	"os/signal"
	"time"

	"github.com/levvs-one/sora-client/tools/sora-ext/internal/server"
	"github.com/levvs-one/sora-client/tools/sora-ext/internal/validate"
)

// cmdDev: dev mode. Serves the project on 127.0.0.1 with live reload,
// re-validates on every change, and prints the URL for the app.
func cmdDev(args []string) int {
	fs := flag.NewFlagSet("dev", flag.ContinueOnError)
	port := fs.Int("port", 8377, "")
	if err := fs.Parse(reorderArgs(args, nil)); err != nil {
		return 1
	}
	dir := "."
	if fs.NArg() > 0 {
		dir = fs.Arg(0)
	}
	if st, err := os.Stat(dir); err != nil || !st.IsDir() {
		return errUsage("dev needs a project directory, got %q", dir)
	}
	srv := server.New(server.Options{Dir: dir, Port: *port, LiveReload: true})

	validateOnce := func() {
		r := validate.ValidateProject(dir)
		r.Render(os.Stdout)
		fmt.Println()
	}
	fmt.Printf("sora-ext dev - %s\n", dir)
	validateOnce()
	entry := firstPanel(dir)
	url := fmt.Sprintf("http://127.0.0.1:%d/%s", *port, entry)
	fmt.Printf("serving on %s (loopback only)\n", url)
	fmt.Printf("in the app: Extensions → Connect dev server → %s\n", url)
	fmt.Println("watching for changes (Ctrl+C to stop)…")

	stop := make(chan struct{})
	defer close(stop)
	go server.Watch(dir, 500*time.Millisecond, stop, func() {
		fmt.Println("- changed -")
		validateOnce()
		srv.BroadcastReload()
	})

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt)
	go func() {
		<-sig
		fmt.Println("\nstopped")
		os.Exit(0)
	}()
	if err := srv.Run(); err != nil {
		return errOp("%v", err)
	}
	return 0
}

// cmdServe: serves the project with the window.soraExt mock injected, for
// testing panels in a desktop browser without the app.
func cmdServe(args []string) int {
	fs := flag.NewFlagSet("serve", flag.ContinueOnError)
	port := fs.Int("port", 8378, "")
	fixtures := fs.String("fixtures", "", "")
	if err := fs.Parse(reorderArgs(args, nil)); err != nil {
		return 1
	}
	dir := "."
	if fs.NArg() > 0 {
		dir = fs.Arg(0)
	}
	if st, err := os.Stat(dir); err != nil || !st.IsDir() {
		return errUsage("serve needs a project directory, got %q", dir)
	}
	srv := server.New(server.Options{Dir: dir, Port: *port, InjectMock: true, FixturesPath: *fixtures})
	entry := firstPanel(dir)
	url := fmt.Sprintf("http://127.0.0.1:%d/%s", *port, entry)
	fmt.Printf("serving %s with mocked window.soraExt (loopback only)\n", dir)
	fmt.Printf("open: %s\n", url)
	fmt.Printf("fire a mock event: curl -X POST http://127.0.0.1:%d/__soraext__/event -d '{\"kind\":\"session.connected\"}'\n", *port)
	fmt.Printf("call log:          http://127.0.0.1:%d/__soraext__/calls\n", *port)
	fmt.Println("Ctrl+C to stop.")
	if err := srv.Run(); err != nil {
		return errOp("%v", err)
	}
	return 0
}

// firstPanel returns the first panel entry from the manifest, or
// "panel.html" when the manifest cannot be read.
func firstPanel(dir string) string {
	r := validate.ValidateManifestFile(dir + "/sora-extension.json")
	if r.OK() && r.Manifest != nil && r.Manifest.UI != nil && len(r.Manifest.UI.Panels) > 0 {
		return r.Manifest.UI.Panels[0].Entry
	}
	return "panel.html"
}
