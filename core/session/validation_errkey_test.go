package session

// Pins for validation error keys at the session layer: the generic
// outbounds wrap used to bury catalog errors raised by engine
// validation — the olcrtc connect gates above all — under
// core.plan.outbounds_invalid, the specific key surviving only in
// the detail. A catalog error now keeps its key and code through
// Manager.Connect and Session.Start; an unclassified failure still
// gets the generic key.

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

func TestManagerConnectPreservesCatalogValidationKey(t *testing.T) {
	eng := newFakeEngine()
	eng.validate = errs.Newf(errs.CodeFailedPrecondition, errs.KeyOlcrtcTokenRequired,
		"olcrtc: wbstream datachannel needs a provider account token")
	manager := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return eng, nil },
	})
	_, err := manager.Connect(context.Background(), testPlan("gate"), Settings{})
	if errs.KeyOf(err) != errs.KeyOlcrtcTokenRequired {
		t.Fatalf("key = %v, want %v (err = %v)", errs.KeyOf(err), errs.KeyOlcrtcTokenRequired, err)
	}
	if errs.CodeOf(err) != errs.CodeFailedPrecondition {
		t.Fatalf("code = %v, want %v (err = %v)", errs.CodeOf(err), errs.CodeFailedPrecondition, err)
	}
	if !strings.Contains(errs.Detail(err), "wbstream datachannel") {
		t.Fatalf("detail = %q, want the gate's diagnostic text", errs.Detail(err))
	}
}

func TestManagerConnectWrapsPlainValidationErrorAsOutbounds(t *testing.T) {
	eng := newFakeEngine()
	eng.validate = errors.New("engine cannot carry this plan")
	manager := NewManager(ManagerConfig{
		Factory: func(context.Context, *engine.Plan) (engine.Engine, error) { return eng, nil },
	})
	_, err := manager.Connect(context.Background(), testPlan("plain"), Settings{})
	if errs.KeyOf(err) != errs.KeyPlanOutbounds {
		t.Fatalf("key = %v, want %v (err = %v)", errs.KeyOf(err), errs.KeyPlanOutbounds, err)
	}
}

func TestSessionStartPreservesCatalogValidationKey(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	eng.validate = errs.Newf(errs.CodeFailedPrecondition, errs.KeyOlcrtcNotConnectable,
		"olcrtc: provider \"none\" connects by a direct engine URL and token")
	s, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	err = s.Start(context.Background())
	if errs.KeyOf(err) != errs.KeyOlcrtcNotConnectable {
		t.Fatalf("Start key = %v, want %v (err = %v)", errs.KeyOf(err), errs.KeyOlcrtcNotConnectable, err)
	}
	if got := s.Status().Key; got != errs.KeyOlcrtcNotConnectable {
		t.Fatalf("status key = %v, want %v", got, errs.KeyOlcrtcNotConnectable)
	}
}

func TestSessionStartWrapsPlainValidationErrorAsOutbounds(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	eng.validate = errors.New("engine cannot carry this plan")
	s, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	err = s.Start(context.Background())
	if errs.KeyOf(err) != errs.KeyPlanOutbounds {
		t.Fatalf("Start key = %v, want %v (err = %v)", errs.KeyOf(err), errs.KeyPlanOutbounds, err)
	}
	if got := s.Status().Key; got != errs.KeyPlanOutbounds {
		t.Fatalf("status key = %v, want %v", got, errs.KeyPlanOutbounds)
	}
}

func TestNewWrapsPlainPlanFailureAsOutbounds(t *testing.T) {
	plan := testPlan("dup")
	plan.Outbounds = append(plan.Outbounds, plan.Outbounds[0])
	eng, guard := newFakeEngine(), &fakeGuard{}
	cfg := testConfig(eng, guard)
	cfg.Plan = plan
	_, err := New(cfg)
	if errs.KeyOf(err) != errs.KeyPlanOutbounds {
		t.Fatalf("key = %v, want %v (err = %v)", errs.KeyOf(err), errs.KeyPlanOutbounds, err)
	}
}
