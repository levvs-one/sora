module github.com/levvs-one/sora-client/tools/sora-ext

go 1.27

toolchain go1.27.2

replace github.com/levvs-one/sora-client/core => ../../core

require github.com/levvs-one/sora-client/core v0.0.0-00010101000000-000000000000

require (
	golang.org/x/net v0.61.0 // indirect
	golang.org/x/sys v0.49.0 // indirect
	golang.org/x/text v0.43.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20260706201446-f0a921348800 // indirect
	google.golang.org/grpc v1.84.0 // indirect
	google.golang.org/protobuf v1.36.12 // indirect
)
