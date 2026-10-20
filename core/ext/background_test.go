package ext

import (
	"archive/zip"
	"bytes"
	"context"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestParseBackgroundConfig(t *testing.T) {
	cases := []struct {
		name string
		raw  string
		want BackgroundConfig
		ok   bool
	}{
		{"empty object keeps defaults", `{}`, BackgroundConfig{true, 60}, true},
		{"full document", `{"enabled":false,"interval_minutes":120}`, BackgroundConfig{false, 120}, true},
		{"unknown fields ignored", `{"enabled":true,"interval_minutes":45,"ui_theme":"dark"}`, BackgroundConfig{true, 45}, true},
		{"missing enabled defaults true", `{"interval_minutes":30}`, BackgroundConfig{true, 30}, true},
		{"missing interval defaults 60", `{"enabled":false}`, BackgroundConfig{false, 60}, true},
		{"interval clamped to floor", `{"interval_minutes":1}`, BackgroundConfig{true, 15}, true},
		{"interval clamped to ceiling", `{"interval_minutes":20000}`, BackgroundConfig{true, 10080}, true},
		{"fractional interval truncates like Dart toInt", `{"interval_minutes":90.9}`, BackgroundConfig{true, 90}, true},
		{"bad enabled type falls back", `{"enabled":"yes"}`, BackgroundConfig{true, 60}, false},
		{"bad interval type falls back", `{"interval_minutes":"60"}`, BackgroundConfig{true, 60}, false},
		{"array document falls back", `[1,2]`, BackgroundConfig{true, 60}, false},
		{"syntax error falls back", `{"enabled":`, BackgroundConfig{true, 60}, false},
		{"empty file falls back", ``, BackgroundConfig{true, 60}, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, ok := ParseBackgroundConfig([]byte(tc.raw))
			if ok != tc.ok {
				t.Fatalf("ok = %v, want %v", ok, tc.ok)
			}
			if got != tc.want {
				t.Fatalf("got %+v, want %+v", got, tc.want)
			}
		})
	}
}

func TestBackgroundDefaults(t *testing.T) {
	if got := BackgroundDefaults(nil); got != (BackgroundConfig{true, 60}) {
		t.Fatalf("nil ext: got %+v", got)
	}
	x := &ManifestExt{}
	if got := BackgroundDefaults(x); got != (BackgroundConfig{true, 60}) {
		t.Fatalf("no background_task: got %+v", got)
	}
	x.Background = &BackgroundTask{IntervalMinutes: 120, Entry: "worker.js"}
	if got := BackgroundDefaults(x); got != (BackgroundConfig{true, 120}) {
		t.Fatalf("declared 120: got %+v", got)
	}
	x.Background.IntervalMinutes = 3
	if got := BackgroundDefaults(x); got != (BackgroundConfig{true, 15}) {
		t.Fatalf("declared 3 must clamp to 15: got %+v", got)
	}
}

// buildRawPackage assembles a signed .soraext from raw manifest bytes, so
// tests can install manifests carrying the v2-runtime keys (background_task,
// network_hosts) that the Manifest struct does not model.
func buildRawPackage(t *testing.T, manRaw []byte) []byte {
	t.Helper()
	strFiles := map[string]string{
		manifestName: string(manRaw),
		"panel.html": "<html><body>hi</body></html>",
	}
	checksums := MakeChecksums(strFiles)
	sig, err := SignPayload(testSeed, "test key", sigFileChecksums, time.Now().Unix(), []byte(checksums))
	if err != nil {
		t.Fatal(err)
	}
	binFiles := map[string][]byte{
		manifestName:  manRaw,
		"panel.html":  []byte("<html><body>hi</body></html>"),
		checksumsName: []byte(checksums),
		signatureName: []byte(sig),
	}
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	for _, name := range []string{manifestName, checksumsName, signatureName, "panel.html"} {
		w, err := zw.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := w.Write(binFiles[name]); err != nil {
			t.Fatal(err)
		}
	}
	if err := zw.Close(); err != nil {
		t.Fatal(err)
	}
	return buf.Bytes()
}

// installBg installs an extension entitled to background workers + net.fetch
// whose manifest declares the given background interval.
func installBg(t *testing.T, s *Store, minutes int) {
	t.Helper()
	raw := rawManifestWith(t, bgManifest(t), map[string]any{
		"background_task": map[string]any{"interval_minutes": minutes, "entry": "worker.js"},
		"network_hosts":   []string{"api.example.com"},
	})
	pkg, err := OpenBytes(buildRawPackage(t, raw))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := s.Install(pkg, SourceSideload, []string{"background", "net.fetch"}); err != nil {
		t.Fatalf("install: %v", err)
	}
}

func writeBackgroundFile(t *testing.T, s *Store, id, body string) {
	t.Helper()
	if err := os.WriteFile(s.backgroundPath(id), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
}

func TestGetBackgroundConfigMissingSeedsFromManifest(t *testing.T) {
	s := testStore(t)
	installBg(t, s, 30)
	cfg, err := s.GetBackgroundConfig("com.example.hello")
	if err != nil {
		t.Fatal(err)
	}
	if cfg != (BackgroundConfig{true, 30}) {
		t.Fatalf("got %+v, want {true 30}", cfg)
	}
}

func TestGetBackgroundConfigNoDeclarationFallsBackToHour(t *testing.T) {
	s := testStore(t)
	installHello(t, s, "1.0.0")
	cfg, err := s.GetBackgroundConfig("com.example.hello")
	if err != nil {
		t.Fatal(err)
	}
	if cfg != (BackgroundConfig{true, 60}) {
		t.Fatalf("got %+v, want {true 60}", cfg)
	}
}

func TestGetBackgroundConfigReadsFile(t *testing.T) {
	s := testStore(t)
	installBg(t, s, 30)
	writeBackgroundFile(t, s, "com.example.hello", `{"enabled":false,"interval_minutes":120}`)
	cfg, err := s.GetBackgroundConfig("com.example.hello")
	if err != nil {
		t.Fatal(err)
	}
	if cfg != (BackgroundConfig{false, 120}) {
		t.Fatalf("got %+v, want {false 120}", cfg)
	}
}

func TestGetBackgroundConfigClampsFile(t *testing.T) {
	s := testStore(t)
	installBg(t, s, 30)
	writeBackgroundFile(t, s, "com.example.hello", `{"interval_minutes":5}`)
	cfg, err := s.GetBackgroundConfig("com.example.hello")
	if err != nil {
		t.Fatal(err)
	}
	if cfg.IntervalMinutes != 15 || !cfg.Enabled {
		t.Fatalf("hand-edited interval must clamp to 15: got %+v", cfg)
	}
}

func TestGetBackgroundConfigCorruptFallsBack(t *testing.T) {
	s := testStore(t)
	installBg(t, s, 30)
	writeBackgroundFile(t, s, "com.example.hello", `{"interval_minutes":`)
	cfg, err := s.GetBackgroundConfig("com.example.hello")
	if err != nil {
		t.Fatal(err)
	}
	if cfg != (BackgroundConfig{true, 30}) {
		t.Fatalf("corrupt file must fall back to seeded defaults: got %+v", cfg)
	}
}

func TestGetBackgroundConfigNotInstalled(t *testing.T) {
	s := testStore(t)
	if _, err := s.GetBackgroundConfig("com.example.nope"); err == nil {
		t.Fatal("want an error for an unknown extension")
	}
}

func TestUninstallRemovesBackgroundFile(t *testing.T) {
	s := testStore(t)
	installBg(t, s, 30)
	writeBackgroundFile(t, s, "com.example.hello", `{"enabled":false,"interval_minutes":120}`)
	if err := s.Uninstall("com.example.hello"); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(s.dir, "com.example.hello.background.json")); !os.IsNotExist(err) {
		t.Fatal("background.json must be removed on uninstall")
	}
}

func TestRegisterConfigDisabledNeverRuns(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60)
	var runs atomic.Int32
	run := func(ctx context.Context, env *WorkerEnv) error {
		runs.Add(1)
		return nil
	}
	if err := s.RegisterConfig(m, x, BackgroundConfig{Enabled: false, IntervalMinutes: 60}, run); err != nil {
		t.Fatal(err)
	}
	task, ok := s.Task(m.ID)
	if !ok {
		t.Fatal("disabled task must still be registered")
	}
	if !task.disabled.Load() {
		t.Fatal("task must be marked disabled")
	}
	s.Start(context.Background())
	defer s.Stop()
	if task.ctx != nil {
		t.Fatal("disabled task must not own a ticker loop")
	}
	if runs.Load() != 0 {
		t.Fatalf("disabled worker ran %d times", runs.Load())
	}
}

func TestRegisterConfigIntervalOverride(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60) // manifest declares 60
	if err := s.RegisterConfig(m, x, BackgroundConfig{Enabled: true, IntervalMinutes: 120}, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	if task.Interval != 2*time.Hour {
		t.Fatalf("user override 120 min: interval = %s, want 2h", task.Interval)
	}
	if err := s.RegisterConfig(m, x, BackgroundConfig{Enabled: true, IntervalMinutes: 1}, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ = s.Task(m.ID)
	if task.Interval != MinWorkerInterval {
		t.Fatalf("user override 1 min must clamp to 15 min: got %s", task.Interval)
	}
}

func TestRegisterConfigReenableStartsLoop(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 60)
	s.Start(context.Background())
	defer s.Stop()
	if err := s.RegisterConfig(m, x, BackgroundConfig{Enabled: false, IntervalMinutes: 60}, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	if task.ctx != nil {
		t.Fatal("disabled task must not start a loop while the scheduler runs")
	}
	if err := s.RegisterConfig(m, x, BackgroundConfig{Enabled: true, IntervalMinutes: 60}, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ = s.Task(m.ID)
	if task.ctx == nil {
		t.Fatal("re-enabling must start the ticker loop")
	}
}

func TestRegisterAppliesManifestSeededDefaults(t *testing.T) {
	s := NewScheduler(nil)
	m, x := bgPair(t, 1) // declared 1 min: seeded default clamps to 15
	if err := s.Register(m, x, okRun); err != nil {
		t.Fatal(err)
	}
	task, _ := s.Task(m.ID)
	if task.Interval != MinWorkerInterval {
		t.Fatalf("interval = %s, want %s", task.Interval, MinWorkerInterval)
	}
	if task.disabled.Load() {
		t.Fatal("plain Register must leave the task enabled")
	}
}

func logText(s *Scheduler, extID string) string {
	var b strings.Builder
	for _, e := range s.Hub().Log(extID).Entries() {
		b.WriteString(e.Message)
		b.WriteByte('\n')
	}
	return b.String()
}
