package ext

import (
	"errors"
	"sync"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/levvs-one/sora-client/core/errs"
	extv1 "github.com/levvs-one/sora-client/core/gen/sora/ext/v1"
)

// Deps connects app-owned workers to the authenticated control service.
type Deps struct {
	Scheduler     *Scheduler
	WorkerEvent   func() string
	VerifyControl func(token []byte) bool
}

// Host implements the app-owned worker lifecycle stream.
type Host struct {
	extv1.UnimplementedExtensionHostServer
	workerMu sync.Mutex
	workers  map[string]*workerLease
	deps     Deps
}

// NewHost binds the worker service to the control plane.
func NewHost(deps Deps) *Host {
	return &Host{deps: deps}
}

// toStatus maps core errors to gRPC statuses, preserving codes.
func toStatus(err error) error {
	if err == nil {
		return nil
	}
	e := &errs.Error{}
	if errors.As(err, &e) {
		switch e.Code() {
		case errs.CodeInvalidArgument:
			return status.Error(codes.InvalidArgument, e.Error())
		case errs.CodeUnauthenticated:
			return status.Error(codes.Unauthenticated, e.Error())
		case errs.CodeNotFound:
			return status.Error(codes.NotFound, e.Error())
		case errs.CodeUnavailable:
			return status.Error(codes.Unavailable, e.Error())
		}
	}
	return status.Error(codes.Internal, err.Error())
}
