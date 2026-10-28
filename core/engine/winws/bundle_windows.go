package winws

import (
	"debug/pe"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"unsafe"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/svc"
	"golang.org/x/sys/windows/svc/mgr"
)

func compatibleHost() error {
	var process, native uint16
	if err := windows.IsWow64Process2(windows.CurrentProcess(), &process, &native); err != nil {
		return fmt.Errorf("winws: identify native Windows architecture: %w", err)
	}
	if native != pe.IMAGE_FILE_MACHINE_AMD64 || process != pe.IMAGE_FILE_MACHINE_UNKNOWN {
		return errors.New("winws requires a native AMD64 process and kernel; emulated ARM64 is unsupported")
	}
	system, err := windows.GetSystemDirectory()
	if err != nil {
		return err
	}
	if info, err := os.Stat(filepath.Join(system, "wlanapi.dll")); err != nil || !info.Mode().IsRegular() {
		return errors.New("winws requires the Windows WLANAPI component")
	}
	return nil
}

type lockedBundle []*os.File

func (b lockedBundle) Close() error {
	var result error
	for _, file := range b {
		result = errors.Join(result, file.Close())
	}
	return result
}

// Hold read-only handles without write/delete sharing through process shutdown.
// EXE/DLL paths and driver bytes cannot be replaced by ordinary writers between
// verification and normal startup.
func lockBundle(binary string) (io.Closer, error) {
	if err := compatibleHost(); err != nil {
		return nil, err
	}
	if !filepath.IsAbs(binary) || !strings.EqualFold(filepath.Base(binary), "winws.exe") {
		return nil, errors.New("winws requires its installed absolute binary path")
	}
	dir := filepath.Dir(binary)
	names := []string{dir}
	for name := range componentDigests {
		names = append(names, filepath.Join(dir, name))
	}
	var held lockedBundle
	var driver *os.File
	for index, path := range names {
		name, err := windows.UTF16PtrFromString(path)
		if err != nil {
			_ = held.Close()
			return nil, err
		}
		handle, err := windows.CreateFile(name, windows.GENERIC_READ, windows.FILE_SHARE_READ, nil,
			windows.OPEN_EXISTING, windows.FILE_FLAG_OPEN_REPARSE_POINT|windows.FILE_FLAG_BACKUP_SEMANTICS, 0)
		if err != nil {
			_ = held.Close()
			return nil, fmt.Errorf("winws: lock installed component: %w", err)
		}
		file := os.NewFile(uintptr(handle), path)
		held = append(held, file)
		var info windows.ByHandleFileInformation
		if err := windows.GetFileInformationByHandle(handle, &info); err != nil ||
			info.FileAttributes&windows.FILE_ATTRIBUTE_REPARSE_POINT != 0 ||
			(index > 0 && info.FileAttributes&windows.FILE_ATTRIBUTE_DIRECTORY != 0) {
			_ = held.Close()
			return nil, errors.New("winws: installed bundle contains an unreadable or reparse component")
		}
		if filepath.Base(path) == "WinDivert64.sys" {
			driver = file
		}
	}
	if err := verifyComponents(dir); err != nil {
		_ = held.Close()
		return nil, err
	}
	path, err := windows.UTF16PtrFromString(driver.Name())
	if err != nil {
		_ = held.Close()
		return nil, err
	}
	file := windows.WinTrustFileInfo{Size: uint32(unsafe.Sizeof(windows.WinTrustFileInfo{})), FilePath: path, File: windows.Handle(driver.Fd())}
	data := windows.WinTrustData{
		Size: uint32(unsafe.Sizeof(windows.WinTrustData{})), UIChoice: windows.WTD_UI_NONE,
		RevocationChecks: windows.WTD_REVOKE_WHOLECHAIN, UnionChoice: windows.WTD_CHOICE_FILE,
		StateAction:                     windows.WTD_STATEACTION_VERIFY,
		ProvFlags:                       windows.WTD_REVOCATION_CHECK_CHAIN_EXCLUDE_ROOT | windows.WTD_CACHE_ONLY_URL_RETRIEVAL,
		FileOrCatalogOrBlobOrSgnrOrCert: unsafe.Pointer(&file),
	}
	verifyErr := windows.WinVerifyTrustEx(windows.InvalidHWND, &windows.WINTRUST_ACTION_GENERIC_VERIFY_V2, &data)
	data.StateAction = windows.WTD_STATEACTION_CLOSE
	closeErr := windows.WinVerifyTrustEx(windows.InvalidHWND, &windows.WINTRUST_ACTION_GENERIC_VERIFY_V2, &data)
	if err := errors.Join(verifyErr, closeErr); err != nil {
		_ = held.Close()
		return nil, fmt.Errorf("winws: Windows driver trust or cached revocation check failed: %w", err)
	}
	return held, nil
}

// Query only: WinDivert's service is shared. Sora never stops or deletes it.
// A no-capture child pins the loaded service before the traffic child starts.
func checkDriverService(binary string, required bool) error {
	manager, err := mgr.Connect()
	if err != nil {
		return err
	}
	defer func() { _ = manager.Disconnect() }()
	service, err := manager.OpenService("WinDivert")
	if errors.Is(err, windows.ERROR_SERVICE_DOES_NOT_EXIST) && !required {
		return nil
	}
	if err != nil {
		return fmt.Errorf("winws: inspect WinDivert service: %w", err)
	}
	defer func() { _ = service.Close() }()
	config, err := service.Config()
	if err != nil {
		return err
	}
	actual := strings.TrimPrefix(strings.Trim(config.BinaryPathName, "\""), "\\??\\")
	expected := filepath.Join(filepath.Dir(binary), "WinDivert64.sys")
	if config.ServiceType != windows.SERVICE_KERNEL_DRIVER || !strings.EqualFold(filepath.Clean(actual), expected) {
		return errors.New("winws: an incompatible WinDivert service is already registered")
	}
	if required {
		status, err := service.Query()
		if err != nil {
			return err
		}
		if status.State != svc.Running {
			return errors.New("winws: WinDivert service is not running after no-capture readiness")
		}
	}
	return nil
}
