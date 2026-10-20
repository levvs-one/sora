# Signature sources for the engine release assets fetched by fetch.sh, one
# line per engine: "<engine> <method> [detail]".
#
# Methods:
#   none            The upstream publishes no signatures at all; the SHA-256
#                   in engines.lock is the only check. This is the honest
#                   current state for mihomo and the sing-box fork — see
#                   FIX-PLAN.md section 9 (owner decision: trust, switch
#                   upstream, or build from source).
#   dgst-crosscheck Verify the lock digest against the upstream's published
#                   checksum file (<asset-url>.dgst). Catches lock tampering
#                   and version drift; it does NOT authenticate the upstream
#                   release itself (the .dgst comes from the same release).
#   cosign          Verify the asset with cosign. Detail is "<identity>"
#                   (keyless, Rekor) or "pubkey:<path>" for a pinned key.
#                   fetch.sh fails closed when cosign is missing or the
#                   signature is invalid.
#
# Surveyed 2026-10-19: Xray publishes .dgst only; mihomo and Leadaxe/sing-box-lx
# publish no signatures.
# wintun.net publishes no signatures for the builds zip either; the SHA-256 in
# engines.lock (verified against the site 2026-10-20) is the only check.
xray     dgst-crosscheck
mihomo   none
sing-box none
wintun   none
