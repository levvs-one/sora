#!/usr/bin/env bash
# Downloads the engine builds of engines.lock for one architecture, refuses any
# file whose SHA-256 differs from the lock, and lays them out as the core looks
# for them: sing-box, xray, mihomo, geoip.dat and geosite.dat in one directory.
# The geo databases come from the Xray archive, which is pinned like the rest.
#
#   packaging/engines/fetch.sh amd64|arm64 <destination>
set -euo pipefail

arch=${1:?architecture: amd64, arm64, windows-amd64 or win7-386}
dest=${2:?destination directory}
lock="$(dirname "$0")/engines.lock"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$dest"
dest=$(cd "$dest" && pwd)

found=0
while read -r engine line_arch digest url; do
	[[ -z "$engine" || "$engine" == \#* || "$line_arch" != "$arch" ]] && continue
	found=$((found + 1))
	file="$work/$(basename "$url")"
	curl --fail --location --silent --show-error --retry 3 --proto '=https' --output "$file" "$url"
	echo "$digest  $file" | sha256sum --check --quiet --strict
	if [[ "$arch" == windows-* || "$arch" == win7-* ]]; then
		# Every Windows build is a zip with one executable named after its
		# engine; Xray's also carries the geo databases.
		unzip -o -q "$file" -d "$work/$engine"
		exe=$(find "$work/$engine" -iname "${engine}*.exe" ! -iname 'wxray.exe' | head -1)
		[[ -n "$exe" ]] || { echo "engines.lock: no executable in $(basename "$url")" >&2; exit 1; }
		install -m 0755 "$exe" "$dest/$engine.exe"
		if [[ "$engine" == sing-box && "$arch" == windows-amd64 ]]; then
			# The DLL is version-coupled to the engine and covered by the archive checksum.
			cronet=$(find "$work/$engine" -name libcronet.dll -type f)
			[[ -n "$cronet" ]] || { echo "sing-box archive has no libcronet.dll" >&2; exit 1; }
			install -m 0644 "$cronet" "$dest/libcronet.dll"
		fi
		if [[ "$engine" == xray ]]; then
			install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$dest/"
		fi
		echo "$engine $arch: verified"
		continue
	fi
	case "$engine" in
	sing-box)
		tar --extract --gzip --file "$file" --directory "$work" --wildcards '*/sing-box'
		install -m 0755 "$work"/sing-box-*/sing-box "$dest/sing-box"
		;;
	xray)
		unzip -o -q "$file" xray geoip.dat geosite.dat -d "$work/xray"
		install -m 0755 "$work/xray/xray" "$dest/xray"
		install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$dest/"
		;;
	mihomo)
		gunzip --stdout "$file" >"$work/mihomo"
		install -m 0755 "$work/mihomo" "$dest/mihomo"
		;;
	*)
		echo "engines.lock: unknown engine $engine" >&2
		exit 1
		;;
	esac
	echo "$engine $arch: verified"
done <"$lock"

if [[ "$found" -ne 3 ]]; then
	echo "engines.lock has $found engines for $arch, expected 3" >&2
	exit 1
fi

# The archived upstream has no binary releases. Keep its wire implementation
# unchanged and verify the complete source archive before invoking the Go build.
if [[ "$arch" != win7-* ]]; then
 olcrtc_revision=f3ad8fb7c0d0fa981423f83269526fa94077c23d
 olcrtc_digest=3a9d5af88f5d74daefab96e8d642409946be79fc89f35587c1b74722ca2c3a4f
 source_file="$work/olcrtc.tar.gz"
 curl --fail --location --silent --show-error --retry 3 --proto '=https' --output "$source_file" "https://codeload.github.com/openlibrecommunity/olcrtc/tar.gz/$olcrtc_revision"
 echo "$olcrtc_digest  $source_file" | sha256sum --check --quiet --strict
 mkdir "$work/olcrtc-source"
 tar --extract --gzip --file "$source_file" --directory "$work/olcrtc-source" --strip-components=1
 target_os=linux
 target_arch=$arch
 target_name=olcrtc
 if [[ "$arch" == windows-amd64 ]]; then
  target_os=windows
  target_arch=amd64
  target_name=olcrtc.exe
 fi
 (cd "$work/olcrtc-source" && GOTOOLCHAIN=go1.27.3 CGO_ENABLED=0 GOOS=$target_os GOARCH=$target_arch go build -mod=readonly -trimpath -buildvcs=false -ldflags='-s -w -buildid=' -o "$dest/$target_name" ./cmd/olcrtc)
 binary_digest=$(sha256sum "$dest/$target_name")
 binary_digest=${binary_digest%% *}
 printf '{"Revision":"%s","SHA256":"%s"}\n' "$olcrtc_revision" "$binary_digest" >"$dest/$target_name.json"
 install -m 0644 "$work/olcrtc-source/LICENSE" "$dest/olcrtc.LICENSE"
 echo "olcrtc $arch: source verified, built $olcrtc_revision"
fi
