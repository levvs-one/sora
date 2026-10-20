//go:build linux

package session

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
)

func TestShutdownProcessHelper(t *testing.T) {
	if len(os.Args) < 3 || os.Args[len(os.Args)-2] != "sora-shutdown-helper" {
		return
	}
	switch os.Args[len(os.Args)-1] {
	case "check":
		return
	case "unroute":
		if err := os.Remove("route"); err != nil {
			t.Fatal(err)
		}
	case "run":
		signal.Ignore(syscall.SIGTERM)
		if err := os.WriteFile("ready", []byte(strconv.Itoa(os.Getpid())), 0o600); err != nil {
			t.Fatal(err)
		}
		for {
			time.Sleep(time.Hour)
		}
	default:
		t.Fatal("unknown shutdown helper mode")
	}
}

type shutdownDriver struct {
	binary, home string
}

func (shutdownDriver) Kind() engine.Kind { return engine.KindMihomo }
func (shutdownDriver) Render(p *engine.Plan, _ supervise.Runtime) ([]byte, error) {
	return []byte(p.SessionID), nil
}
func (shutdownDriver) RunArgs(supervise.Runtime) []string {
	return []string{"-test.run=^TestShutdownProcessHelper$", "--", "sora-shutdown-helper", "run"}
}
func (shutdownDriver) CheckArgs(supervise.Runtime) []string {
	return []string{"-test.run=^TestShutdownProcessHelper$", "--", "sora-shutdown-helper", "check"}
}
func (d shutdownDriver) Handshake(context.Context, supervise.Runtime) (string, error) {
	_, err := os.ReadFile(filepath.Join(d.home, "ready"))
	return "1.19.32", err
}
func (shutdownDriver) Reload(context.Context, supervise.Runtime, []byte) error {
	return supervise.ErrReloadUnsupported
}
func (d shutdownDriver) Route(context.Context, *engine.Plan) error {
	return os.WriteFile(filepath.Join(d.home, "route"), []byte("owned"), 0o600)
}
func (d shutdownDriver) Unroute(ctx context.Context) error {
	pid, err := os.ReadFile(filepath.Join(d.home, "ready"))
	if err != nil {
		return err
	}
	if _, err := os.Stat(filepath.Join("/proc", string(pid))); !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("child has not been reaped: %s", pid)
	}
	// A real context-bound cleanup command must still be able to start
	// after SIGKILL and reap have consumed the complete grace period.
	cmd := exec.CommandContext(ctx, d.binary, "-test.run=^TestShutdownProcessHelper$", "--", "sora-shutdown-helper", "unroute")
	cmd.Dir = d.home
	return cmd.Run()
}

type shutdownEngine struct {
	*supervise.Supervisor
}

func (*shutdownEngine) Groups(context.Context) ([]engine.GroupStatus, error) {
	return nil, errors.New("shutdown test driver has no group controller")
}
func (*shutdownEngine) Select(context.Context, string, string) error {
	return errors.New("shutdown test driver has no group controller")
}
func (*shutdownEngine) Delay(context.Context, string, string, time.Duration) (time.Duration, error) {
	return 0, errors.New("shutdown test driver has no probe controller")
}
func (*shutdownEngine) Counters(context.Context) (engine.Counters, error) {
	return engine.Counters{}, errors.New("shutdown test driver has no counter controller")
}

func TestStopReapsSIGTERMIgnoringProcessAndUnroutes(t *testing.T) {
	for _, cancelled := range []bool{false, true} {
		t.Run(fmt.Sprintf("cancelled caller %t", cancelled), func(t *testing.T) {
			binary, err := os.Executable()
			if err != nil {
				t.Fatal(err)
			}
			home := t.TempDir()
			grace := 100 * time.Millisecond
			sup, err := supervise.New(supervise.Config{
				Binary: supervise.Binary{Path: binary}, HomeDir: home, StopGrace: grace,
			}, shutdownDriver{binary: binary, home: home})
			if err != nil {
				t.Fatal(err)
			}
			t.Cleanup(func() { _ = sup.Close() })
			cfg := testConfig(&shutdownEngine{Supervisor: sup}, &fakeGuard{})
			cfg.Plan.Tun = engine.Tun{Enabled: true, DeviceName: "sora-stop-test"}
			cfg.StopGrace, cfg.StatsInterval = grace, time.Hour
			// The helper owns a process and route marker, not a host adapter.
			cfg.TunUp = func(context.Context, string) error {
				_, err := os.Stat(filepath.Join(home, "ready"))
				return err
			}
			s, err := New(cfg)
			if err != nil {
				t.Fatal(err)
			}
			if err := s.Start(t.Context()); err != nil {
				t.Fatal(err)
			}
			ctx, cancel := context.WithCancel(t.Context())
			defer cancel()
			if cancelled {
				cancel()
			}
			started := time.Now()
			err = s.Stop(ctx)
			if elapsed := time.Since(started); elapsed < grace {
				t.Errorf("process did not consume its SIGTERM grace: %s", elapsed)
			}
			if err != nil {
				t.Fatalf("Stop after ignored SIGTERM: %v", err)
			}
			if _, err := os.Stat(filepath.Join(home, "route")); !errors.Is(err, os.ErrNotExist) {
				t.Fatalf("route cleanup did not finish: %v", err)
			}
			if sup.State() != engine.StateStopped || s.State() != StateDisconnected {
				t.Fatalf("shutdown state: engine %s, session %s", sup.State(), s.State())
			}
			select {
			case <-s.Done():
			case <-time.After(time.Second):
				t.Fatal("session supervision did not finish")
			}
		})
	}
}
