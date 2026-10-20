package control_test

import (
	"context"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	leakv1 "github.com/levvs-one/sora-client/core/gen/sora/leak/v1"
)

// leakTestStream is a minimal server-streaming stub for RunLeakTests.
type leakTestStream struct {
	grpc.ServerStream
	ctx  context.Context
	sent []*leakv1.LeakTestResult
}

func (s *leakTestStream) Send(r *leakv1.LeakTestResult) error {
	s.sent = append(s.sent, r)
	return nil
}

func (s *leakTestStream) Context() context.Context { return s.ctx }

func TestRunLeakTestsRefusesACallerWithoutTheToken(t *testing.T) {
	server, _, _ := newLogServer(t, newStubEngine())
	stream := &leakTestStream{ctx: context.Background()}
	err := server.RunLeakTests(&leakv1.RunLeakTestsRequest{
		ApiVersion:           clientVersion(),
		ControlAuthenticator: []byte("wrong"),
	}, stream)
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("RunLeakTests with a wrong token = %v", err)
	}
}

func TestRunLeakTestsNeedsAnActiveSession(t *testing.T) {
	server, _, _ := newLogServer(t, newStubEngine())
	stream := &leakTestStream{ctx: context.Background()}
	err := server.RunLeakTests(&leakv1.RunLeakTestsRequest{
		ApiVersion:           clientVersion(),
		ControlAuthenticator: testToken,
	}, stream)
	// Without a session there is no tunnel to test: the call must fail
	// instead of inventing answers.
	if status.Code(err) != codes.FailedPrecondition {
		t.Fatalf("RunLeakTests without a session = %v", err)
	}
	if len(stream.sent) != 0 {
		t.Fatalf("RunLeakTests streamed %d results without a session", len(stream.sent))
	}
}
