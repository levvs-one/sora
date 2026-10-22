package olcrtc

import (
	"context"
	"errors"
	"fmt"
	"maps"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"sync"
	"time"

	"github.com/txthinking/socks5"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/engine/supervise"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/logs"
)

// Engine owns both sides of the authenticated loopback bridge. The auxiliary
// clients share its session lifetime and are retired before replacements.
type Engine struct {
	engine.Engine
	binary, home string
	center       *logs.Center
	redactor     *engine.Redactor
	bus          *engine.EventBus
	op           sync.Mutex
	mu           sync.Mutex
	clients      []*client
	unsub        func()
	workers      sync.WaitGroup
}

type client struct {
	listener Listener
	proc     *supervise.Process
	spec     supervise.Spec
	home     string
	ctx      context.Context
	cancel   context.CancelFunc
	state    engine.State
}

// Wrap adds olcrtc to an already selected forwarding engine.
func Wrap(inner engine.Engine, binary, home string, center *logs.Center) *Engine {
	e := &Engine{Engine: inner, binary: binary, home: home, center: center, redactor: engine.NewRedactor(), bus: engine.NewEventBus(128)}
	ch, unsub := inner.Events().Subscribe()
	e.unsub = unsub
	e.workers.Add(1)
	go func() {
		defer e.workers.Done()
		for ev := range ch {
			if ev.Kind == engine.EventState {
				ev.State = e.State()
			}
			e.bus.Publish(ev)
		}
	}()
	return e
}

// Events includes failures from every process in the connection.
func (e *Engine) Events() *engine.EventBus { return e.bus }

// State requires every auxiliary client and the native engine to be ready.
func (e *Engine) State() engine.State {
	e.mu.Lock()
	defer e.mu.Unlock()
	for _, c := range e.clients {
		if c.state != engine.StateRunning {
			return c.state
		}
	}
	return e.Engine.State()
}

// Capabilities describes the wrapped engine, including the auxiliary protocol.
func (e *Engine) Capabilities() engine.Capabilities {
	caps := e.Engine.Capabilities()
	caps.Protocols = maps.Clone(caps.Protocols)
	caps.Protocols[engine.ProtocolOLCRTC] = true
	return caps
}

// Validate rejects incompatible combinations before the current session stops.
func (e *Engine) Validate(ctx context.Context, p *engine.Plan) error {
	if p == nil {
		return errors.New("olcrtc: nil plan")
	}
	if err := p.Validate(); err != nil {
		return err
	}
	count := 0
	for _, o := range p.Outbounds {
		if o.Protocol != engine.ProtocolOLCRTC {
			continue
		}
		count++
		c := o.OLCRTC
		if c.Provider == "telemost" && (c.Transport == "datachannel" || c.Transport == "seichannel") || c.Provider == "wbstream" && c.Transport == "datachannel" {
			return errs.Newf(errs.CodeFailedPrecondition, errs.KeyPlanEngineUnsupported, "olcrtc: this provider cannot carry the selected transport in its guest flow")
		}
	}
	if count > 32 {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeyPlanTooLarge, "olcrtc: a session supports at most 32 simultaneous rooms")
	}
	return e.Engine.Validate(ctx, e.rewrite(p, nil))
}

func (e *Engine) rewrite(p *engine.Plan, listeners map[string]Listener) *engine.Plan {
	out := Rewrite(p, listeners)
	if p.Tun.Enabled && runtime.GOOS == "windows" {
		// The packet engine must not send the carrier's own call back into itself.
		out.Rules = append([]engine.Rule{{Type: engine.RuleProcess, Value: filepath.Base(e.binary), Target: "direct"}}, p.Rules...)
	}
	return out
}

// Apply opens authenticated clients before the native engine can route to them.
func (e *Engine) Apply(ctx context.Context, p *engine.Plan) error {
	e.op.Lock()
	defer e.op.Unlock()
	if err := e.Validate(ctx, p); err != nil {
		return err
	}
	if err := e.stop(ctx); err != nil {
		return err
	}
	e.redactor.Add(p.Secrets()...)
	e.redactor.Add(p.Identifiers()...)
	listeners := map[string]Listener{}
	for _, o := range p.Outbounds {
		if o.Protocol != engine.ProtocolOLCRTC {
			continue
		}
		c, err := e.start(ctx, o)
		if err != nil {
			return errors.Join(e.redactor.Err(err), e.stop(context.WithoutCancel(ctx)))
		}
		listeners[o.ID] = c.listener
	}
	if err := e.Engine.Apply(ctx, e.rewrite(p, listeners)); err != nil {
		return errors.Join(err, e.stop(context.WithoutCancel(ctx)))
	}
	e.mu.Lock()
	clients := append([]*client(nil), e.clients...)
	e.mu.Unlock()
	for _, c := range clients {
		e.workers.Add(1)
		//nolint:gosec // the child context belongs to this session and Stop cancels it independently of the initiating RPC
		go e.watch(c)
	}
	return nil
}

func (e *Engine) start(ctx context.Context, o engine.Outbound) (*client, error) {
	port, err := supervise.FreePort()
	if err != nil {
		return nil, err
	}
	user, err := supervise.RandomSecret()
	if err != nil {
		return nil, err
	}
	password, err := supervise.RandomSecret()
	if err != nil {
		return nil, err
	}
	l := Listener{Port: uint16(port), Username: user, Password: password} //nolint:gosec // FreePort returns a TCP port
	e.redactor.Add(user, password)
	raw, err := Render(o, l)
	if err != nil {
		return nil, err
	}
	return e.launch(ctx, raw, l)
}

func (e *Engine) launch(ctx context.Context, raw []byte, l Listener) (*client, error) {
	e.redactor.Add(l.Username, l.Password)
	if err := os.MkdirAll(e.home, 0700); err != nil {
		return nil, err
	}
	home, err := os.MkdirTemp(e.home, "client-")
	if err != nil {
		return nil, err
	}
	path := filepath.Join(home, "client.yaml")
	if err = os.WriteFile(path, raw, 0600); err != nil {
		return nil, errors.Join(err, os.RemoveAll(home))
	}
	lifetime, cancel := context.WithCancel(context.Background())
	c := &client{listener: l, home: home, ctx: lifetime, cancel: cancel, state: engine.StateStarting}
	c.spec = supervise.Spec{Name: "olcrtc", Path: e.binary, Args: []string{path}, Dir: home, Lines: e.logLine}
	c.proc, err = supervise.Start(lifetime, c.spec)
	if err == nil {
		e.mu.Lock()
		e.clients = append(e.clients, c)
		e.mu.Unlock()
		err = waitReady(ctx, c)
	}
	if err != nil {
		cancel()
		if c.proc != nil {
			err = errors.Join(err, c.proc.Stop(context.WithoutCancel(ctx), time.Second))
		}
		if c.proc == nil {
			err = errors.Join(err, os.RemoveAll(home))
		}
		return nil, err
	}
	e.mu.Lock()
	c.state = engine.StateRunning
	e.mu.Unlock()
	return c, nil
}

// waitReady authenticates to the actual listener, preventing an unrelated local
// listener from satisfying readiness after the free-port reservation closes.
func waitReady(ctx context.Context, c *client) error {
	ctx, cancel := context.WithTimeout(ctx, 45*time.Second)
	defer cancel()
	ticker := time.NewTicker(50 * time.Millisecond)
	defer ticker.Stop()
	for {
		if c.proc.Exited() {
			if err := c.proc.Err(); err != nil {
				return err
			}
			return errors.New("olcrtc: exited before its SOCKS listener opened")
		}
		if err := authenticate(ctx, c.listener); err == nil {
			return nil
		}
		select {
		case <-ctx.Done():
			return fmt.Errorf("olcrtc: SOCKS listener did not become ready: %w: %s", ctx.Err(), c.proc.Output().Last(5))
		case <-ticker.C:
		}
	}
}

func authenticate(ctx context.Context, l Listener) error {
	client, err := socks5.NewClient(net.JoinHostPort("127.0.0.1", strconv.Itoa(int(l.Port))), l.Username, l.Password, 0, 0)
	if err != nil {
		return err
	}
	defer func() { _ = client.Close() }()
	client.DialTCP = func(network, _, address string) (net.Conn, error) {
		conn, err := (&net.Dialer{Timeout: 200 * time.Millisecond}).DialContext(ctx, network, address)
		if err != nil {
			return nil, err
		}
		deadline := time.Now().Add(300 * time.Millisecond)
		if d, ok := ctx.Deadline(); ok && d.Before(deadline) {
			deadline = d
		}
		if err := conn.SetDeadline(deadline); err != nil {
			_ = conn.Close()
			return nil, err
		}
		return conn, nil
	}
	return client.Negotiate(nil)
}

func (e *Engine) watch(c *client) {
	defer e.workers.Done()
	budget := engine.NewRestartBudget(5, 10*time.Minute, nil)
	backoff := engine.DefaultBackoff()
	for {
		err := c.proc.Wait(c.ctx)
		if c.ctx.Err() != nil {
			return
		}
		e.op.Lock()
		if c.ctx.Err() != nil {
			e.op.Unlock()
			return
		}
		e.mu.Lock()
		c.state = engine.StateRecovering
		e.mu.Unlock()
		if err == nil {
			err = errors.New("olcrtc: process exited unexpectedly")
		}
		masked := e.redactor.Err(err)
		e.bus.Publish(engine.Event{Kind: engine.EventEngineDown, State: engine.StateRecovering, Err: errs.Wrap(masked, errs.CodeUnavailable, errs.KeyEngineStopped)})
		if !budget.Allow() {
			e.mu.Lock()
			c.state = engine.StateFailed
			e.mu.Unlock()
			e.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: errs.Wrap(masked, errs.CodeUnavailable, errs.KeyEngineRestartSpent)})
			e.op.Unlock()
			return
		}
		e.op.Unlock()
		if backoff.Wait(c.ctx, budget.Used()-1) != nil {
			return
		}
		e.op.Lock()
		if c.ctx.Err() != nil {
			e.op.Unlock()
			return
		}
		c.proc, err = supervise.Start(c.ctx, c.spec)
		if err == nil {
			err = waitReady(c.ctx, c)
		}
		if err != nil {
			if c.proc != nil {
				_ = c.proc.Stop(context.Background(), time.Second)
			}
			e.mu.Lock()
			c.state = engine.StateFailed
			e.mu.Unlock()
			e.bus.Publish(engine.Event{Kind: engine.EventFatal, State: engine.StateFailed, Err: errs.Wrap(e.redactor.Err(err), errs.CodeUnavailable, errs.KeyEngineStartFailed)})
			e.op.Unlock()
			return
		}
		e.mu.Lock()
		c.state = engine.StateRunning
		e.mu.Unlock()
		e.bus.Publish(engine.Event{Kind: engine.EventState, State: e.State()})
		e.op.Unlock()
	}
}

func (e *Engine) logLine(line string) {
	if e.center != nil {
		e.center.Write(time.Time{}, logs.LevelInfo, "olcrtc", e.redactor.String(line))
	}
}

func (e *Engine) stop(ctx context.Context) error {
	failure := e.Engine.Stop(ctx)
	e.mu.Lock()
	clients := e.clients
	e.clients = nil
	e.mu.Unlock()
	var retained []*client
	for _, c := range clients {
		c.cancel()
		if c.proc != nil {
			failure = errors.Join(failure, c.proc.Stop(ctx, time.Second))
			if !c.proc.Exited() {
				retained = append(retained, c)
				continue
			}
		}
		if err := os.RemoveAll(c.home); err != nil {
			failure = errors.Join(failure, err)
			retained = append(retained, c)
		}
	}
	e.mu.Lock()
	e.clients = retained
	e.mu.Unlock()
	return e.redactor.Err(failure)
}

// Stop removes routing before shutting down the auxiliary listeners.
func (e *Engine) Stop(ctx context.Context) error {
	e.mu.Lock()
	for _, c := range e.clients {
		c.cancel()
	}
	e.mu.Unlock()
	e.op.Lock()
	defer e.op.Unlock()
	return e.stop(ctx)
}

// Close waits for every watcher and event relay after releasing process ownership.
func (e *Engine) Close() error {
	err := e.Stop(context.Background())
	err = errors.Join(err, e.Engine.Close())
	e.unsub()
	e.workers.Wait()
	return err
}

// Connections retains the native engine's connection-center capability.
func (e *Engine) Connections(ctx context.Context) ([]engine.Connection, error) {
	if tracker, ok := e.Engine.(engine.ConnectionTracker); ok {
		return tracker.Connections(ctx)
	}
	return nil, errs.Newf(errs.CodeUnsupported, errs.KeyConnectionsUnavailable, "olcrtc: the selected forwarding engine cannot list connections")
}

// CloseConnection delegates connection ownership to the native engine.
func (e *Engine) CloseConnection(ctx context.Context, id string) error {
	if tracker, ok := e.Engine.(engine.ConnectionTracker); ok {
		return tracker.CloseConnection(ctx, id)
	}
	return errs.Newf(errs.CodeUnsupported, errs.KeyConnectionsUnavailable, "olcrtc: the selected forwarding engine cannot close connections")
}

// CloseConnections closes native flows before route changes.
func (e *Engine) CloseConnections(ctx context.Context) error {
	if tracker, ok := e.Engine.(engine.ConnectionTracker); ok {
		return tracker.CloseConnections(ctx)
	}
	return errs.Newf(errs.CodeUnsupported, errs.KeyConnectionsUnavailable, "olcrtc: the selected forwarding engine cannot close connections")
}
