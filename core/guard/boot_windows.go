package guard

import (
	"unsafe"

	"golang.org/x/sys/windows"
)

func bootID() (string, error) {
	// SystemBootEnvironmentInformation has a boot GUID stable across core restarts.
	var info struct {
		ID       windows.GUID
		Firmware uint32
		_        uint32
		Flags    uint64
	}
	err := windows.NtQuerySystemInformation(90, unsafe.Pointer(&info), uint32(unsafe.Sizeof(info)), nil)
	return info.ID.String(), err
}
