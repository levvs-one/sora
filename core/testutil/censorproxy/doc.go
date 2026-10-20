// Package censorproxy is the "censor's proxy" regression testbed: a passive
// traffic classifier run over captured flows before release. Each release is
// scored by the stand; metric degradation is a release blocker.
//
// Architecture (spec reports/tspu-solutions/10-censor-proxy-testbed.md):
//   - L1: Wu et al. heuristics — threshold rules over the first N packets
//     (payload entropy, handshake sizes, in/out balance, inter-arrival
//     timing). Cheap, deterministic, explainable; every failure carries a
//     concrete "why" string.
//   - L2: JA4/JA3 cross-check plus an SNI-consistency detector (SNI == Host).
//     JA4 computation is reused from core/diagnostics (AssessJA4 with an
//     injected ClientHello capture); the stand never duplicates it.
//
// Input is a Flow (packets with size/direction/time, plus payload for the
// ClientHello) or a classic pcap file via ReadPcap. Output is a Verdict:
// per-detector score in [0,1] with an explanation string, plus a weighted
// aggregate score. Thresholds: >=0.7 release blocker, 0.4-0.7 warning with
// mandatory review, <0.4 ok. Thresholds are constants marked for calibration
// on the first runs; changing a threshold is a separate commit.
//
// Honest limitations (spec §3) — what the stand does NOT do:
//  1. It does not emulate an active censor: probing, throttling, SNI
//     blocklists, ISP-level behavioral heuristics are out of scope. This is
//     a passive traffic classifier.
//  2. It knows nothing out-of-band: ASN/IP reputation, DNS signals, user
//     timing patterns — the stand sees only the flow.
//  3. Wu et al. heuristics are noisy on short flows; flows below MinPackets
//     are reported as "insufficient data", never as "clean".
//  4. Detectors lag the real censor by definition; the stand catches
//     regressions against a baseline, not "invisibility".
//
// L3 (wavelet-RF) and L4 (DF-CNN) are separate tasks and are not implemented
// here.
package censorproxy
