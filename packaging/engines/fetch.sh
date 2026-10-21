#!/usr/bin/env bash
# Downloads the engine builds of engines.lock for one architecture, refuses any
# file whose SHA-256 differs from the lock, and lays them out as the core looks
# for them: sing-box, xray, mihomo, geoip.dat and geosite.dat in one directory.
# The geo databases come from the Xray archive, which is pinned like the rest.
# tar uses --no-same-owner: chown can be forbidden in rootless containers, and extracted ownership is unused (files are installed via install -m).
#
#   packaging/engines/fetch.sh amd64|arm64|windows-amd64|win7-386 <destination>
set -euo pipefail

arch=${1:?architecture: amd64, arm64, windows-amd64 or win7-386}
dest=${2:?destination directory}
lock="$(dirname "$0")/engines.lock"
sigmanifest="$(dirname "$0")/engines.sig"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$dest"

# signature_method prints the engines.sig method for an engine, defaulting to
# "none" with a warning when the manifest has no entry.
signature_method() {
	awk -v e="$1" '$1 == e {print $2; found=1} END {if (!found) exit 1}' "$sigmanifest" 2>/dev/null || {
		echo "engines.sig: no entry for $1; treating as unsigned" >&2
		echo none
	}
}

# verify_upstream_signature enforces the engines.sig declaration for one
# downloaded asset. It fails closed: a declared signature that cannot be
# checked aborts the fetch (SORA-M3).
verify_upstream_signature() {
	engine=$1 digest=$2 url=$3
	method=$(signature_method "$engine")
	case "$method" in
	none)
		echo "$engine: upstream publishes no signatures; lock digest is the only check (see engines.sig)" >&2
		;;
	dgst-crosscheck)
		dgst_file="$work/$(basename "$url").dgst"
		curl --fail --location --silent --show-error --retry 3 --connect-timeout 20 --max-time 600 --proto '=https' --output "$dgst_file" "$url.dgst" \
			|| { echo "engines.sig: could not download $url.dgst" >&2; exit 1; }
		published=$(awk '/^SHA2-256=/ {print $2}' "$dgst_file" | tr 'A-Z' 'a-z')
		if [ -z "$published" ]; then
			echo "engines.sig: no SHA2-256 in $url.dgst" >&2
			exit 1
		fi
		if [ "$published" != "$(printf '%s' "$digest" | tr 'A-Z' 'a-z')" ]; then
			echo "engines.sig: lock digest for $engine does not match the upstream .dgst" >&2
			exit 1
		fi
		echo "$engine: lock digest matches upstream .dgst"
		;;
	cosign)
		detail=$(awk -v e="$engine" '$1 == e {print $3}' "$sigmanifest")
		command -v cosign >/dev/null 2>&1 || { echo "engines.sig: cosign is required but not installed" >&2; exit 1; }
		[ -n "$detail" ] || { echo "engines.sig: no identity declared for $engine" >&2; exit 1; }
		asset="$work/$(basename "$url")"
		sig_file="$asset.sig"
		curl --fail --location --silent --show-error --retry 3 --connect-timeout 20 --max-time 600 --proto '=https' --output "$sig_file" "$url.sig" \
			|| { echo "engines.sig: could not download $url.sig" >&2; exit 1; }
		case "$detail" in
		keyless:*)
			identity=${detail#keyless:}
			cosign verify-blob --certificate-identity "$identity" \
				--certificate-oidc-issuer https://token.actions.githubusercontent.com \
				--signature "$sig_file" "$asset" >/dev/null \
				|| { echo "engines.sig: cosign keyless verification failed for $engine" >&2; exit 1; }
			;;
		pubkey:*)
			cosign verify-blob --key "${detail#pubkey:}" --signature "$sig_file" "$asset" >/dev/null \
				|| { echo "engines.sig: cosign verification failed for $engine" >&2; exit 1; }
			;;
		*)
			echo "engines.sig: bad cosign detail for $engine (want keyless:<id> or pubkey:<path>)" >&2
			exit 1
			;;
		esac
		echo "$engine: cosign signature verified ($detail)"
		;;
	*)
		echo "engines.sig: unknown method $method for $engine" >&2
		exit 1
		;;
	esac
}

# engines.digests records the SHA-256 of the installed binaries (not the
# download archives). The core verifies every discovered engine binary
# against this manifest and refuses to execute anything unverified (SORA-H5).
digests="$dest/engines.digests"
: >"$digests"
record_digest() {
	sha256sum "$1" | sed "s|$1|$(basename "$1")|" >>"$digests"
}

found=0
while read -r engine line_arch digest url; do
	[[ -z "$engine" || "$engine" == \#* || "$line_arch" != "$arch" ]] && continue
	found=$((found + 1))
	file="$work/$(basename "$url")"
	curl --fail --location --silent --show-error --retry 3 --connect-timeout 20 --max-time 600 --proto '=https' --output "$file" "$url"
	echo "$digest  $file" | sha256sum --check --quiet --strict
	# Enforce the upstream-signature declaration from engines.sig (SORA-M3).
	verify_upstream_signature "$engine" "$digest" "$url"
	if [[ "$engine" == olcrtc ]]; then
		# olcrtc ships no release binaries (see engines.lock): the
		# verified artifact is the source archive of the pinned tag,
		# and the binary is built here, per architecture, with the
		# upstream install.sh flags. Its own digest is recorded in
		# engines.digests like every other engine's, so the core's
		# SORA-H5 verification covers the sidecar unchanged. The
		# build needs a Go toolchain able to build the tag's go.mod
		# (go 1.26+; GOTOOLCHAIN=auto fetches it when the local go is
		# older). No win7-386 line exists in the lock: that toolchain
		# no longer targets Windows 7.
		command -v go >/dev/null 2>&1 || { echo "engines.lock: building olcrtc needs a Go toolchain in PATH" >&2; exit 1; }
		case "$arch" in
		amd64) goos=linux goarch=amd64 ;;
		arm64) goos=linux goarch=arm64 ;;
		windows-amd64) goos=windows goarch=amd64 ;;
		*) echo "engines.lock: no olcrtc build for $arch" >&2; exit 1 ;;
		esac
		mkdir -p "$work/olcrtc-src"
		tar --no-same-owner --extract --gzip --file "$file" --directory "$work/olcrtc-src" --strip-components=1
		(cd "$work/olcrtc-src" && CGO_ENABLED=0 GOOS="$goos" GOARCH="$goarch" \
			go build -trimpath -ldflags="-s -w" -o "$work/olcrtc-bin" ./cmd/olcrtc)
		if [[ "$goos" == windows ]]; then
			install -m 0755 "$work/olcrtc-bin" "$dest/olcrtc.exe"
			record_digest "$dest/olcrtc.exe"
		else
			install -m 0755 "$work/olcrtc-bin" "$dest/olcrtc"
			record_digest "$dest/olcrtc"
		fi
		echo "$engine $arch: verified (built from pinned source)"
		continue
	fi
	if [[ "$arch" == windows-* || "$arch" == win7-* ]]; then
		if [[ "$engine" == wintun ]]; then
			# The wintun zip carries one dll per architecture; extract the
			# matching one next to the engine executables. Windows needs it
			# on the DLL search path for the system-stack TUN path.
			case "$arch" in
			windows-amd64) wsub=amd64 ;;
			win7-386) wsub=x86 ;;
			*) echo "engines.lock: no wintun build for $arch" >&2; exit 1 ;;
			esac
			unzip -o -q "$file" -d "$work/wintun"
			dll=$(find "$work/wintun" -path "*/bin/$wsub/wintun.dll" | head -1)
			[[ -n "$dll" ]] || { echo "engines.lock: no $wsub wintun.dll in $(basename "$url")" >&2; exit 1; }
			install -m 0755 "$dll" "$dest/wintun.dll"
			record_digest "$dest/wintun.dll"
			echo "$engine $arch: verified"
			continue
		fi
		# Every Windows build is a zip with one executable named after its
		# engine; Xray's also carries the geo databases.
		unzip -o -q "$file" -d "$work/$engine"
		exe=$(find "$work/$engine" -iname "${engine}*.exe" ! -iname 'wxray.exe' | head -1)
		[[ -n "$exe" ]] || { echo "engines.lock: no executable in $(basename "$url")" >&2; exit 1; }
		install -m 0755 "$exe" "$dest/$engine.exe"
		record_digest "$dest/$engine.exe"
		if [[ "$engine" == xray ]]; then
			install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$dest/"
		fi
		echo "$engine $arch: verified"
		continue
	fi
	case "$engine" in
	sing-box)
		tar --no-same-owner --extract --gzip --file "$file" --directory "$work" --wildcards '*/sing-box'
		install -m 0755 "$work"/sing-box-*/sing-box "$dest/sing-box"
		record_digest "$dest/sing-box"
		;;
	xray)
		unzip -o -q "$file" xray geoip.dat geosite.dat -d "$work/xray"
		install -m 0755 "$work/xray/xray" "$dest/xray"
		install -m 0644 "$work/xray/geoip.dat" "$work/xray/geosite.dat" "$dest/"
		record_digest "$dest/xray"
		;;
	mihomo)
		gunzip --stdout "$file" >"$work/mihomo"
		install -m 0755 "$work/mihomo" "$dest/mihomo"
		record_digest "$dest/mihomo"
		;;
	*)
		echo "engines.lock: unknown engine $engine" >&2
		exit 1
		;;
	esac
	echo "$engine $arch: verified"
done <"$lock"

# Three engines everywhere, plus wintun.dll on the Windows arches,
# plus the olcrtc sidecar on every arch except win7-386 (see the
# lock: its Go toolchain no longer targets Windows 7).
expected=3
if [[ "$arch" != win7-386 ]]; then
	expected=$((expected + 1))
fi
if [[ "$arch" == windows-* || "$arch" == win7-* ]]; then
	expected=$((expected + 1))
fi
if [[ "$found" -ne "$expected" ]]; then
	echo "engines.lock has $found assets for $arch, expected $expected" >&2
	exit 1
fi
