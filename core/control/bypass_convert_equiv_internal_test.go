package control

// M4: the two proto->engine BypassStrategy converters — ext's
// ProtoToEngineStrategy and control's bypassStrategyFromProto — must
// agree field for field. This test lives in package control because
// it is the side that may import ext, and it asserts EVERY field of
// BOTH results against a full 29-field fixture with distinctive
// values, so a drift in either converter names the field it lost.

import (
	"reflect"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/ext"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestBypassConvertersAgreeOnFullFixture(t *testing.T) {
	in := &corev1.BypassStrategy{
		SplitPos: []string{"1", "host+2"}, Disorder: true, DisorderScope: "tls",
		Oob: true, OobScope: "http", TlsRecord: "sniext+1",
		HostCase: true, DomainCase: true, MethodEol: true, HostDot: true,
		HostTab: true, HostNoSpace: true, MethodSpace: true, UnixEol: true,
		SplitAnyProtocol: true, TamperStart: "n1", TamperCutoff: "n9",
		OobData: "0x41", Mss: "1200",
		Desync: []string{"fake", "split2"}, FakeTls: "tls-custom.bin",
		FakeQuic: "quic-custom.bin", Fooling: "badseq", Ttl: 7, AutoTtl: true,
		Repeats: 3, FilterTcp: "80,443", FilterUdp: "443", FilterL7: "tls,quic",
	}
	fromExt := ext.ProtoToEngineStrategy(in)
	fromControl := bypassStrategyFromProto(in)
	if !reflect.DeepEqual(fromExt, fromControl) {
		t.Fatalf("converters disagree:\next:     %+v\ncontrol: %+v", fromExt, fromControl)
	}
	assertOne := func(label string, e engine.BypassStrategy) {
		t.Helper()
		if len(e.SplitPos) != 2 || e.SplitPos[0] != "1" || e.SplitPos[1] != "host+2" {
			t.Errorf("%s SplitPos = %v", label, e.SplitPos)
		}
		if !e.Disorder {
			t.Errorf("%s Disorder = false", label)
		}
		if e.DisorderScope != "tls" {
			t.Errorf("%s DisorderScope = %q", label, e.DisorderScope)
		}
		if !e.OOB {
			t.Errorf("%s OOB = false", label)
		}
		if e.OOBScope != "http" {
			t.Errorf("%s OOBScope = %q", label, e.OOBScope)
		}
		if e.TLSRecord != "sniext+1" {
			t.Errorf("%s TLSRecord = %q", label, e.TLSRecord)
		}
		if !e.HostCase {
			t.Errorf("%s HostCase = false", label)
		}
		if !e.DomainCase {
			t.Errorf("%s DomainCase = false", label)
		}
		if !e.MethodEOL {
			t.Errorf("%s MethodEOL = false", label)
		}
		if !e.HostDot {
			t.Errorf("%s HostDot = false", label)
		}
		if !e.HostTab {
			t.Errorf("%s HostTab = false", label)
		}
		if !e.HostNoSpace {
			t.Errorf("%s HostNoSpace = false", label)
		}
		if !e.MethodSpace {
			t.Errorf("%s MethodSpace = false", label)
		}
		if !e.UnixEOL {
			t.Errorf("%s UnixEOL = false", label)
		}
		if !e.SplitAnyProtocol {
			t.Errorf("%s SplitAnyProtocol = false", label)
		}
		if e.TamperStart != "n1" {
			t.Errorf("%s TamperStart = %q", label, e.TamperStart)
		}
		if e.TamperCutoff != "n9" {
			t.Errorf("%s TamperCutoff = %q", label, e.TamperCutoff)
		}
		if e.OOBData != "0x41" {
			t.Errorf("%s OOBData = %q", label, e.OOBData)
		}
		if e.MSS != "1200" {
			t.Errorf("%s MSS = %q", label, e.MSS)
		}
		if len(e.Desync) != 2 || e.Desync[0] != "fake" || e.Desync[1] != "split2" {
			t.Errorf("%s Desync = %v", label, e.Desync)
		}
		if e.FakeTLS != "tls-custom.bin" {
			t.Errorf("%s FakeTLS = %q", label, e.FakeTLS)
		}
		if e.FakeQUIC != "quic-custom.bin" {
			t.Errorf("%s FakeQUIC = %q", label, e.FakeQUIC)
		}
		if e.Fooling != "badseq" {
			t.Errorf("%s Fooling = %q", label, e.Fooling)
		}
		if e.TTL != 7 {
			t.Errorf("%s TTL = %d", label, e.TTL)
		}
		if !e.AutoTTL {
			t.Errorf("%s AutoTTL = false", label)
		}
		if e.AutoTTLDelta != 0 {
			t.Errorf("%s AutoTTLDelta = %d, want 0 (not a contract field)", label, e.AutoTTLDelta)
		}
		if e.Repeats != 3 {
			t.Errorf("%s Repeats = %d", label, e.Repeats)
		}
		if e.FilterTCP != "80,443" {
			t.Errorf("%s FilterTCP = %q", label, e.FilterTCP)
		}
		if e.FilterUDP != "443" {
			t.Errorf("%s FilterUDP = %q", label, e.FilterUDP)
		}
		if e.FilterL7 != "tls,quic" {
			t.Errorf("%s FilterL7 = %q", label, e.FilterL7)
		}
	}
	assertOne("ext.ProtoToEngineStrategy", fromExt)
	assertOne("control.bypassStrategyFromProto", fromControl)
}
