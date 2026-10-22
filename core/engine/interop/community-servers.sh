#!/usr/bin/env bash
# Test servers only. Neither executable is included in Sora packages.
set -euo pipefail
dest=${1:?destination directory}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$dest"
curl --fail --location --silent --show-error --retry 3 --proto '=https' \
  -o "$work/mita.tar.gz" https://github.com/enfein/mieru/releases/download/v3.38.1/mita_3.38.1_linux_amd64.tar.gz
echo "015248cd8f9b3b2bc9da2e22f10996952a6ebe782918625a5f26741470a3cae8  $work/mita.tar.gz" | sha256sum --check --strict
tar -xzf "$work/mita.tar.gz" -C "$work" mita
install -m 0755 "$work/mita" "$dest/mita"
curl --fail --location --silent --show-error --retry 3 --proto '=https' \
  -o "$work/caddy.tar.xz" https://github.com/klzgrad/forwardproxy/releases/download/v2.11.7-naive/caddy-forwardproxy-naive.tar.xz
echo "ac97057c925bb098eb575e7b0cb8bd547d4c5f845b09a3dedfbe34444aa7ae88  $work/caddy.tar.xz" | sha256sum --check --strict
tar -xJf "$work/caddy.tar.xz" -C "$work" caddy-forwardproxy-naive/caddy
install -m 0755 "$work/caddy-forwardproxy-naive/caddy" "$dest/caddy"
