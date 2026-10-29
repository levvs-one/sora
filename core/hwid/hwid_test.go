package hwid_test

import (
	"net/http"
	"runtime"
	"strings"
	"testing"

	"github.com/levvs-one/sora-client/core/hwid"
)

func TestDeriveIsStableKeyedAndAccepted(t *testing.T) {
	machine := []byte("4c4c4544004e3010804db7c04f4e4d32")
	first, second := hwid.Derive(machine), hwid.Derive(machine)
	if first != second {
		t.Fatalf("the same machine gave %q and %q", first, second)
	}
	if len(first) != 32 || !hwid.Valid(first) {
		t.Fatalf("identifier %q is not 32 characters Remnawave accepts", first)
	}
	if strings.Contains(first, string(machine[:16])) {
		t.Fatalf("identifier %q carries the machine id", first)
	}
	if other := hwid.Derive([]byte("4c4c4544004e3010804db7c04f4e4d33")); other == first {
		t.Fatal("two machines share one identifier")
	}
}

func TestRandomIdentifiersDifferAndAreAccepted(t *testing.T) {
	first, err := hwid.Random()
	if err != nil {
		t.Fatal(err)
	}
	second, err := hwid.Random()
	if err != nil {
		t.Fatal(err)
	}
	if first == second || !hwid.Valid(first) || len(first) != 32 {
		t.Fatalf("random identifiers %q and %q", first, second)
	}
}

func TestValidFollowsTheRemnawavePattern(t *testing.T) {
	for id, want := range map[string]bool{
		"0123456789":              true,
		"abcDEF-123=":             true,
		strings.Repeat("a", 64):   true,
		"012345678":               false,
		strings.Repeat("a", 65):   false,
		"0123456789\r\nX-Evil: 1": false,
		"0123456789 0123456789":   false,
		"0123456789_0123456789":   false,
	} {
		if got := hwid.Valid(id); got != want {
			t.Errorf("Valid(%q) = %v, want %v", id, got, want)
		}
	}
}

func TestMachineIdentifierStaysTheSame(t *testing.T) {
	first, err := hwid.Machine()
	if err != nil {
		if runtime.GOOS == "linux" || runtime.GOOS == "windows" {
			t.Skipf("this machine has no readable machine id: %v", err)
		}
		return
	}
	second, err := hwid.Machine()
	if err != nil || first != second || !hwid.Valid(first) {
		t.Fatalf("machine identifier %q then %q, %v", first, second, err)
	}
}

func TestApplySetsTheHeadersPanelsRead(t *testing.T) {
	header := http.Header{}
	identity := hwid.For("0123456789abcdef0123456789abcdef")
	identity.Apply(header)
	if header.Get("x-hwid") != "0123456789abcdef0123456789abcdef" {
		t.Fatalf("x-hwid = %q", header.Get("x-hwid"))
	}
	if header.Get("x-device-model") != "PC" {
		t.Errorf("x-device-model = %q, want the coarse model", header.Get("x-device-model"))
	}
	if runtime.GOOS == "linux" && header.Get("x-device-os") != "Linux" ||
		runtime.GOOS == "windows" && header.Get("x-device-os") != "Windows" {
		t.Errorf("x-device-os = %q on %s", header.Get("x-device-os"), runtime.GOOS)
	}
	for _, value := range []string{header.Get("x-ver-os"), header.Get("x-device-os")} {
		if strings.ContainsAny(value, "\r\n") || len(value) > 64 {
			t.Errorf("header value %q is not a bounded single line", value)
		}
	}
	for name := range header {
		known := false
		for _, allowed := range hwid.Names {
			known = known || http.CanonicalHeaderKey(allowed) == name
		}
		if !known {
			t.Errorf("Apply set %q, which is not one of the device headers", name)
		}
	}
}
