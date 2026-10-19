//go:build !linux && !windows

package ipc

// PolkitAction names the polkit control action on Linux; other systems have
// no polkit.
const PolkitAction = "io.github.levvs-one.sora.control"

// PolkitReadAction names the polkit read-only action on Linux; other systems
// have no polkit.
const PolkitReadAction = "io.github.levvs-one.sora.read"

// polkitAllows rejects authorization; socket-group permissions enforce access
// without polkit.
func polkitAllows(Peer, string) bool { return false }
