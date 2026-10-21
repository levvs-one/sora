module github.com/levvs-one/sora-client/tools/sora-ext

go 1.27

toolchain go1.27.3

replace github.com/levvs-one/sora-client/core => ../../core

require (
	aead.dev/minisign v0.3.0
	github.com/levvs-one/sora-client/core v0.0.0-00010101000000-000000000000
)

require (
	golang.org/x/crypto v0.57.0 // indirect
	golang.org/x/net v0.60.0 // indirect
	golang.org/x/sys v0.48.0 // indirect
	golang.org/x/text v0.42.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260706201446-f0a921348800 // indirect
	google.golang.org/grpc v1.83.2 // indirect
	google.golang.org/protobuf v1.36.11 // indirect
)
