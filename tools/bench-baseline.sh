#!/usr/bin/env bash
# bench-baseline.sh — reproducible performance-regression gate for every Go
# benchmark committed in this repository.
#
# WHAT IT DOES
#   Discovers all packages that contain `func Benchmark...` in every Go
#   module of this repo (core/, service/sync/, tools/sora-ext/ in sora;
#   core/ in sora-legacy), runs them with one fixed recipe, reduces each
#   benchmark to its deterministic allocation metrics, and compares them
#   against the committed baseline in tools/bench-baseline.txt.
#
# WHY ONLY B/op AND allocs/op ARE GATED — ns/op IS DELIBERATELY EXCLUDED
#   ns/op is a wall-clock sample. On a shared VM / CI runner it swings by
#   2-3x for identical code (neighbour tenants, CPU throttling, steal
#   time), so a gate on ns/op would be a coin flip that trains everyone
#   to ignore it. B/op and allocs/op are exact counters produced by the
#   Go allocator (testing.B.ReportAllocs / -benchmem): for a given Go
#   toolchain and fixed benchmark inputs they are reproducible on any
#   machine, so a regression in them is real signal, not noise. ns/op is
#   still printed in the raw output for eyeballing, but it is parsed over
#   and discarded before the comparison — it can never fail this gate.
#
# FIXED RECIPE (identical for baseline capture and for every check run)
#   go test -run='^$' -bench=. -benchmem -benchtime=100x -count=3
#   The one exception is core/cmd/sora-core (BenchmarkNewCold performs a
#   full App construction with real filesystem I/O, ~0.45 s/op): it runs
#   with -benchtime=20x. The iteration count changes only how long the
#   measurement takes, never the per-op allocation counters.
#   With -count=3 the gate keeps the MINIMUM B/op across the counts (and
#   the allocs/op of that run; ties break to the lower allocs/op): the
#   steady-state floor, with one-off warm-up allocations (sync.Pool,
#   lazy init) amortised away.
#
# THRESHOLD — WHY 5% (plus absolute floors)
#   Because B/op and allocs/op are deterministic counters, run-to-run
#   variance of the gated value is ~0; the threshold does not need to
#   absorb measurement noise the way an ns/op gate would (those need
#   10-30%+). 5% is chosen as the smallest band that still tolerates the
#   two legitimate sources of jitter: (a) Go toolchain micro-changes in
#   allocator size-class rounding between point releases, and (b) map
#   growth / string-interning boundary effects where one extra element
#   legitimately rounds a buffer up a size class. Anything above 5% on
#   an exact counter is a real allocation regression and should fail.
#   Two absolute floors keep tiny benchmarks fair:
#     - B/op must also grow by at least 32 B (one small object) — a
#       160 -> 161 B/op wobble cannot fail anyone;
#     - allocs/op must also grow by at least 1 allocation.
#   Zero is special: several hot paths in this repo are allocation-free
#   BY CONTRACT (0 B/op, 0 allocs/op in the baseline). A baseline of 0
#   therefore fails on ANY new allocation (allocs/op >= 1) or on more
#   than 32 B/op appearing — losing the zero-alloc property is exactly
#   the regression this gate exists to catch.
#
# RACY BENCHMARKS — WIDENED BANDS FOR TWO MEASUREMENTS
#   Two benchmarks in the set are concurrency-shaped: helper goroutines
#   perform part of the work, and whether their allocations are
#   attributed to the measurement window is scheduler-dependent. On
#   IDENTICAL code, repeated runs on this VM measured:
#     core/probe BenchmarkRunSeriesShort (serial probe loop racing a
#       context/timer allocation): allocs/op flips 17 <-> 18 between
#       counts, B/op swings ~1213 -> ~1333 (+10%);
#     service/sync/transport BenchmarkTransportRoundTrip1KB (reader
#       goroutine drains a Noise transport): single counts swing
#       16 -> 807 B/op, allocs/op 1 -> 3;
#     core/probe BenchmarkDownloadGoodput (30 ms time-boxed loopback
#       download against an in-process httptest server whose own
#       allocations share the process — the benchmark's header comment
#       says so): B/op scales with the chunks served inside the window,
#       43794 -> 50047 B/op across counts on identical code, while
#       allocs/op stay tight (318 -> 331), so only its B/op band is
#       widened (25%); allocs keep the strict 5%;
#     service/sync/api BenchmarkHandleDocGet256KiB (256 KiB document
#       served through the handler into an httptest recorder): B/op
#       1088344 -> 1229323 across counts on identical code (buffer
#       growth/chunking of a quarter-megabyte body), allocs/op tight
#       (40 -> 42), so only its B/op band is widened (25%). Its PUT
#       sibling is stable (+-0.7%) and keeps the strict band.
#   Gating those two at 5% would fail on noise, so they get explicit,
#   per-benchmark widened bands in the comparison below (25% B/op and
#   +2 allocs for RunSeriesShort; a 1024 B/op absolute cap and +2
#   allocs for TransportRoundTrip1KB — a real regression there, e.g. a
#   per-message buffer leaving the pool, sustains >= 1 KiB/op as the
#   MINIMUM across counts, which races alone never produced: worst
#   observed polluted count was 807 B/op). Every other benchmark —
#   including the allocation-free-by-contract hot paths — keeps the
#   strict 5% band. The exceptions are keyed by exact package+name and
#   exist ONLY in the two repos' shared script so they stay visible in
#   review; a benchmark that becomes deterministic should be removed
#   from the table, never added to it casually.
#
# VERDICTS
#   REGRESS  gated metric grew past the threshold  -> exit 1
#   MISSING  benchmark is in the baseline but produced no result
#            (renamed, removed, newly skipped, or its package failed
#            to build)                              -> exit 1
#   NEW      benchmark ran but is not in the baseline yet: reported,
#            NOT gated. Add it by re-capturing the baseline.
#   OK / IMPROVED  within threshold / below baseline.
#
# USAGE
#   tools/bench-baseline.sh              check against the baseline
#   tools/bench-baseline.sh --update     re-capture tools/bench-baseline.txt
#                                        (review the diff line by line:
#                                        every raised number must be
#                                        explained by the change that
#                                        caused it; never hand-edit
#                                        numbers you did not measure)
#   tools/bench-baseline.sh --list       inventory only: print the
#                                        discovered benchmark packages
#                                        and functions, run nothing
#
# ENVIRONMENT
#   GO                 go binary (default: `go` from PATH)
#   BENCH_THRESHOLD_PCT  override the 5% threshold (integer)
#   BENCH_BENCHTIME      override the fixed iteration count (default 100x)
#   BENCH_COUNT          override -count (default 3)
#   TMPDIR / GOCACHE     honoured as usual by the Go toolchain; on the
#                        audit VM pass TMPDIR=$HOME/workspace/.build-tmp
#                        GOCACHE=$HOME/workspace/.gocache-v.
#
# The same script is committed in sora and sora-legacy (the parity set);
# each repo carries its own tools/bench-baseline.txt. Keep the two script
# copies byte-identical.

set -uo pipefail

GO=${GO:-go}
THRESHOLD_PCT=${BENCH_THRESHOLD_PCT:-5}
BENCHTIME=${BENCH_BENCHTIME:-100x}
BENCHTIME_COLD=${BENCH_BENCHTIME_COLD:-20x}
BENCHCOUNT=${BENCH_COUNT:-3}

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BASELINE="$ROOT/tools/bench-baseline.txt"

mode=check
case "${1:-}" in
  "") mode=check ;;
  --update) mode=update ;;
  --list) mode=list ;;
  *) echo "usage: $0 [--update|--list]" >&2; exit 2 ;;
esac

command -v "$GO" >/dev/null 2>&1 || { echo "error: go binary '$GO' not found" >&2; exit 2; }

# --- Discovery ---------------------------------------------------------------
# Every directory holding a go.mod is a module (skip vendored / third-party
# trees). Inside a module, every package directory whose *_test.go files
# declare a Benchmark function joins the set. Discovery is dynamic on
# purpose: a newly committed benchmark shows up as NEW on the next run
# instead of silently escaping the gate.
discover() {
  local moddir rel pkgdir
  while IFS= read -r moddir; do
    rel=${moddir#"$ROOT"/}
    [ "$rel" = "$moddir" ] && rel="."
    while IFS= read -r pkgdir; do
      if [ "$pkgdir" = "." ]; then echo "$rel";
      elif [ "$rel" = "." ]; then echo "$pkgdir";
      else echo "$rel/$pkgdir"; fi
    done < <(cd "$moddir" && grep -rl '^func Benchmark' --include='*_test.go' . 2>/dev/null \
             | sed 's|^\./||' | awk -F/ '{ if (NF == 1) print "."; else { OFS="/"; NF--; print } }' | sort -u)
  done < <(find "$ROOT" -name go.mod -not -path '*/third_party/*' -not -path '*/vendor/*' -not -path '*/.git/*' \
           | sed 's|/go.mod$||' | sort)
}

MAPFILE_PKGS=()
while IFS= read -r p; do [ -n "$p" ] && MAPFILE_PKGS+=("$p"); done < <(discover)
if [ "${#MAPFILE_PKGS[@]}" -eq 0 ]; then
  echo "error: no benchmark packages discovered under $ROOT" >&2; exit 2
fi

if [ "$mode" = list ]; then
  for p in "${MAPFILE_PKGS[@]}"; do
    echo "## $p"
    grep -h '^func Benchmark' "$ROOT/$p"/*_test.go 2>/dev/null \
      | sed 's/^func \([A-Za-z0-9_]*\).*/  \1/' | sort
  done
  exit 0
fi

# --- Run ---------------------------------------------------------------------
RAW=$(mktemp "${TMPDIR:-/tmp}/bench-baseline-raw.XXXXXX")
CURRENT=$(mktemp "${TMPDIR:-/tmp}/bench-baseline-cur.XXXXXX")
trap 'rm -f "$RAW" "$CURRENT"' EXIT
: > "$RAW"

run_pkg() {
  local pkgpath=$1
  local modroot relpkg bt
  # Module root = longest ancestor directory of the package holding a go.mod.
  modroot="$ROOT/$pkgpath"
  while [ "$modroot" != "$ROOT" ] && [ ! -f "$modroot/go.mod" ]; do
    modroot=$(dirname "$modroot")
  done
  relpkg=$pkgpath
  if [ "$modroot" != "$ROOT" ]; then
    mrel=${modroot#"$ROOT"/}
    if [ "$pkgpath" = "$mrel" ]; then relpkg="."; else relpkg=${pkgpath#"$mrel"/}; fi
  fi
  bt="$BENCHTIME"
  # BenchmarkNewCold: full App construction per op (~0.45 s/op of real
  # filesystem I/O). 20x keeps the package under ~30 s while the per-op
  # allocation counters stay exact.
  if [ "$pkgpath" = "core/cmd/sora-core" ]; then bt="$BENCHTIME_COLD"; fi
  echo "## pkg $pkgpath" >> "$RAW"
  echo "--- $pkgpath (benchtime=$bt count=$BENCHCOUNT)"
  (cd "$modroot" && "$GO" test -run='^$' -bench=. -benchmem \
      -benchtime="$bt" -count="$BENCHCOUNT" "./$relpkg/") >> "$RAW" 2>&1 \
    || echo "## FAIL $pkgpath" >> "$RAW"
}

for p in "${MAPFILE_PKGS[@]}"; do run_pkg "$p"; done

# --- Normalise ---------------------------------------------------------------
# One line per benchmark: "<pkg> <name> <min B/op> <allocs/op of that run>".
# The -<GOMAXPROCS> suffix is stripped. ns/op and every other column are
# parsed over and discarded on purpose (see header: ns/op is never gated).
awk '
  /^## pkg / { pkg = $3; pending = ""; next }
  /^Benchmark/ {
    name = $1; sub(/-[0-9]+$/, "", name)
    b = ""; a = ""
    for (i = 2; i <= NF; i++) {
      if ($i == "B/op") b = $(i-1)
      if ($i == "allocs/op") a = $(i-1)
    }
    if (b == "") { pending = name; next }
    pending = ""
    k = pkg " " name
    if (!(k in mb) || b < mb[k] || (b == mb[k] && a < ma[k])) { mb[k] = b; ma[k] = a }
    next
  }
  {
    # Split result line: log output written by the benchmark itself (or
    # by a background goroutine it spawned — BenchmarkNewCold is the
    # known case) can interleave with the framework print, leaving the
    # metrics on a following line of their own
    # ("20  434889755 ns/op  220897 B/op  965 allocs/op"). Attribute
    # such a continuation line to the pending benchmark.
    if (pending == "") next
    b = ""; a = ""
    for (i = 2; i <= NF; i++) {
      if ($i == "B/op") b = $(i-1)
      if ($i == "allocs/op") a = $(i-1)
    }
    if (b == "") next
    k = pkg " " pending
    if (!(k in mb) || b < mb[k] || (b == mb[k] && a < ma[k])) { mb[k] = b; ma[k] = a }
    pending = ""
  }
  END { for (k in mb) print k, mb[k], ma[k] }
' "$RAW" | sort > "$CURRENT"

if [ ! -s "$CURRENT" ]; then
  echo "error: no benchmark results parsed; raw output follows" >&2
  cat "$RAW" >&2
  exit 2
fi

# --- Update mode ---------------------------------------------------------------
if [ "$mode" = update ]; then
  if grep -q '^## FAIL' "$RAW"; then
    echo "error: at least one package failed (see '## FAIL' in raw output below); refusing to capture a partial baseline" >&2
    cat "$RAW" >&2
    exit 1
  fi
  {
    echo "# bench-baseline.txt — allocation baseline for tools/bench-baseline.sh."
    echo "# Columns: <package> <benchmark> <B/op> <allocs/op>  (min over -count=$BENCHCOUNT, -benchtime=$BENCHTIME; core/cmd/sora-core at $BENCHTIME_COLD)."
    echo "# ns/op is intentionally NOT recorded: it is wall-clock noise on shared runners; B/op and allocs/op are exact allocator counters."
    echo "# Captured: $(date -u '+%Y-%m-%dT%H:%M:%SZ')  commit: $(cd "$ROOT" && git rev-parse HEAD 2>/dev/null || echo unknown)  go: $("$GO" version)"
    echo "# Re-capture only via: tools/bench-baseline.sh --update  (then review every raised number)."
    cat "$CURRENT"
  } > "$BASELINE"
  echo "Baseline written to $BASELINE ($(grep -vc '^#' "$BASELINE") benchmarks)."
  exit 0
fi

# --- Compare -------------------------------------------------------------------
[ -f "$BASELINE" ] || { echo "error: baseline $BASELINE not found; capture it with --update" >&2; exit 2; }

status=0
awk -v pct="$THRESHOLD_PCT" '
  BEGIN {
    # Racy-benchmark exceptions (see header). eb: B/op band in percent;
    # ebabs: B/op absolute cap; ea: allocs/op absolute tolerance.
    eb["core/probe" SUBSEP "BenchmarkRunSeriesShort"] = 25
    eb["core/probe" SUBSEP "BenchmarkDownloadGoodput"] = 25
    eb["service/sync/api" SUBSEP "BenchmarkHandleDocGet256KiB"] = 25
    ea["core/probe" SUBSEP "BenchmarkRunSeriesShort"] = 2
    ebabs["service/sync/transport" SUBSEP "BenchmarkTransportRoundTrip1KB"] = 1024
    ea["service/sync/transport" SUBSEP "BenchmarkTransportRoundTrip1KB"] = 2
  }
  FNR == NR {
    if ($1 ~ /^#/ || NF == 0) next
    key = $1 SUBSEP $2; bb[key] = $3; ba[key] = $4; seen[key] = 1; next
  }
  {
    key = $1 SUBSEP $2; got[key] = 1
    if (!(key in bb)) { printf "NEW      %s %s: %s B/op %s allocs/op (not in baseline, not gated)\n", $1, $2, $3, $4; next }
    fail = ""
    bp = (key in eb) ? eb[key] : pct
    if (key in ebabs) { if ($3 > ebabs[key] && $3 > bb[key] * 4) fail = "B/op " bb[key] " -> " $3 " (past racy cap " ebabs[key] ")" }
    else if (bb[key] == 0) { if ($3 > 32) fail = "B/op 0 -> " $3 " (allocation-free baseline)" }
    else if ($3 > bb[key] * (1 + bp/100) && $3 - bb[key] >= 32) fail = "B/op " bb[key] " -> " $3
    if (key in ea) { if ($4 - ba[key] > ea[key]) fail = fail " allocs/op " ba[key] " -> " $4 " (past racy tolerance +" ea[key] ")" }
    else if (ba[key] == 0) { if ($4 >= 1) fail = fail " allocs/op 0 -> " $4 }
    else if ($4 > ba[key] * (1 + pct/100) && $4 - ba[key] >= 1) fail = fail " allocs/op " ba[key] " -> " $4
    if (fail != "") { printf "REGRESS  %s %s: %s\n", $1, $2, fail; bad = 1 }
    else if ($3 < bb[key] || $4 < ba[key]) printf "IMPROVED %s %s: %s B/op (base %s), %s allocs/op (base %s) — consider lowering the baseline\n", $1, $2, $3, bb[key], $4, ba[key]
    else printf "OK       %s %s: %s B/op (base %s), %s allocs/op (base %s)\n", $1, $2, $3, bb[key], $4, ba[key]
  }
  END {
    for (k in seen) if (!(k in got)) {
      split(k, parts, SUBSEP)
      printf "MISSING  %s %s: in baseline but produced no result (renamed, removed, skipped, or package failed to build)\n", parts[1], parts[2]
      bad = 1
    }
    exit bad
  }
' "$BASELINE" "$CURRENT" || status=$?

if [ "$status" -eq 0 ]; then
  echo "BENCH GATE GREEN: $(grep -vc '^#' "$BASELINE") baselined benchmarks, no allocation regression past ${THRESHOLD_PCT}% (floors: +32 B, +1 alloc; ns/op not gated)."
else
  echo "BENCH GATE RED: allocation regression or missing benchmark (see REGRESS/MISSING lines above)." >&2
fi
exit "$status"
