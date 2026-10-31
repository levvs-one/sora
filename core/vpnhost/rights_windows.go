package vpnhost

import (
	"errors"
	"os"
)

const rightsSpace = 0

// receivedFile has no meaning on Windows, where engines own their adapter.
func receivedFile([]byte) (*os.File, error) {
	return nil, errors.New("vpnhost: not supported on Windows")
}
