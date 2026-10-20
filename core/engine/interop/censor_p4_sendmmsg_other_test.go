//go:build !linux

package interop_test

// sendmmsgDenied on non-Linux platforms: the direct sendmmsg probe
// is a Linux syscall shape, so there is no probe evidence — the
// AWG traffic proof runs (an engine-log EPERM signature can still
// skip it). See censor_p4_sendmmsg_linux_test.go (CENSOR-P4 fix M1).
func sendmmsgDenied() bool { return false }
