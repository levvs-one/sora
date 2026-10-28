package winws

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/logs"
)

const readyMarker = "windivert initialized. capture is started."

// Engine owns only its child processes and file handles. Driver registration
// belongs to Windows/WinDivert and may remain loaded after the session ends.
type Engine struct {
	engine.Engine
	binary, home string
	logs         *logs.Center
	op           sync.Mutex
	proc         *supervise.Process
	bootstrap    *supervise.Process
	cancel       context.CancelFunc
	held         io.Closer
	fatal        error
	closed       bool

	// Native boundaries stay injectable in package tests, never on the wire or
	// in an extension. Production constructors always use the host checks.
	openBundle   func(string) (io.Closer, error)
	checkService func(string, bool) error
}

// Wrap adds the explicitly selected machine-wide filter without starting it.
func Wrap(inner engine.Engine, binary, home string, center *logs.Center) *Engine {
	return &Engine{Engine: inner, binary: binary, home: home, logs: center,
		openBundle: lockBundle, checkService: checkDriverService}
}

// State cannot report a working session after the filter failed.
func (e *Engine) State() engine.State {
	e.op.Lock()
	defer e.op.Unlock()
	if e.fatal != nil {
		return engine.StateFailed
	}
	return e.Engine.State()
}

func admit(p *engine.Plan) ([]string, error) {
	if p == nil {
		return nil, errors.New("winws: nil plan")
	}
	if err := p.Validate(); err != nil {
		return nil, err
	}
	if len(p.Outbounds) != 1 || p.Outbounds[0].Protocol != engine.ProtocolWinws {
		return nil, errors.New("winws: a dedicated system-wide filter plan is required")
	}
	return Args(*p.Outbounds[0].Bypass)
}

// Validate does not open WinDivert or install a driver while checking a proposed
// replacement. Startup repeats bundle checks under retained native file locks.
func (e *Engine) Validate(ctx context.Context, p *engine.Plan) error {
	if _, err := admit(p); err != nil {
		return err
	}
	held, err := e.openBundle(e.binary)
	if err != nil {
		return err
	}
	defer func() { _ = held.Close() }()
	if err := e.checkService(e.binary, false); err != nil {
		return err
	}
	return e.Engine.Validate(ctx, Rewrite(p))
}

// Apply confirms a no-capture child and its pinned driver before opening the
// host-owned TCP filter. It never falls back to an unshaped or SOCKS backend.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	args, err := admit(p)
	if err != nil {
		return err
	}
	if err := e.Validate(ctx, p); err != nil {
		return err
	}
	e.op.Lock()
	defer e.op.Unlock()
	if e.closed {
		return errors.New("winws: engine is closed")
	}
	if err := e.stop(context.WithoutCancel(ctx)); err != nil {
		return err
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	e.held, err = e.openBundle(e.binary)
	if err != nil {
		return err
	}
	life, cancel := context.WithCancel(context.WithoutCancel(ctx))
	e.cancel = cancel
	fail := func(cause error) error {
		return errors.Join(cause, e.stop(context.WithoutCancel(ctx)))
	}
	if err := e.checkService(e.binary, false); err != nil {
		return fail(err)
	}
	if err := ctx.Err(); err != nil {
		return fail(err)
	}
	e.bootstrap, err = e.start(life, []string{"--wf-raw=false"})
	if err != nil {
		return fail(err)
	}
	// The temporary process holds a handle to the driver so Windows cannot
	// unload/reload it between this identity check and the capturing child.
	if err := waitReady(ctx, e.bootstrap); err != nil {
		return fail(err)
	}
	if err := e.checkService(e.binary, true); err != nil {
		return fail(err)
	}
	if err := ctx.Err(); err != nil {
		return fail(err)
	}
	e.proc, err = e.start(life, args)
	if err != nil {
		return fail(err)
	}
	if err := waitReady(ctx, e.proc); err != nil {
		return fail(err)
	}
	if err := e.bootstrap.Stop(context.WithoutCancel(ctx), 0); err != nil {
		return fail(err)
	}
	e.bootstrap = nil
	if err := e.Engine.Apply(ctx, Rewrite(p)); err != nil {
		return fail(err)
	}
	if e.proc.Exited() {
		return fail(fmt.Errorf("winws: exited during forwarder startup: %w", errors.Join(e.proc.Err(), errors.New(e.proc.Output().Last(5)))))
	}
	e.fatal = nil
	go e.watch(life, e.proc)
	return nil
}

func (e *Engine) start(ctx context.Context, args []string) (*supervise.Process, error) {
	return supervise.Start(ctx, supervise.Spec{Name: "Winws", Path: e.binary, Args: args,
		Dir: e.home, Lines: func(line string) {
			if e.logs != nil {
				e.logs.Write(time.Time{}, logs.LevelInfo, "zapret", line)
			}
		}})
}

func waitReady(ctx context.Context, proc *supervise.Process) error {
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	tick := time.NewTicker(20 * time.Millisecond)
	defer tick.Stop()
	for {
		if proc.Exited() {
			return fmt.Errorf("winws: exited before readiness: %w", errors.Join(proc.Err(), errors.New(proc.Output().Last(5))))
		}
		if strings.Contains(proc.Output().Last(80), readyMarker) {
			return nil
		}
		select {
		case <-ctx.Done():
			return fmt.Errorf("winws: readiness: %w", ctx.Err())
		case <-tick.C:
		}
	}
}

// A filter crash ends the forwarder as well; reconnect is an explicit session
// operation. A packet already racing the kernel's handle close is not an atomic
// killswitch guarantee.
func (e *Engine) watch(ctx context.Context, proc *supervise.Process) {
	err := proc.Wait(ctx)
	if ctx.Err() != nil {
		return
	}
	e.op.Lock()
	if e.proc != proc {
		e.op.Unlock()
		return
	}
	if err == nil {
		err = errors.New("winws exited unexpectedly with status 0")
	}
	e.fatal = errs.Wrap(err, errs.CodeUnavailable, errs.KeyEngineStopped)
	fatal := errors.Join(e.fatal, e.stop(context.WithoutCancel(ctx)))
	e.op.Unlock()
	e.Engine.Events().Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: fatal})
}

func (e *Engine) stop(ctx context.Context) error {
	innerErr := e.Engine.Stop(ctx)
	for _, proc := range []*supervise.Process{e.proc, e.bootstrap} {
		if proc != nil {
			if err := proc.Stop(ctx, 0); err != nil && !proc.Exited() {
				return errors.Join(innerErr, err)
			}
		}
	}
	e.proc, e.bootstrap = nil, nil
	// Stop owns termination; cancel only after reap so Start's cancellation
	// goroutine cannot race a second TerminateProcess against it.
	if e.cancel != nil {
		e.cancel()
	}
	e.cancel = nil
	if e.held != nil {
		innerErr = errors.Join(innerErr, e.held.Close())
		e.held = nil
	}
	return innerErr
}

// Stop releases only Sora's filters/processes. Never stop the shared driver.
func (e *Engine) Stop(ctx context.Context) error {
	e.op.Lock()
	defer e.op.Unlock()
	return e.stop(ctx)
}

// Close serializes with a pending apply so no late child survives shutdown.
func (e *Engine) Close() error {
	e.op.Lock()
	defer e.op.Unlock()
	e.closed = true
	return errors.Join(e.stop(context.Background()), e.Engine.Close())
}
