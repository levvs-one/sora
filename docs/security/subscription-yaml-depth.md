# YAML subscription depth policy

The previous `gopkg.in/yaml.v3` import decoded the whole document before applying
the outbound count limit. Eight bounded regression cases containing 256 nested
flow/block sequences/mappings were accepted, including ignored root metadata
and a proxy after `MaxItems: 1`. This demonstrates the absent product depth
policy, not a measured denial of service or code execution.

The YAML subscription consumer now uses the unmodified, pinned
`go.yaml.in/yaml/v4` v4.0.0-rc.6 with `WithV3Defaults()` and its existing
`plugin/limit.DepthValue(128)`. The library checks the scanner's `flow_level`
and block indentation stack independently before further nesting. This is
**128 per kind**, not a claim that every mixed YAML tree has at most 128 nodes
along a path. Default alias checks and unique-key checks remain enabled. Any
violation returns the existing data-free `ErrInvalid`, without partially
importing earlier entries. Other formats and engine YAML producers are unchanged.

128 permits substantially more nesting than the supported provider structures;
the positive regression retains nested options at depth 32. Flow depths
127/128 pass and 129 fails. Provider anchors/merge keys, quoted punctuation,
plain `on`, quoted numeric passwords, deduplication and option preservation
are covered. Duplicate keys, recursive aliases and excessive alias expansion
remain rejected. The existing cross-format count/accounting tests still apply.
The dedicated fuzz target exercises public parsing with a fixed `proxies:`
prefix; its execution time is bounded by the test runner. A local run completed
14,886 executions in 6.012 seconds without a failure. Concurrent valid/invalid
imports also exercise independent per-call policies under the race detector;
this does not cap aggregate concurrent import memory.

## Candidate decision, 26 October 2026

The installed Go standard library has no YAML parser. `core/go.mod` and the
installed v3 Node/Decoder APIs were inspected. A post-parse Node walk would not
limit scanner nesting before allocation; decoding each proxy separately would
also reset alias accounting. A new handwritten YAML scanner was rejected.

| Candidate | Latest module version/date | Stars / open issues | Module ZIP / minimum Go | License and decision |
| --- | --- | --- | --- | --- |
| [go-yaml](https://github.com/yaml/go-yaml/tree/v4.0.0-rc.6) | v4.0.0-rc.6, 2026-06-17 | 543 / 56 | 354,570 bytes / 1.18; no module dependencies | Apache-2.0 plus MIT libyaml files. Selected: supported scanner depth and alias plugin, V3 compatibility preset. |
| [goccy/go-yaml](https://github.com/goccy/go-yaml/tree/v1.19.2) | v1.19.2, 2026-01-08 | 2,242 / 159 | 490,954 bytes / 1.21; no module dependencies | MIT. Public options lack the required configurable scanner depth hook; decoder has a fixed 10,000-depth guard. Last repository push 2026-04-11 is over six months old. |
| [sigs.k8s.io/yaml](https://github.com/kubernetes-sigs/yaml/tree/v1.6.0) | v1.6.0, 2025-07-24 | 355 / 7 | 60,719 bytes / 1.22; go.mod lists four dependencies | MIT/BSD plus forked YAML notices. YAML-to-JSON wrapper does not expose the required scanner budget. |

Repository metadata and issue-only counts came from authenticated GitHub API;
module version dates, ZIP sizes and Go requirements came from downloaded module
metadata/go.mod. ZIP size is source-distribution size, not installed binary size.
The selected repository last pushed 2026-10-24. Its module is a **prerelease**:
API and behavior compatibility remain a maintenance risk. It is pinned exactly
and scoped to subscription imports; this change does not upgrade other v3 users.
The original v3 dependency remains in the module. Upstream NOTICE, MIT notice
and the existing Apache text are included in `THIRD-PARTY-NOTICES.md`.

API/source checked before implementation:
[limit plugin](https://pkg.go.dev/go.yaml.in/yaml/v4/plugin/limit),
[versioned API](https://github.com/yaml/go-yaml/blob/v4.0.0-rc.6/yaml.go),
[scanner](https://github.com/yaml/go-yaml/blob/v4.0.0-rc.6/internal/libyaml/scanner.go).

The default-capacity benchmark imported all 20,000 distinct proxies on both
implementations. One home-pc/linux-amd64 Go 1.27.3 iteration allocated
109,910,896 bytes before and 110,276,824 bytes after. This is a compatibility and
allocation observation, not a throughput claim or a regression threshold.

## Remaining limits

Input bytes remain capped at 16 MiB. Width, total AST nodes, accepted option
sizes, rejected-item reports, JSON depth and concurrent imports still need
their own resource budgets. This is not a hard process memory/CPU sandbox,
complete S3 audit or independent external audit. No exhaustion experiment,
engine execution or owner service/network change was performed.
