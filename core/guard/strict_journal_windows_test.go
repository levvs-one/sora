//go:build windows

package guard

import (
	"errors"
	"fmt"
	"path/filepath"
	"slices"
	"testing"

	"github.com/tailscale/wf"

	"github.com/levvs-one/sora-client/core/session"
)

type journalConnection struct {
	installed    map[wf.RuleID]bool
	added        []wf.RuleID
	deleted      []wf.RuleID
	beforeAdd    func(*wf.Rule) error
	beforeDelete func(wf.RuleID) error
	sublayerErr  error
	sublayers    int
}

func (c *journalConnection) AddSublayer(*wf.Sublayer) error {
	c.sublayers++
	return c.sublayerErr
}
func (c *journalConnection) DeleteSublayer(wf.SublayerID) error {
	if len(c.installed) != 0 {
		return errors.New("filters still installed")
	}
	c.sublayers--
	return nil
}
func (c *journalConnection) AddRule(rule *wf.Rule) error {
	if c.beforeAdd != nil {
		if err := c.beforeAdd(rule); err != nil {
			return err
		}
	}
	c.installed[rule.ID] = true
	c.added = append(c.added, rule.ID)
	return nil
}
func (c *journalConnection) DeleteRule(id wf.RuleID) error {
	c.deleted = append(c.deleted, id)
	if c.beforeDelete != nil {
		if err := c.beforeDelete(id); err != nil {
			return err
		}
	}
	if !c.installed[id] {
		return fmt.Errorf("missing: %w", errFilterNotFound)
	}
	delete(c.installed, id)
	return nil
}

func TestStrictInstallJournalsBeforeAnyWFPChanges(t *testing.T) {
	w := &WFP{stateDir: t.TempDir(), enginesDir: t.TempDir(), policy: session.Settings{StrictKillSwitch: true, Reconnect: true}}
	old := wf.RuleID{Data1: 1}
	missing := wf.RuleID{Data1: 2}
	if err := w.saveStrictIDs([]wf.RuleID{old, missing}); err != nil {
		t.Fatal(err)
	}
	c := &journalConnection{installed: map[wf.RuleID]bool{old: true}}
	var planned []wf.RuleID
	c.beforeAdd = func(rule *wf.Rule) error {
		ids, err := w.strictIDs()
		if err != nil {
			t.Fatal(err)
		}
		if !slices.Contains(ids, old) || !slices.Contains(ids, missing) || !slices.Contains(ids, rule.ID) {
			t.Fatalf("filter is not journaled before AddRule: %v", ids)
		}
		if len(c.added) == 0 {
			planned = ids
		}
		if len(planned) <= len(c.added)+2 {
			t.Fatal("plan did not include every rule in advance")
		}
		if !rule.Persistent {
			t.Fatal("reconnect lost persistence")
		}
		if !c.installed[old] {
			t.Fatal("old block removed before replacement finished")
		}
		return nil
	}
	if err := w.installStrict(c); err != nil {
		t.Fatal(err)
	}
	ids, err := w.strictIDs()
	if err != nil || !slices.Equal(ids, c.added) {
		t.Fatalf("final record: %v, %v", ids, err)
	}
	if len(c.installed) != len(c.added) {
		t.Fatal("old filters were retained")
	}
	// A fresh process must be able to perform an explicit Disconnect.
	recovered := &WFP{stateDir: w.stateDir}
	if err := recovered.clearStrict(c, ids); err != nil {
		t.Fatal(err)
	}
	if ids, err := recovered.strictIDs(); err != nil || len(ids) != 0 || len(c.installed) != 0 {
		t.Fatalf("recovery left filters: %v, %v", ids, err)
	}
}

func TestStrictInstallRollsBackEveryFailure(t *testing.T) {
	// Cover every AddRule position, including failure to add the final block.
	probe := &WFP{enginesDir: t.TempDir(), policy: session.Settings{StrictKillSwitch: true}}
	count := 0
	if err := probe.rules(func(*wf.Rule) error { count++; return nil }, strictSublayer); err != nil {
		t.Fatal(err)
	}
	for stage := -3; stage < count; stage++ {
		t.Run(fmt.Sprint(stage), func(t *testing.T) {
			dir := t.TempDir()
			w := &WFP{stateDir: dir, enginesDir: t.TempDir(), policy: session.Settings{StrictKillSwitch: true, Reconnect: true}}
			old := wf.RuleID{Data1: 1}
			if err := w.saveStrictIDs([]wf.RuleID{old}); err != nil {
				t.Fatal(err)
			}
			c := &journalConnection{installed: map[wf.RuleID]bool{old: true}}
			injected := errors.New("injected install failure")
			switch stage {
			case -3:
				c.sublayerErr = injected
			case -2:
				c.beforeDelete = func(id wf.RuleID) error {
					if id == old {
						return injected
					}
					return nil
				}
			case -1:
				c.beforeAdd = func(*wf.Rule) error {
					if len(c.added) == count-1 {
						w.stateDir = filepath.Join(dir, "missing")
					}
					return nil
				}
			default:
				c.beforeAdd = func(*wf.Rule) error {
					if len(c.added) == stage {
						return injected
					}
					return nil
				}
			}
			if err := w.installStrict(c); err == nil {
				t.Fatal("install error hidden")
			}
			w.stateDir = dir
			for _, id := range c.added {
				if c.installed[id] {
					t.Fatal("added persistent filter survived rollback")
				}
			}
			ids, err := w.strictIDs()
			if err != nil || len(ids) != count+1 {
				t.Fatalf("recovery plan lost: %v, %v", ids, err)
			}
			// Retry cleanup from a new process, including never-installed entries.
			c.beforeDelete = nil
			recovered := &WFP{stateDir: dir}
			if err := recovered.clearStrict(c, ids); err != nil {
				t.Fatal(err)
			}
			if len(c.installed) != 0 {
				t.Fatal("Disconnect stranded filters")
			}
		})
	}
}

func TestStrictInstallCannotModifyWFPWithoutJournal(t *testing.T) {
	for _, invalid := range []string{"", "missing"} {
		w := &WFP{stateDir: invalid, enginesDir: t.TempDir(), policy: session.Settings{StrictKillSwitch: true}}
		if invalid != "" {
			w.stateDir = filepath.Join(t.TempDir(), invalid)
		}
		c := &journalConnection{installed: map[wf.RuleID]bool{}}
		if err := w.installStrict(c); err == nil {
			t.Fatal("journal error hidden")
		}
		if c.sublayers != 0 || len(c.added) != 0 {
			t.Fatal("WFP changed before journal was saved")
		}
	}
}

func TestStrictRollbackFailureRetainsJournalForDisconnect(t *testing.T) {
	w := &WFP{stateDir: t.TempDir(), enginesDir: t.TempDir(), policy: session.Settings{StrictKillSwitch: true}}
	c := &journalConnection{installed: map[wf.RuleID]bool{}}
	addErr, deleteErr := errors.New("add failed"), errors.New("rollback failed")
	c.beforeAdd = func(*wf.Rule) error {
		if len(c.added) == 2 {
			return addErr
		}
		return nil
	}
	c.beforeDelete = func(wf.RuleID) error { return deleteErr }
	err := w.installStrict(c)
	if !errors.Is(err, addErr) || !errors.Is(err, deleteErr) {
		t.Fatalf("lost install or rollback error: %v", err)
	}
	ids, err := w.strictIDs()
	if err != nil {
		t.Fatal(err)
	}
	c.beforeDelete = nil
	recovered := &WFP{stateDir: w.stateDir}
	if err := recovered.clearStrict(c, ids); err != nil {
		t.Fatal(err)
	}
	if len(c.installed) != 0 {
		t.Fatal("retry failed to remove rollback remnants")
	}
}

func TestStrictDisconnectRecoversPartiallyInstalledPlan(t *testing.T) {
	for _, installed := range []int{0, 1, 2} {
		t.Run(fmt.Sprint(installed), func(t *testing.T) {
			w := &WFP{stateDir: t.TempDir()}
			ids := []wf.RuleID{{Data1: 1}, {Data1: 2}, {Data1: 3}}
			if err := w.saveStrictIDs(ids); err != nil {
				t.Fatal(err)
			}
			c := &journalConnection{installed: map[wf.RuleID]bool{}}
			for _, id := range ids[:installed] {
				c.installed[id] = true
			}
			recovered := &WFP{stateDir: w.stateDir}
			if armed, err := recovered.Armed(t.Context()); !armed || err != nil {
				t.Fatalf("partial plan is not armed: %v", err)
			}
			recorded, err := recovered.strictIDs()
			if err != nil {
				t.Fatal(err)
			}
			if err := recovered.clearStrict(c, recorded); err != nil {
				t.Fatal(err)
			}
			if !slices.Equal(c.deleted, ids) || len(c.installed) != 0 {
				t.Fatal("Disconnect did not remove the full planned set")
			}
			if armed, err := recovered.Armed(t.Context()); armed || err != nil {
				t.Fatalf("Disconnect retained intent: %v", err)
			}
		})
	}
}

func TestStrictDisconnectRetriesFailedDeletion(t *testing.T) {
	w := &WFP{stateDir: t.TempDir()}
	ids := []wf.RuleID{{Data1: 1}, {Data1: 2}}
	if err := w.saveStrictIDs(ids); err != nil {
		t.Fatal(err)
	}
	c := &journalConnection{installed: map[wf.RuleID]bool{ids[0]: true, ids[1]: true}}
	injected := errors.New("delete failed")
	c.beforeDelete = func(id wf.RuleID) error {
		if id == ids[0] {
			return injected
		}
		return nil
	}
	if err := w.clearStrict(c, ids); !errors.Is(err, injected) {
		t.Fatalf("delete error lost: %v", err)
	}
	if c.installed[ids[1]] {
		t.Fatal("one deletion failure skipped the remaining filters")
	}
	if got, err := w.strictIDs(); err != nil || !slices.Equal(got, ids) {
		t.Fatalf("retry lost journal: %v, %v", got, err)
	}
	c.beforeDelete = nil
	if err := w.clearStrict(c, ids); err != nil {
		t.Fatal(err)
	}
}
