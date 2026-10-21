package ext

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/errs"
	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
)

type workerLease struct {
	cancel context.CancelFunc
	done   chan struct{}
}

// RunWorker uses the app's verified registry, not the separate service-owned
// registry. The control token and transport authenticate this delegation.
// No manifest, source, token or arbitrary native callback is exposed to JS.
func (h *Host) RunWorker(stream extv1.ExtensionHost_RunWorkerServer) error {
	first, err := stream.Recv()
	if err != nil {
		return err
	}
	if h.deps.VerifyControl == nil || !h.deps.VerifyControl(first.GetControlToken()) {
		return status.Error(codes.Unauthenticated, "ext: control authentication failed")
	}
	if h.deps.Scheduler == nil {
		return status.Error(codes.Unavailable, "ext: scheduler unavailable")
	}
	m, x, err := ParseManifestFull([]byte(first.GetManifestJson()))
	if err != nil {
		return toStatus(err)
	}
	if len(first.GetSource()) > MaxWorkerSource {
		return status.Error(codes.InvalidArgument, "worker source exceeds 1 MiB")
	}
	cfg, ok := ParseBackgroundConfig([]byte(first.GetConfigJson()))
	if !ok {
		return status.Error(codes.InvalidArgument, "invalid worker configuration")
	}
	ctx, cancel := context.WithCancel(stream.Context())
	defer cancel()
	lease := &workerLease{cancel: cancel, done: make(chan struct{})}
	h.workerMu.Lock()
	if h.workers == nil {
		h.workers = map[string]*workerLease{}
	}
	if previous := h.workers[m.ID]; previous != nil {
		previous.cancel()
		select {
		case <-previous.done:
		case <-ctx.Done():
			h.workerMu.Unlock()
			return ctx.Err()
		}
	}
	h.workers[m.ID] = lease
	h.workerMu.Unlock()
	defer func() {
		h.deps.Scheduler.Unregister(m.ID)
		close(lease.done)
		h.workerMu.Lock()
		if h.workers[m.ID] == lease {
			delete(h.workers, m.ID)
		}
		h.workerMu.Unlock()
	}()
	outgoing := make(chan *extv1.WorkerHostMessage, MaxLogEntries+1)
	replies := make(chan json.RawMessage)
	received := make(chan error, 1)
	go func() {
		for {
			msg, recvErr := stream.Recv()
			if recvErr != nil {
				received <- recvErr
				return
			}
			select {
			case replies <- json.RawMessage(msg.GetReplyJson()):
			case <-ctx.Done():
				return
			}
		}
	}()
	send := func(runCtx context.Context, msg *extv1.WorkerHostMessage) error {
		select {
		case outgoing <- msg:
			return nil
		case <-runCtx.Done():
			return runCtx.Err()
		}
	}
	var lastLogAt time.Time
	run := func(runCtx context.Context, env *WorkerEnv) error {
		runCtx, stop := context.WithTimeout(runCtx, WorkerWallTimeout)
		defer stop()
		call := func(callCtx context.Context, raw json.RawMessage) (json.RawMessage, error) {
			return workerBridgeCall(callCtx, m, env, raw, func() (json.RawMessage, error) {
				if err := send(callCtx, &extv1.WorkerHostMessage{CallJson: string(raw)}); err != nil {
					return nil, err
				}
				select {
				case reply := <-replies:
					return reply, nil
				case <-callCtx.Done():
					return nil, callCtx.Err()
				}
			})
		}
		event := "session.disconnected"
		if h.deps.WorkerEvent != nil {
			event = h.deps.WorkerEvent()
		}
		runErr := RunJavaScriptProcess(runCtx, first.GetSource(), event, call)
		if runErr != nil {
			env.log.Append(LogError, fmt.Sprintf("worker failed: %v", runErr))
		}
		for _, entry := range env.log.Entries() {
			if !entry.At.After(lastLogAt) {
				continue
			}
			lastLogAt = entry.At
			if err := send(ctx, &extv1.WorkerHostMessage{Log: entry.Message}); err != nil {
				return err
			}
		}
		if runErr != nil && ctx.Err() == nil && !errors.Is(runErr, context.Canceled) {
			_ = send(ctx, &extv1.WorkerHostMessage{Failed: true})
		}
		return runErr
	}
	if err = h.deps.Scheduler.RegisterConfig(m, x, cfg, run); err != nil {
		return toStatus(err)
	}
	outgoing <- &extv1.WorkerHostMessage{Log: "background worker scheduled"}
	for {
		select {
		case <-ctx.Done():
			return nil
		case err = <-received:
			if errors.Is(err, io.EOF) {
				return nil
			}
			return err
		case msg := <-outgoing:
			if err = stream.Send(msg); err != nil {
				return err
			}
		}
	}
}

// The same permission registry as Host.check gates every core-side worker
// call, followed by PanelBridge for the app-owned settings and notifications.
func workerBridgeCall(ctx context.Context, m *Manifest, env *WorkerEnv, raw json.RawMessage, forward func() (json.RawMessage, error)) (json.RawMessage, error) {
	var msg struct {
		ID     any             `json:"id"`
		Method string          `json:"method"`
		Args   json.RawMessage `json:"args"`
	}
	if err := json.Unmarshal(raw, &msg); err != nil {
		return nil, err
	}
	reply := func(result any, code string) (json.RawMessage, error) {
		return json.Marshal(map[string]any{"id": msg.ID, "ok": code == "", "result": result, "error": code})
	}
	switch msg.Method {
	case "log":
		var args struct {
			Message string `json:"message"`
		}
		if err := json.Unmarshal(msg.Args, &args); err != nil {
			return reply(nil, "invalid-argument")
		}
		env.Logf("%s", args.Message)
		return reply(nil, "")
	case "net.fetch":
		var args struct {
			URL     string            `json:"url"`
			Method  string            `json:"method"`
			Headers map[string]string `json:"headers"`
			Body    string            `json:"body"`
		}
		if err := json.Unmarshal(msg.Args, &args); err != nil {
			return reply(nil, "invalid-argument")
		}
		response, err := env.Fetch(ctx, FetchRequest{URL: args.URL, Method: args.Method, Headers: args.Headers, Body: []byte(args.Body)})
		if err != nil {
			code := "internal"
			if errs.CodeOf(err) == errs.CodePermissionDenied || errs.KeyOf(err) == KeyNetFetchDenied {
				code = "permission-denied"
			}
			if errs.KeyOf(err) == KeyNetFetchNoTunnel || errs.KeyOf(err) == KeyNetFetchPaused {
				code = "not-connected"
			}
			return reply(nil, code)
		}
		return reply(map[string]any{"status": response.Status, "headers": response.Headers, "body": string(response.Body)}, "")
	case "getConnections", "getServers", "notify":
		rpc := map[string]string{"getConnections": "GetConnections", "getServers": "GetServers", "notify": "Notify"}[msg.Method]
		if !hasPermission(m, rpcPermissions[rpc]) {
			env.log.Append(LogWarn, msg.Method+" DENIED: permission not granted")
			return reply(nil, "permission-denied")
		}
	case "getSettings", "setSettings":
		// Extension-local settings are permissionless in the panel contract.
	default:
		return reply(nil, "invalid-argument")
	}
	return forward()
}
