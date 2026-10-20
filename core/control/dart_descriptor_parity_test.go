package control_test

import (
	"encoding/base64"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"unicode"

	"google.golang.org/protobuf/encoding/prototext"
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
//
// Two sibling surfaces are pinned with the same strictness, because a
// drift confined to either of them compiles fine in Dart and was
// invisible to the descriptor comparison alone (S1 review mutations
// M2/M3): the $json maps in the same pbjson file (the descriptor in
// decoded, per-field form that the Dart JSON codec actually walks),
// and the server-streaming shape of the pbgrpc client stubs.

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

// lowerCamel mirrors protoc-gen-dart method naming (WatchEvents ->
// watchEvents).
func lowerCamel(protoName string) string {
	runes := []rune(protoName)
	if len(runes) > 0 {
		runes[0] = unicode.ToLower(runes[0])
	}
	return string(runes)
}

// knownDartMapEntryGaps lists the nested types whose embedded Dart
// descriptor omits options.map_entry=true even though the Go contract
// sets it. The omission is pre-existing and harmless: the Dart runtime
// never consults the embedded descriptor for map behaviour, because
// core_control.pb.dart declares both fields as maps directly in
// BuilderInfo (..m<String, String>(..., entryClassName:
// '<Message>.RenamesEntry', keyFieldType/valueFieldType OS)), so
// renames is a Map on the wire and in the API either way. Only a
// descriptor consumer reading the pbjson bytes would miss the flag.
//
// The list is a whitelist for exactly this one flag on exactly these
// types: descriptorEqualModuloKnownMapEntryGaps forgives nothing else,
// so a NEW map entry (or any other nested drift) still fails the full
// comparison, and an entry here may be deleted once the Dart stub is
// regenerated with the flag — never silently extended.
var knownDartMapEntryGaps = map[string]bool{
	"SaveSubscriptionOverrideRequest.RenamesEntry": true,
	"GetSubscriptionOverrideResponse.RenamesEntry": true,
}

// descriptorEqualModuloKnownMapEntryGaps reports whether got equals
// want as a whole DescriptorProto — nested types, oneofs, extensions,
// reserved ranges and options included — after patching, on a clone of
// got, only the whitelisted map_entry gaps above. Everything else is
// compared byte-for-byte by proto.Equal, so nested-type drift that the
// field-by-field loop (which only sees top-level fields) cannot see is
// still caught.
func descriptorEqualModuloKnownMapEntryGaps(got, want *descriptorpb.DescriptorProto) bool {
	g := proto.Clone(got).(*descriptorpb.DescriptorProto)
	forgiveMapEntryGaps(g, want, got.GetName())
	return proto.Equal(g, want)
}

func forgiveMapEntryGaps(got, want *descriptorpb.DescriptorProto, path string) {
	wantNested := make(map[string]*descriptorpb.DescriptorProto, len(want.NestedType))
	for _, n := range want.NestedType {
		wantNested[n.GetName()] = n
	}
	for _, gn := range got.NestedType {
		wn, ok := wantNested[gn.GetName()]
		if !ok {
			continue // unknown nested type: proto.Equal reports it
		}
		child := path + "." + gn.GetName()
		if knownDartMapEntryGaps[child] && wn.GetOptions().GetMapEntry() && !gn.GetOptions().GetMapEntry() {
			if gn.Options == nil {
				gn.Options = &descriptorpb.MessageOptions{}
			}
			mapEntry := true
			gn.Options.MapEntry = &mapEntry
		}
		forgiveMapEntryGaps(gn, wn, child)
	}
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
		// Strict whole-descriptor comparison: the loop above pins the
		// top-level fields, this pins everything below and beside them
		// (nested types and their fields, oneof declarations, options),
		// forgiving only the whitelisted map_entry gaps.
		if !descriptorEqualModuloKnownMapEntryGaps(&got, want) {
			t.Errorf("message %s: Dart descriptor differs from the Go contract beyond the known map_entry gaps:\nDart: %s\nGo:   %s",
				md.Name(), prototext.Format(&got), prototext.Format(want))
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
		if !proto.Equal(&got, want) {
			t.Errorf("enum %s: Dart descriptor differs from the Go contract:\nDart: %s\nGo:   %s",
				ed.Name(), prototext.Format(&got), prototext.Format(want))
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

// --- Dart $json maps (core_control.pbjson.dart) ---------------------
//
// Beside every binary descriptor, pbjson carries a decoded form of the
// same DescriptorProto as a Dart map literal:
//
//	const OutboundSpec$json = {
//	  '1': 'OutboundSpec',
//	  '2': [
//	    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
//	    ...
//	  ],
//	};
//
// Keys are DescriptorProto field numbers as strings ('1' name, '2'
// fields/values, '8' oneof_decl; per field: '1' name, '3' number, '4'
// label, '5' type, '6' type_name, '9' oneof_index, '10' json_name).
// This is the shape the Dart JSON codec walks, so a field dropped here
// (review mutation M2 dropped flow from OutboundSpec$json only) breaks
// JSON parity while the binary descriptor stays correct — hence it is
// parsed and pinned against the same Go contract, and any key this
// parser does not know how to pin fails the test instead of passing
// silently.

var dartJSONDeclRe = regexp.MustCompile(`const (\w+)\$json =`)

// dartJSONParser is a minimal recursive-descent parser for the Dart
// literal subset protoc-gen-dart emits in $json maps: single-quoted
// strings, integers, lists and string-keyed maps.
type dartJSONParser struct {
	src  string
	pos  int
	name string
}

func (p *dartJSONParser) fail(format string, args ...any) error {
	return fmt.Errorf("Dart $json %s at offset %d: %s", p.name, p.pos, fmt.Sprintf(format, args...))
}

func (p *dartJSONParser) skipWS() {
	for p.pos < len(p.src) {
		switch p.src[p.pos] {
		case ' ', '\t', '\n', '\r':
			p.pos++
		default:
			return
		}
	}
}

func (p *dartJSONParser) parseValue() (any, error) {
	p.skipWS()
	if p.pos >= len(p.src) {
		return nil, p.fail("unexpected end of input")
	}
	switch c := p.src[p.pos]; {
	case c == '{':
		return p.parseMap()
	case c == '[':
		return p.parseList()
	case c == '\'':
		return p.parseString()
	case c == '-' || (c >= '0' && c <= '9'):
		return p.parseInt()
	default:
		return nil, p.fail("unexpected character %q", c)
	}
}

func (p *dartJSONParser) parseMap() (map[string]any, error) {
	p.pos++ // consume '{'
	out := make(map[string]any)
	for {
		p.skipWS()
		if p.pos < len(p.src) && p.src[p.pos] == '}' {
			p.pos++
			return out, nil
		}
		key, err := p.parseString()
		if err != nil {
			return nil, err
		}
		p.skipWS()
		if p.pos >= len(p.src) || p.src[p.pos] != ':' {
			return nil, p.fail("expected ':' after key %q", key)
		}
		p.pos++
		val, err := p.parseValue()
		if err != nil {
			return nil, err
		}
		out[key] = val
		p.skipWS()
		if p.pos < len(p.src) && p.src[p.pos] == ',' {
			p.pos++
			continue
		}
		if p.pos < len(p.src) && p.src[p.pos] == '}' {
			p.pos++
			return out, nil
		}
		return nil, p.fail("expected ',' or '}' in map")
	}
}

func (p *dartJSONParser) parseList() ([]any, error) {
	p.pos++ // consume '['
	var out []any
	for {
		p.skipWS()
		if p.pos < len(p.src) && p.src[p.pos] == ']' {
			p.pos++
			return out, nil
		}
		val, err := p.parseValue()
		if err != nil {
			return nil, err
		}
		out = append(out, val)
		p.skipWS()
		if p.pos < len(p.src) && p.src[p.pos] == ',' {
			p.pos++
			continue
		}
		if p.pos < len(p.src) && p.src[p.pos] == ']' {
			p.pos++
			return out, nil
		}
		return nil, p.fail("expected ',' or ']' in list")
	}
}

func (p *dartJSONParser) parseString() (string, error) {
	if p.pos >= len(p.src) || p.src[p.pos] != '\'' {
		return "", p.fail("expected string")
	}
	p.pos++
	var b strings.Builder
	for p.pos < len(p.src) {
		c := p.src[p.pos]
		p.pos++
		switch c {
		case '\'':
			return b.String(), nil
		case '\\':
			if p.pos >= len(p.src) {
				return "", p.fail("unterminated escape")
			}
			esc := p.src[p.pos]
			p.pos++
			switch esc {
			case 'n':
				b.WriteByte('\n')
			case 't':
				b.WriteByte('\t')
			case 'r':
				b.WriteByte('\r')
			default: // \', \\, \$ and any other escaped char stand for themselves
				b.WriteByte(esc)
			}
		default:
			b.WriteByte(c)
		}
	}
	return "", p.fail("unterminated string")
}

func (p *dartJSONParser) parseInt() (int64, error) {
	start := p.pos
	if p.src[p.pos] == '-' {
		p.pos++
	}
	for p.pos < len(p.src) && p.src[p.pos] >= '0' && p.src[p.pos] <= '9' {
		p.pos++
	}
	n, err := strconv.ParseInt(p.src[start:p.pos], 10, 64)
	if err != nil {
		return 0, p.fail("bad integer: %v", err)
	}
	return n, nil
}

// dartJSONMaps parses every const <Name>$json literal in the Dart
// pbjson file into generic maps keyed by proto type name.
func dartJSONMaps(t *testing.T) map[string]map[string]any {
	t.Helper()
	path := filepath.Join("..", "..", "app", "lib", "src", "generated", "sora", "core", "v1", "core_control.pbjson.dart")
	raw, err := os.ReadFile(path) //nolint:gosec // fixed repo-relative path
	if err != nil {
		t.Fatalf("read Dart pbjson: %v", err)
	}
	text := string(raw)
	out := make(map[string]map[string]any)
	for _, m := range dartJSONDeclRe.FindAllStringSubmatchIndex(text, -1) {
		name := text[m[2]:m[3]]
		p := &dartJSONParser{src: text, pos: m[1], name: name}
		v, err := p.parseValue()
		if err != nil {
			t.Fatalf("parse %v", err)
		}
		top, ok := v.(map[string]any)
		if !ok {
			t.Fatalf("Dart $json %s: top level is not a map", name)
		}
		if _, dup := out[name]; dup {
			t.Fatalf("Dart pbjson declares $json for %s twice", name)
		}
		out[name] = top
	}
	if len(out) == 0 {
		t.Fatal("no Dart $json maps found; the extraction pattern no longer matches the generated file")
	}
	return out
}

func jsonStr(m map[string]any, key string) (string, bool) {
	v, ok := m[key].(string)
	return v, ok
}

func jsonInt(m map[string]any, key string) (int64, bool) {
	v, ok := m[key].(int64)
	return v, ok
}

// checkJSONKeys fails on any key outside the pinned set, so a $json
// entry that grows a component this test does not compare (a default
// value, a new option) is reported instead of silently ignored.
func checkJSONKeys(t *testing.T, where string, m map[string]any, allowed ...string) {
	t.Helper()
	ok := make(map[string]bool, len(allowed))
	for _, k := range allowed {
		ok[k] = true
	}
	for k := range m {
		if !ok[k] {
			t.Errorf("%s: $json carries unpinned key %q", where, k)
		}
	}
}

func TestDartJSONMapsMatchGoContract(t *testing.T) {
	maps := dartJSONMaps(t)
	file := corev1.File_sora_core_v1_core_control_proto

	messages := file.Messages()
	for i := 0; i < messages.Len(); i++ {
		md := messages.Get(i)
		where := "message " + string(md.Name())
		top, ok := maps[string(md.Name())]
		if !ok {
			t.Errorf("%s: no $json map in Dart pbjson", where)
			continue
		}
		checkJSONKeys(t, where, top, "1", "2", "8")
		want := protodesc.ToDescriptorProto(md)
		if name, _ := jsonStr(top, "1"); name != want.GetName() {
			t.Errorf("%s: $json name %q, Go contract %q", where, name, want.GetName())
		}

		// Fields ('2'), matched by number: $json field order is the
		// generator's, not the contract's, so order itself is not
		// pinned — membership and every attribute are.
		rawFields, _ := top["2"].([]any)
		if len(rawFields) != len(want.Field) {
			t.Errorf("%s: $json has %d fields, Go contract has %d", where, len(rawFields), len(want.Field))
		}
		byNumber := make(map[int32]map[string]any, len(rawFields))
		for _, rawField := range rawFields {
			fm, ok := rawField.(map[string]any)
			if !ok {
				t.Errorf("%s: $json field entry is not a map: %v", where, rawField)
				continue
			}
			checkJSONKeys(t, where+" field", fm, "1", "3", "4", "5", "6", "9", "10")
			num, ok := jsonInt(fm, "3")
			if !ok {
				t.Errorf("%s: $json field entry without a number: %v", where, fm)
				continue
			}
			if _, dup := byNumber[int32(num)]; dup {
				t.Errorf("%s: $json has two entries for field %d", where, num)
			}
			byNumber[int32(num)] = fm
		}
		for _, wf := range want.Field {
			gf, ok := byNumber[wf.GetNumber()]
			if !ok {
				t.Errorf("%s: $json lacks field %s (%d)", where, wf.GetName(), wf.GetNumber())
				continue
			}
			name, _ := jsonStr(gf, "1")
			label, _ := jsonInt(gf, "4")
			typ, _ := jsonInt(gf, "5")
			typeName, hasTypeName := jsonStr(gf, "6")
			jsonName, _ := jsonStr(gf, "10")
			if name != wf.GetName() || label != int64(wf.GetLabel()) || typ != int64(wf.GetType()) ||
				jsonName != wf.GetJsonName() || hasTypeName != (wf.GetTypeName() != "") || typeName != wf.GetTypeName() {
				t.Errorf("%s field %d: $json {name:%q label:%d type:%d type_name:%q json_name:%q}, Go contract %+v",
					where, wf.GetNumber(), name, label, typ, typeName, jsonName, wf)
			}
			oneof, hasOneof := jsonInt(gf, "9")
			switch {
			case wf.OneofIndex == nil && hasOneof:
				t.Errorf("%s field %d: $json puts the field in oneof %d, Go contract has no oneof", where, wf.GetNumber(), oneof)
			case wf.OneofIndex != nil && !hasOneof:
				t.Errorf("%s field %d: $json has no oneof index, Go contract has oneof %d", where, wf.GetNumber(), wf.GetOneofIndex())
			case wf.OneofIndex != nil && oneof != int64(wf.GetOneofIndex()):
				t.Errorf("%s field %d: $json oneof index %d, Go contract %d", where, wf.GetNumber(), oneof, wf.GetOneofIndex())
			}
			delete(byNumber, wf.GetNumber())
		}
		for num := range byNumber {
			t.Errorf("%s: $json carries field %d with no counterpart in the Go contract", where, num)
		}

		// Oneof declarations ('8'), in contract order.
		var gotOneofs []string
		if rawOneofs, present := top["8"]; present {
			list, ok := rawOneofs.([]any)
			if !ok {
				t.Errorf("%s: $json oneof_decl is not a list", where)
			}
			for _, rawOneof := range list {
				om, ok := rawOneof.(map[string]any)
				if !ok {
					t.Errorf("%s: $json oneof entry is not a map: %v", where, rawOneof)
					continue
				}
				checkJSONKeys(t, where+" oneof", om, "1")
				name, _ := jsonStr(om, "1")
				gotOneofs = append(gotOneofs, name)
			}
		}
		if len(gotOneofs) != len(want.OneofDecl) {
			t.Errorf("%s: $json has %d oneof declarations, Go contract has %d", where, len(gotOneofs), len(want.OneofDecl))
		} else {
			for j, wo := range want.OneofDecl {
				if gotOneofs[j] != wo.GetName() {
					t.Errorf("%s: $json oneof %d is %q, Go contract %q", where, j, gotOneofs[j], wo.GetName())
				}
			}
		}
	}

	enums := file.Enums()
	for i := 0; i < enums.Len(); i++ {
		ed := enums.Get(i)
		where := "enum " + string(ed.Name())
		top, ok := maps[string(ed.Name())]
		if !ok {
			t.Errorf("%s: no $json map in Dart pbjson", where)
			continue
		}
		checkJSONKeys(t, where, top, "1", "2")
		want := protodesc.ToEnumDescriptorProto(ed)
		if name, _ := jsonStr(top, "1"); name != want.GetName() {
			t.Errorf("%s: $json name %q, Go contract %q", where, name, want.GetName())
		}
		rawValues, _ := top["2"].([]any)
		if len(rawValues) != len(want.Value) {
			t.Errorf("%s: $json has %d values, Go contract has %d", where, len(rawValues), len(want.Value))
			continue
		}
		for j, wv := range want.Value {
			vm, ok := rawValues[j].(map[string]any)
			if !ok {
				t.Errorf("%s value %d: $json entry is not a map: %v", where, j, rawValues[j])
				continue
			}
			checkJSONKeys(t, where+" value", vm, "1", "2")
			name, _ := jsonStr(vm, "1")
			num, _ := jsonInt(vm, "2")
			if name != wv.GetName() || num != int64(wv.GetNumber()) {
				t.Errorf("%s value %d: $json %s=%d, Go contract %s=%d", where, j, name, num, wv.GetName(), wv.GetNumber())
			}
		}
	}

	// Guard against $json maps for types the contract no longer has.
	known := make(map[string]bool)
	for i := 0; i < messages.Len(); i++ {
		known[string(messages.Get(i).Name())] = true
	}
	for i := 0; i < enums.Len(); i++ {
		known[string(enums.Get(i).Name())] = true
	}
	for name := range maps {
		if !known[name] {
			t.Errorf("Dart pbjson carries $json for %s with no counterpart in the Go contract", name)
		}
	}
}

// dartClientStubRe matches a client method signature in
// core_control.pbgrpc.dart: the return kind and type, then the
// lowerCamel method name. Server-side handlers use $async.Stream and
// are not matched — the client stub is what app code calls.
var dartClientStubRe = regexp.MustCompile(`\$grpc\.(ResponseStream|ResponseFuture)<[^>]+>\s+(\w+)\(`)

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

	// Index the client stubs by Dart method name, remembering whether
	// each returns a stream or a future.
	stubs := make(map[string]string)
	for _, m := range dartClientStubRe.FindAllStringSubmatch(text, -1) {
		if prev, dup := stubs[m[2]]; dup {
			t.Errorf("Dart pbgrpc declares client stub %s twice (%s and %s)", m[2], prev, m[1])
		}
		stubs[m[2]] = m[1]
	}

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
			// Server-streaming shape: the Go contract says whether
			// the method streams; the Dart stub must return
			// ResponseStream for exactly those methods and
			// ResponseFuture for the rest. A mismatch compiles in
			// Dart and silently un-streams (or hangs) at call time
			// (review mutation M3).
			kind, ok := stubs[lowerCamel(string(md.Name()))]
			if !ok {
				t.Errorf("Dart pbgrpc has no client method for %s", full)
				continue
			}
			wantKind := "ResponseFuture"
			if md.IsStreamingServer() {
				wantKind = "ResponseStream"
			}
			if kind != wantKind {
				t.Errorf("Dart pbgrpc stub %s returns %s, Go contract server-streaming=%v wants %s",
					md.Name(), kind, md.IsStreamingServer(), wantKind)
			}
			if md.IsStreamingClient() {
				t.Errorf("Go contract method %s is client-streaming; the Dart stub shape is not pinned for that, extend this test", md.Name())
			}
		}
	}
	for _, m := range regexp.MustCompile(`'(/sora\.core\.v1\.CoreControl/\w+)'`).FindAllStringSubmatch(text, -1) {
		name := m[1][strings.LastIndex(m[1], "/")+1:]
		if services.Get(0).Methods().ByName(protoreflect.Name(name)) == nil {
			t.Errorf("Dart pbgrpc stub %s has no counterpart in the Go contract", m[1])
		}
	}
	// Reverse guard for the signature index: no Dart client stub
	// without a Go method behind it.
	for name, kind := range stubs {
		found := false
		for i := 0; i < services.Len() && !found; i++ {
			methods := services.Get(i).Methods()
			for j := 0; j < methods.Len(); j++ {
				if lowerCamel(string(methods.Get(j).Name())) == name {
					found = true
					break
				}
			}
		}
		if !found {
			t.Errorf("Dart pbgrpc client stub %s (%s) has no counterpart in the Go contract", name, kind)
		}
	}
}
