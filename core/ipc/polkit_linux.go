//go:build linux

package ipc

import (
	"context"
	"time"

	"github.com/godbus/dbus/v5"
)

// PolkitAction authorizes full core control via service/linux/sora.policy.
// Active local users are allowed without a password (allow_active=yes):
// any process in the active local session holds full control, the same
// trust boundary as the Windows build. Do NOT change the policy to auth_*:
// polkitAllows checks authorization with interaction disabled, so an
// auth_* default would always return a challenge and silently kill the
// control path. sora owns the action because non-root checks of other
// processes require action ownership.
const PolkitAction = "io.github.levvs-one.sora.control"

// PolkitReadAction authorizes read-only access (status, statistics, events,
// logs) via service/linux/sora.policy. Active local users need no password;
// anything mutating or private requires PolkitAction (SORA-H2).
const PolkitReadAction = "io.github.levvs-one.sora.read"

// polkitTimeout bounds authorization requests; timeout rejects the peer.
const polkitTimeout = 3 * time.Second

// polkitSubject encodes the kernel-reported client as (sa{sv}). Zero start time
// makes polkit resolve process timing to prevent reused PIDs inheriting
// authorization.
type polkitSubject struct {
	Kind    string
	Details map[string]dbus.Variant
}

type polkitResult struct {
	Authorized bool
	Challenge  bool
	Details    map[string]string
}

// polkitAllows checks the peer's action authorization. Missing bus, polkit, or
// policy rejects the connection.
func polkitAllows(peer Peer, action string) bool {
	if !peer.Verified || peer.PID <= 0 {
		return false
	}
	conn, err := dbus.ConnectSystemBus()
	if err != nil {
		return false
	}
	defer func() { _ = conn.Close() }()
	subject := polkitSubject{Kind: "unix-process", Details: map[string]dbus.Variant{
		"pid":        dbus.MakeVariant(uint32(peer.PID)), //nolint:gosec // a kernel pid, positive and below 2^22
		"start-time": dbus.MakeVariant(uint64(0)),
		"uid":        dbus.MakeVariant(int32(peer.UID)), //nolint:gosec // a kernel uid
	}}
	ctx, cancel := context.WithTimeout(context.Background(), polkitTimeout)
	defer cancel()
	// Disable interaction so authorization cannot hold a connection open
	// for a password prompt.
	call := conn.Object("org.freedesktop.PolicyKit1", "/org/freedesktop/PolicyKit1/Authority").CallWithContext(ctx,
		"org.freedesktop.PolicyKit1.Authority.CheckAuthorization", 0,
		subject, action, map[string]string{}, uint32(0), "")
	if call.Err != nil {
		return false
	}
	var result polkitResult
	if err := call.Store(&result); err != nil {
		return false
	}
	return result.Authorized
}
