//go:build windows

package guard

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/tailscale/wf"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/session"
)

func TestWFPStrictOLCRTCUsesTheInstalledCarrierAndServiceAccount(t *testing.T) {
	dir := t.TempDir()
	for _, name := range []string{"olcrtc.exe", "xray.exe"} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte("engine identity fixture"), 0600); err != nil {
			t.Fatal(err)
		}
	}
	app, err := wf.AppID(filepath.Join(dir, "olcrtc.exe"))
	if err != nil {
		t.Fatal(err)
	}
	owner, err := sameAccount()
	if err != nil {
		t.Fatal(err)
	}
	for _, enabled := range []bool{false, true} {
		w := &WFP{enginesDir: dir, policy: session.Settings{StrictKillSwitch: true, OLCRTC: enabled}}
		permits := 0
		if err := w.rules(func(r *wf.Rule) error {
			if r.Name != "Sora: olcrtc.exe" {
				return nil
			}
			if r.Action != wf.ActionPermit || len(r.Conditions) != 2 {
				t.Fatal("carrier permit lost exact identity")
			}
			fields := map[wf.FieldID]any{}
			for _, c := range r.Conditions {
				if c.Op != wf.MatchTypeEqual {
					t.Fatal("inexact carrier match")
				}
				fields[c.Field] = c.Value
			}
			if fields[wf.FieldALEAppID] != app || fields[wf.FieldALEUserID].(*windows.SECURITY_DESCRIPTOR).String() != owner.String() {
				t.Fatal("carrier permit allows another file or account")
			}
			permits++
			return nil
		}, strictSublayer); err != nil {
			t.Fatal(err)
		}
		want := 0
		if enabled {
			want = 2
		}
		if permits != want {
			t.Fatalf("carrier enabled=%v permits=%d", enabled, permits)
		}
	}
}
