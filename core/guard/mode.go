// Kill-switch modes: how far the block goes.
//
//   - ModeStandard (the default): the kill switch is armed while the session
//     asks for it and lifted when the session ends or the core exits.
//   - modeStrict (internal only): the block is persistent. Once armed it
//     survives a core crash, a clean exit, and a reboot, until the user
//     explicitly turns the kill switch off. A strictWanted marker in
//     Options.StateDir records the intent; Guard.reconcile re-arms the
//     firewall from the marker at startup. The mode is not exposed:
//     enabling a persistent firewall block is a product decision the
//     owner has not taken, so the machinery stays tested but
//     unreachable from the public API.
//   - ModeOff: the kill switch never arms. Asking for it fails instead of
//     silently reporting a block that is not there.
//
// ModeStandard is the zero value so existing callers keep their behaviour.
package guard

import (
	"errors"
	"os"
	"path/filepath"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// Mode selects how far the kill switch goes.
type Mode int

const (
	// ModeStandard arms the kill switch while the session asks for it and
	// lifts it on restore. This is the zero value and the historical
	// behaviour.
	ModeStandard Mode = iota
	// modeStrict keeps the block armed across crashes, clean exits, and
	// reboots until the kill switch is explicitly turned off. Unexported:
	// no caller outside this package may select it.
	modeStrict
	// ModeOff never arms the kill switch; requesting it is an error.
	ModeOff
)

// String renders the mode for logs, diagnostics, and user-facing settings.
func (m Mode) String() string {
	switch m {
	case ModeStandard:
		return "standard"
	case modeStrict:
		return "strict"
	case ModeOff:
		return "off"
	default:
		return "unknown"
	}
}

// parseMode parses a mode name. Matching is case-insensitive; anything
// else fails closed so a typo can never silently pick a weaker mode than
// intended. Unexported: the persistent mode is not user-facing, so no
// caller outside this package parses mode names.
func parseMode(name string) (Mode, error) {
	switch strings.ToLower(strings.TrimSpace(name)) {
	case "standard":
		return ModeStandard, nil
	case "strict":
		return modeStrict, nil
	case "off":
		return ModeOff, nil
	default:
		return ModeStandard, errs.Newf(errs.CodeInvalidArgument, errs.KeyGuardFirewallFail,
			"guard: unknown kill-switch mode %q (want off, standard, or strict)", name)
	}
}

// strictMarkerName is the file in Options.StateDir recording that strict
// mode wants the block armed. Its presence — not its content — is the
// intent: a crash or a reboot must not be able to clear it, only an
// explicit user action removes it.
const strictMarkerName = "killswitch.strict"

// strictMarkerVersion versions the marker content so a future format can
// be distinguished from a foreign file that happens to share the name.
const strictMarkerVersion = "sora-strict-v1\n"

// strictWanted reports whether the state directory carries a strict-mode
// marker: the user asked for a persistent block and never turned it off.
// Callers use it at startup to decide between Guard.reconcile (re-arm) and
// stale-table cleanup (remove). A corrupt directory fails closed towards
// keeping the block: an unreadable state must not silently drop
// protection the user asked for. Unexported with the rest of the strict
// machinery.
func strictWanted(stateDir string) bool {
	if stateDir == "" {
		return false
	}
	content, err := os.ReadFile(filepath.Join(stateDir, strictMarkerName))
	if err != nil {
		return false
	}
	return len(content) > 0
}

// writeStrictMarker records the persistent strict intent. The write is
// atomic (temporary file plus rename) so a crash mid-write can never leave
// a half-written marker behind.
func writeStrictMarker(stateDir string) error {
	if stateDir == "" {
		return errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: strict mode needs a state directory for its marker")
	}
	if err := os.MkdirAll(stateDir, 0o700); err != nil {
		return errs.Newf(errs.CodeInternal, errs.KeyGuardFirewallFail,
			"guard: cannot create the kill-switch state directory: %v", err)
	}
	path := filepath.Join(stateDir, strictMarkerName)
	tmp, err := os.CreateTemp(stateDir, ".killswitch.strict.*")
	if err != nil {
		return errs.Newf(errs.CodeInternal, errs.KeyGuardFirewallFail,
			"guard: cannot stage the strict-mode marker: %v", err)
	}
	tmpName := tmp.Name()
	if _, err := tmp.WriteString(strictMarkerVersion); err != nil {
		_ = tmp.Close()
		_ = os.Remove(tmpName)
		return errs.Newf(errs.CodeInternal, errs.KeyGuardFirewallFail,
			"guard: cannot write the strict-mode marker: %v", err)
	}
	if err := tmp.Close(); err != nil {
		_ = os.Remove(tmpName)
		return errs.Newf(errs.CodeInternal, errs.KeyGuardFirewallFail,
			"guard: cannot write the strict-mode marker: %v", err)
	}
	if err := os.Chmod(tmpName, 0o600); err != nil {
		_ = os.Remove(tmpName)
		return errs.Newf(errs.CodeInternal, errs.KeyGuardFirewallFail,
			"guard: cannot protect the strict-mode marker: %v", err)
	}
	if err := os.Rename(tmpName, path); err != nil {
		_ = os.Remove(tmpName)
		return errs.Newf(errs.CodeInternal, errs.KeyGuardFirewallFail,
			"guard: cannot publish the strict-mode marker: %v", err)
	}
	return nil
}

// removeStrictMarker clears the persistent strict intent. A missing marker
// is success so explicit disables stay idempotent.
func removeStrictMarker(stateDir string) error {
	if stateDir == "" {
		return nil
	}
	err := os.Remove(filepath.Join(stateDir, strictMarkerName))
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return errs.Newf(errs.CodeInternal, errs.KeyGuardFirewallFail,
			"guard: cannot clear the strict-mode marker: %v", err)
	}
	return nil
}
