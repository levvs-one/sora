//go:build windows

package main

import (
	"errors"
	"strings"
	"testing"
	"time"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"
)

type stoppingService struct {
	states       []svc.State
	queries      int
	controls     int
	queryErrorAt int
	queryError   error
	controlError error
}

func (s *stoppingService) Query() (svc.Status, error) {
	s.queries++
	if s.queries == s.queryErrorAt {
		return svc.Status{}, s.queryError
	}
	return svc.Status{State: s.states[min(s.queries-1, len(s.states)-1)]}, nil
}

func (s *stoppingService) Control(command svc.Cmd) (svc.Status, error) {
	if command != svc.Stop {
		return svc.Status{}, errors.New("fixture received an unexpected control")
	}
	s.controls++
	return svc.Status{State: svc.StopPending}, s.controlError
}

func TestStopServiceWaitsForStoppedOrReportsFailure(t *testing.T) {
	injected := errors.New("fixture SCM failure")
	for _, tc := range []struct {
		name     string
		service  stoppingService
		controls int
		wantErr  error
	}{
		{"already-stopped", stoppingService{states: []svc.State{svc.Stopped}}, 0, nil},
		{"running", stoppingService{states: []svc.State{svc.Running, svc.StopPending, svc.Stopped}}, 1, nil},
		{"already-stopping", stoppingService{states: []svc.State{svc.StopPending, svc.Stopped}, controlError: windows.ERROR_SERVICE_CANNOT_ACCEPT_CTRL}, 0, nil},
		{"initial-query-failure", stoppingService{states: []svc.State{svc.Running}, queryErrorAt: 1, queryError: injected}, 0, injected},
		{"stop-refused", stoppingService{states: []svc.State{svc.Running}, controlError: injected}, 1, injected},
		{"stopped-during-control", stoppingService{states: []svc.State{svc.Running, svc.Stopped}, controlError: windows.ERROR_SERVICE_NOT_ACTIVE}, 1, nil},
		{"later-query-failure", stoppingService{states: []svc.State{svc.Running}, queryErrorAt: 2, queryError: injected}, 1, injected},
	} {
		t.Run(tc.name, func(t *testing.T) {
			err := stopService(&tc.service)
			if !errors.Is(err, tc.wantErr) || tc.service.controls != tc.controls {
				t.Fatalf("stop error=%v controls=%d, wanted %v/%d", err, tc.service.controls, tc.wantErr, tc.controls)
			}
		})
	}
}

func TestStopServiceRejectsAnExpiredStopBudget(t *testing.T) {
	service := stoppingService{states: []svc.State{svc.Running, svc.StopPending}}
	started := time.Now()
	err := stopService(&service)
	elapsed := time.Since(started)
	if err == nil || !strings.Contains(err.Error(), "did not stop within 30 seconds") || elapsed < 30*time.Second || elapsed > 35*time.Second || service.controls != 1 {
		t.Fatalf("stuck SCM result=%v elapsed=%s controls=%d", err, elapsed, service.controls)
	}
}
