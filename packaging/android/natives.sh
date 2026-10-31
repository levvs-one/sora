#!/usr/bin/env bash
# Builds sora-core and lays out the engines the Android app ships. Android only
# runs files from an app's native library directory, so each one goes there as
# lib<name>.so; the geo databases go into the assets.
#
#   packaging/android/natives.sh <arm64|amd64>...
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
lock="$root/packaging/engines/engines.lock"
sdk=${ANDROID_HOME:?ANDROID_HOME must point at the Android SDK}
ndk=${ANDROID_NDK_HOME:-$sdk/ndk/$(ls "$sdk/ndk" | sort -V | tail -1)}
clang="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin"
jni="$root/app/android/app/src/main/jniLibs"
geo="$root/app/android/app/src/main/assets/geo"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fetch() { # engine arch destination
	local digest url
	read -r _ _ digest url < <(awk -v e="$1" -v a="$2" '$1 == e && $2 == a' "$lock")
	[[ -n "$url" ]] || { echo "engines.lock: no $1 for $2" >&2; exit 1; }
	curl --fail --location --silent --show-error --retry 3 --proto '=https' --output "$3" "$url"
	echo "$digest  $3" | sha256sum --check --quiet --strict
}

for arch in "$@"; do
	case "$arch" in
	arm64) abi=arm64-v8a target=aarch64-linux-android26 ;;
	amd64) abi=x86_64 target=x86_64-linux-android26 ;;
	*) echo "unknown architecture $arch" >&2; exit 1 ;;
	esac
	out="$jni/$abi"
	mkdir -p "$out" "$geo"
	(
		cd "$root/core"
		GOOS=android GOARCH=$arch CGO_ENABLED=1 CC="$clang/$target-clang" \
			go build -trimpath -ldflags "-s -w -X main.buildVersion=${SORA_VERSION:-dev}" \
			-o "$out/libsora_core.so" ./cmd/sora-core
	)
	fetch xray "android-$arch" "$work/xray.zip"
	unzip -o -q "$work/xray.zip" xray geoip.dat geosite.dat -d "$work/xray"
	install -m 0755 "$work/xray/xray" "$out/libxray.so"
	install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$geo/"
	fetch mihomo "android-$arch" "$work/mihomo.gz"
	gunzip --stdout "$work/mihomo.gz" >"$work/mihomo"
	install -m 0755 "$work/mihomo" "$out/libmihomo.so"
	echo "$abi: done"
done
