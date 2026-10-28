package bypass

import (
	"fmt"
	"runtime"
	"strconv"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

func proxyArgs(strategy engine.BypassStrategy, port int, protocol engine.Protocol) ([]string, error) {
	if protocol == engine.ProtocolByeDPI || runtime.GOOS == "windows" {
		return WindowsArgs(strategy, port)
	}
	return Args(strategy, port), nil
}

// WindowsArgs uses ByeDPI's native SOCKS proxy without a packet interception
// driver. tpws markers have different semantics and must not be approximated.
func WindowsArgs(strategy engine.BypassStrategy, port int) ([]string, error) {
	if err := (engine.Outbound{ID: "bypass", Protocol: engine.ProtocolBypass, Bypass: &strategy}).Validate(); err != nil {
		return nil, err
	}
	if strategy.MethodEOL {
		return nil, fmt.Errorf("bypass: ByeDPI does not support HTTP method EOL shaping")
	}
	args := []string{"--ip=127.0.0.1", "--port=" + strconv.Itoa(port), "--no-udp"}
	mode := "--split="
	if strategy.Disorder && strategy.OOB {
		mode = "--disoob="
	} else if strategy.Disorder {
		mode = "--disorder="
	} else if strategy.OOB {
		mode = "--oob="
	}
	for _, position := range strategy.SplitPos {
		if _, err := strconv.Atoi(position); err != nil {
			return nil, fmt.Errorf("bypass: ByeDPI needs numeric split positions, not %q", position)
		}
		args = append(args, mode+position)
	}
	if strategy.TLSRecord != "" {
		if _, err := strconv.Atoi(strategy.TLSRecord); err != nil {
			return nil, fmt.Errorf("bypass: ByeDPI needs a numeric TLS record position, not %q", strategy.TLSRecord)
		}
		args = append(args, "--tlsrec="+strategy.TLSRecord)
	}
	var modifications []string
	if strategy.HostCase {
		modifications = append(modifications, "hcsmix")
	}
	if strategy.DomainCase {
		modifications = append(modifications, "dcsmix")
	}
	if len(modifications) > 0 {
		args = append(args, "--mod-http="+strings.Join(modifications, ","))
	}
	return args, nil
}
