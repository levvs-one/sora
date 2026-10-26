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

# Windows uses a native, driver-free SOCKS reshaper; packet interception is
# deliberately not part of this backend. Its upstream release is MIT licensed.
if [[ "$arch" == windows-amd64 ]]; then
 byedpi_digest=70d2c94147193cb915f9c6eb5144b8d404dacbcfa90bda2383b6b211afafa456
 byedpi_file="$work/byedpi.zip"
 curl --fail --location --silent --show-error --retry 3 --proto '=https' --output "$byedpi_file" 'https://github.com/hufrea/byedpi/releases/download/v0.17.3/byedpi-17.3-x86_64-w64.zip'
 echo "$byedpi_digest  $byedpi_file" | sha256sum --check --quiet --strict
 unzip -p "$byedpi_file" ciadpi.exe >"$dest/byedpi.exe"
 install -m 0644 "$(dirname "$0")/byedpi.LICENSE" "$dest/byedpi.LICENSE"
 echo 'byedpi windows-amd64: verified v0.17.3'
fi


# Keep Winws and its version-coupled DLLs in their own directory. Installing the
# bundle copies files only; the optional runtime owns loading after user consent.
if [[ "$arch" == windows-amd64 ]]; then
 winws_dir="$dest/winws"
 mkdir -p "$winws_dir/licenses" "$winws_dir/sources"
 zapret_archive="$work/zapret-v72.13.zip"
 curl --fail --location --silent --show-error --retry 3 --proto '=https' --proto-redir '=https' --max-filesize 7959200 --output "$zapret_archive" 'https://github.com/bol-van/zapret/releases/download/v72.13/zapret-v72.13.zip'
 echo "c493e33a0dc4eba23a8686efdaba55f59755ad6ade3564aebd9d13f4c65e2e0c  $zapret_archive" | sha256sum --check --quiet --strict
 while read -r name digest; do
  unzip -p "$zapret_archive" "zapret-v72.13/binaries/windows-x86_64/$name" >"$work/$name"
  echo "$digest  $work/$name" | sha256sum --check --quiet --strict
  install -m 0644 "$work/$name" "$winws_dir/$name"
 done <<'WINWS_COMPONENTS'
winws.exe a14bff1df6234ea555d2e0c61b589f0707c0b12d6c9b7eeccda76012154996e8
WinDivert.dll c1e060ee19444a259b2162f8af0f3fe8c4428a1c6f694dce20de194ac8d7d9a2
WinDivert64.sys 8da085332782708d8767bcace5327a6ec7283c17cfb85e40b03cd2323a90ddc2
cygwin1.dll 103104a52e5293ce418944725df19e2bf81ad9269b9a120d71d39028e821499b
WINWS_COMPONENTS
 install -m 0644 "$zapret_archive" "$winws_dir/sources/zapret-v72.13.zip"
 install -m 0644 "$(dirname "$0")"/winws-licenses/*.txt "$winws_dir/licenses/"
 while read -r name digest size url; do
  curl --fail --location --silent --show-error --retry 3 --proto '=https' --proto-redir '=https' --max-filesize "$size" --output "$work/$name" "$url"
  echo "$digest  $work/$name" | sha256sum --check --quiet --strict
  install -m 0644 "$work/$name" "$winws_dir/sources/$name"
 done <<'WINWS_SOURCES'
WinDivert-v2.2.2-source.tar.gz 300c1b14e08652e0f8647bf06e9b212f924af76cb2459bd0f88da481c9b08336 164606 https://codeload.github.com/basil00/WinDivert/tar.gz/refs/tags/v2.2.2
cygwin-3.4.10-1-src.tar.xz ac70af0d4e644732f74946f55f7bafe010bab9b9da39a9327c3f0367f1fa43a2 8964220 https://ftp.cvut.cz/mirrors/cygwin.com/x86_64/release/cygwin/cygwin-3.4.10-1-src.tar.xz
WINWS_SOURCES
 echo 'winws windows-amd64: verified v72.13, native libraries, licences and complete upstream sources'
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
