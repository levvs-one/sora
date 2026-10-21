package guard

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"

	"github.com/levvs-one/sora-client/core/session"
)

// An inactive record is retained so startup can finish interrupted cleanup.
type strictIntent struct {
	Boot     string
	Settings session.Settings
}

func (g *Guard) saveIntent(settings session.Settings) error {
	if g.opts.DataDir == "" {
		return errors.New("guard: strict mode needs a data directory")
	}
	boot, err := bootID()
	if err != nil {
		return err
	}
	data, err := json.Marshal(strictIntent{Boot: boot, Settings: settings})
	if err != nil {
		return err
	}
	file, err := os.CreateTemp(g.opts.DataDir, ".strict-*")
	if err != nil {
		return err
	}
	defer func() { _ = os.Remove(file.Name()) }()
	_, writeErr := file.Write(data)
	syncErr := file.Sync()
	closeErr := file.Close()
	if err := errors.Join(writeErr, syncErr, closeErr); err != nil {
		return err
	}
	if err := os.Rename(file.Name(), filepath.Join(g.opts.DataDir, "strict-killswitch.json")); err != nil {
		return err
	}
	if runtime.GOOS == "linux" {
		dir, err := os.Open(g.opts.DataDir)
		if err != nil {
			return err
		}
		return errors.Join(dir.Sync(), dir.Close())
	}
	return nil
}

// Recover runs before engine discovery or background network work.
func (g *Guard) Recover(ctx context.Context) error {
	data, err := os.ReadFile(filepath.Join(g.opts.DataDir, "strict-killswitch.json"))
	if errors.Is(err, os.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	var intent strictIntent
	if err := json.Unmarshal(data, &intent); err != nil {
		return fmt.Errorf("guard: invalid strict intent: %w", err)
	}
	boot, err := bootID()
	if err != nil {
		return err
	}
	if intent.Settings.StrictKillSwitch && (intent.Boot == boot || intent.Settings.Reconnect) {
		return g.Apply(ctx, intent.Settings)
	}
	return g.Release(ctx)
}

// Release is explicit user consent to restore connectivity, even after a crash.
func (g *Guard) Release(ctx context.Context) error {
	g.mu.Lock()
	defer g.mu.Unlock()
	_, intentErr := os.Stat(filepath.Join(g.opts.DataDir, "strict-killswitch.json"))
	if errors.Is(intentErr, os.ErrNotExist) && !g.applied.KillSwitch {
		return nil
	}
	// Save the decision first: a crash during Disarm must not rearm on startup.
	var persistErr error
	if g.opts.DataDir != "" && (!errors.Is(intentErr, os.ErrNotExist) || g.applied.StrictKillSwitch) {
		persistErr = g.saveIntent(session.Settings{})
	}
	disarmErr := g.firewall.Disarm(context.WithoutCancel(ctx))
	if disarmErr == nil {
		g.applied = session.Settings{}
	}
	return errors.Join(persistErr, disarmErr)
}
