# ByeDPI profiles

This extension selects profiles for the existing Windows host backend.
It does not install a native executable, driver or operating-system component.
The profile is selected explicitly as a serverless mode; manual Sora settings
are retained. Disabling or uninstalling the selected extension stops its session.

The source targets the 1.1.3 release candidate; there is no production package
or catalog entry yet. Publish only after an actual 1.1.3-or-later host supports
this descriptor. Integration tests use a separate temporary author identity.
The Windows host backend is driverless; Linux selection is not claimed.

The `net.hooks` permission is dangerous and requires the existing explicit
installation consent. No profile guarantees evasion in every network.
