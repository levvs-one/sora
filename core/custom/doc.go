// Package custom stores servers the user adds manually, outside
// subscriptions. Server metadata lives in custom/servers.json with
// owner-only permissions; credential material lives in the core secret
// vault under a derived reference, exactly like subscription credentials.
// The vault, not this package, owns encryption, so no new secret handling
// is invented here.
package custom
