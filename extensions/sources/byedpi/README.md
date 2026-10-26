# ByeDPI profiles

This extension selects profiles for the existing Windows host backend.
It does not install a native executable, driver or operating-system component.
The profile is selected explicitly as a serverless mode; manual Sora settings
are retained. Disabling or uninstalling the selected extension stops its session.

The source is prepared for normal author-signed package/catalog publication;
there is no production package or catalog entry yet. Integration tests use a
separate temporary author identity. The current host backend is driverless. Linux backend selection is not claimed by this descriptor.

The `net.hooks` permission is dangerous and requires the existing explicit
installation consent. No profile guarantees evasion in every network.
