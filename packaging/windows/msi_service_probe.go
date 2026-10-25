//go:build windows

// Command msi_service_probe tests MSI service transactions on disposable CI runners.
package main

import (
	"bufio"
	"context"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"github.com/Microsoft/go-winio"
	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"
	"golang.org/x/sys/windows/svc/mgr"
)

var fixtureVersion = "unbuilt"
var failStart = "0"

type fixtureService struct{ name string }

func (h fixtureService) Execute(_ []string, requests <-chan svc.ChangeRequest, status chan<- svc.Status) (bool, uint32) {
	status <- svc.Status{State: svc.StartPending}
	if failStart == "1" {
		return true, 7
	}
	listener, err := winio.ListenPipe(`\\.\pipe\`+h.name, &winio.PipeConfig{
		SecurityDescriptor: "D:P(A;;GA;;;SY)(A;;GA;;;BA)",
	})
	if err != nil {
		return false, 1
	}
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			connection, err := listener.Accept()
			if err != nil {
				return
			}
			_ = connection.SetWriteDeadline(time.Now().Add(2 * time.Second))
			_, _ = io.WriteString(connection, fixtureVersion+"\n")
			_ = connection.Close()
		}
	}()
	defer func() { _ = listener.Close(); <-done }()
	status <- svc.Status{State: svc.Running, Accepts: svc.AcceptStop | svc.AcceptShutdown}
	for change := range requests {
		switch change.Cmd {
		case svc.Interrogate:
			status <- change.CurrentStatus
		case svc.Stop, svc.Shutdown:
			status <- svc.Status{State: svc.StopPending}
			return false, 0
		}
	}
	return false, 0
}

func checkService(name, expected string) error {
	manager, err := mgr.Connect()
	if err != nil {
		return err
	}
	defer func() { _ = manager.Disconnect() }()
	service, err := manager.OpenService(name)
	if err != nil {
		return err
	}
	defer func() { _ = service.Close() }()
	before, err := service.Query()
	if err != nil {
		return err
	}
	if before.State != svc.Running || before.ProcessId == 0 {
		return errors.New("fixture service is not running")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	connection, err := winio.DialPipeContext(ctx, `\\.\pipe\`+name)
	if err != nil {
		return err
	}
	defer func() { _ = connection.Close() }()
	_ = connection.SetDeadline(time.Now().Add(5 * time.Second))
	pipe, ok := connection.(interface{ Fd() uintptr })
	if !ok {
		return errors.New("fixture connection has no kernel pipe handle")
	}
	var pid uint32
	if err := windows.GetNamedPipeServerProcessId(windows.Handle(pipe.Fd()), &pid); err != nil {
		return err
	}
	if pid != before.ProcessId {
		return errors.New("fixture pipe does not belong to the SCM process")
	}
	version, err := bufio.NewReader(io.LimitReader(connection, 32)).ReadString('\n')
	if err != nil {
		return err
	}
	if version != expected+"\n" {
		return fmt.Errorf("fixture IPC version mismatch: %q", version)
	}
	after, err := service.Query()
	if err != nil {
		return err
	}
	if after.State != svc.Running || after.ProcessId != pid {
		return errors.New("fixture service changed during readiness")
	}
	return json.NewEncoder(os.Stdout).Encode(map[string]any{"version": expected, "pipe_pid": pid, "scm_pid": after.ProcessId})
}

func main() {
	if len(os.Args) < 3 || !strings.HasPrefix(os.Args[2], "SoraMSIFixture-") {
		os.Exit(40)
	}
	identity, err := hex.DecodeString(strings.TrimPrefix(os.Args[2], "SoraMSIFixture-"))
	if err != nil || len(identity) != 16 {
		os.Exit(41)
	}
	switch {
	case len(os.Args) == 3 && os.Args[1] == "run":
		var isService bool
		isService, err = svc.IsWindowsService()
		if err == nil && isService {
			err = svc.Run(os.Args[2], fixtureService{name: os.Args[2]})
		} else {
			err = errors.New("fixture service must be started by SCM")
		}
	case len(os.Args) == 4 && os.Args[1] == "check":
		err = checkService(os.Args[2], os.Args[3])
	default:
		err = errors.New("invalid fixture command")
	}
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
