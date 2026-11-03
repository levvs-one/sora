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

# The upstream Android binary reads /data/system/packages.xml before it opens
# the adapter, which only root can do. The cmfa tag, the one its Android app
# builds with, leaves that out. The tag also closes the controller API the core
# drives, so that one file goes.
build_mihomo() { # arch clang output
	local url version
	if [[ ! -d "$work/mihomo-source" ]]; then
		fetch mihomo android-source "$work/mihomo.tar.gz"
		mkdir "$work/mihomo-source"
		tar --extract --gzip --file "$work/mihomo.tar.gz" --strip-components=1 --directory "$work/mihomo-source"
		rm "$work/mihomo-source/hub/route/patch_android.go"
	fi
	url=$(awk '$1 == "mihomo" && $2 == "android-source" { print $4 }' "$lock")
	version=$(basename "$url" .tar.gz)
	(
		cd "$work/mihomo-source"
		GOOS=android GOARCH=$1 CGO_ENABLED=1 CC="$2" go build -buildvcs=false -trimpath \
			-tags with_gvisor,cmfa \
			-ldflags "-s -w -buildid= -X github.com/metacubex/mihomo/constant.Version=$version" \
			-o "$3" .
	)
}

# sing-box runs with the platform its Android library expects from an app, added
# as one file, so the adapter comes from VpnService. A second file and one line
# move its API from a loopback port to a private socket.
build_singbox() { # arch clang output
	local source commit url
	source="$work/sing-box-source"
	read -r _ _ commit url < <(awk '$1 == "sing-box" && $2 == "android-source"' "$lock")
	if [[ ! -d "$source" ]]; then
		git init --quiet "$source"
		git -C "$source" fetch --quiet --depth 1 "${url%#*}" "$commit"
		git -C "$source" -c advice.detachedHead=false checkout --quiet FETCH_HEAD
		git -C "$source" submodule update --quiet --init --depth 1 \
			submodules/wireguard-go submodules/sing-tun submodules/gvisor submodules/utls
		cp "$root/packaging/android/sing-box-platform.go" "$source/cmd/sing-box/platform_sora.go"
		cp "$root/packaging/android/sing-box-control.go" "$source/experimental/clashapi/control_sora.go"
		sed -i 's/net.Listen("tcp", s.httpServer.Addr)/net.Listen(controlNetwork(s.httpServer.Addr), s.httpServer.Addr)/' \
			"$source/experimental/clashapi/server.go"
		grep --quiet controlNetwork "$source/experimental/clashapi/server.go"
	fi
	(
		cd "$source"
		GOOS=android GOARCH=$1 CGO_ENABLED=1 CC="$2" go build -buildvcs=false -trimpath \
			-tags with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api,with_xhttp,with_awg,with_low_memory,badlinkname,tfogo_checklinkname0 \
			-ldflags "-s -w -buildid= -checklinkname=0 -X 'github.com/sagernet/sing-box/constant.Version=${url#*#}'" \
			-o "$3" ./cmd/sing-box
	)
}

# The rule sets of core/routing/presets.go, so sing-box connects without GitHub.
fetch_rule_sets() {
	local rules commit url name
	rules="$root/app/android/app/src/main/assets/rules"
	mkdir -p "$rules"
	read -r _ _ commit url < <(awk '$1 == "rule-set" && $2 == "geosite"' "$lock")
	for name in category-ads-all category-gov-ru category-bank-ru category-ru tld-ru yandex vk mailru category-ir cn; do
		curl --fail --location --silent --show-error --retry 3 --proto '=https' \
			--output "$rules/geosite-$name.srs" "$url/$commit/geosite-$name.srs"
	done
	read -r _ _ commit url < <(awk '$1 == "rule-set" && $2 == "geoip"' "$lock")
	for name in ru ir cn; do
		curl --fail --location --silent --show-error --retry 3 --proto '=https' \
			--output "$rules/geoip-$name.srs" "$url/$commit/geoip-$name.srs"
	done
}

# The pinned source of the desktop packages, so both run the same revision.
olcrtc_revision=$(sed -n 's/^ *olcrtc_revision=//p' "$root/packaging/engines/fetch.sh")
olcrtc_digest=$(sed -n 's/^ *olcrtc_digest=//p' "$root/packaging/engines/fetch.sh")

# anet, its way around Android hiding the interface list from apps, links into
# the net package and needs the linker check off.
build_olcrtc() {
	local source="$work/olcrtc-source"
	if [ ! -d "$source" ]; then
		curl --fail --location --silent --show-error --retry 3 --proto '=https' --output "$work/olcrtc.tar.gz" 			"https://codeload.github.com/openlibrecommunity/olcrtc/tar.gz/$olcrtc_revision"
		echo "$olcrtc_digest  $work/olcrtc.tar.gz" | sha256sum --check --quiet --strict
		mkdir "$source"
		tar --extract --gzip --file "$work/olcrtc.tar.gz" --directory "$source" --strip-components=1
	fi
	(cd "$source" && GOOS=android GOARCH=$1 CGO_ENABLED=1 CC="$2" go build -mod=readonly -trimpath -buildvcs=false 		-ldflags '-s -w -buildid= -checklinkname=0' -o "$3" ./cmd/olcrtc)
}

fetch_rule_sets
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
	(
		cd "$root/service/sync"
		GOOS=android GOARCH=$arch CGO_ENABLED=1 CC="$clang/$target-clang" \
			go build -trimpath -ldflags "-s -w" -o "$out/libsora_sync.so" ./cmd/sora-sync
	)
	fetch xray "android-$arch" "$work/xray.zip"
	unzip -o -q "$work/xray.zip" xray geoip.dat geosite.dat -d "$work/xray"
	install -m 0755 "$work/xray/xray" "$out/libxray.so"
	install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$geo/"
	build_mihomo "$arch" "$clang/$target-clang" "$out/libmihomo.so"
	build_singbox "$arch" "$clang/$target-clang" "$out/libsingbox.so"
	fetch byedpi "android-$arch" "$work/byedpi.tar.gz"
	tar --extract --to-stdout --gzip --file "$work/byedpi.tar.gz" "ciadpi-${target%%-*}" >"$work/byedpi"
	install -m 0755 "$work/byedpi" "$out/libbyedpi.so"
	build_olcrtc "$arch" "$clang/$target-clang" "$out/libolcrtc.so"
	printf '{"Revision":"%s","SHA256":"%s"}
' "$olcrtc_revision" "$(sha256sum "$out/libolcrtc.so" | cut -d' ' -f1)" >"$geo/olcrtc-$abi.json"
	echo "$abi: done"
done
