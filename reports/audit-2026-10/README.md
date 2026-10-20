# Audit program 2026-10 — full working archive

This directory holds the complete record of the October 2026 audit and
improvement program for sora and sora-legacy: the initial audit of both
repositories, three rounds of fixes, the feature waves, the 5-pass review,
the research departments (web, network, TSPU/blocking, deep research), the
extensions department, three full autonomous passes through every
department, the final mega-audit, and the optimizer departments
(20 + 40 agents).

Everything here is a working document produced during the program. The code
changes themselves live in this branch (`bugfix/audit-2026-10-19`) in both
repositories.

## Start here

- `FINAL-HANDOFF.md` — the shortest path: what was done, what remains, and
  what only the owner can do.
- `PASS3-SUMMARY.md` — the state after the third full pass, with the delta
  across all three passes.
- `OWNER-DECISIONS-PASS2.md` — the 10 decisions only the owner can make
  (key ceremony, engine bumps, NOT WIRED module fates, Android, etc.).
- `FINAL-AUDIT.md` — the mega-audit verdicts per zone.
- `OPT40.md` — the final optimizer department: measured wins, benchmark
  gates, saturation verdict.

## Map

- Audits and fixes: `UNIFIED-REPORT.md`, `sora-audit.md`,
  `sora-legacy-audit.md`, `FIX-PLAN.md`, `FIX-REPORT.md`, `REVIEW-5PASS.md`,
  `POWER-RUN.md`, `ANALYSIS-20.md`, `DETAIL-FIXES.md`
- Features: `FEATURE-PLAN.md`, `FEATURE-REPORT.md`, `EXTENSIONS-VISION.md`,
  `EXTENSIONS-40.md`, `SWARM-REPORT.md`
- Research: `WEB-RESEARCH.md`, `WEB-RESEARCH-2.md` … `WEB-RESEARCH-5.md`,
  `NET-RESEARCH.md`, `DEEP-RESEARCH-70.md`, `competitor-analysis.md`
- TSPU/blocking: `TSPU-ANALYSIS.md`, `TSPU-SOLUTIONS.md`, `TSPU-FINISH.md`,
  `PASS1/2/3-TSPU-*.md`
- Passes: `PASS1-SUMMARY.md`, `PASS2-SUMMARY.md`, `PASS3-SUMMARY.md` and the
  per-department `PASS*-*.md` files
- Optimizers: `OPTIMIZERS.md`, `OPT40.md`
- Subdirectories (`partials/`, `tspu-analysis/`, `deep-research/`,
  `detail-fixes-parts/`, `final-audit/`, `review-5pass/`, `github-design/`,
  `tspu-solutions/`) — the per-agent working reports behind the summaries.

This archive is meant to be reviewed and then deleted before release if
desired; it is not product documentation.
