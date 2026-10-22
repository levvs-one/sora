package custom

import (
	"net/netip"
	"slices"
	"sort"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/secret"
)

// Field limits. Ids double as vault-reference fragments, so they stay
// within the vault's 64-byte reference limit with room for the prefix and
// suffix ("custom_" + id + "_cred").
const (
	maxIDLen   = 48
	maxNameLen = 128 // UTF-8 bytes, like OutboundSpec display names
	maxAddrLen = 253 // longest DNS name on the wire
)

// Protocol is the canonical protocol name, matching the engine's strings.
type Protocol string

// Supported protocols for manually added servers.
const (
	ProtocolVLESS       Protocol = "vless"
	ProtocolVMESS       Protocol = "vmess"
	ProtocolTrojan      Protocol = "trojan"
	ProtocolShadowsocks Protocol = "shadowsocks"
	ProtocolWireGuard   Protocol = "wireguard"
)

// Protocols follows the engine catalog so newly supported protocols reach
// the editor without another client-side list. Internal outbounds have no endpoint.
func Protocols() []string {
	seen := map[string]bool{}
	for _, caps := range engine.Catalog {
		for p, supported := range caps.Protocols {
			if supported && p != engine.ProtocolDirect && p != engine.ProtocolXrayProfile {
				seen[string(p)] = true
			}
		}
	}
	out := make([]string, 0, len(seen))
	for p := range seen {
		out = append(out, p)
	}
	sort.Strings(out)
	return out
}

func validProtocol(p Protocol) bool { return slices.Contains(Protocols(), string(p)) }

// ValidateID checks a server id. The charset excludes every path separator,
// so an id can never escape into a path traversal even where one is used in
// a filename.
func ValidateID(id string) error {
	if id == "" {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server id is empty")
	}
	if len(id) > maxIDLen {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server id is longer than %d bytes", maxIDLen)
	}
	for i := 0; i < len(id); i++ {
		c := id[i]
		if c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-' || c == '_' {
			continue
		}
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server id has an unsupported character")
	}
	return nil
}

// ValidateName checks the display name.
func ValidateName(name string) error {
	if strings.TrimSpace(name) == "" {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server name is empty")
	}
	if len(name) > maxNameLen {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server name is longer than %d bytes", maxNameLen)
	}
	return nil
}

// ValidateAddress accepts an IP literal or a DNS hostname. Numeric-looking
// input must parse as an IP, so "999.1.1.1" is rejected instead of being
// treated as a hostname.
func ValidateAddress(address string) error {
	address = strings.TrimSpace(address)
	if address == "" {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server address is empty")
	}
	if len(address) > maxAddrLen {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server address is longer than %d bytes", maxAddrLen)
	}
	if _, err := netip.ParseAddr(address); err == nil {
		return nil
	}
	host := strings.TrimSuffix(address, ".")
	if looksNumeric(host) {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server address is not a valid IP or hostname")
	}
	for _, label := range strings.Split(host, ".") {
		if err := validateLabel(label); err != nil {
			return err
		}
	}
	return nil
}

// looksNumeric reports whether the host consists only of digits and dots,
// i.e. it was meant as an IPv4 literal.
func looksNumeric(host string) bool {
	if host == "" {
		return false
	}
	for i := 0; i < len(host); i++ {
		if host[i] >= '0' && host[i] <= '9' || host[i] == '.' {
			continue
		}
		return false
	}
	return true
}

// validateLabel checks one DNS label: 1..63 bytes, letters/digits/hyphens,
// no leading or trailing hyphen.
func validateLabel(label string) error {
	if len(label) == 0 || len(label) > 63 {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server address has a bad hostname label")
	}
	for i := 0; i < len(label); i++ {
		c := label[i]
		if c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-' {
			continue
		}
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server address has a bad hostname label")
	}
	if label[0] == '-' || label[len(label)-1] == '-' {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server address has a bad hostname label")
	}
	return nil
}

// ValidatePort checks the TCP port range.
func ValidatePort(port uint32) error {
	if port == 0 || port > 65535 {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: the server port is outside 1..65535")
	}
	return nil
}

// ValidateProtocol checks the protocol against the supported set.
func ValidateProtocol(p Protocol) error {
	if !validProtocol(p) {
		return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
			"custom: unsupported protocol")
	}
	return nil
}

// ValidateCredentials bounds secret material to the vault's limit. Empty
// material is rejected only when required (on create); on update an empty
// value keeps the stored secret.
func ValidateCredentials(material []byte, required bool) error {
	if len(material) == 0 {
		if required {
			return errs.Newf(errs.CodeInvalidArgument, errs.KeyInvalidRequest,
				"custom: the credentials are empty")
		}
		return nil
	}
	if len(material) > secret.MaxSecretBytes {
		return errs.Newf(errs.CodeResourceExhausted, errs.KeySecretTooLarge,
			"custom: the credentials exceed the vault limit")
	}
	return nil
}
