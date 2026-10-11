// Package legacycontrol serves the existing control contract to .NET Framework
// clients over the same account-restricted IPC transport as the modern client.
package legacycontrol

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net"
	"time"

	"github.com/creachadair/jrpc2"
	"github.com/creachadair/jrpc2/handler"
	"golang.org/x/sync/semaphore"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/control"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/ipc"
)

// JSON carries base64 protobuf bytes and an escaped protobuf-JSON string.
const requestLimit = 2 * control.MaxRecvMsgBytes
const responseLimit = 2 * control.MaxSendMsgBytes

type parameters struct {
	Payload  string `json:"payload"`
	StreamID string `json:"streamId,omitempty"`
}

// Serve uses generated method descriptors, so authentication, validation and
// lifecycle behavior remain in the shared control implementation.
func Serve(ctx context.Context, listener *ipc.Listener, service corev1.CoreControlServer) error {
	return listener.Serve(ctx, func(ctx context.Context, connection net.Conn) error {
		return serveConnection(ctx, connection, service)
	})
}

func serveConnection(ctx context.Context, connection net.Conn, service corev1.CoreControlServer) error {
	mux := handler.Map{}
	for _, method := range corev1.CoreControl_ServiceDesc.Methods {
		mux[method.MethodName] = func(ctx context.Context, request *jrpc2.Request) (any, error) {
			var params parameters
			if err := request.UnmarshalParams(&params); err != nil {
				return nil, err
			}
			result, err := method.Handler(service, ctx, func(value any) error {
				return protojson.Unmarshal([]byte(params.Payload), value.(proto.Message))
			}, nil)
			if err != nil {
				return nil, err
			}
			if response, ok := result.(*corev1.HandshakeResponse); ok && len(response.GetControlAuthenticator()) == control.TokenLen {
				if err := connection.SetReadDeadline(time.Time{}); err != nil {
					return nil, err
				}
			}
			payload, err := protojson.Marshal(result.(proto.Message))
			return string(payload), err
		}
	}
	for _, method := range corev1.CoreControl_ServiceDesc.Streams {
		mux[method.StreamName] = func(ctx context.Context, request *jrpc2.Request) (any, error) {
			var params parameters
			if err := request.UnmarshalParams(&params); err != nil {
				return nil, err
			}
			if params.StreamID == "" || len(params.StreamID) > 128 {
				return nil, &jrpc2.Error{Code: jrpc2.InvalidParams, Message: "missing or oversized stream ID"}
			}
			stream := &serverStream{ctx: ctx, params: params, server: jrpc2.ServerFromContext(ctx)}
			err := method.Handler(service, stream)
			return map[string]any{"headers": stream.headers, "trailers": stream.trailers}, err
		}
	}
	// Reserve executor capacity for cancellation notifications. Long-lived
	// watches must never fill every slot and block their own cancellation.
	slots := semaphore.NewWeighted(8)
	for name, action := range mux {
		if name == "Disconnect" || name == "GetStatus" || name == "Handshake" {
			continue
		}
		mux[name] = func(ctx context.Context, request *jrpc2.Request) (any, error) {
			if !slots.TryAcquire(1) {
				return nil, &jrpc2.Error{Code: -32001, Message: "too many active operations; cancel one before starting another"}
			}
			defer slots.Release(1)
			return action(ctx, request)
		}
	}
	mux["$/cancelRequest"] = func(ctx context.Context, request *jrpc2.Request) (any, error) {
		var params struct {
			ID json.RawMessage `json:"id"`
		}
		if err := request.UnmarshalParams(&params); err != nil {
			return nil, err
		}
		jrpc2.ServerFromContext(ctx).CancelRequest(string(params.ID))
		return nil, nil
	}
	server := jrpc2.NewServer(mux, &jrpc2.ServerOptions{
		AllowPush: true, DisableBuiltin: true, Concurrency: 16,
		NewContext: func() context.Context { return ctx },
	})
	scanner := bufio.NewScanner(connection)
	scanner.Buffer(make([]byte, 4096), requestLimit)
	if err := connection.SetReadDeadline(time.Now().Add(10 * time.Second)); err != nil {
		return err
	}
	server.Start(&frames{connection: connection, scanner: scanner})
	// Let the receiver stop the RPC server after transport closure. Calling
	// jrpc2.Stop concurrently with a buffered receive can close its work queue
	// before that receive is dispatched (jrpc2 v1.3.5).
	stop := context.AfterFunc(ctx, func() { _ = connection.Close() })
	defer stop()
	return server.Wait()
}

// Scanner bounds framing before a JSON decoder allocates a request. Its NDJSON
// framing is supported directly by StreamJsonRpc.NewLineDelimitedMessageHandler.
type frames struct {
	connection net.Conn
	scanner    *bufio.Scanner
}

func (f *frames) Recv() ([]byte, error) {
	if !f.scanner.Scan() {
		if err := f.scanner.Err(); err != nil {
			return nil, err
		}
		return nil, io.EOF
	}
	return append([]byte(nil), f.scanner.Bytes()...), nil
}

func (f *frames) Send(payload []byte) error {
	if len(payload) > responseLimit {
		return errors.New("legacy control response exceeds the transport limit")
	}
	if err := f.connection.SetWriteDeadline(time.Now().Add(5 * time.Second)); err != nil {
		return err
	}
	_, err := f.connection.Write(append(payload, '\n'))
	return err
}

func (f *frames) Close() error { return f.connection.Close() }

type serverStream struct {
	ctx         context.Context
	params      parameters
	server      *jrpc2.Server
	received    bool
	headers     metadata.MD
	trailers    metadata.MD
	headersSent bool
}

func (s *serverStream) Context() context.Context { return s.ctx }

func (s *serverStream) RecvMsg(value any) error {
	if s.received {
		return io.EOF
	}
	s.received = true
	return protojson.Unmarshal([]byte(s.params.Payload), value.(proto.Message))
}

func (s *serverStream) SendMsg(value any) error {
	payload, err := protojson.Marshal(value.(proto.Message))
	if err != nil {
		return err
	}
	s.headersSent = true
	return s.server.Notify(s.ctx, "CoreEvent", []any{s.params.StreamID, string(payload)})
}

func (s *serverStream) SetHeader(header metadata.MD) error {
	if s.headersSent {
		return errors.New("stream headers have already been sent")
	}
	s.headers = metadata.Join(s.headers, header)
	return nil
}

func (s *serverStream) SendHeader(header metadata.MD) error {
	if err := s.SetHeader(header); err != nil {
		return err
	}
	s.headersSent = true
	return nil
}

func (s *serverStream) SetTrailer(trailer metadata.MD) {
	s.trailers = metadata.Join(s.trailers, trailer)
}
