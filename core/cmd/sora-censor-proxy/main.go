// Command sora-censor-proxy runs the "censor's proxy" regression testbed
// (core/testutil/censorproxy) over a pcap file and prints the verdict to
// stdout. Manual runs; CI wiring is a separate task after threshold
// calibration.
//
// Exit codes: 0 = OK, 1 = warning, 2 = blocker, 3 = insufficient data or error.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"github.com/levvs-one/sora-client/core/testutil/censorproxy"
)

const (
	exitOK = iota
	exitWarning
	exitBlocker
	exitError
)

func main() {
	pcapPath := flag.String("pcap", "", "путь к pcap-файлу (classic pcap, IPv4/TCP)")
	profile := flag.String("profile", "chrome", "uTLS-профиль для JA4-оценки")
	host := flag.String("host", "", "ожидаемый Host для проверки SNI-консистентности")
	minPackets := flag.Int("min-packets", 0, "минимум пакетов для вердикта (0 = 50)")
	asJSON := flag.Bool("json", false, "вывод в JSON")
	flag.Parse()

	if *pcapPath == "" {
		fmt.Fprintln(os.Stderr, "нужен -pcap <файл>")
		flag.Usage()
		os.Exit(exitError)
	}
	f, err := os.Open(*pcapPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "не открыть pcap: %v\n", err)
		os.Exit(exitError)
	}
	flow, err := censorproxy.ReadPcap(f)
	f.Close()
	if err != nil {
		fmt.Fprintf(os.Stderr, "не прочитать pcap: %v\n", err)
		os.Exit(exitError)
	}

	v := censorproxy.Run(flow, censorproxy.Config{
		Profile:    *profile,
		DestHost:   *host,
		MinPackets: *minPackets,
	})

	if *asJSON {
		out := struct {
			Level        string        `json:"level"`
			Score        float64       `json:"score"`
			Packets      int           `json:"packets"`
			Insufficient bool          `json:"insufficient"`
			Reason       string        `json:"reason,omitempty"`
			Detectors    []detectorOut `json:"detectors"`
		}{
			Level:        v.Level.String(),
			Score:        v.Score,
			Packets:      len(flow.Packets),
			Insufficient: v.Insufficient,
			Reason:       v.Reason,
		}
		for _, r := range v.Results {
			out.Detectors = append(out.Detectors, detectorOut{
				Name:         r.Name,
				Score:        r.Score,
				Explain:      r.Explain,
				Insufficient: r.Insufficient,
			})
		}
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		enc.SetEscapeHTML(false)
		if err := enc.Encode(out); err != nil {
			fmt.Fprintf(os.Stderr, "не закодировать JSON: %v\n", err)
			os.Exit(exitError)
		}
	} else {
		fmt.Printf("sora-censor-proxy: %s (score %.3f, пакетов %d)\n", v.Level, v.Score, len(flow.Packets))
		if v.Insufficient {
			fmt.Printf("  %s\n", v.Reason)
		}
		for _, r := range v.Results {
			mark := " "
			if r.Insufficient {
				mark = "~"
			}
			fmt.Printf("  [%s] %-20s %.2f — %s\n", mark, r.Name, r.Score, r.Explain)
		}
	}

	switch v.Level {
	case censorproxy.LevelOK:
		os.Exit(exitOK)
	case censorproxy.LevelWarning:
		os.Exit(exitWarning)
	case censorproxy.LevelBlocker:
		os.Exit(exitBlocker)
	default:
		os.Exit(exitError)
	}
}

type detectorOut struct {
	Name         string  `json:"name"`
	Score        float64 `json:"score"`
	Explain      string  `json:"explain"`
	Insufficient bool    `json:"insufficient,omitempty"`
}
