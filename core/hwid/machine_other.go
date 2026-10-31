//go:build !linux && !windows && !android

package hwid

import (
	"errors"
	"runtime"
)

var osName = runtime.GOOS

// machineID is not read on platforms Sora does not ship; a random identifier
// is stored instead.
func machineID() ([]byte, error) { return nil, errors.New("hwid: no machine id on " + runtime.GOOS) }

func osVersion() string { return "" }
