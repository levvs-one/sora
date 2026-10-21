//go:build !linux && !windows

package guard

import "errors"

func bootID() (string, error) {
	return "", errors.New("guard: strict mode is unsupported on this platform")
}
