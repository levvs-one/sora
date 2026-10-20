package censorproxy

import (
	"fmt"
	"math"
	"time"
)

// DetectorResult is the verdict of one detector.
type DetectorResult struct {
	// Name identifies the detector.
	Name string
	// Score is the suspicion score in [0,1]; 0 is benign, 1 is certain
	// detection. Zero when Insufficient.
	Score float64
	// Explain is the concrete "why" in plain words.
	Explain string
	// Insufficient means the detector could not run (e.g. no payload, no
	// ClientHello observed); it is excluded from the aggregate score.
	Insufficient bool
}

type detector func(f *Flow, cfg Config) DetectorResult

// shannonEntropy returns the Shannon entropy of b in bits per byte.
func shannonEntropy(b []byte) float64 {
	if len(b) == 0 {
		return 0
	}
	var freq [256]int
	for _, x := range b {
		freq[x]++
	}
	var e float64
	n := float64(len(b))
	for _, c := range freq {
		if c == 0 {
			continue
		}
		p := float64(c) / n
		e -= p * math.Log2(p)
	}
	return e
}

// firstPacketEntropy implements the Wu et al. entropy heuristic: the first
// bytes of an obfuscated tunnel (Shadowsocks AEAD, WireGuard handshake) are
// indistinguishable from random (~7.9 bits/byte), while a TLS ClientHello
// carries structured fields (typically 4.5-6.5 bits/byte over the first
// kilobytes). High early entropy is a distinguisher.
func firstPacketEntropy(f *Flow, cfg Config) DetectorResult {
	const name = "first-packet-entropy"
	var early []byte
	n := 0
	for _, p := range f.outbound() {
		if n >= 10 || len(early) >= 8192 {
			break
		}
		if len(p.Payload) == 0 {
			continue
		}
		early = append(early, p.Payload...)
		n++
	}
	if len(early) < 32 {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "недостаточно payload в первых исходящих пакетах для оценки энтропии"}
	}
	e := shannonEntropy(early)
	var score float64
	switch {
	case e < 6.5:
		score = 0
	case e < 7.0:
		score = (e - 6.5) / 0.5 * 0.3
	case e < 7.5:
		score = 0.3 + (e-7.0)/0.5*0.4
	default:
		score = 1.0
	}
	why := "энтропия в норме"
	if score >= 0.7 {
		why = "энтропия как у шифрованного туннеля без handshake-структуры"
	} else if score > 0 {
		why = "энтропия выше типичной для TLS ClientHello"
	}
	return DetectorResult{Name: name, Score: score,
		Explain: fmt.Sprintf("энтропия payload первых %d исходящих пакетов: %.2f бит/байт — %s", n, e, why)}
}

// handshakeSizes checks the first outbound packet sizes against a TLS
// handshake profile. A ClientHello is a few hundred bytes; a tiny first
// packet looks like an obfuscated probe, an oversized one like a padded
// tunnel handshake.
func handshakeSizes(f *Flow, cfg Config) DetectorResult {
	const name = "handshake-sizes"
	out := f.outbound()
	if len(out) == 0 {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "нет исходящих пакетов для анализа handshake"}
	}
	s0 := out[0].Size
	var score float64
	var why string
	switch {
	case s0 < 64:
		score, why = 1.0, "слишком мал для ClientHello — похоже на обфусцированный probe"
	case s0 < 128:
		score, why = 0.6, "меньше типичного ClientHello"
	case s0 <= 1460:
		score, why = 0, "в диапазоне типичного ClientHello"
	default:
		score, why = 0.7, "больше MTU-сегмента для первого handshake-пакета"
	}
	return DetectorResult{Name: name, Score: score,
		Explain: fmt.Sprintf("размер первого исходящего пакета: %d байт — %s", s0, why)}
}

// inOutBalance looks at the in/out payload byte ratio past the handshake
// (Wu et al. size features). Interactive browsing is inbound-heavy; a
// strongly outbound-skewed flow looks like an upload tunnel.
func inOutBalance(f *Flow, cfg Config) DetectorResult {
	const name = "in-out-balance"
	var in, out int64
	for i, p := range f.Packets {
		if i < 5 {
			continue // skip the handshake
		}
		if p.Dir == Outbound {
			out += int64(p.Size)
		} else {
			in += int64(p.Size)
		}
	}
	if in+out == 0 {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "нет payload после handshake для оценки баланса in/out"}
	}
	if in == 0 {
		return DetectorResult{Name: name, Score: 1.0,
			Explain: fmt.Sprintf("входящего payload нет вообще (%d байт исходящих) — односторонний поток", out)}
	}
	r := float64(out) / float64(in)
	var score float64
	var why string
	switch {
	case r <= 2:
		score, why = 0, "баланс в норме"
	case r <= 4:
		score, why = 0.4, "заметный перекос в исходящий трафик"
	case r <= 8:
		score, why = 0.7, "сильный перекос в исходящий трафик"
	default:
		score, why = 1.0, "почти весь трафик исходящий — похоже на upload-туннель"
	}
	return DetectorResult{Name: name, Score: score,
		Explain: fmt.Sprintf("соотношение out/in после handshake: %.2f (%d/%d байт) — %s", r, out, in, why)}
}

// interArrival examines outbound timing regularity past the handshake (Wu et
// al. timing features). Human-driven traffic is bursty; machine-regular
// spacing (low coefficient of variation) looks like tunnel keepalives.
// Long quiet gaps are flagged as well.
func interArrival(f *Flow, cfg Config) DetectorResult {
	const name = "inter-arrival"
	var gaps []float64
	var prev time.Duration
	n := 0
	for _, p := range f.Packets {
		if p.Dir != Outbound {
			continue
		}
		n++
		if n <= 5 {
			prev = p.At
			continue
		}
		gaps = append(gaps, float64(p.At-prev)/float64(time.Second))
		prev = p.At
	}
	if len(gaps) < 5 {
		return DetectorResult{Name: name, Insufficient: true,
			Explain: "мало исходящих пакетов после handshake для анализа тайминга"}
	}
	var sum float64
	for _, g := range gaps {
		sum += g
	}
	mean := sum / float64(len(gaps))
	var vsum float64
	for _, g := range gaps {
		d := g - mean
		vsum += d * d
	}
	std := math.Sqrt(vsum / float64(len(gaps)))
	cv := 0.0
	if mean > 0 {
		cv = std / mean
	}
	var score float64
	why := fmt.Sprintf("CV=%.2f — тайминг как у живого трафика", cv)
	switch {
	case cv < 0.25:
		score, why = 0.7, fmt.Sprintf("слишком регулярные интервалы (CV=%.2f) — похоже на машинные keepalive", cv)
	case cv < 0.5:
		score, why = 0.3, fmt.Sprintf("умеренно регулярные интервалы (CV=%.2f)", cv)
	}
	for _, g := range gaps {
		if g > 30 {
			if score < 0.4 {
				score = 0.4
			}
			why += fmt.Sprintf("; тихий период %.0f c", g)
			break
		}
	}
	return DetectorResult{Name: name, Score: score,
		Explain: fmt.Sprintf("регулярность исходящих интервалов после handshake: %s", why)}
}
