package main

import (
	"encoding/json"
	"os"
	"strings"
)

// This executable only observes the fixture payload; it cannot manage services.
func main() {
	if len(os.Args) != 5 {
		os.Exit(40)
	}
	data, err := os.ReadFile(os.Args[1])
	if err != nil || len(data) > 4096 || strings.TrimSpace(string(data)) != os.Args[3] {
		os.Exit(41)
	}
	observation, err := json.Marshal(map[string]any{
		"observed": string(data), "expected": os.Args[3], "failed": os.Args[4] == "1",
	})
	if err != nil || os.WriteFile(os.Args[2], observation, 0o600) != nil {
		os.Exit(42)
	}
	if os.Args[4] == "1" {
		os.Exit(1)
	}
}
