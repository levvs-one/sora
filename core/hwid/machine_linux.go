//go:build linux && !android

package hwid

import (
	"bufio"
	"bytes"
	"errors"
	"os"
	"strings"

	"golang.org/x/sys/unix"
)

const osName = "Linux"

// machineID reads the systemd machine id, which is world-readable and set once
// per installation of the operating system.
func machineID() ([]byte, error) {
	for _, read := range []func() ([]byte, error){
		func() ([]byte, error) { return os.ReadFile("/etc/machine-id") },
		func() ([]byte, error) { return os.ReadFile("/var/lib/dbus/machine-id") },
	} {
		raw, err := read()
		if err != nil {
			continue
		}
		id := bytes.TrimSpace(raw)
		// An image prepared for cloning carries an empty or "uninitialized"
		// id that many machines share.
		if len(id) == 32 && !bytes.Equal(id, bytes.Repeat([]byte("0"), 32)) {
			return id, nil
		}
	}
	return nil, errors.New("hwid: no machine id")
}

// osVersion names the distribution, falling back to the kernel release.
func osVersion() string {
	if file, err := os.Open("/etc/os-release"); err == nil {
		defer func() { _ = file.Close() }()
		fields := map[string]string{}
		scanner := bufio.NewScanner(file)
		for scanner.Scan() {
			key, value, ok := strings.Cut(scanner.Text(), "=")
			if ok {
				fields[key] = strings.Trim(value, `"'`)
			}
		}
		if name := fields["PRETTY_NAME"]; name != "" {
			return name
		}
		if name := strings.TrimSpace(fields["NAME"] + " " + fields["VERSION_ID"]); name != "" {
			return name
		}
	}
	var uts unix.Utsname
	if unix.Uname(&uts) == nil {
		return unix.ByteSliceToString(uts.Release[:])
	}
	return ""
}
