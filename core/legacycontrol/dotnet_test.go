package legacycontrol

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/core/ipc"
)

func TestStreamJsonRpcInterop(t *testing.T) {
	client := os.Getenv("SORA_INTEROP_CLIENT")
	if client == "" {
		t.Skip("set SORA_INTEROP_CLIENT to the built ControlInterop executable or DLL")
	}
	endpoint := filepath.Join(t.TempDir(), "legacy.sock")
	if runtime.GOOS == "windows" {
		endpoint = `\\.\pipe\sora-legacy-interop-` + filepath.Base(t.TempDir())
	}
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	listener, err := ipc.Listen(ctx, ipc.Options{Address: endpoint})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = listener.Close() }()
	service, _ := testService(t)
	finished := make(chan error, 1)
	go func() { finished <- Serve(ctx, listener, service) }()
	command := exec.CommandContext(ctx, client, endpoint)
	if dotnet := os.Getenv("SORA_DOTNET_BIN"); dotnet != "" {
		command = exec.CommandContext(ctx, dotnet, client, endpoint)
	}
	output, err := command.CombinedOutput()
	t.Log(string(output))
	cancel()
	select {
	case <-finished:
	case <-time.After(2 * time.Second):
		t.Error("legacy listener did not release its resources")
	}
	if err != nil {
		t.Fatal(err)
	}
}
