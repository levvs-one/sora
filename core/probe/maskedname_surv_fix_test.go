package probe

import (
	"context"
	"strings"
	"testing"
	"time"
)

// TestMaskedNameGarbageInputs pins CENSOR-SURV review §6: MaskedName
// panicked on dot-names (labels[0][0] on an empty first label) and
// produced mojibake on unicode first labels (byte, not rune). The
// helper's whole job is masking untrusted names for logs, so its
// input domain is garbage: no input may panic.
func TestMaskedNameGarbageInputs(t *testing.T) {
	cases := []struct{ in, want string }{
		{"", ""},
		{".", "***"},
		{"..", "***"},
		{"...", "***"},
		{".com", "c***"},
		{".a", "a***"},
		{"a.", "a***"},
		{"www.microsoft.com", "w***.microsoft.com"},
		{"éxample.com", "é***.com"},
		{"привет.example.ru", "п***.example.ru"},
		{"привет", "п***"},
		{"203.0.113.7", "203.***"},
		{"2001:db8::1", "2001:***"},
		{"localhost", "l***"},
	}
	for _, tc := range cases {
		if got := MaskedName(tc.in); got != tc.want {
			t.Errorf("MaskedName(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
	// Super-long and invalid-UTF-8 inputs: no panic, no raw bytes of
	// the secret label in the output beyond the first rune.
	long := strings.Repeat("a", 5000) + ".example.com"
	if got := MaskedName(long); !strings.HasPrefix(got, "a***.example.com") {
		t.Errorf("MaskedName(super-long) = %.40q…, want a***.example.com shape", got)
	}
	if got := MaskedName("\xff\xfe.example.com"); strings.Contains(got, "\xff") {
		t.Errorf("MaskedName(invalid utf-8) = %q, must not leak the raw broken byte", got)
	}
}

// TestHandshakeBudgetErrorMasksSNI pins the other half of review §6:
// a budget refusal's error text lands in censor Event.Detail, so it
// must carry the masked name, never the raw SNI.
func TestHandshakeBudgetErrorMasksSNI(t *testing.T) {
	l := NewHandshakeLimiter(1, 30*time.Millisecond)
	hold, err := l.Acquire(context.Background(), "secret-host.example.com")
	if err != nil {
		t.Fatal(err)
	}
	defer hold()
	_, err = l.Acquire(context.Background(), "secret-host.example.com")
	if err == nil {
		t.Fatal("saturated limiter must refuse the second acquire")
	}
	if strings.Contains(err.Error(), "secret-host") {
		t.Fatalf("budget error leaks the raw SNI: %q", err.Error())
	}
	if !strings.Contains(err.Error(), "s***.example.com") {
		t.Fatalf("budget error = %q, want the masked name s***.example.com", err.Error())
	}
}
