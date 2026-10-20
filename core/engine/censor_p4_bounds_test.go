package engine

import (
	"strings"
	"testing"
)

// CENSOR-P4 "мелочи" §1: AmneziaWG junk-parameter boundaries. Every
// bound is exercised at 0 / min / max / max+1 / negative, the mutual
// constraints (Jmin<=Jmax, S1+56!=S2, H ranges disjoint) at their
// exact edges, and rejection must be a validation error — the input
// struct is never clamped or rewritten (asserted at the end).

func TestValidateAmneziaWGBoundaries(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(a *AmneziaWG)
		want   string // substring of the expected error; "" = valid
	}{
		// Jc: 0 disables junk, 1..128 valid.
		{"jc zero", func(a *AmneziaWG) { a.Jc = 0 }, ""},
		{"jc one", func(a *AmneziaWG) { a.Jc = 1 }, ""},
		{"jc max", func(a *AmneziaWG) { a.Jc = 128 }, ""},
		{"jc max+1", func(a *AmneziaWG) { a.Jc = 129 }, "jc 129 is outside 0-128"},
		{"jc negative", func(a *AmneziaWG) { a.Jc = -1 }, "jc -1 is outside 0-128"},
		// Jmin/Jmax: 0..1280 (below the minimal IPv6 MTU), ordered.
		{"jmin zero", func(a *AmneziaWG) { a.Jmin = 0 }, ""},
		{"jmax max", func(a *AmneziaWG) { a.Jmax = 1280 }, ""},
		{"jmax max+1", func(a *AmneziaWG) { a.Jmax = 1281 }, "jmax 1281 is outside 0-1280"},
		{"jmin negative", func(a *AmneziaWG) { a.Jmin = -1 }, "jmin -1 is outside 0-1280"},
		{"jmin equals jmax", func(a *AmneziaWG) { a.Jmin, a.Jmax = 70, 70 }, ""},
		{"jmin above jmax by one", func(a *AmneziaWG) { a.Jmin, a.Jmax = 71, 70 }, "jmin 71 exceeds jmax 70"},
		// S1..S4 caps differ per packet class (init/response/cookie/data).
		{"s1 max", func(a *AmneziaWG) { a.S1 = 1132 }, ""},
		{"s1 max+1", func(a *AmneziaWG) { a.S1 = 1133 }, "s1 1133 is outside 0-1132"},
		{"s2 max", func(a *AmneziaWG) { a.S2 = 1188 }, ""},
		{"s2 max+1", func(a *AmneziaWG) { a.S2 = 1189 }, "s2 1189 is outside 0-1188"},
		{"s3 max", func(a *AmneziaWG) { a.S3 = 1216 }, ""},
		{"s3 max+1", func(a *AmneziaWG) { a.S3 = 1217 }, "s3 1217 is outside 0-1216"},
		{"s4 max", func(a *AmneziaWG) { a.S4 = 32 }, ""},
		{"s4 max+1", func(a *AmneziaWG) { a.S4 = 33 }, "s4 33 is outside 0-32"},
		{"s3 negative", func(a *AmneziaWG) { a.S3 = -1 }, "s3 -1 is outside 0-1216"},
		// S1+56 == S2 collision: exact edge and one-off on both sides.
		{"s collision exact", func(a *AmneziaWG) { a.S1, a.S2 = 15, 71 }, "s1+56 must not equal s2"},
		{"s collision minus one", func(a *AmneziaWG) { a.S1, a.S2 = 15, 70 }, ""},
		{"s collision plus one", func(a *AmneziaWG) { a.S1, a.S2 = 15, 72 }, ""},
		{"s both zero exempt", func(a *AmneziaWG) { a.S1, a.S2 = 0, 0 }, ""},
		{"s zero and 56 collides", func(a *AmneziaWG) { a.S1, a.S2 = 0, 56 }, "s1+56 must not equal s2"},
		// H1..H4 magic: 5..2147483647, ranges ordered, pairwise disjoint.
		{"h min", func(a *AmneziaWG) { a.H1 = "5" }, ""},
		{"h below min", func(a *AmneziaWG) { a.H1 = "4" }, "outside 5-2147483647"},
		{"h max", func(a *AmneziaWG) { a.H1 = "2147483647" }, ""},
		{"h max+1", func(a *AmneziaWG) { a.H1 = "2147483648" }, "outside 5-2147483647"},
		{"h range touching next is overlap", func(a *AmneziaWG) { a.H2 = "800000-900000" }, "overlap"},
		{"h range adjacent is ok", func(a *AmneziaWG) { a.H2 = "800001-900000" }, ""},
		{"h range reversed", func(a *AmneziaWG) { a.H3 = "900-100" }, "lower bound above"},
		{"h single equals other single", func(a *AmneziaWG) { a.H1, a.H2 = "12345", "12345" }, "overlap"},
		{"h empty stays unset", func(a *AmneziaWG) { a.H1 = "" }, ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia()
			tc.mutate(a)
			before := *a
			err := wireguardWithAmnezia(a).Validate()
			if tc.want == "" {
				if err != nil {
					t.Fatalf("Validate = %v, want nil", err)
				}
			} else if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
			// Validation reports; it never clamps or rewrites input.
			if *a != before {
				t.Fatalf("validation mutated the parameters: %+v -> %+v", before, *a)
			}
		})
	}
}

// TestValidateAmneziaWG31Boundaries: the 3.1 side of the same
// discipline — range<uint16> edges and the header-protection S>=12
// floor at its exact boundary.
func TestValidateAmneziaWG31Boundaries(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(a *AmneziaWG)
		want   string
	}{
		{"padding zero disables", func(a *AmneziaWG) { a.ContentPaddingAddition = "0" }, ""},
		{"padding max", func(a *AmneziaWG) { a.ContentPaddingAddition = "65535" }, ""},
		{"padding max+1", func(a *AmneziaWG) { a.ContentPaddingAddition = "65536" }, "contentpaddingaddition"},
		{"padding range max", func(a *AmneziaWG) { a.ContentPaddingAddition = "65000-65535" }, ""},
		{"padding range reversed", func(a *AmneziaWG) { a.ContentPaddingAddition = "96-32" }, "contentpaddingaddition"},
		{"s floor exact with key", func(a *AmneziaWG) { a.S1, a.S2, a.S3, a.S4 = 12, 25, 12, 12 }, ""},
		{"s floor minus one with key", func(a *AmneziaWG) { a.S3 = 11 }, "requires s3 >= 12"},
		{"keepalive zero range disables", func(a *AmneziaWG) { a.KeepaliveTimeout = "0-0" }, ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			a := goodAmnezia31()
			tc.mutate(a)
			err := wireguardWithAmnezia(a).Validate()
			if tc.want == "" {
				if err != nil {
					t.Fatalf("Validate = %v, want nil", err)
				}
			} else if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("Validate = %v, want error containing %q", err, tc.want)
			}
		})
	}
	if (&AmneziaWG{KeepaliveTimeout: "0-0"}).UsesAWG31() {
		t.Fatal(`"0-0" must disable its 3.1 mechanism (awgRangeEnabled)`)
	}
}
