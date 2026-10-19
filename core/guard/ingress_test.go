package guard_test

import (
	"context"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/guard"
)

func TestDefaultIngressConfigIsOnWithLocalTrafficKept(t *testing.T) {
	cfg := guard.DefaultIngressConfig()
	if !cfg.Enabled {
		t.Error("ingress protection must be on by default")
	}
	if !cfg.AllowLoopback {
		t.Error("loopback must be kept by default")
	}
	if !cfg.AllowLAN {
		t.Error("LAN must be kept by default")
	}
}

func TestNftIngressRulesetOrdersAcceptsBeforeTheDrop(t *testing.T) {
	cfg := guard.DefaultIngressConfig()
	cfg.VPNEndpoints = []string{"203.0.113.7", "[2001:db8::7]:443"}
	ruleset, err := guard.NftIngressRuleset(cfg, []string{"192.168.0.0/16"})
	if err != nil {
		t.Fatalf("NftIngressRuleset() error = %v", err)
	}
	wants := []string{
		"table inet sora_ingress {",
		"chain ingress {",
		"type filter hook input priority filter;",
		`iif "lo" accept`,
		`iifname "sora0" accept`,
		"ct state established,related accept",
		"ip saddr 203.0.113.7 accept",
		"ip6 saddr 2001:db8::7 accept",
		"ip saddr 192.168.0.0/16 accept",
		"counter drop",
	}
	for _, want := range wants {
		if !strings.Contains(ruleset, want) {
			t.Errorf("the ruleset does not contain %q:\n%s", want, ruleset)
		}
	}
	// Every accept must precede the final drop, and the drop must be the
	// last rule in the chain.
	drop := strings.LastIndex(ruleset, "counter drop")
	for _, accept := range wants[:len(wants)-1] {
		if i := strings.Index(ruleset, accept); i < 0 || i > drop {
			t.Errorf("%q is not before the final drop", accept)
		}
	}
	if tail := strings.TrimSpace(ruleset[strings.LastIndex(ruleset, "counter drop"):]); !strings.HasPrefix(tail, "counter drop comment") {
		t.Errorf("the drop is not the final rule: %q", tail)
	}
}

// TestNftIngressRulesetNeverDropsEstablished is the negative case the owner
// cares about: the only drop in the ruleset is the final one, and
// established/related traffic is accepted before it.
func TestNftIngressRulesetNeverDropsEstablished(t *testing.T) {
	ruleset, err := guard.NftIngressRuleset(guard.DefaultIngressConfig(), nil)
	if err != nil {
		t.Fatalf("NftIngressRuleset() error = %v", err)
	}
	// "drop" also appears inside the final rule's comment; count the
	// action itself.
	if n := strings.Count(ruleset, "counter drop"); n != 1 {
		t.Fatalf("the ruleset has %d drops, want exactly the final one:\n%s", n, ruleset)
	}
	established := strings.Index(ruleset, "ct state established,related accept")
	drop := strings.Index(ruleset, "counter drop")
	if established < 0 || established > drop {
		t.Fatal("established/related traffic is not accepted before the drop")
	}
}

func TestNftIngressRulesetKeepsPrivateSpaceByDefault(t *testing.T) {
	ruleset, err := guard.NftIngressRuleset(guard.DefaultIngressConfig(), nil)
	if err != nil {
		t.Fatalf("NftIngressRuleset() error = %v", err)
	}
	for _, network := range []string{"10.0.0.0/8", "192.168.0.0/16", "169.254.0.0/16", "fe80::/10"} {
		if !strings.Contains(ruleset, "saddr "+network+" accept") {
			t.Errorf("the ruleset does not keep inbound from %s reachable", network)
		}
	}
}

func TestNftIngressRulesetWithoutLANSkipsLocalAccepts(t *testing.T) {
	cfg := guard.DefaultIngressConfig()
	cfg.AllowLAN = false
	ruleset, err := guard.NftIngressRuleset(cfg, []string{"192.168.0.0/16"})
	if err != nil {
		t.Fatalf("NftIngressRuleset() error = %v", err)
	}
	if strings.Contains(ruleset, "192.168.0.0/16") {
		t.Error("LAN accept leaked into a config with AllowLAN=false")
	}
	// Loopback and established must survive regardless.
	for _, want := range []string{`iif "lo" accept`, "ct state established,related accept"} {
		if !strings.Contains(ruleset, want) {
			t.Errorf("the ruleset lost %q with AllowLAN=false", want)
		}
	}
}

func TestNftIngressRulesetRejectsBadEndpoints(t *testing.T) {
	for _, bad := range []string{
		"not-an-ip",
		"example.com",
		"203.0.113.7; echo pwned",
		"203.0.113.7\nadd rule inet sora_ingress ingress accept",
		"203.0.113.7:99999",
		"",
		"   ",
	} {
		cfg := guard.DefaultIngressConfig()
		cfg.VPNEndpoints = []string{bad}
		if _, err := guard.NftIngressRuleset(cfg, nil); err == nil {
			t.Errorf("NftIngressRuleset() accepted the endpoint %q", bad)
		}
	}
}

func TestNftIngressRemoveNamesTheOwnedTable(t *testing.T) {
	if got := strings.TrimSpace(guard.NftIngressRemove()); got != "delete table inet sora_ingress" {
		t.Errorf("NftIngressRemove() = %q", got)
	}
}

// fakeFirewall is a Firewall test double recording calls.
type fakeFirewall struct {
	armPorts [][]uint16
	disarms  int
	armErr   error
	armed    bool
}

func (f *fakeFirewall) Arm(_ context.Context, ports []uint16) error {
	f.armPorts = append(f.armPorts, ports)
	if f.armErr != nil {
		return f.armErr
	}
	f.armed = true
	return nil
}

func (f *fakeFirewall) Disarm(_ context.Context) error {
	f.disarms++
	f.armed = false
	return nil
}

func (f *fakeFirewall) Armed(_ context.Context) (bool, error) { return f.armed, nil }

func TestIngressFirewallDelegatesToTheInnerFirewall(t *testing.T) {
	inner := &fakeFirewall{}
	// Disabled here: fakeFirewall is neither Nftables nor NoopFirewall,
	// and an enabled config over an unknown firewall type must fail
	// closed (covered by the Linux backend test with a real Nftables).
	cfg := guard.DefaultIngressConfig()
	cfg.Enabled = false
	decorated := guard.WithIngress(inner, cfg)
	ctx := context.Background()
	ports := []uint16{7890}
	if err := decorated.Arm(ctx, ports); err != nil {
		t.Fatalf("Arm() error = %v", err)
	}
	if len(inner.armPorts) != 1 || len(inner.armPorts[0]) != 1 || inner.armPorts[0][0] != 7890 {
		t.Errorf("inner Arm did not receive the engine ports: %v", inner.armPorts)
	}
	if armed, _ := decorated.Armed(ctx); !armed {
		t.Error("Armed() = false after Arm")
	}
	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() error = %v", err)
	}
	if inner.disarms != 1 {
		t.Errorf("inner Disarm calls = %d, want 1", inner.disarms)
	}
	if armed, err := decorated.IngressArmed(ctx); err != nil || armed {
		t.Errorf("IngressArmed() = %v, %v after Disarm", armed, err)
	}
}

// TestIngressFirewallDisabledSkipsTheRules locks the "выключаемо"
// requirement: with Enabled=false the kill switch still arms, but no
// ingress state is recorded and a second Disarm stays safe.
func TestIngressFirewallDisabledSkipsTheRules(t *testing.T) {
	inner := &fakeFirewall{}
	cfg := guard.DefaultIngressConfig()
	cfg.Enabled = false
	decorated := guard.WithIngress(inner, cfg)
	ctx := context.Background()
	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() error = %v", err)
	}
	if !inner.armed {
		t.Error("the kill switch did not arm with ingress disabled")
	}
	if armed, err := decorated.IngressArmed(ctx); err != nil || armed {
		t.Errorf("IngressArmed() = %v, %v with ingress disabled", armed, err)
	}
	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() error = %v", err)
	}
	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("second Disarm() error = %v", err)
	}
}

// TestIngressFirewallInnerFailureArmsNothing locks fail-closed ordering:
// when the kill switch refuses to arm, the decorator must not report
// ingress as armed.
func TestIngressFirewallInnerFailureArmsNothing(t *testing.T) {
	inner := &fakeFirewall{armErr: context.DeadlineExceeded}
	decorated := guard.WithIngress(inner, guard.DefaultIngressConfig())
	if err := decorated.Arm(context.Background(), nil); err == nil {
		t.Fatal("Arm() succeeded while the inner firewall failed")
	}
	// The fake firewall has no ingress backend on this platform, so only
	// the "not armed" half of the answer is asserted.
	if armed, _ := decorated.IngressArmed(context.Background()); armed {
		t.Error("IngressArmed() = true after a failed Arm")
	}
}

// TestIngressFirewallOnNoopPlatform is the Android/VpnService shape:
// PlatformFirewall returns NoopFirewall where the OS owns the tunnel, and
// ingress must be a no-op rather than an error.
func TestIngressFirewallOnNoopPlatform(t *testing.T) {
	decorated := guard.WithIngress(nil, guard.DefaultIngressConfig())
	ctx := context.Background()
	if err := decorated.Arm(ctx, nil); err != nil {
		t.Fatalf("Arm() over NoopFirewall error = %v", err)
	}
	if err := decorated.Disarm(ctx); err != nil {
		t.Fatalf("Disarm() over NoopFirewall error = %v", err)
	}
}

// TestNftIngressReplaceIsASingleBatch pins the atomic install: the delete
// and the new table must travel in one nft batch so re-arming never leaves
// a window with the ingress table absent.
func TestNftIngressReplaceIsASingleBatch(t *testing.T) {
	batch, err := guard.NftIngressReplace(guard.DefaultIngressConfig(), nil)
	if err != nil {
		t.Fatalf("NftIngressReplace() error = %v", err)
	}
	if !strings.Contains(batch, "delete table inet sora_ingress\ntable inet sora_ingress {") {
		t.Errorf("the replace batch does not delete-then-install in one go:\n%s", batch)
	}
	if n := strings.Count(batch, "counter drop"); n != 1 {
		t.Errorf("the replace batch has %d drops, want exactly the final one", n)
	}
}

// TestIngressFirewallValidatesBeforeArmingInner locks the fail-closed
// ordering: a bad endpoint must fail before the kill switch is touched, so
// a config error can never leave the kill switch armed behind an error.
func TestIngressFirewallValidatesBeforeArmingInner(t *testing.T) {
	inner := &fakeFirewall{}
	cfg := guard.DefaultIngressConfig()
	cfg.VPNEndpoints = []string{"not-an-ip"}
	decorated := guard.WithIngress(inner, cfg)
	if err := decorated.Arm(context.Background(), nil); err == nil {
		t.Fatal("Arm() succeeded with an invalid VPN endpoint")
	}
	if len(inner.armPorts) != 0 {
		t.Error("the inner firewall was armed before the config was validated")
	}
	// The fake firewall has no ingress backend on this platform, so only
	// the "not armed" half of the answer is asserted.
	if armed, _ := decorated.IngressArmed(context.Background()); armed {
		t.Error("IngressArmed() = true after a failed Arm")
	}
	if inner.armed {
		t.Error("the kill switch stayed armed after a config failure")
	}
}
