// Package hwid gives subscription providers a stable device identifier that
// counts this machine without revealing its own identifiers. Panels such as
// Remnawave limit devices per subscription by the x-hwid request header.
package hwid

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"regexp"
	"strings"
	"sync"
)

// salt keys the hash so the identifier cannot be matched against the machine
// id it came from, or against what another program derives from that id.
const salt = "sora/hwid/v1/4c1e9b7f2d6a"

// length is the number of hex characters sent; 128 bits is enough to keep
// identifiers of different machines apart.
const length = 32

// Remnawave ignores an x-hwid outside this pattern (extract-hwid-headers.util.ts
// in remnawave/backend) and treats the request as one without an identifier.
var accepted = regexp.MustCompile(`^[a-zA-Z0-9=-]{10,64}$`)

// Valid reports whether id is an identifier providers accept.
func Valid(id string) bool { return accepted.MatchString(id) }

// Derive turns a machine id into the identifier. The same machine id always
// gives the same identifier, so it survives reinstalls of Sora.
func Derive(machineID []byte) string {
	mac := hmac.New(sha256.New, []byte(salt))
	mac.Write(machineID)
	return hex.EncodeToString(mac.Sum(nil))[:length]
}

// Random returns a new identifier unrelated to the machine.
func Random() (string, error) {
	raw := make([]byte, length/2)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return hex.EncodeToString(raw), nil
}

// Machine derives the identifier from the operating system's machine id. It
// fails where no machine id is readable; callers then store a random one.
func Machine() (string, error) {
	id, err := machineID()
	if err != nil {
		return "", err
	}
	return Derive(id), nil
}

// Identity is what a subscription request tells the provider about the device.
type Identity struct {
	HWID      string
	OS        string
	OSVersion string
	Model     string
}

// Apply sets the headers in the form Remnawave, Happ and v2RayTun use.
func (i Identity) Apply(header http.Header) {
	header.Set("X-Hwid", i.HWID)
	for name, value := range map[string]string{"X-Device-Os": i.OS, "X-Ver-Os": i.OSVersion, "X-Device-Model": i.Model} {
		if value != "" {
			header.Set(name, value)
		}
	}
}

// Names lists the headers Apply may set.
var Names = []string{"X-Hwid", "X-Device-Os", "X-Ver-Os", "X-Device-Model"}

// model is deliberately coarse: a hardware model or host name would add
// nothing for counting devices and would identify the person.
const model = "PC"

var describe = sync.OnceValue(func() Identity {
	return Identity{OS: osName, OSVersion: headerText(osVersion()), Model: model}
})

// For returns the identity carrying id.
func For(id string) Identity {
	identity := describe()
	identity.HWID = id
	return identity
}

// headerText keeps printable ASCII so an OS string cannot break the header.
func headerText(value string) string {
	var out strings.Builder
	for _, r := range strings.TrimSpace(value) {
		if r >= 0x20 && r <= 0x7e && out.Len() < 64 {
			out.WriteRune(r)
		}
	}
	return strings.TrimSpace(out.String())
}
