//go:build !linux

package main

import (
	"context"
	"fmt"
)

func prepareUpdateSnapshot(_ context.Context, _, _, _, _, _ string) error {
	return fmt.Errorf("release: privileged update snapshots require Linux")
}
