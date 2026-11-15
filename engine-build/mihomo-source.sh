#!/usr/bin/env bash
# Lays out the mihomo source of engines.lock with Sora's REALITY patch applied
# and prints the version the build reports. Every platform builds mihomo from
# this tree: upstream binaries send a REALITY client version that current Xray
# servers reject (see mihomo-reality.patch).
#
#   packaging/engines/mihomo-source.sh <empty destination>
set -euo pipefail

dest=${1:?destination directory}
here=$(cd "$(dirname "$0")" && pwd)
# The suffix names the patch set; the core lifts the REALITY refusal for
# builds that report it (engine.BuildCapabilities).
suffix=sora.1

read -r _ _ digest url < <(awk '$1 == "mihomo" && $2 == "source"' "$here/engines.lock")
[[ -n "$url" ]] || { echo "engines.lock: no mihomo source" >&2; exit 1; }
mkdir "$dest"
curl --fail --location --silent --show-error --retry 3 --proto '=https' --output "$dest.tar.gz" "$url"
echo "$digest  $dest.tar.gz" | sha256sum --check --quiet --strict
tar --extract --gzip --strip-components=1 --directory "$dest" <"$dest.tar.gz"
rm "$dest.tar.gz"
patch --directory "$dest" --strip 1 --forward --quiet <"$here/mihomo-reality.patch"
echo "$(basename "$url" .tar.gz)-$suffix"
