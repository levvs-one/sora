package guard

import (
	"context"
	"encoding/json"
	"errors"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/session"
)

type intentFirewall struct {
	armed  bool
	fail   bool
	policy session.Settings
}

func (f *intentFirewall) Arm(context.Context, []uint16) error { f.armed = true; return nil }
func (f *intentFirewall) Disarm(context.Context) error {
	if f.fail {
		return errors.New("firewall unavailable")
	}
	f.armed = false
	return nil
}
func (f *intentFirewall) Armed(context.Context) (bool, error) { return f.armed, nil }
func (f *intentFirewall) SetPolicy(s session.Settings)        { f.policy = s }

func TestStrictIntentLifecycle(t *testing.T) {
	ctx := t.Context()
	dir := t.TempDir()
	opts := Options{DataDir: dir, EnginePorts: []uint16{7890}}
	firewall := &intentFirewall{}
	first, err := New(opts, firewall)
	if err != nil {
		t.Fatal(err)
	}
	settings := session.Settings{StrictKillSwitch: true, Reconnect: true, Endpoints: []session.Endpoint{{Address: netip.MustParseAddrPort("203.0.113.2:443"), Protocol: "tcp"}}}
	if err := first.Apply(ctx, settings); err != nil {
		t.Fatal(err)
	}
	if err := first.Restore(ctx); err != nil {
		t.Fatal(err)
	}
	if !firewall.armed {
		t.Fatal("shutdown lifted strict protection")
	}
	recovered, _ := New(opts, firewall)
	if err := recovered.Recover(ctx); err != nil {
		t.Fatal(err)
	}
	if !recovered.Current().StrictKillSwitch || !firewall.policy.Reconnect {
		t.Fatal("restart lost protection")
	}
	firewall.fail = true
	if err := recovered.Release(ctx); err == nil {
		t.Fatal("cleanup failure was hidden")
	}
	// A crash after recording Disconnect must retry cleanup, never rearm.
	firewall.fail = false
	afterCrash, _ := New(opts, firewall)
	if err := afterCrash.Recover(ctx); err != nil {
		t.Fatal(err)
	}
	if firewall.armed || afterCrash.Current().KillSwitch {
		t.Fatal("disconnect was undone on restart")
	}
	if err := afterCrash.Release(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestStrictRebootRequiresReconnect(t *testing.T) {
	for _, reconnect := range []bool{false, true} {
		t.Run(map[bool]string{false: "off", true: "on"}[reconnect], func(t *testing.T) {
			dir := t.TempDir()
			data, err := json.Marshal(strictIntent{Boot: "a previous boot", Settings: session.Settings{StrictKillSwitch: true, Reconnect: reconnect}})
			if err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(filepath.Join(dir, "strict-killswitch.json"), data, 0600); err != nil {
				t.Fatal(err)
			}
			f := &intentFirewall{armed: true}
			g, _ := New(Options{DataDir: dir, EnginePorts: []uint16{7890}}, f)
			if err := g.Recover(t.Context()); err != nil {
				t.Fatal(err)
			}
			if f.armed != reconnect {
				t.Fatalf("armed=%v, reconnect=%v", f.armed, reconnect)
			}
		})
	}
}

func TestStrictRulesExemptOnlyRecovery(t *testing.T) {
	policy := session.Settings{StrictKillSwitch: true, Endpoints: []session.Endpoint{{Address: netip.MustParseAddrPort("203.0.113.2:443"), Protocol: "tcp"}, {Address: netip.MustParseAddrPort("[2001:db8::2]:8443"), Protocol: "udp"}}}
	rules := StrictNftRuleset(999, policy)
	for _, required := range []string{"meta skuid 999 ip daddr 203.0.113.2 tcp dport 443 accept", "meta skuid 999 ip6 daddr 2001:db8::2 udp dport 8443 accept", "udp sport 68 udp dport 67", "icmpv6 type", "hoplimit 255", "meta skuid 999 meta l4proto"} {
		if !strings.Contains(rules, required) {
			t.Fatalf("missing %s", required)
		}
	}
	for _, forbidden := range []string{"meta skuid 999 accept", "ct direction reply", "ip daddr 192.168.0.0/16 accept", "ip6 daddr fe80::/10 accept"} {
		if strings.Contains(rules, forbidden) {
			t.Fatalf("unsafe permit %s", forbidden)
		}
	}
	policy.AllowLAN = true
	if !strings.Contains(StrictNftRuleset(999, policy), "ip daddr 192.168.0.0/16 accept") {
		t.Fatal("explicit LAN permission lost")
	}
}

func TestStrictLegacyEndpointRecoveryFailsClosed(t *testing.T) {
	var settings session.Settings
	if err := json.Unmarshal([]byte(`{"StrictKillSwitch":true,"Endpoints":["203.0.113.2:443"]}`), &settings); err != nil {
		t.Fatal(err)
	}
	rules := StrictNftRuleset(999, settings)
	if strings.Contains(rules, "203.0.113.2") || !strings.Contains(rules, "counter drop") {
		t.Fatal("legacy intent granted an unknown endpoint transport")
	}
	settings.Endpoints[0].Protocol = "tcp, udp"
	if strings.Contains(StrictNftRuleset(999, settings), "203.0.113.2") {
		t.Fatal("unknown protocol allowed")
	}
}
