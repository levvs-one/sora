//go:build windows

package hwid

import (
	"errors"
	"fmt"
	"strings"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/registry"
)

const osName = "Windows"

// machineID reads MachineGuid, written once at Windows setup. The key is
// readable by the LocalSystem service and by every user; the 64-bit view is
// used because a 32-bit view would miss the value.
func machineID() ([]byte, error) {
	key, err := registry.OpenKey(registry.LOCAL_MACHINE, `SOFTWARE\Microsoft\Cryptography`, registry.QUERY_VALUE|registry.WOW64_64KEY)
	if err != nil {
		return nil, err
	}
	defer func() { _ = key.Close() }()
	guid, _, err := key.GetStringValue("MachineGuid")
	if err != nil {
		return nil, err
	}
	guid = strings.ToLower(strings.TrimSpace(guid))
	if guid == "" {
		return nil, errors.New("hwid: empty MachineGuid")
	}
	return []byte(guid), nil
}

// osVersion reports the real version; GetVersionEx lies to unmanifested
// programs, RtlGetVersion does not.
func osVersion() string {
	info := windows.RtlGetVersion()
	return fmt.Sprintf("%d.%d.%d", info.MajorVersion, info.MinorVersion, info.BuildNumber)
}
