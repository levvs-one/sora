package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// flags holds operator settings with defaults for a standard installation.
type flags struct {
	dataDir     string
	enginesDir  string
	engine      string
	localPort   int
	bypass      string
	socket      string
	logLevel    string
	check       bool
	fileKeys    bool
	envBin      bool
	showVersion bool
	install     bool
	uninstall   bool
	showToken   bool
	seriesProbe string
	seriesTLS   bool
	seriesMin   int
	quicProbe   string
	dnsCheck    bool
}

func main() {
	// Windows services must respond to SCM instead of using the console.
	if handled, err := runService(os.Args[1:]); handled {
		if err != nil {
			os.Exit(1)
		}
		return
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	err := run(ctx, os.Args[1:])
	stop()
	if err != nil {
		// Exit codes identify failure classes for scripts; the key and
		// detail identify the cause.
		code := 1
		if errs.CodeOf(err) == errs.CodeInvalidArgument {
			code = 2
		}
		fmt.Fprintf(os.Stderr, "sora-core: %s: %s\n", errs.KeyOf(err), errs.Detail(err))
		os.Exit(code)
	}
}

func run(ctx context.Context, arguments []string) error {
	set := flag.NewFlagSet("sora-core", flag.ContinueOnError)
	// Usage belongs on stdout so "sora-core -h | less" works; the
	// formatted error below stays on stderr.
	set.SetOutput(os.Stdout)
	var f flags
	set.StringVar(&f.dataDir, "data-dir", defaultDataDir(), "where the token, the secrets and the engine state live")
	set.StringVar(&f.enginesDir, "engines-dir", filepath.Join(defaultDataDir(), "engines"), "where the engine binaries are looked for")
	set.StringVar(&f.engine, "engine", "", "pin one engine: sing-box, xray or mihomo; empty picks one per plan")
	set.IntVar(&f.localPort, "tunnel-port", 0, "loopback port the tunnel is served on; 0 picks a free one")
	set.StringVar(&f.bypass, "bypass", "", "comma separated destinations that skip the tunnel")
	set.StringVar(&f.socket, "socket", "", "control plane socket; empty is the platform address")
	set.StringVar(&f.logLevel, "log-level", "info", "debug, info, warn or error")
	set.BoolVar(&f.check, "check", false, "build everything, report on it and exit without serving")
	set.BoolVar(&f.fileKeys, "allow-file-keys", false, "fall back to a key file when the machine key store is unavailable")
	set.BoolVar(&f.envBin, "allow-env-bin", false, "honor SORA_*_BIN engine overrides during discovery; the operator takes responsibility for the pointed-at binary")
	set.BoolVar(&f.showVersion, "version", false, "print the contract and build version and exit")
	set.BoolVar(&f.install, "install-service", false, "Windows: register this executable as the SoraCore service with the other flags, start it and exit")
	set.BoolVar(&f.uninstall, "uninstall-service", false, "Windows: stop and remove the SoraCore service and exit")
	set.BoolVar(&f.showToken, "print-token", false, "print the control plane token and exit")
	set.StringVar(&f.seriesProbe, "series-probe", "", "probe one host:port in a series (T055 two-stage blocking check) and exit; see -series-probe-minutes")
	set.BoolVar(&f.seriesTLS, "series-probe-tls", false, "series probe: require a TLS handshake, not just an open socket")
	set.IntVar(&f.seriesMin, "series-probe-minutes", 0, "series probe length in minutes; 0 is the full 15-minute confirmation window")
	set.StringVar(&f.quicProbe, "quic-probe", "", "probe one host[:port] for QUIC censorship (T008 residual-ban check, ban tracker persists in the data dir) and exit")
	set.BoolVar(&f.dnsCheck, "dns-check", false, "probe the path for DNS interception/injection (T010) and exit")
	if err := set.Parse(arguments); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			// -h/--help: the usage is already printed above. A help
			// request is neither a failure nor an authentication
			// problem, so exit 0 without the error line.
			return nil
		}
		// A malformed flag line is the operator's mistake, not an
		// authentication failure.
		return errs.Wrap(err, errs.CodeInvalidArgument, errs.KeyInvalidRequest)
	}
	if f.uninstall {
		return uninstallService()
	}
	if f.install {
		// Pass persistent service settings without forwarding the
		// install flag.
		return installService([]string{"-data-dir", f.dataDir, "-engines-dir", f.enginesDir})
	}
	if f.showVersion {
		fmt.Printf("sora-core %s (contract %d.%d, min supported %d, %s/%s)\n",
			buildVersion, Version.Major, Version.Minor, Version.MinSupportedMinor, runtime.GOOS, runtime.GOARCH)
		return nil
	}

	if f.showToken {
		token, err := printToken(f.dataDir)
		if err != nil {
			return err
		}
		fmt.Println(token)
		return nil
	}
	if f.seriesProbe != "" {
		// A measurement, not a service: no engines, no installation
		// state needed.
		res, err := runSeriesProbe(ctx, f.seriesProbe, f.seriesTLS, f.seriesMin)
		if err != nil {
			return err
		}
		for _, line := range seriesProbeLines(f.seriesProbe, f.seriesTLS, res) {
			fmt.Println(line)
		}
		return seriesProbeError(res)
	}
	if f.quicProbe != "" {
		// A measurement, not a service — same contract as the series
		// probe. The ban tracker file lives in the data dir.
		lines, err := runQUICProbe(ctx, f.dataDir, f.quicProbe)
		if err != nil {
			return err
		}
		for _, line := range lines {
			fmt.Println(line)
		}
		return nil
	}
	if f.dnsCheck {
		for _, line := range runDNSInterceptCheck(ctx) {
			fmt.Println(line)
		}
		return nil
	}
	logger, err := newLogger(f.logLevel)
	if err != nil {
		return err
	}
	options := Options{
		Diagnostic:    f.check,
		DataDir:       f.dataDir,
		EnginesDir:    f.enginesDir,
		Engine:        engine.Kind(f.engine),
		LocalPort:     f.localPort,
		Bypass:        splitList(f.bypass),
		Socket:        f.socket,
		Log:           logger,
		AllowFileKeys: f.fileKeys,
		AllowEnvBin:   f.envBin,
	}
	app, err := New(ctx, options)
	if err != nil {
		if f.check {
			// A readiness check must report build failures even on
			// a broken installation.
			fmt.Println("result: the core cannot be built on this machine")
			fmt.Println("problem: " + string(errs.KeyOf(err)) + ": " + errs.Detail(err))
			return nil
		}
		return err
	}
	defer func() {
		if closeErr := app.Close(); closeErr != nil {
			logger.Error("shutdown was not clean", "error", errs.Detail(closeErr))
		}
	}()
	if f.check {
		lines, ok := checkReport(app)
		for _, line := range lines {
			fmt.Println(line)
		}
		if !ok {
			// A nonzero exit code lets scripts detect an unready
			// installation.
			return errs.Newf(errs.CodeFailedPrecondition, errs.KeyEngineStartFailed,
				"core: the installation is not ready")
		}
		return nil
	}
	return app.Serve(ctx)
}

// buildVersion is set at build time; unstamped builds report "dev".
var buildVersion = "dev"

// defaultDataDir returns the per-user directory for manual runs. Services
// receive an explicit directory.
func defaultDataDir() string {
	if dir := strings.TrimSpace(os.Getenv("SORA_DATA_DIR")); dir != "" {
		return dir
	}
	if dir, err := os.UserConfigDir(); err == nil {
		return filepath.Join(dir, "sora", "core")
	}
	return filepath.Join(".", ".sora-core")
}

// splitList parses a comma-separated list and skips empty entries.
func splitList(value string) []string {
	var out []string
	for _, part := range strings.Split(value, ",") {
		if trimmed := strings.TrimSpace(part); trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}
