package control_test

import (
	"strings"
	"testing"

	"google.golang.org/protobuf/reflect/protoreflect"

	"github.com/levvs-one/sora-client/core/control"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestNegotiate(t *testing.T) {
	tests := []struct {
		name    string
		client  *corev1.ApiVersion
		server  *corev1.ApiVersion
		want    uint32
		wantErr bool
	}{
		{"highest common minor", &corev1.ApiVersion{Major: 1, Minor: 4}, &corev1.ApiVersion{Major: 1, Minor: 3}, 3, false},
		{"minimum bounds", &corev1.ApiVersion{Major: 1, Minor: 4, MinSupportedMinor: 2}, &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 1}, 3, false},
		{"no common minor", &corev1.ApiVersion{Major: 1, Minor: 1}, &corev1.ApiVersion{Major: 1, Minor: 3, MinSupportedMinor: 2}, 0, true},
		{"major mismatch", &corev1.ApiVersion{Major: 1}, &corev1.ApiVersion{Major: 2}, 0, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := control.Negotiate(tt.client, tt.server)
			if (err != nil) != tt.wantErr || got != tt.want {
				t.Fatalf("Negotiate() = (%d, %v), want (%d, error=%v)", got, err, tt.want, tt.wantErr)
			}
		})
	}
}

func TestCoreEventPayloadKinds(t *testing.T) {
	// CoreEvent fields: 4=StateChanged, 5=StatsTick,
	// 6=BypassStrategyChanged, 7=ProbeResult, 8=LogBatch, 9=SoraError,
	// 10=KillSwitchChanged, 11=GroupSwitched, 12=ProfileMatched,
	ones := []protoreflect.FieldNumber{4, 5, 6, 7, 8, 9, 10, 11, 12}
	message := (&corev1.CoreEvent{}).ProtoReflect().Descriptor().Oneofs().Get(0)
	if message.Fields().Len() != len(ones) {
		t.Fatalf("payload has %d fields, want %d", message.Fields().Len(), len(ones))
	}
	for _, number := range ones {
		if message.Fields().ByNumber(number) == nil {
			t.Fatalf("payload field %d is missing", number)
		}
	}
}

// TestNewFieldTagsAreStable pins the wire tags of every field added in
// contract 1.8-1.10. Tags are the wire identity: renumbering one silently
// breaks generated clients. Add new fields with new tags only.
func TestNewFieldTagsAreStable(t *testing.T) {
	file := (&corev1.CoreEvent{}).ProtoReflect().Descriptor().ParentFile()
	want := map[string]map[string]protoreflect.FieldNumber{
		"SessionPlan": {
			"tun_stack": 14, "chain": 15, "zapret_with_vpn": 16, "zapret_strategy": 17,
		},
		"CheckDnsLeaksRequest":  {"api_version": 1, "control_authenticator": 2, "session_id": 3},
		"CheckDnsLeaksResponse": {"checks": 1, "error": 2},
		"DnsLeakCheck": {
			"id": 1, "label": 2, "expected": 3, "actual": 4, "leaked": 5, "fix_hint": 6,
		},
		"BenchmarkServersRequest": {
			"api_version": 1, "control_authenticator": 2, "request_id": 3,
			"server_ids": 4, "duration_s": 5, "concurrency": 6, "url": 7,
		},
		"BandwidthSample": {
			"server_id": 1, "bytes_per_sec": 2, "progress_pct": 3, "done": 4, "error": 5,
		},
		"GetBenchmarksRequest":  {"api_version": 1, "control_authenticator": 2, "server_ids": 3},
		"GetBenchmarksResponse": {"benchmarks": 1, "error": 2},
		"BenchmarkRecord": {
			"server_id": 1, "bytes_per_sec": 2, "latency_ms": 3, "measured_at_unix": 4,
		},
		"SaveSubscriptionOverrideRequest": {
			"api_version": 1, "control_authenticator": 2, "subscription_id": 3,
			"renames": 4, "hidden": 5, "pinned_order": 6, "clear": 7,
		},
		"SaveSubscriptionOverrideResponse": {"error": 1, "state": 2},
		"GetSubscriptionOverrideRequest": {
			"api_version": 1, "control_authenticator": 2, "subscription_id": 3,
		},
		"GetSubscriptionOverrideResponse": {
			"renames": 1, "hidden": 2, "pinned_order": 3, "extra_rules": 4, "error": 5,
		},
		"OverrideRule":   {"destination": 1, "outbound_id": 2},
		"ProfileMatched": {"profile_id": 1, "profile_name": 2, "auto_apply": 3},
		"NetworkProfile": {
			"id": 1, "name": 2, "triggers": 3, "apply": 4, "auto_apply": 5,
		},
		"ProfileTriggers": {"ssids": 1, "gateways": 2, "asns": 3},
		"ProfileApply": {
			"mode": 1, "dns": 2, "rules_preset": 3, "server_id": 4, "engine": 5,
		},
		"ListProfilesRequest":  {"api_version": 1, "control_authenticator": 2},
		"ListProfilesResponse": {"profiles": 1, "error": 2},
		"SaveProfileRequest": {
			"api_version": 1, "control_authenticator": 2, "profile": 3,
		},
		"SaveProfileResponse":           {"profile": 1, "error": 2},
		"DeleteProfileRequest":          {"api_version": 1, "control_authenticator": 2, "profile_id": 3},
		"DeleteProfileResponse":         {"error": 1},
		"GetNetworkFingerprintRequest":  {"api_version": 1, "control_authenticator": 2},
		"GetNetworkFingerprintResponse": {"fingerprint": 1, "error": 2},
		"NetworkFingerprint":            {"ssid": 1, "gateway": 2, "asn": 3, "fingerprint": 4},
		"ProbeChainRequest": {
			"api_version": 1, "control_authenticator": 2, "request_id": 3, "server_ids": 4,
		},
		"ProbeChainResponse": {
			"hops": 1, "total_latency_ms": 2, "engines": 3, "error": 4,
		},
		"ChainHop": {"server_id": 1, "reachable": 2, "latency_ms": 3},
	}
	for msgName, fields := range want {
		msg := file.Messages().ByName(protoreflect.Name(msgName))
		if msg == nil {
			t.Errorf("message %s is missing from the contract", msgName)
			continue
		}
		for fieldName, number := range fields {
			fd := msg.Fields().ByName(protoreflect.Name(fieldName))
			if fd == nil {
				t.Errorf("%s.%s is missing from the contract", msgName, fieldName)
				continue
			}
			if fd.Number() != number {
				t.Errorf("%s.%s is tag %d, want %d", msgName, fieldName, fd.Number(), number)
			}
		}
	}
}

func TestSoraErrorIsRedacted(t *testing.T) {
	fields := (&corev1.SoraError{}).ProtoReflect().Descriptor().Fields()
	for i := 0; i < fields.Len(); i++ {
		if fields.Get(i).Name() == "detail" || fields.Get(i).Name() == "raw_detail" {
			t.Fatalf("SoraError contains an unredacted detail field: %s", fields.Get(i).Name())
		}
	}
}

// TestSecretMaterialHasExactlyOneCarrier checks that only PutSecret carries
// credentials, exactly once. Other methods use references and cannot expose
// stored material.
func TestSecretMaterialHasExactlyOneCarrier(t *testing.T) {
	service := (&corev1.HandshakeRequest{}).ProtoReflect().Descriptor().ParentFile().Services().ByName("CoreControl")
	if service == nil {
		t.Fatal("the contract has no CoreControl service")
	}
	carriers := make([]string, 0, 1)
	methods := service.Methods()
	for i := range methods.Len() {
		method := methods.Get(i)
		input := method.Input()
		if input.Fields().ByName("material") != nil {
			carriers = append(carriers, string(method.Name()))
			continue
		}
		if input.Fields().ByName("payload") != nil {
			// Import and fetch carry subscription bodies for
			// parsing into references, not separate credential
			// fields.
			continue
		}
	}
	if len(carriers) != 1 || carriers[0] != "PutSecret" {
		t.Fatalf("credential material is carried by %v, want exactly PutSecret", carriers)
	}
}

// TestErrorCodesAreUniqueAndNamed checks that wire error codes have unique
// numbers and an identifying prefix.
func TestErrorCodesAreUniqueAndNamed(t *testing.T) {
	codes := corev1.SoraErrorCode_name
	seen := make(map[int32]string, len(codes))
	for number, name := range codes {
		if number == 0 {
			if name != "SORA_ERROR_CODE_UNSPECIFIED" {
				t.Errorf("the zero code is %q", name)
			}
			continue
		}
		if !strings.HasPrefix(name, "SORA_ERROR_CODE_") {
			t.Errorf("code %d is named %q without the enum prefix", number, name)
		}
		if other, dup := seen[number]; dup {
			t.Errorf("code %d is used by both %q and %q", number, other, name)
		}
		seen[number] = name
	}
	for _, want := range []string{
		"SORA_ERROR_CODE_VERSION_MISMATCH",
		"SORA_ERROR_CODE_UNAUTHENTICATED",
		"SORA_ERROR_CODE_PERMISSION_DENIED",
		"SORA_ERROR_CODE_CANCELLED",
	} {
		if _, ok := codes[corev1.SoraErrorCode_value[want]]; !ok {
			t.Errorf("the contract has no %s", want)
		}
	}
}

func TestExcludedCoreFieldsStayReserved(t *testing.T) {
	for _, check := range []struct {
		message protoreflect.MessageDescriptor
		number  protoreflect.FieldNumber
		name    protoreflect.Name
	}{
		{(&corev1.CoreEvent{}).ProtoReflect().Descriptor(), 13, "censorship_detected"},
		{(&corev1.OutboundSpec{}).ProtoReflect().Descriptor(), 10, "flow"},
		{(&corev1.OutboundSpec{}).ProtoReflect().Descriptor(), 11, "flow_auto"},
	} {
		if !check.message.ReservedRanges().Has(check.number) || !check.message.ReservedNames().Has(check.name) {
			t.Errorf("%s.%s (%d) is not reserved", check.message.FullName(), check.name, check.number)
		}
	}
}
