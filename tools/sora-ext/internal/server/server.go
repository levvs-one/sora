// Package server is the local development server behind `sora-ext dev`
// and `sora-ext serve`.
//
// It serves a project directory over 127.0.0.1 only (never off-device) and
// injects scripts into served HTML:
//
//   - the window.soraExt mock (serve: browser testing without the app),
//   - a live-reload snippet (dev: refresh on file change).
//
// Endpoints under /__soraext__/:
//
//	/mock.js          the injected mock script
//	/manifest.json   the project's sora-extension.json
//	/fixtures.json   mock fixture data (or {})
//	/events          server-sent events (reload, soraext-event)
//	/event           POST {"kind","detail"} -> broadcasts a mock event
//	/calls           GET: the mock's API call log; POST: append an entry
package server

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

// Options configures the server.
type Options struct {
	Dir          string
	Port         int
	InjectMock   bool
	LiveReload   bool
	FixturesPath string // "" = built-in defaults
}

// Server is a running dev server.
type Server struct {
	opts     Options
	mux      *http.ServeMux
	mu       sync.Mutex
	clients  map[chan string]bool
	calls    []map[string]any
	fixtures []byte
}

// New creates a server (call Run to start it).
func New(opts Options) *Server {
	s := &Server{opts: opts, mux: http.NewServeMux(), clients: map[chan string]bool{}, calls: []map[string]any{}}
	if opts.FixturesPath != "" {
		if b, err := os.ReadFile(opts.FixturesPath); err == nil {
			s.fixtures = b
		}
	}
	if len(s.fixtures) == 0 {
		s.fixtures = []byte("{}")
	}
	s.routes()
	return s
}

// BroadcastEvent pushes a mock window.soraExt event to connected pages.
func (s *Server) BroadcastEvent(kind, detail string) {
	msg, _ := json.Marshal(map[string]string{"kind": kind, "detail": detail})
	s.broadcast("soraext-event", string(msg))
}

// BroadcastReload tells live-reload clients to refresh.
func (s *Server) BroadcastReload() {
	s.broadcast("reload", "{}")
}

func (s *Server) broadcast(event, data string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for ch := range s.clients {
		select {
		case ch <- event + "\n" + data:
		default:
		}
	}
}

func (s *Server) routes() {
	s.mux.HandleFunc("/__soraext__/mock.js", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/javascript")
		_, _ = w.Write(mockJS)
	})
	s.mux.HandleFunc("/__soraext__/manifest.json", func(w http.ResponseWriter, r *http.Request) {
		b, err := os.ReadFile(filepath.Join(s.opts.Dir, "sora-extension.json"))
		if err != nil {
			http.Error(w, "no sora-extension.json", http.StatusNotFound)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write(b)
	})
	s.mux.HandleFunc("/__soraext__/fixtures.json", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write(s.fixtures)
	})
	s.mux.HandleFunc("/__soraext__/events", s.handleEvents)
	s.mux.HandleFunc("/__soraext__/event", s.handleFireEvent)
	s.mux.HandleFunc("/__soraext__/calls", s.handleCalls)
	s.mux.HandleFunc("/", s.handleFile)
}

func (s *Server) handleEvents(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	fl, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", http.StatusInternalServerError)
		return
	}
	ch := make(chan string, 8)
	s.mu.Lock()
	s.clients[ch] = true
	s.mu.Unlock()
	defer func() {
		s.mu.Lock()
		delete(s.clients, ch)
		s.mu.Unlock()
	}()
	_, _ = fmt.Fprintf(w, "event: hello\ndata: {}\n\n")
	fl.Flush()
	for {
		select {
		case <-r.Context().Done():
			return
		case msg := <-ch:
			parts := strings.SplitN(msg, "\n", 2)
			_, _ = fmt.Fprintf(w, "event: %s\ndata: %s\n\n", parts[0], parts[1])
			fl.Flush()
		}
	}
}

func (s *Server) handleFireEvent(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST only", http.StatusMethodNotAllowed)
		return
	}
	var ev struct {
		Kind   string `json:"kind"`
		Detail string `json:"detail"`
	}
	body, _ := io.ReadAll(io.LimitReader(r.Body, 1<<20))
	if err := json.Unmarshal(body, &ev); err != nil || ev.Kind == "" {
		http.Error(w, `want JSON {"kind": "...", "detail": "..."}`, http.StatusBadRequest)
		return
	}
	s.BroadcastEvent(ev.Kind, ev.Detail)
	w.WriteHeader(http.StatusNoContent)
}

func (s *Server) handleCalls(w http.ResponseWriter, r *http.Request) {
	s.mu.Lock()
	defer s.mu.Unlock()
	switch r.Method {
	case http.MethodGet:
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(s.calls)
	case http.MethodPost:
		var e map[string]any
		body, _ := io.ReadAll(io.LimitReader(r.Body, 1<<20))
		if err := json.Unmarshal(body, &e); err != nil {
			http.Error(w, "bad JSON", http.StatusBadRequest)
			return
		}
		s.calls = append(s.calls, e)
		w.WriteHeader(http.StatusNoContent)
	default:
		http.Error(w, "GET/POST only", http.StatusMethodNotAllowed)
	}
}

func (s *Server) handleFile(w http.ResponseWriter, r *http.Request) {
	// os.Root confines every lookup to the project directory, so a request
	// path with "..", an absolute path or a symlink cannot leave it.
	root, err := os.OpenRoot(s.opts.Dir)
	if err != nil {
		http.Error(w, "project directory unavailable", http.StatusInternalServerError)
		return
	}
	defer func() { _ = root.Close() }()
	name := filepath.FromSlash(strings.TrimPrefix(r.URL.Path, "/"))
	f, err := root.Open(name)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer func() { _ = f.Close() }()
	st, err := f.Stat()
	if err != nil || st.IsDir() {
		http.NotFound(w, r)
		return
	}
	if strings.HasSuffix(strings.ToLower(name), ".html") {
		b, err := io.ReadAll(f)
		if err != nil {
			http.Error(w, "read error", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_, _ = w.Write(s.inject(b))
		return
	}
	http.ServeContent(w, r, st.Name(), st.ModTime(), f)
}

// inject adds the mock and/or live-reload scripts to HTML.
func (s *Server) inject(b []byte) []byte {
	var tags []string
	if s.opts.InjectMock {
		tags = append(tags, `<script src="/__soraext__/mock.js"></script>`)
	}
	if s.opts.LiveReload {
		tags = append(tags, `<script>
(function(){var es=new EventSource("/__soraext__/events");
es.addEventListener("reload",function(){location.reload()});})();
</script>`)
	}
	if len(tags) == 0 {
		return b
	}
	snippet := []byte(strings.Join(tags, "\n"))
	if i := bytes.LastIndex(bytes.ToLower(b), []byte("</head>")); i >= 0 {
		out := make([]byte, 0, len(b)+len(snippet))
		out = append(out, b[:i]...)
		out = append(out, snippet...)
		out = append(out, b[i:]...)
		return out
	}
	return append(snippet, b...)
}

// Run starts the server on 127.0.0.1:port. It blocks until the listener
// errors.
func (s *Server) Run() error {
	addr := fmt.Sprintf("127.0.0.1:%d", s.opts.Port)
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("listen %s: %w (is another sora-ext dev/serve running?)", addr, err)
	}
	return http.Serve(ln, s.mux)
}

// Snapshot hashes the file tree: name, size and mtime of every file.
// Polling keeps the tool dependency-free (no fsnotify); 500 ms is plenty
// for a dev loop and cheap on any machine.
func Snapshot(dir string) (string, error) {
	var names []string
	meta := map[string]string{}
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}
		rel, _ := filepath.Rel(dir, path)
		rel = filepath.ToSlash(rel)
		if strings.HasPrefix(rel, ".") || strings.HasSuffix(rel, ".soraext") {
			return nil
		}
		names = append(names, rel)
		meta[rel] = fmt.Sprintf("%d/%d", info.Size(), info.ModTime().UnixNano())
		return nil
	})
	if err != nil {
		return "", err
	}
	sort.Strings(names)
	h := sha256.New()
	for _, n := range names {
		_, _ = fmt.Fprintf(h, "%s=%s\n", n, meta[n])
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

// Watch polls dir and calls onChange whenever the snapshot changes.
// It returns when stop is closed.
func Watch(dir string, interval time.Duration, stop <-chan struct{}, onChange func()) {
	last, _ := Snapshot(dir)
	t := time.NewTicker(interval)
	defer t.Stop()
	for {
		select {
		case <-stop:
			return
		case <-t.C:
			cur, err := Snapshot(dir)
			if err != nil || cur == last {
				continue
			}
			last = cur
			onChange()
		}
	}
}
