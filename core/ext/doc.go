// Package ext runs app-owned extension workers and supplies the manifest,
// package and minisign functions used by the sora-ext authoring CLI.
//
// The Flutter app (app/lib/src/ext) owns installation, updates, rollback,
// enablement, settings, grants, catalog/cache and revocation enforcement.
// Panels call its permission-checked PanelBridge directly. The app verifies
// packages and pins author keys before delegating any worker to the core.
//
// ExtensionHost exposes only RunWorker, a bidirectional lifecycle stream
// authenticated by the app control token and transport. The first message
// supplies the verified manifest with grants, source and background config;
// later messages carry replies to app bridge calls. The core has no on-disk
// extension registry or revocation cache.
//
// Scheduler applies interval bounds, overlap protection, failure limits and
// kill-switch pause. Each run uses a disposable goja process with CPU, memory
// and wall-time budgets. Worker calls are permission-checked; app-owned APIs
// go back through PanelBridge, and net.fetch uses an allowlisted HTTPS Fetcher
// bound to the current VPN proxy. Without a proxy it fails closed. Closing
// the lifecycle stream cancels active work and unregisters the task.
//
// ParseManifestFull, Package.Verify/VerifyWithKey, MakeChecksums, SignPayload
// and VerifyPayload support CLI validation, packing, signing and publishing.
// Theme and routing assets are applied by the app; network hooks are not run.
package ext
