package ext

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

// TestEnforcementDartMirrorMatches pins the Dart mirror of the
// enforcement matrix (app/lib/src/ext/enforcement.dart) to this Go
// table. The install prompt and the detail screen read the Dart table:
// if it drifted — above all if it upgraded one of the two RiskDangerous
// rows the Go side honestly reports as unimplemented — the user would
// be told a protection exists that no code performs. The Go test pins
// the Go claims against the gates; this test pins the mirror against
// the Go table, row for row, in registry order.
func TestEnforcementDartMirrorMatches(t *testing.T) {
	path := filepath.Join("..", "..", "app", "lib", "src", "ext", "enforcement.dart")
	raw, err := os.ReadFile(path) //nolint:gosec // fixed repo-relative path
	if err != nil {
		t.Fatalf("read Dart mirror: %v", err)
	}
	dartStatus := map[EnforcementStatus]string{
		EnforcementEnforced:      "ExtEnforcementStatus.enforced",
		EnforcementInstallTime:   "ExtEnforcementStatus.installTime",
		EnforcementInert:         "ExtEnforcementStatus.inert",
		EnforcementUnimplemented: "ExtEnforcementStatus.unimplemented",
	}
	// Each Dart row is an ExtEnforcementRow('<id>', <status>, '<note>')
	// possibly wrapped across lines.
	rowRe := regexp.MustCompile(`ExtEnforcementRow\(\s*'([^']+)',\s*(ExtEnforcementStatus\.\w+)`)
	matches := rowRe.FindAllStringSubmatch(string(raw), -1)
	// The constructor's own declaration mentions the type once with no
	// quoted id; only rows with a quoted first argument count.
	var rows [][2]string
	for _, m := range matches {
		rows = append(rows, [2]string{m[1], m[2]})
	}
	table := EnforcementTable()
	if len(rows) != len(table) {
		t.Fatalf("Dart mirror has %d rows, Go table has %d", len(rows), len(table))
	}
	for i, row := range table {
		if rows[i][0] != row.ID {
			t.Errorf("row %d: Dart id %q, Go id %q (order or membership drifted)", i, rows[i][0], row.ID)
			continue
		}
		if want := dartStatus[row.Status]; rows[i][1] != want {
			t.Errorf("%q: Dart status %s, Go status %s maps to %s", row.ID, rows[i][1], row.Status, want)
		}
	}
	// The two RiskDangerous rows must stay unimplemented in the mirror
	// too — said explicitly, not only via the table walk above, because
	// this is the load-bearing honesty claim of the whole matrix.
	for _, id := range []string{"routing.rules", "net.hooks"} {
		re := regexp.MustCompile(`ExtEnforcementRow\(\s*'` + regexp.QuoteMeta(id) + `',\s*ExtEnforcementStatus\.unimplemented`)
		if !re.MatchString(string(raw)) {
			t.Errorf("Dart mirror does not pin %q as unimplemented", id)
		}
		if !strings.Contains(string(raw), id) {
			t.Errorf("Dart mirror has no row for %q at all", id)
		}
	}
}
