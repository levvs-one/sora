package hwid

import (
	"errors"
	"os"
)

const osName = "Android"

// machineID is the identifier the app reads from the system for this core.
func machineID() ([]byte, error) {
	if id := os.Getenv("SORA_DEVICE_ID"); id != "" {
		return []byte(id), nil
	}
	return nil, errors.New("hwid: the app passed no device id")
}

func osVersion() string { return os.Getenv("SORA_OS_VERSION") }
