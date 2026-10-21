module github.com/levvs-one/sora-client/tools/sora-ext

go 1.27

toolchain go1.27.2

replace github.com/levvs-one/sora-client/core => ../../core

require (
	aead.dev/minisign v0.3.0
	github.com/levvs-one/sora-client/core v0.0.0-00010101000000-000000000000
)

require (
	github.com/dlclark/regexp2/v2 v2.8.1 // indirect
	github.com/dop251/goja v0.0.0-20261020172427-7b1a02208696 // indirect
	github.com/go-sourcemap/sourcemap v2.1.3+incompatible // indirect
	github.com/google/pprof v0.0.0-20230207041349-798e818bf904 // indirect
	golang.org/x/crypto v0.57.0 // indirect
	golang.org/x/net v0.60.0 // indirect
	golang.org/x/sys v0.48.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260706201446-f0a921348800 // indirect
	google.golang.org/grpc v1.83.2 // indirect
	google.golang.org/protobuf v1.36.11 // indirect
)
