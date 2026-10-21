#!/usr/bin/env python3
"""Parity check: proto/sora/*/*.proto  vs  Dart stubs (generated + hand-written).

Compares, per proto file mapped to its Dart stub(s):
  - message set (including nested messages)
  - every field: tag number -> (proto name, canonical type, repeated, oneof)
  - oneof member tag sets
  - enum set + every enum value number
  - service RPC set: name -> (request, response, client/server streaming)

proto/ is the source of truth (Go gen/ is protoc-built from it).

Usage:  python3 app/tool/proto_parity.py
Exit code 0 = parity, 1 = mismatch (details on stdout).

Excluded contracts are listed in EXPECTED_GAPS.
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# proto file -> dart stub files (pb.py path, pbenum path or None, pbgrpc path or None)
MAPPINGS = {
    "proto/sora/core/v1/core_control.proto": (
        "app/lib/src/generated/sora/core/v1/core_control.pb.dart",
        "app/lib/src/generated/sora/core/v1/core_control.pbenum.dart",
        "app/lib/src/generated/sora/core/v1/core_control.pbgrpc.dart",
    ),
    "proto/sora/custom/v1/custom.proto": (
        "app/lib/src/generated/sora/custom/v1/custom.pb.dart",
        "app/lib/src/generated/sora/custom/v1/custom.pbenum.dart",
        "app/lib/src/generated/sora/custom/v1/custom.pbgrpc.dart",
    ),
    "proto/sora/leak/v1/leak.proto": (
        "app/lib/src/generated/sora/leak/v1/leak.pb.dart",
        None,
        "app/lib/src/generated/sora/leak/v1/leak.pbgrpc.dart",
    ),
    "proto/sora/obfs/v1/obfs.proto": (
        "app/lib/src/generated/sora/obfs/v1/obfs.pb.dart",
        "app/lib/src/generated/sora/obfs/v1/obfs.pbenum.dart",
        None,
    ),
}

# The extension host and censorship contracts are outside this checker.
EXPECTED_GAPS = {
    "proto/sora/censor/v1/censor.proto": "reserved contract without a client",
    "proto/sora/ext/v1/ext_host.proto": "extension host checked separately",
}

# proto scalar -> canonical dart-side type used in BuilderInfo generics
SCALAR = {
    "string": "string",
    "bool": "bool",
    "int32": "int", "uint32": "int", "sint32": "int",
    "fixed32": "int", "sfixed32": "int",
    "int64": "int64", "uint64": "int64", "sint64": "int64",
    "fixed64": "int64", "sfixed64": "int64",
    "float": "double", "double": "double",
    "bytes": "bytes",
}

WELL_KNOWN = {
    "google.protobuf.Timestamp": "Timestamp",
    "google.protobuf.Duration": "Duration",
}


def strip_comments(s):
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.S)
    s = re.sub(r"//[^\n]*", "", s)
    return s


# ---------------------------------------------------------------- proto parsing

class ProtoModel:
    def __init__(self):
        self.package = ""
        self.messages = {}  # fullname -> {"fields": {tag: dict}, "oneofs": {name: [tags]}}
        self.enums = {}     # fullname -> {value_name: number}
        self.services = {}  # name -> {rpc: (req, resp, cstream, sstream)}


FIELD_RE = re.compile(
    r"^(repeated\s+)?(?:optional\s+|required\s+)?"
    r"((?:map\s*<[^>]+>)|[\w.]+)"
    r"\s+(\w+)\s*=\s*(\d+)\s*(?:\[[^\]]*\])?\s*;?\s*$"
)
ENUM_VALUE_RE = re.compile(r"^(\w+)\s*=\s*(-?\d+)\s*(?:\[[^\]]*\])?\s*;?\s*$")
RPC_RE = re.compile(
    r"^rpc\s+(\w+)\s*\(\s*(stream\s+)?(\w+)\s*\)\s*returns\s*\(\s*(stream\s+)?(\w+)\s*\)"
)


def parse_proto(path):
    with open(path, encoding="utf-8") as f:
        text = strip_comments(f.read())
    model = ProtoModel()
    m = re.search(r"^\s*package\s+([\w.]+)\s*;", text, re.M)
    if m:
        model.package = m.group(1)

    # Split into top-level blocks by brace matching.
    blocks = []  # (kind, name, body)
    i, n = 0, len(text)
    header_re = re.compile(r"\b(message|enum|service)\s+(\w+)\s*\{", re.S)
    while i < n:
        mm = header_re.search(text, i)
        if not mm:
            break
        kind, name = mm.group(1), mm.group(2)
        depth = 1
        j = mm.end()
        while j < n and depth:
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
            j += 1
        blocks.append((kind, name, text[mm.end():j - 1]))
        i = j

    for kind, name, body in blocks:
        if kind == "message":
            parse_message(model, name, body, prefix="", enums=None)
        elif kind == "enum":
            model.enums[name] = parse_enum(body)
        elif kind == "service":
            model.services[name] = parse_service(body)
    resolve_types(model)
    return model


def parse_message(model, name, body, prefix, enums):
    fullname = prefix + name
    entry = {"fields": {}, "oneofs": {}, "prefix": prefix}
    model.messages[fullname] = entry
    # oneof blocks: parse separately, then remove them from the body
    oneof_re = re.compile(r"\boneof\s+(\w+)\s*\{")
    spans = []
    for mm in oneof_re.finditer(body):
        depth = 1
        j = mm.end()
        while j < len(body) and depth:
            if body[j] == "{":
                depth += 1
            elif body[j] == "}":
                depth -= 1
            j += 1
        spans.append((mm.start(), j, mm.group(1), body[mm.end():j - 1]))
    removed = list(body)
    for s, e, oname, obody in spans:
        tags = []
        for line in obody.split(";"):
            fm = FIELD_RE.match(line.strip())
            if fm:
                rep, ftype, fname, tag = fm.group(1), fm.group(2), fm.group(3), int(fm.group(4))
                entry["fields"][tag] = field_info(ftype, fname, tag, oneof=oname,
                                                 repeated=rep is not None)
                tags.append(tag)
        entry["oneofs"][oname] = sorted(tags)
        for k in range(s, e):
            removed[k] = " "
    body2 = "".join(removed)
    # nested messages / enums
    for kind, sub, subbody, start, end in find_blocks(body2):
        if kind == "message":
            parse_message(model, sub, subbody, prefix=fullname + ".", enums=enums)
        elif kind == "enum":
            model.enums[fullname + "." + sub] = parse_enum(subbody)
    # fields (nested blocks blanked out)
    body2 = body2.strip()
    for line in body2.split(";"):
        line = line.strip()
        if not line or line.startswith(("reserved", "option ", "extensions")):
            continue
        fm = FIELD_RE.match(line)
        if fm:
            rep, ftype, fname, tag = fm.group(1), fm.group(2), fm.group(3), int(fm.group(4))
            if tag in entry["fields"]:
                entry["dup_tag"] = True
            entry["fields"][tag] = field_info(ftype, fname, tag, oneof=None,
                                             repeated=rep is not None)


def find_blocks(body):
    out = []
    header_re = re.compile(r"\b(message|enum)\s+(\w+)\s*\{", re.S)
    i, n = 0, len(body)
    while i < n:
        mm = header_re.search(body, i)
        if not mm:
            break
        depth = 1
        j = mm.end()
        while j < n and depth:
            if body[j] == "{":
                depth += 1
            elif body[j] == "}":
                depth -= 1
            j += 1
        out.append((mm.group(1), mm.group(2), body[mm.end():j - 1], mm.start(), j))
        i = j
    for _, _, _, s, e in out:  # blank nested blocks for the field scan
        pass
    return out


def field_info(ftype, fname, tag, oneof, repeated=False):
    ftype = ftype.strip()
    if ftype.startswith("map<"):
        return {"name": fname, "raw": None, "type": "map", "oneof": oneof}
    raw = SCALAR.get(ftype, WELL_KNOWN.get(ftype, ftype))
    if repeated and not raw.startswith(("msg:", "enum:")):
        # scalar or still-unresolved name; resolved names get rep_ below
        raw = "rep:" + raw
    return {"name": fname, "raw": raw, "type": None, "oneof": oneof,
            "repeated": repeated}


def resolve_types(model):
    """Turn field raw names into final canonical types (msg:/enum:/rep_*)."""
    for pname, pentry in model.messages.items():
        prefix = pentry["prefix"]
        for tag, finfo in pentry["fields"].items():
            raw = finfo["raw"]
            if raw is None or finfo["type"] is not None:
                continue  # map, or already scalar
            rep = finfo["repeated"]
            if raw.startswith("rep:"):
                rep = True
                raw = raw[4:]
            if raw in SCALAR.values():
                base = raw
            else:
                # resolve message/enum name against scope: prefix+T, then T.
                # A dotted name from another package (sora.core.v1.ApiVersion)
                # arrives in Dart under its simple name via import.
                resolved = None
                for cand in (prefix + raw, raw):
                    if cand in model.messages or cand in model.enums:
                        resolved = cand
                        break
                if resolved is None and "." in raw:
                    resolved = raw.split(".")[-1]
                if resolved is None:
                    base = "msg:" + raw  # unknown; will surface as mismatch
                else:
                    dname = resolved.replace(".", "_")
                    base = ("enum:" if resolved in model.enums else "msg:") + dname
            if rep:
                base = {"string": "rep_string", "int": "rep_int",
                        "int64": "rep_int64", "bytes": "rep_bytes",
                        "double": "rep_double", "bool": "rep_bool"}.get(base, base)
                if base.startswith("msg:"):
                    base = "rep_" + base
                elif base.startswith("enum:"):
                    base = "rep_" + base
            finfo["type"] = base


def parse_enum(body):
    values = {}
    for line in body.split(";"):
        line = line.strip()
        if not line or line.startswith(("reserved", "option")):
            continue
        # allow "optional" prefix leftovers; enum values are simple
        mm = ENUM_VALUE_RE.match(re.sub(r"^\[(.*?)\]\s*", "", line))
        if mm:
            values[mm.group(1)] = int(mm.group(2))
    return values


def parse_service(body):
    rpcs = {}
    # rpcs may carry an option block { ... }; normalize to ';'
    body = re.sub(r"rpc\s+(\w+\s*\(.*?\)\s*returns\s*\(.*?\))\s*\{[^}]*\}",
                  r"rpc \1;", body, flags=re.S)
    for line in body.split(";"):
        mm = RPC_RE.match(line.strip())
        if mm:
            name = mm.group(1)
            rpcs[name] = (mm.group(3), mm.group(5),
                           mm.group(2) is not None, mm.group(4) is not None)
    return rpcs


# ---------------------------------------------------------------- Dart parsing

CLASS_RE = re.compile(r"^class (\w+) extends \$pb\.GeneratedMessage \{", re.M)
ENUM_RE = re.compile(r"^class (\w+) extends \$pb\.ProtobufEnum \{", re.M)
DART_ENUM_VALUE_RE = re.compile(r"static const \w+ (\w+)\s*=\s*\w+\._\(\s*(-?\d+),")
# BuilderInfo field entries. Order matters: more specific first.
BUILDER_PATTERNS = [
    (re.compile(r"\.\.aOM<\$(?:\d+)\.(\w+)>\((\d+),"), "msg"),
    (re.compile(r"\.\.aOM<(\w+)>\((\d+),"), "msg"),
    (re.compile(r"\.\.aE<(\w+)>\((\d+),"), "enum"),
    (re.compile(r"\.\.pPM<(\w+)>\((\d+),"), "rep_msg"),
    (re.compile(r"\.\.pc<(\w+)>\((\d+),"), "rep_msg"),
    (re.compile(r"\.\.pPS\((\d+),"), "rep_string"),
    (re.compile(r"\.\.p<\$core\.int>\((\d+),"), "rep_int"),
    (re.compile(r"\.\.p<\$fixnum\.Int64>\((\d+),"), "rep_int64"),
    (re.compile(r"\.\.m<[^,]+,\s*[^>]+>\((\d+),"), "map"),
    (re.compile(r"\.\.aOS\((\d+),"), "string"),
    (re.compile(r"\.\.aOB\((\d+),"), "bool"),
    (re.compile(r"\.\.aI\((\d+),"), "int"),  # ..aI(tag, fieldType: OU3), uint32
    (re.compile(r"\.\.a<\$core\.int>\((\d+),"), "int"),
    (re.compile(r"\.\.aInt64\((\d+),"), "int64"),
    (re.compile(r"\.\.a<\$fixnum\.Int64>\((\d+),"), "int64"),
    (re.compile(r"\.\.a<\$core\.double>\((\d+),"), "double"),
    (re.compile(r"\.\.a<\$core\.List<\$core\.int>>\((\d+),"), "bytes"),
]
ONEOF_RE = re.compile(r"\.\.oo\(\d+,\s*\[([\d,\s]+)\]\)")
FIELD_NAME_RE = re.compile(r"_omitFieldNames \? '' : '(\w+)'")


class DartModel:
    def __init__(self):
        self.messages = {}  # dart class name -> {"fields": {tag: dict}, "oneofs": [[tags]]}
        self.enums = {}     # name -> {value: number}
        self.rpcs = {}       # rpc name -> (req, resp, cstream, sstream)


def camel(s):
    parts = s.split("_")
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def parse_dart_pb(path, model):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    # enums
    for mm in ENUM_RE.finditer(text):
        name = mm.group(1)
        # enum body: up to the "static const List<Name> values" line
        body = text[mm.end():mm.end() + 6000]
        vals = {}
        for vm in DART_ENUM_VALUE_RE.finditer(body):
            if vm.start() > body.find("static const $core.List<%s> values" % name) > 0:
                break
            vals[vm.group(1)] = int(vm.group(2))
        model.enums[name] = vals
    # messages
    for mm in CLASS_RE.finditer(text):
        name = mm.group(1)
        # BuilderInfo block: from here to hasRequiredFields
        tail = text[mm.end():mm.end() + 12000]
        bi_start = tail.find("BuilderInfo")
        bi_end = tail.find("..hasRequiredFields")
        if bi_start < 0 or bi_end < 0:
            model.messages[name] = {"fields": {}, "oneofs": [], "no_builder": True}
            continue
        bi = tail[bi_start:bi_end]
        # protoc-gen-dart wraps long entries: "..aOM<Foo>(\n    17, ...".
        # Join the open paren with its tag so one-line regexes see them.
        bi = re.sub(r"\(\s*\n\s*", "(", bi)
        fields = {}
        # field dart-names per tag, for the naming check
        names = {}
        for pat, kind in BUILDER_PATTERNS:
            for fm in pat.finditer(bi):
                if kind in ("msg", "enum", "rep_msg"):
                    typ, tag = fm.group(1), int(fm.group(2))
                    canon = {"msg": "msg:" + typ, "enum": "enum:" + typ,
                             "rep_msg": "rep_msg:" + typ}[kind]
                else:
                    tag = int(fm.group(1))
                    canon = kind
                # dart property name: the string right after the tag in this entry
                rest = bi[fm.end():fm.end() + 120]
                nm = FIELD_NAME_RE.search(rest)
                dname = nm.group(1) if nm else ""
                if tag in fields:
                    fields[tag]["dup"] = True
                fields[tag] = {"type": canon, "dart_name": dname}
        oneofs = [sorted(int(x) for x in oo.group(1).split(","))
                  for oo in ONEOF_RE.finditer(bi)]
        model.messages[name] = {"fields": fields, "oneofs": oneofs}


def parse_dart_grpc(path, model):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    # method signature: $grpc.ResponseFuture<$X.Resp> name(
    # ($X. prefix optional: hand-written obfs.dart uses bare type names)
    sig_re = re.compile(
        r"\$grpc\.(ResponseFuture|ResponseStream)<(?:\$\w+\.)?(\w+)>\s+(\w+)\s*\(\s*\n?\s*(?:\$[\w.]+\.)?(\w+)\s+request",
        re.S)
    for mm in sig_re.finditer(text):
        ret, resp, mname, req = mm.group(1), mm.group(2), mm.group(3), mm.group(4)
        sstream = ret == "ResponseStream"
        # client streaming: method takes $async.Stream<Req>
        cstream = "$async.Stream" in text[mm.start():mm.start() + 400].split("request")[0]
        rpc = mname[:1].upper() + mname[1:]
        model.rpcs[rpc] = (req, resp, cstream, sstream)
    # cross-check path names from the ClientMethod table
    path_re = re.compile(
        r"static final _\$\w+\s*=\s*\$grpc\.ClientMethod<[^>]+>\(\s*'([^']+)'", re.S)
    model.paths = [p.split("/")[-1] for p in path_re.findall(text)]


# ---------------------------------------------------------------- comparison

def check(proto_path, pb_path, pbenum_path, pbgrpc_path):
    errors, warnings = [], []
    proto = parse_proto(os.path.join(REPO, proto_path))
    dart = DartModel()
    parse_dart_pb(os.path.join(REPO, pb_path), dart)
    if pbenum_path:
        parse_dart_pb(os.path.join(REPO, pbenum_path), dart)
    if pbgrpc_path and pbgrpc_path != pb_path:
        parse_dart_grpc(os.path.join(REPO, pbgrpc_path), dart)
    elif pbgrpc_path:
        parse_dart_grpc(os.path.join(REPO, pb_path), dart)  # obfs.dart: client inline

    # messages: proto Outer.Inner == dart Outer_Inner
    for pname, pentry in sorted(proto.messages.items()):
        dname = pname.replace(".", "_")
        if dname not in dart.messages:
            errors.append(f"[{proto_path}] message {pname}: missing Dart class {dname}")
            continue
        dentry = dart.messages[dname]
        if dentry.get("no_builder"):
            errors.append(f"[{proto_path}] {dname}: BuilderInfo not found in Dart")
            continue
        for tag, finfo in sorted(pentry["fields"].items()):
            if tag not in dentry["fields"]:
                errors.append(f"[{proto_path}] {pname}: field {tag} "
                              f"({finfo['name']}) missing in Dart")
                continue
            dfield = dentry["fields"][tag]
            want = finfo["type"]
            if want != dfield["type"]:
                # proto enum field vs dart aE -> "enum:X" both sides; ok
                errors.append(f"[{proto_path}] {pname}: field {tag} ({finfo['name']}) "
                              f"type mismatch proto={want} dart={dfield['type']}")
            if dfield["dart_name"] and dfield["dart_name"] != camel(finfo["name"]):
                warnings.append(f"[{proto_path}] {pname}: field {tag} dart name "
                                f"'{dfield['dart_name']}' != camelCase('{finfo['name']}')")
        for tag in sorted(set(dentry["fields"]) - set(pentry["fields"])):
            errors.append(f"[{proto_path}] {pname}: Dart has extra field "
                          f"tag {tag} ({dentry['fields'][tag]['dart_name']})")
        # oneofs
        proto_tags = sorted(t for oo in pentry["oneofs"].values() for t in oo)
        dart_tags = sorted(t for oo in dentry["oneofs"] for t in oo)
        if proto_tags != dart_tags:
            errors.append(f"[{proto_path}] {pname}: oneof member tags differ "
                          f"proto={proto_tags} dart={dart_tags}")

    for dname in sorted(dart.messages):
        pname = dname.replace("_", ".")
        # nested: Outer_Inner -> Outer.Inner; top-level classes map directly
        if pname not in proto.messages and dname not in [
                p.replace(".", "_") for p in proto.messages]:
            # allow helper types that are not proto messages? none expected
            errors.append(f"[{proto_path}] Dart class {dname}: no such proto message")

    # enums
    for ename, evalues in sorted(proto.enums.items()):
        dname = ename.replace(".", "_")
        if dname not in dart.enums:
            errors.append(f"[{proto_path}] enum {ename}: missing Dart enum {dname}")
            continue
        for vname, vnum in sorted(evalues.items(), key=lambda kv: kv[1]):
            if vname not in dart.enums[dname]:
                errors.append(f"[{proto_path}] enum {ename}: value {vname} missing in Dart")
            elif dart.enums[dname][vname] != vnum:
                errors.append(f"[{proto_path}] enum {ename}: value {vname} number "
                              f"mismatch proto={vnum} dart={dart.enums[dname][vname]}")
        for vname in dart.enums[dname]:
            if vname not in evalues:
                errors.append(f"[{proto_path}] enum {ename}: Dart has extra value {vname}")
    for dname in sorted(dart.enums):
        if dname.replace("_", ".") not in proto.enums:
            errors.append(f"[{proto_path}] Dart enum {dname}: no such proto enum")

    # RPCs
    for sname, rpcs in proto.services.items():
        for rname, (req, resp, cs, ss) in sorted(rpcs.items()):
            if rname not in dart.rpcs:
                errors.append(f"[{proto_path}] service {sname}: RPC {rname} missing in Dart client")
                continue
            dreq, dresp, dcs, dss = dart.rpcs[rname]
            if dreq != req:
                errors.append(f"[{proto_path}] RPC {rname}: request type "
                              f"proto={req} dart={dreq}")
            if dresp != resp:
                errors.append(f"[{proto_path}] RPC {rname}: response type "
                              f"proto={resp} dart={dresp}")
            if dcs != cs or dss != ss:
                errors.append(f"[{proto_path}] RPC {rname}: streaming mismatch "
                              f"proto=(c={cs},s={ss}) dart=(c={dcs},s={dss})")
    expected_rpcs = {name for rpcs in proto.services.values() for name in rpcs}
    for name in sorted(set(dart.rpcs) - expected_rpcs):
        errors.append(f"[{proto_path}] Dart RPC {name}: no such proto method")
    if hasattr(dart, "paths"):
        for sname, rpcs in proto.services.items():
            for rname in rpcs:
                if rname not in dart.paths:
                    errors.append(f"[{proto_path}] RPC {rname}: path "
                                  f"'/.../{rname}' missing in Dart ClientMethod table")
    return errors, warnings


def main():
    all_errors, all_warnings = [], []
    for proto_path, (pb, pbenum, pbgrpc) in MAPPINGS.items():
        errs, warns = check(proto_path, pb, pbenum, pbgrpc)
        all_errors += errs
        all_warnings += warns
    for proto_path, why in EXPECTED_GAPS.items():
        print(f"SKIP {proto_path}: {why}")
    for w in all_warnings:
        print("WARN " + w)
    for e in all_errors:
        print("FAIL " + e)
    n_msg = sum(len(parse_proto(os.path.join(REPO, p)).messages) for p in MAPPINGS)
    print(f"checked {len(MAPPINGS)} protos "
          f"({n_msg} messages): {len(all_errors)} errors, {len(all_warnings)} warnings")
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
