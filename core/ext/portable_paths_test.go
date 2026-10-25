package ext

import (
	"encoding/json"
	"os"
	"strings"
	"testing"
)

func TestPortableArchivePathsRejectWindowsAliases(t *testing.T) {
	data, err := os.ReadFile("../../app/test/fixtures/ext/portable_paths.json")
	if err != nil {
		t.Fatal(err)
	}
	var vectors struct {
		Unsafe    []string   `json:"unsafe"`
		Conflicts [][]string `json:"conflicts"`
		Valid     []string   `json:"valid"`
	}
	if err := json.Unmarshal(data, &vectors); err != nil {
		t.Fatal(err)
	}
	cases := make([][]string, 0, len(vectors.Unsafe)+len(vectors.Conflicts))
	for _, name := range vectors.Unsafe {
		cases = append(cases, []string{name})
	}
	cases = append(cases, vectors.Conflicts...)
	for _, names := range cases {
		t.Run(strings.Join(names, "+"), func(t *testing.T) {
			extra := map[string]string{}
			for _, name := range names {
				extra[name] = "signed alias content"
			}
			if _, err := OpenBytes(buildPackage(t, testManifest(t), extra, nil)); err == nil {
				t.Fatal("unsafe or ambiguous signed archive was accepted")
			}
			pkg, err := OpenBytes(buildPackage(t, testManifest(t), nil, nil))
			if err != nil {
				t.Fatal(err)
			}
			for _, name := range names {
				pkg.Files[name] = []byte("changed after opening")
			}
			if err := pkg.Verify(); err == nil || !strings.Contains(err.Error(), "path") {
				t.Fatalf("mutable file map did not reach path validation: %v", err)
			}
		})
	}
	extra := map[string]string{}
	for _, name := range vectors.Valid {
		extra[name] = "portable content"
	}
	pkg, err := OpenBytes(buildPackage(t, testManifest(t), extra, nil))
	if err != nil {
		t.Fatal(err)
	}
	if err := pkg.Verify(); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{strings.Repeat("a", 256), strings.Repeat("я", 128), string([]byte{0xff})} {
		if isSafeArchivePath(name) {
			t.Errorf("invalid component/UTF-8 bytes accepted: %q", name)
		}
	}
	for _, name := range []string{strings.Repeat("a", 255), strings.Repeat("я", 127), strings.Repeat("a", 255) + "/" + strings.Repeat("b", 254) + "/x"} {
		if !isSafeArchivePath(name) {
			t.Errorf("valid boundary rejected: %q", name)
		}
	}
}
