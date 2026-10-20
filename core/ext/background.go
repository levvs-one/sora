// Background task runtime configuration (<id>.background.json).
//
// The app (Dart ExtensionStore, app/lib/src/ext/store.dart) writes one JSON
// file per extension next to <id>.settings.json:
//
//	{"enabled": true, "interval_minutes": 60}
//
// It is the user's override of the manifest's declared background_task:
// "enabled" toggles the worker on/off, "interval_minutes" replaces the
// declared interval. The Go runtime reads the file through
// Store.GetBackgroundConfig and the Scheduler applies it at Register time
// via RegisterConfig.
//
// Parsing is deliberately tolerant, mirroring the Dart side: a missing file
// seeds defaults from the manifest declaration, a corrupt file or a bad
// field falls back to defaults (the next app-side save repairs the file),
// and the interval is always clamped — a hand-edited file can never
// schedule runs more often than the platform allows.
package ext

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// DefaultBackgroundIntervalMinutes is the fallback worker interval in
// minutes when neither the file nor the manifest declares one. It mirrors
// the Dart BackgroundTaskConfig.defaultIntervalMinutes.
const DefaultBackgroundIntervalMinutes = 60

// BackgroundConfig is the runtime user configuration for one extension's
// background worker, read from <store>/<id>.background.json.
//
// JSON schema (mirrors the Dart BackgroundTaskConfig):
//
//	{
//	  "enabled": true,            // optional, defaults to true
//	  "interval_minutes": 60      // optional, defaults to 60, clamped to 15..10080
//	}
//
// Unknown fields are ignored. The interval is clamped into
// [MinWorkerInterval, MaxWorkerInterval] on read, so a hand-edited file
// cannot schedule runs more often than the platform allows.
type BackgroundConfig struct {
	// Enabled toggles the background worker. False means the worker is
	// registered but never runs; the extension itself stays installed and
	// enabled.
	Enabled bool `json:"enabled"`
	// IntervalMinutes is the user's desired period in whole minutes. It
	// replaces the manifest's declared interval and is clamped into
	// [15, 10080] (see clampBackgroundMinutes).
	IntervalMinutes int `json:"interval_minutes"`
}

// DefaultBackgroundConfig returns the enabled-every-hour default, mirroring
// the Dart BackgroundTaskConfig defaults.
func DefaultBackgroundConfig() BackgroundConfig {
	return BackgroundConfig{Enabled: true, IntervalMinutes: DefaultBackgroundIntervalMinutes}
}

// BackgroundDefaults seeds the config from the manifest's declared
// background_task (the author's wish, clamped), enabled. It mirrors the
// Dart ExtensionStore.getBackgroundTask seed: the settings show what the
// extension would do out of the box.
func BackgroundDefaults(x *ManifestExt) BackgroundConfig {
	cfg := DefaultBackgroundConfig()
	if x != nil && x.Background != nil {
		cfg.IntervalMinutes = x.Background.IntervalMinutes
	}
	cfg.IntervalMinutes = clampBackgroundMinutes(cfg.IntervalMinutes)
	return cfg
}

// clampBackgroundMinutes clamps whole minutes into the worker schedule
// bounds [MinWorkerInterval, MaxWorkerInterval], mirroring the Dart
// BackgroundTaskConfig.clampInterval (15..10080).
func clampBackgroundMinutes(minutes int) int {
	if minutes < int(MinWorkerInterval/time.Minute) {
		return int(MinWorkerInterval / time.Minute)
	}
	if minutes > MaxBackgroundIntervalMinutes {
		return MaxBackgroundIntervalMinutes
	}
	return minutes
}

// ParseBackgroundConfig parses one <id>.background.json document. It is
// tolerant by design, mirroring the Dart side: unknown fields are ignored,
// a missing field keeps its default, and ok=false (with defaults returned)
// on any structural problem — a non-object document, a type mismatch, or a
// JSON syntax error. The caller falls back to defaults; the next app-side
// save repairs the file.
func ParseBackgroundConfig(raw []byte) (cfg BackgroundConfig, ok bool) {
	cfg = DefaultBackgroundConfig()
	// Decode into anys so a wrong field type (e.g. "enabled": 1, which the
	// Dart `as bool?` cast would reject) fails the whole document into
	// defaults instead of silently keeping a half-parsed config.
	var doc struct {
		Enabled         any `json:"enabled"`
		IntervalMinutes any `json:"interval_minutes"`
	}
	if err := json.Unmarshal(raw, &doc); err != nil {
		return DefaultBackgroundConfig(), false
	}
	switch v := doc.Enabled.(type) {
	case nil:
		// absent: keep the default (true)
	case bool:
		cfg.Enabled = v
	default:
		return DefaultBackgroundConfig(), false
	}
	switch v := doc.IntervalMinutes.(type) {
	case nil:
		// absent: keep the default (60)
	case float64:
		// The Dart side reads the field as num?.toInt(): fractional
		// values truncate toward zero. Mirror that.
		cfg.IntervalMinutes = int(v)
	default:
		return DefaultBackgroundConfig(), false
	}
	cfg.IntervalMinutes = clampBackgroundMinutes(cfg.IntervalMinutes)
	return cfg, true
}

// backgroundPath is the per-extension background task config file,
// mirroring the Dart ExtensionStore._backgroundFile ("<id>.background.json").
func (s *Store) backgroundPath(id string) string {
	return filepath.Join(s.dir, id+".background.json")
}

// GetBackgroundConfig reads the user's background task override for an
// installed extension. A missing file seeds defaults from the manifest's
// declared background_task (enabled); a corrupt file falls back to the same
// defaults, mirroring the Dart ExtensionStore.getBackgroundTask.
func (s *Store) GetBackgroundConfig(id string) (BackgroundConfig, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	inst, ok := s.installed[id]
	if !ok {
		return BackgroundConfig{}, errs.Newf(errs.CodeNotFound, KeyLifecycle, "ext: %q is not installed", id)
	}
	var x ManifestExt
	if len(inst.ExtJSON) > 0 {
		// The registry only ever stores what marshalManifestExt wrote, so
		// this cannot fail; a failure seeds the unseeded default instead
		// of erroring the read.
		_ = json.Unmarshal(inst.ExtJSON, &x)
	}
	def := BackgroundDefaults(&x)
	raw, err := os.ReadFile(s.backgroundPath(id)) //nolint:gosec // fixed suffix inside the store dir
	if err != nil {
		if os.IsNotExist(err) {
			return def, nil
		}
		return BackgroundConfig{}, errs.Newf(errs.CodeInternal, KeyLifecycle,
			"ext: cannot read the background config of %q: %v", id, err)
	}
	if cfg, ok := ParseBackgroundConfig(raw); ok {
		return cfg, nil
	}
	return def, nil
}
