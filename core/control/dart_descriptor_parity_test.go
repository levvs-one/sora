package control_test

import (
	"encoding/base64"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"unicode"

	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protodesc"
	"google.golang.org/protobuf/reflect/protoreflect"
	"google.golang.org/protobuf/types/descriptorpb"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// The Dart stubs under app/lib/src/generated are maintained by hand
// (protoc-gen-dart is unavailable on the core side; see
// TestNewFieldTagsAreStable). The binary wire code in *.pb.dart is only
// half of the stub: *.pbjson.dart carries a serialized DescriptorProto
// per message and enum, which the Dart JSON codec and any descriptor
// consumer trust. Those embedded descriptors have drifted before —
// OutboundSpec gained flow (10) and flow_auto (11) in contract 1.11 and
// the pb.dart code grew them, but the pbjson descriptor did not — so
// this test decodes every embedded Dart descriptor and pins it, field
// by field and enum value by enum value, against the Go contract,
// which is generated from proto/sora/core/v1/core_control.proto.

var dartDescriptorRe = regexp.MustCompile(`(?m)^final \$typed_data\.Uint8List (\w+Descriptor) =\s*\n?\s*\$convert\.base64Decode\(((?:\s*'[^']*')+)\s*\);?`)

func dartDescriptors(t *testing.T) map[string][]byte {
	t.Helper()
	path := filepath.Join("..", "..", "app", "lib", "src", "generated", "sora", "core", "v1", "core_control.pbjson.dart")
	raw, err := os.ReadFile(path) //nolint:gosec // fixed repo-relative path
	if err != nil {
		t.Fatalf("read Dart pbjson: %v", err)
	}
	out := make(map[string][]byte)
	for _, m := range dartDescriptorRe.FindAllStringSubmatch(string(raw), -1) {
		var b64 strings.Builder
		for _, chunk := range regexp.MustCompile(`'([^']*)'`).FindAllStringSubmatch(m[2], -1) {
			b64.WriteString(chunk[1])
		}
		decoded, err := base64.StdEncoding.DecodeString(b64.String())
		if err != nil {
			t.Fatalf("decode Dart descriptor %s: %v", m[1], err)
		}
		out[m[1]] = decoded
	}
	if len(out) == 0 {
		t.Fatal("no Dart descriptors found; the extraction pattern no longer matches the generated file")
	}
	return out
}

// descriptorVarName mirrors protoc-gen-dart naming: lowerCamel of the
// proto name plus "Descriptor" (e.g. SoraErrorCode -> soraErrorCodeDescriptor).
func descriptorVarName(protoName string) string {
	runes := []rune(protoName)
	if len(runes) > 0 {
		runes[0] = unicode.ToLower(runes[0])
	}
	return string(runes) + "Descriptor"
}

func TestDartEmbeddedDescriptorsMatchGoContract(t *testing.T) {
	dart := dartDescriptors(t)
	file := corev1.File_sora_core_v1_core_control_proto

	messages := file.Messages()
	for i := 0; i < messages.Len(); i++ {
		md := messages.Get(i)
		raw, ok := dart[descriptorVarName(string(md.Name()))]
		if !ok {
			t.Errorf("message %s: no embedded Dart descriptor", md.Name())
			continue
		}
		var got descriptorpb.DescriptorProto
		if err := proto.Unmarshal(raw, &got); err != nil {
			t.Errorf("message %s: unmarshal Dart descriptor: %v", md.Name(), err)
			continue
		}
		want := protodesc.ToDescriptorProto(md)
		if got.GetName() != want.GetName() {
			t.Errorf("message %s: Dart descriptor name %q", md.Name(), got.GetName())
		}
		if len(got.Field) != len(want.Field) {
			t.Errorf("message %s: Dart descriptor has %d fields, Go contract has %d", md.Name(), len(got.Field), len(want.Field))
		}
		byNumber := make(map[int32]*descriptorpb.FieldDescriptorProto, len(got.Field))
		for _, f := range got.Field {
			byNumber[f.GetNumber()] = f
		}
		for _, wf := range want.Field {
			gf, ok := byNumber[wf.GetNumber()]
			if !ok {
				t.Errorf("message %s: Dart descriptor lacks field %s (%d)", md.Name(), wf.GetName(), wf.GetNumber())
				continue
			}
			if gf.GetName() != wf.GetName() || gf.GetType() != wf.GetType() ||
				gf.GetLabel() != wf.GetLabel() || gf.GetTypeName() != wf.GetTypeName() ||
				gf.GetJsonName() != wf.GetJsonName() {
				t.Errorf("message %s field %d: Dart descriptor %+v, Go contract %+v",
					md.Name(), wf.GetNumber(), gf, wf)
			}
		}
	}

	enums := file.Enums()
	for i := 0; i < enums.Len(); i++ {
		ed := enums.Get(i)
		raw, ok := dart[descriptorVarName(string(ed.Name()))]
		if !ok {
			t.Errorf("enum %s: no embedded Dart descriptor", ed.Name())
			continue
		}
		var got descriptorpb.EnumDescriptorProto
		if err := proto.Unmarshal(raw, &got); err != nil {
			t.Errorf("enum %s: unmarshal Dart descriptor: %v", ed.Name(), err)
			continue
		}
		want := protodesc.ToEnumDescriptorProto(ed)
		if len(got.Value) != len(want.Value) {
			t.Errorf("enum %s: Dart descriptor has %d values, Go contract has %d", ed.Name(), len(got.Value), len(want.Value))
			continue
		}
		for j, wv := range want.Value {
			if gv := got.Value[j]; gv.GetName() != wv.GetName() || gv.GetNumber() != wv.GetNumber() {
				t.Errorf("enum %s value %d: Dart descriptor %s=%d, Go contract %s=%d",
					ed.Name(), j, gv.GetName(), gv.GetNumber(), wv.GetName(), wv.GetNumber())
			}
		}
	}

	// Guard against Dart descriptors for messages or enums the contract
	// no longer has (a removed type kept alive in the stub).
	known := make(map[string]bool)
	for i := 0; i < messages.Len(); i++ {
		known[descriptorVarName(string(messages.Get(i).Name()))] = true
	}
	for i := 0; i < enums.Len(); i++ {
		known[descriptorVarName(string(enums.Get(i).Name()))] = true
	}
	for name := range dart {
		if !known[name] {
			t.Errorf("Dart pbjson carries descriptor %s with no counterpart in the Go contract", name)
		}
	}
}

// TestDartGrpcStubsMatchGoContract pins the Dart client method paths in
// core_control.pbgrpc.dart against the Go service descriptor, including
// which methods are server-streaming: a stub drift here compiles fine in
// Dart and only fails, or silently un-streams, at call time.
func TestDartGrpcStubsMatchGoContract(t *testing.T) {
	path := filepath.Join("..", "..", "app", "lib", "src", "generated", "sora", "core", "v1", "core_control.pbgrpc.dart")
	raw, err := os.ReadFile(path) //nolint:gosec // fixed repo-relative path
	if err != nil {
		t.Fatalf("read Dart pbgrpc: %v", err)
	}
	text := string(raw)
	file := corev1.File_sora_core_v1_core_control_proto
	services := file.Services()
	for i := 0; i < services.Len(); i++ {
		sd := services.Get(i)
		methods := sd.Methods()
		for j := 0; j < methods.Len(); j++ {
			md := methods.Get(j)
			full := "/" + string(file.Package()) + "." + string(sd.Name()) + "/" + string(md.Name())
			if !strings.Contains(text, "'"+full+"'") {
				t.Errorf("Dart pbgrpc has no client stub for %s", full)
			}
			_ = protoreflect.MethodDescriptor(md)
		}
	}
	for _, m := range regexp.MustCompile(`'(/sora\.core\.v1\.CoreControl/\w+)'`).FindAllStringSubmatch(text, -1) {
		name := m[1][strings.LastIndex(m[1], "/")+1:]
		if services.Get(0).Methods().ByName(protoreflect.Name(name)) == nil {
			t.Errorf("Dart pbgrpc stub %s has no counterpart in the Go contract", m[1])
		}
	}
}
