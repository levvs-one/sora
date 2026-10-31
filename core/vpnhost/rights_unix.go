//go:build !windows

package vpnhost

import (
	"errors"
	"fmt"
	"os"

	"golang.org/x/sys/unix"
)

var rightsSpace = unix.CmsgSpace(4)

// receivedFile takes the descriptor out of a socket's ancillary data.
func receivedFile(oob []byte) (*os.File, error) {
	messages, err := unix.ParseSocketControlMessage(oob)
	if err != nil {
		return nil, fmt.Errorf("vpnhost: read the descriptor: %w", err)
	}
	for _, message := range messages {
		fds, err := unix.ParseUnixRights(&message)
		if err != nil {
			continue
		}
		if len(fds) > 0 {
			return os.NewFile(uintptr(fds[0]), "vpn"), nil
		}
	}
	return nil, errors.New("vpnhost: the app sent no adapter")
}
