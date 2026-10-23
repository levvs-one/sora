package ext

import (
	"errors"
	"os"
	"os/exec"
	"slices"
	"strings"
	"time"
	"unicode/utf16"
	"unsafe"

	"golang.org/x/sys/windows"
)

func newWorkerJob() (windows.Handle, error) {
	job, err := windows.CreateJobObject(nil, nil)
	if err != nil {
		return 0, err
	}
	limits := windows.JOBOBJECT_EXTENDED_LIMIT_INFORMATION{}
	limits.BasicLimitInformation.LimitFlags = windows.JOB_OBJECT_LIMIT_PROCESS_MEMORY | windows.JOB_OBJECT_LIMIT_PROCESS_TIME | windows.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
	limits.BasicLimitInformation.PerProcessUserTimeLimit = WorkerCPUSeconds * 10000000
	limits.ProcessMemoryLimit = workerOSMemoryBytes
	if _, err = windows.SetInformationJobObject(job, windows.JobObjectExtendedLimitInformation, uintptr(unsafe.Pointer(&limits)), uint32(unsafe.Sizeof(limits))); err != nil {
		_ = windows.CloseHandle(job)
		return 0, err
	}
	return job, nil
}

func limitWorkerProcess() error {
	// A second job retains the OS backstop for direct worker invocations.
	job, err := newWorkerJob()
	if err != nil {
		return err
	}
	if err = windows.AssignProcessToJobObject(job, windows.CurrentProcess()); err != nil {
		_ = windows.CloseHandle(job)
		return err
	}
	// The worker keeps this non-inheritable handle until process exit.
	return nil
}

// processCPUTime is the user and kernel time this process has used.
func processCPUTime() (time.Duration, error) {
	return workerProcessCPUTime(windows.CurrentProcess())
}

func workerProcessCPUTime(process windows.Handle) (time.Duration, error) {
	var creation, exit, kernel, user windows.Filetime
	if err := windows.GetProcessTimes(process, &creation, &exit, &kernel, &user); err != nil {
		return 0, err
	}
	// FILETIME counts 100 ns intervals.
	ticks := func(f windows.Filetime) int64 { return int64(f.HighDateTime)<<32 | int64(f.LowDateTime) }
	return time.Duration((ticks(kernel) + ticks(user)) * 100), nil
}

// x/sys v0.48.0 exposes the attribute API but not this Windows 10 SDK constant.
// https://learn.microsoft.com/windows/win32/api/processthreadsapi/nf-processthreadsapi-updateprocthreadattribute
const (
	procThreadAttributeJobList = 0x0002000d
	jobMsgEndOfProcessTime     = 2
	jobMsgProcessMemoryLimit   = 9
	jobMsgJobMemoryLimit       = 10
)

// These SDK fields are not declared in x/sys v0.48.0.
// https://learn.microsoft.com/windows/win32/api/winnt/ns-winnt-jobobject_associate_completion_port
type workerJobCompletionPort struct {
	key  uintptr
	port windows.Handle
}

func startWorkerCommand(cmd *exec.Cmd) (*workerProcess, error) {
	job, err := newWorkerJob()
	if err != nil {
		return nil, err
	}
	started := false
	defer func() {
		if !started {
			_ = windows.CloseHandle(job)
		}
	}()
	port, err := windows.CreateIoCompletionPort(windows.InvalidHandle, 0, 0, 1)
	if err != nil {
		return nil, err
	}
	defer func() {
		if !started {
			_ = windows.CloseHandle(port)
		}
	}()
	association := workerJobCompletionPort{key: 1, port: port}
	if _, err = windows.SetInformationJobObject(job, windows.JobObjectAssociateCompletionPortInformation, uintptr(unsafe.Pointer(&association)), uint32(unsafe.Sizeof(association))); err != nil {
		return nil, err
	}
	attributes, err := windows.NewProcThreadAttributeList(2)
	if err != nil {
		return nil, err
	}
	defer attributes.Delete()
	// Assignment is part of CreateProcess, so even a core crash before it
	// returns cannot leave a running or suspended child outside this job.
	if err = attributes.Update(procThreadAttributeJobList, unsafe.Pointer(&job), unsafe.Sizeof(job)); err != nil {
		return nil, err
	}
	handles := make([]windows.Handle, 3)
	for i, stream := range []*os.File{cmd.Stdin.(*os.File), cmd.Stdout.(*os.File), cmd.Stderr.(*os.File)} {
		if err = windows.DuplicateHandle(windows.CurrentProcess(), windows.Handle(stream.Fd()), windows.CurrentProcess(), &handles[i], 0, true, windows.DUPLICATE_SAME_ACCESS); err != nil {
			return nil, err
		}
		defer func(handle windows.Handle) { _ = windows.CloseHandle(handle) }(handles[i])
	}
	if err = attributes.Update(windows.PROC_THREAD_ATTRIBUTE_HANDLE_LIST, unsafe.Pointer(&handles[0]), uintptr(len(handles))*unsafe.Sizeof(handles[0])); err != nil {
		return nil, err
	}
	executable, err := windows.UTF16PtrFromString(cmd.Path)
	if err != nil {
		return nil, err
	}
	commandLine, err := windows.UTF16PtrFromString(windows.ComposeCommandLine(cmd.Args))
	if err != nil {
		return nil, err
	}
	var directory *uint16
	if cmd.Dir != "" {
		directory, err = windows.UTF16PtrFromString(cmd.Dir)
		if err != nil {
			return nil, err
		}
	}
	environment := cmd.Environ()
	for _, entry := range environment {
		if strings.ContainsRune(entry, 0) {
			return nil, errors.New("worker environment contains NUL")
		}
	}
	slices.SortFunc(environment, func(a, b string) int { return strings.Compare(strings.ToUpper(a), strings.ToUpper(b)) })
	block := utf16.Encode([]rune(strings.Join(environment, "\x00") + "\x00\x00"))
	startup := windows.StartupInfoEx{StartupInfo: windows.StartupInfo{
		Flags:      windows.STARTF_USESTDHANDLES | windows.STARTF_USESHOWWINDOW,
		ShowWindow: windows.SW_HIDE,
		StdInput:   handles[0], StdOutput: handles[1], StdErr: handles[2],
	}, ProcThreadAttributeList: attributes.List()}
	startup.Cb = uint32(unsafe.Sizeof(startup))
	var child windows.ProcessInformation
	if err = windows.CreateProcess(executable, commandLine, nil, nil, true, windows.CREATE_UNICODE_ENVIRONMENT|windows.EXTENDED_STARTUPINFO_PRESENT|windows.CREATE_NO_WINDOW, &block[0], directory, &startup.StartupInfo, &child); err != nil {
		return nil, err
	}
	_ = windows.CloseHandle(child.Thread)
	process, err := os.FindProcess(int(child.ProcessId))
	if err != nil {
		_ = windows.TerminateJobObject(job, 1)
		_, _ = windows.WaitForSingleObject(child.Process, windows.INFINITE)
		_ = windows.CloseHandle(child.Process)
		return nil, err
	}
	started = true
	return &workerProcess{
		process: process,
		wait: func() (*os.ProcessState, error) {
			state, err := process.Wait()
			if err == nil && !state.Success() {
				err = &exec.ExitError{ProcessState: state}
			}
			return state, err
		},
		usage: func() (workerUsage, error) {
			// Failed large commits may leave peak usage below the budget. Observe
			// hard-limit notifications too, without trusting the worker to exit.
			for {
				var message uint32
				var key uintptr
				var processID *windows.Overlapped
				err := windows.GetQueuedCompletionStatus(port, &message, &key, &processID, 0)
				if errors.Is(err, windows.WAIT_TIMEOUT) {
					break
				}
				if err != nil {
					return workerUsage{}, err
				}
				switch message {
				case jobMsgProcessMemoryLimit, jobMsgJobMemoryLimit:
					return workerUsage{}, errWorkerMemoryBudget
				case jobMsgEndOfProcessTime:
					return workerUsage{}, errWorkerCPUBudget
				}
			}
			var accounting windows.JOBOBJECT_EXTENDED_LIMIT_INFORMATION
			if err := windows.QueryInformationJobObject(job, windows.JobObjectExtendedLimitInformation, uintptr(unsafe.Pointer(&accounting)), uint32(unsafe.Sizeof(accounting)), nil); err != nil {
				return workerUsage{}, err
			}
			cpu, err := workerProcessCPUTime(child.Process)
			return workerUsage{memory: uint64(accounting.PeakProcessMemoryUsed), cpu: cpu}, err
		},
		close: func() {
			_ = windows.CloseHandle(job)
			_ = windows.CloseHandle(port)
			_ = windows.CloseHandle(child.Process)
			_ = process.Release()
		},
	}, nil
}
