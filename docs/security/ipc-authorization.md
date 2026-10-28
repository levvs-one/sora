# Local control authorization boundary

This is an internal source/test review of one S3 boundary, not an independent
external audit or proof of complete user/session isolation.

| Boundary | Source and current rule | Evidence / remaining limit |
| --- | --- | --- |
| UI/native client to local transport | `core/ipc/ipc_windows.go`: named-pipe DACL plus kernel-reported client PID/token/session. `ipc_peer_linux.go`: SO_PEERCRED UID/PID. `ipc_unix.go`: socket permissions plus group/polkit policy. | Transport identity comes from the OS. Current Linux socket mode is 0666 to permit polkit admission, not an assertion that all local users are trusted. Multi-user OS tests are still required. |
| Transport to RPC role | `core/ipc/authlevel.go`: PeerCredentials attaches AuthRead/AuthControl. `core/cmd/sora-core/main.go`: credentials and unary/stream interceptors share the gRPC server. | Actual local-transport regression verifies wrapped connections retain peer identity. Default platform policies are broader than single-owner isolation; see below. |
| Role to control token | `core/control/server.go` Handshake returns the token only for AuthControl after version negotiation. `auth.go` uses a 32-byte random token and constant-time comparison; rotation persists before changing memory. | Actual RPC test proves an AuthRead handshake negotiates without disclosing a token. Existing rotation and wrong-token tests passed. A token alone cannot upgrade the transport's role. |
| Role to unary operation | `core/control/authz.go`: explicit read-only method list, other methods require AuthControl. Mutation handlers additionally check their authenticator/version. | Actual RPC test sends a known valid token and valid plan as AuthRead; Connect and Disconnect are denied and state remains disconnected. Existing AuthControl end-to-end connect/disconnect remains successful with a stub engine. |
| Role to extension lifecycle | The same stream interceptor protects ExtensionHost. `core/ext/worker_host.go` additionally checks the first control token and parses manifest/config/source bounds. | Actual RunWorker stream with a known valid token is denied to AuthRead before worker handling. Core trusts an AuthControl client's app-owned extension delegation; this is not independent verification of the app's on-disk grant registry. |
| Extension to host operations | `core/ext/worker_host.go` checks bridge permissions and routes app APIs back to the app; `core/ext/enforcement.go` distinguishes runtime enforcement, install-time validation, inert and unimplemented permissions. | Reviewed the bridge gate and registry, not every consumer. `settings.read/write` are inert for app settings; `tray` is unimplemented. The integrated `net.hooks` consumer accepts only signed declarative profiles and delegates ordinary authenticated SessionPlans, as described in [the bypass boundary](extension-bypass-profiles.md). Their presence is not a working sandbox guarantee. |
| Downloads to privileged package manager | `packaging/linux/sora-update` invokes installed-core snapshot preparation and verifies private files/package metadata before manager execution. | See [the privileged snapshot audit](privileged-update-snapshot.md), including actual crypto in a namespace. Production package managers, service/firewall and elevation were not exercised on the owner's host. |

## Current platform policy

Windows grants control to kernel-confirmed active-session clients or elevated/
SYSTEM clients admitted by the pipe. It does not restrict control to the GUI's
publisher, one owner SID or a single active RDP session. Linux grants control to
the service UID/group and polkit control-authorized clients; the shipped control
policy allows active local users without interaction. AuthRead is available
when only the read action authorizes a peer, for example under a restricted
administrator policy. Do not describe the default active-user policy as read-only.

Any native process admitted with AuthControl can negotiate the control token and
invoke the allowed service API. Token-file mode 0600 does not isolate it from an
already authorized same-account or active-session process. The extension model
assumes the authenticated app owns package verification/grants/revocation before
worker delegation; a compromised control-authorized native app is a different
boundary from a confined JavaScript worker.

Tightening this policy to one designated owner, selected group or explicit
elevation requires a product/deployment decision and usable authorization flow.
Changing polkit defaults to auth_* alone would break the existing noninteractive
checks. No account, group, polkit, DACL or running service policy was changed by
this review. Reproduce multi-SID/multi-session and PID-lifetime tests on an
approved isolated Windows/Linux test system before claiming stronger isolation.

## Reproducible checks

`TestReadPeerCannotAcquireControlThroughUnaryOrWorkerStream` uses the real local
socket/pipe, gRPC credentials, both method interceptors and registered core/
extension services. Only role classification is injected as AuthRead; engine and
secret data are the existing isolated test fixtures. It does not prove that the
OS correctly classifies a different live user. `TestClientTalksToTheCoreOverTheTransport`
provides the positive AuthControl flow. `TestServerHandshakeSeesThroughListenerWrapping`,
`TestRefusedPeerGetsNothing`, `TestPolkitRefusesWhatItCannotConfirm`, token rotation
and wrong-token-before-effects tests cover the adjacent denial boundaries.

This review does not close S3: subscription/config parser attacks, extension
archives and native bridge consumers, DNS/route command paths, diagnostic data,
privileged directory ownership and complete Windows ACL/session failure tests
still need their own checks. Network worker resource/permission comments above
are not a substitute for running those separate adversarial suites.
