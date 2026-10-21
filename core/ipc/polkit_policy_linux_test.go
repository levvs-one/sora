//go:build linux

package ipc

import (
	"encoding/xml"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

// This file lints the shipped polkit policy (service/linux/sora.policy)
// without root and without a running polkit: it parses the XML the same
// way polkit would read the defaults and asserts the trust boundary the
// daemon relies on. It guards against a repeat of the dead-control-action
// incident: polkitAllows calls CheckAuthorization with interaction disabled,
// so any auth_* default on the control action silently kills Connect for
// desktop users (see core/ipc/polkit_linux.go).

type policyDefaults struct {
	AllowAny      string `xml:"allow_any"`
	AllowInactive string `xml:"allow_inactive"`
	AllowActive   string `xml:"allow_active"`
}

type policyAction struct {
	ID       string         `xml:"id,attr"`
	Defaults policyDefaults `xml:"defaults"`
}

type policyConfig struct {
	Actions []policyAction `xml:"action"`
}

func loadPolicy(t *testing.T) policyConfig {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("cannot locate this test file")
	}
	path := filepath.Join(filepath.Dir(file), "..", "..", "service", "linux", "sora.policy")
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	var cfg policyConfig
	if err := xml.Unmarshal(raw, &cfg); err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
	return cfg
}

func findAction(t *testing.T, cfg policyConfig, id string) policyAction {
	t.Helper()
	for _, a := range cfg.Actions {
		if a.ID == id {
			return a
		}
	}
	t.Fatalf("policy has no action %q", id)
	return policyAction{}
}

// TestPolkitPolicyGrantsControlToActiveSession pins the control-action
// defaults the daemon's non-interactive check needs: allow_active=yes, and
// nothing else granted to remote or inactive sessions.
func TestPolkitPolicyGrantsControlToActiveSession(t *testing.T) {
	cfg := loadPolicy(t)
	control := findAction(t, cfg, PolkitAction)
	if control.Defaults.AllowActive != "yes" {
		t.Fatalf("control action %q must grant the active session without auth "+
			"(allow_active=yes), got %q; an auth_* value always challenges the "+
			"daemon's non-interactive check and kills Connect",
			PolkitAction, control.Defaults.AllowActive)
	}
	if control.Defaults.AllowAny != "auth_admin" {
		t.Fatalf("control action %q must not grant remote sessions (allow_any), got %q",
			PolkitAction, control.Defaults.AllowAny)
	}
	if control.Defaults.AllowInactive != "auth_admin" {
		t.Fatalf("control action %q must not grant inactive sessions (allow_inactive), got %q",
			PolkitAction, control.Defaults.AllowInactive)
	}
}

// TestPolkitPolicyReadStaysPasswordless pins the read-action defaults:
// status and statistics stay available to the active session with no prompt.
func TestPolkitPolicyReadStaysPasswordless(t *testing.T) {
	cfg := loadPolicy(t)
	read := findAction(t, cfg, PolkitReadAction)
	if read.Defaults.AllowActive != "yes" {
		t.Fatalf("read action %q must stay passwordless for the active session, got %q",
			PolkitReadAction, read.Defaults.AllowActive)
	}
}

// TestPolkitPolicyIsMinimal keeps the policy at exactly the two actions the
// daemon knows, so a third privilege cannot creep in unnoticed, and ties the
// Go constants to the policy so a rename on either side breaks loudly.
func TestPolkitPolicyIsMinimal(t *testing.T) {
	cfg := loadPolicy(t)
	want := map[string]bool{PolkitAction: false, PolkitReadAction: false}
	for _, a := range cfg.Actions {
		if _, ok := want[a.ID]; !ok {
			t.Fatalf("policy defines unexpected action %q; keep it to the two the daemon uses", a.ID)
		}
		want[a.ID] = true
	}
	for id, seen := range want {
		if !seen {
			t.Fatalf("policy is missing action %q referenced by the daemon", id)
		}
	}
}
