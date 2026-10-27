# ByeDPI profiles

This extension selects profiles for the existing Windows and Linux host backend.
It does not install a native executable, driver or operating-system component.
The profile is selected explicitly as a serverless mode; manual Sora settings
are retained. Disabling or uninstalling the selected extension stops its session.

The source targets the 1.1.3 release candidate; there is no production package
or catalog entry yet. Publish only after an actual 1.1.3-or-later host supports
this descriptor. Integration tests use a separate temporary author identity.
The host backend is driverless and uses a local TCP SOCKS proxy. Linux packages
support amd64 and arm64; Windows uses the amd64 backend.

The `net.hooks` permission is dangerous and requires the existing explicit
installation consent. No profile guarantees evasion in every network.
