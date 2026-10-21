package server

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestHandleFileStaysInsideTheProject pins that the dev server serves only
// files under its project directory, whatever the request path says.
func TestHandleFileStaysInsideTheProject(t *testing.T) {
	parent := t.TempDir()
	project := filepath.Join(parent, "project")
	if err := os.Mkdir(project, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(parent, "secret.txt"), []byte("outside"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(project, "panel.js"), []byte("inside"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(filepath.Join(parent, "secret.txt"), filepath.Join(project, "link.txt")); err != nil {
		t.Fatal(err)
	}
	s := New(Options{Dir: project})
	get := func(path string) *httptest.ResponseRecorder {
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		r.URL.Path = path
		w := httptest.NewRecorder()
		s.handleFile(w, r)
		return w
	}
	if w := get("/panel.js"); w.Code != http.StatusOK || w.Body.String() != "inside" {
		t.Fatalf("project file: %d %q", w.Code, w.Body.String())
	}
	for _, path := range []string{"/../secret.txt", "/link.txt", "/" + filepath.Join(parent, "secret.txt")} {
		if w := get(path); w.Code == http.StatusOK || strings.Contains(w.Body.String(), "outside") {
			t.Errorf("%s escaped the project: %d %q", path, w.Code, w.Body.String())
		}
	}
}

// TestHandleFileHidesTheAuthorKey pins that the key scaffold writes into the
// project is never served, nor any other hidden path or key file.
func TestHandleFileHidesTheAuthorKey(t *testing.T) {
	project := t.TempDir()
	for name, body := range map[string]string{
		".sora/author.key": "secret", ".env": "secret", "spare.key": "secret", "panel.js": "inside",
	} {
		p := filepath.Join(project, filepath.FromSlash(name))
		if err := os.MkdirAll(filepath.Dir(p), 0o700); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte(body), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	s := New(Options{Dir: project})
	for _, path := range []string{"/.sora/author.key", "/.sora/", "/.env", "/spare.key", "/SPARE.KEY"} {
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		r.URL.Path = path
		w := httptest.NewRecorder()
		s.handleFile(w, r)
		if w.Code == http.StatusOK || strings.Contains(w.Body.String(), "secret") {
			t.Errorf("%s was served: %d %q", path, w.Code, w.Body.String())
		}
	}
	r := httptest.NewRequest(http.MethodGet, "/panel.js", nil)
	w := httptest.NewRecorder()
	s.handleFile(w, r)
	if w.Code != http.StatusOK {
		t.Fatalf("panel.js: %d", w.Code)
	}
}
