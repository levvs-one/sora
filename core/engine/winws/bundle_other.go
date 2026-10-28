//go:build !windows

package winws

import (
	"errors"
	"io"
)

func compatibleHost() error                 { return errors.New("winws requires native AMD64 Windows") }
func lockBundle(string) (io.Closer, error)  { return nil, compatibleHost() }
func checkDriverService(string, bool) error { return compatibleHost() }
