package main

import (
	"encoding/json"
	"io"
	"os"
	"runtime"
)

// This child deliberately has no runtime watchdog or self-imposed OS limits.
// Blocking on stdin after allocating reproduces a worker that uses no CPU
// while retaining too much memory, independently of a particular Go OOM bug.
func main() {
	var input json.RawMessage
	if err := json.NewDecoder(os.Stdin).Decode(&input); err != nil {
		panic(err)
	}
	switch os.Args[1] {
	case "memory":
		data := make([]byte, 192<<20)
		for i := range data {
			data[i] = byte(i)
		}
		_, _ = io.Copy(io.Discard, os.Stdin)
		runtime.KeepAlive(data)
	case "CPU":
		for {
		}
	default:
		panic("unknown budget scenario")
	}
}
