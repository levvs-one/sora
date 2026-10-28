#!/bin/sh
# One-command bootstrap trusts the HTTPS download of this script.
# Existing verifiers stay on the strict signed-metadata path.
#
# SORA_VERSION=1.0.3 installs that release instead of the latest.
# SORA_DIST=<directory> installs packages already in that directory, with
# signed SHA256SUMS; CI uses an isolated verifier with a temporary test key.
set -eu
umask 077

repo=https://github.com/levvs-one/sora

say() { printf '%s\n' "$*"; }
die() {
	printf 'sora: %s\n' "$*" >&2
	exit 1
}

verifier=${SORA_VERIFIER:-/usr/bin/sora-core}
case "$verifier" in /*) ;; *) die 'SORA_VERIFIER must be an absolute path to a previously trusted core' ;; esac
if [ -n "${SORA_VERIFIER:-}" ] && { [ ! -f "$verifier" ] || [ ! -x "$verifier" ]; }; then
	die 'the explicitly selected trusted verifier is unavailable'
fi
if [ -f "$verifier" ] && [ -x "$verifier" ]; then
	verifier=$(readlink -f -- "$verifier") || die 'could not resolve the trusted verifier'
	if [ -z "${SORA_VERIFIER:-}" ] && ! "$verifier" -h 2>&1 | grep -q -- '-verify-release'; then verifier=; fi
else
	verifier=
fi
if [ -n "${SORA_DIST:-}" ]; then
	distribution=$(cd "$SORA_DIST" && pwd -P)
	case "$verifier" in "$distribution"/*) die 'do not trust a verifier supplied with the downloads' ;; esac
fi

case "$(uname -m)" in
x86_64 | amd64) deb_arch=amd64 rpm_arch=x86_64 arch_arch=x86_64 ;;
aarch64 | arm64) deb_arch=arm64 rpm_arch=aarch64 arch_arch=aarch64 ;;
*) die "no Sora build for $(uname -m)" ;;
esac

if command -v apt-get >/dev/null 2>&1; then
	manager=apt
elif command -v dnf >/dev/null 2>&1; then
	manager=dnf
elif command -v zypper >/dev/null 2>&1; then
	manager=zypper
elif command -v pacman >/dev/null 2>&1; then
	manager=pacman
else
	die "no apt, dnf, zypper or pacman here; download a package from $repo/releases"
fi

if [ "$(id -u)" -eq 0 ]; then
	as_root=""
elif command -v sudo >/dev/null 2>&1; then
	as_root=sudo
else
	die "installing packages needs root, and there is no sudo"
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT INT TERM

if [ -z "${SORA_DIST:-}" ]; then
	# Older curl does not enforce --max-filesize on chunked responses.
	curl_ok=$(curl --version | awk 'NR == 1 {split($2, v, "."); if (v[1] > 8 || (v[1] == 8 && v[2] >= 4)) print "yes"; exit}')
	[ "$curl_ok" = yes ] || die 'network installation requires curl 8.4 or later for bounded downloads; authenticated local SORA_DIST remains supported'
fi

fetch() {
	_name=$1 _limit=$2
	if [ -n "${SORA_DIST:-}" ]; then
		if [ ! -f "$SORA_DIST/$_name" ] || [ -L "$SORA_DIST/$_name" ]; then die 'release inputs must be regular files'; fi
		head -c "$((_limit + 1))" -- "$SORA_DIST/$_name" >"$work/$_name" || die "could not copy $_name"
	else
		curl -q -fsSL --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 20 --max-time 600 \
			--max-filesize "$_limit" -o "$work/$_name" "$repo/releases/download/v$version/$_name" || die "could not download $_name within its size limit"
	fi
	_bytes=$(wc -c <"$work/$_name")
	if [ "$_bytes" -lt 1 ] || [ "$_bytes" -gt "$_limit" ]; then die "invalid $_name size"; fi
}

if [ -n "${SORA_DIST:-}" ]; then
	version=${SORA_VERSION:?SORA_VERSION is needed with SORA_DIST}
else
	if [ -z "${SORA_VERSION:-}" ]; then
		# The latest release redirects to its tag; no API call, no rate limit.
		latest=$(curl -fsSLI --proto '=https' -o /dev/null -w '%{url_effective}' "$repo/releases/latest")
		version=${latest##*/v}
		case "$version" in
		[0-9]*.[0-9]*.[0-9]*) ;;
		*) die "could not tell the latest release from $latest" ;;
		esac
	else
		version=$SORA_VERSION
	fi
fi

if [ "${#version}" -gt 64 ] || ! printf '%s\n' "$version" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; then
	die 'not a stable release of Sora'
fi

case "$manager" in
apt) files="sora-core_${version}_${deb_arch}.deb" app="sora_${version}_${deb_arch}.deb" ;;
dnf | zypper) files="sora-core-${version}-1.${rpm_arch}.rpm" app="sora-${version}-1.${rpm_arch}.rpm" ;;
pacman)
	# A pacman version has no "~"; a build between releases loses it.
	pkgver=$(printf '%s' "$version" | tr -d '~')
	files="sora-core-${pkgver}-1-${arch_arch}.pkg.tar.zst" app="sora-${pkgver}-1-${arch_arch}.pkg.tar.zst"
	;;
esac
files="$files $app"

say "sora: installing $version with $manager"
fetch SHA256SUMS 1048576
fetch SHA256SUMS.minisig 8192
grep -Eq ' [ *]release[.]json$' "$work/SHA256SUMS" || die 'schema 1 release metadata is required'
fetch release.json 1048576
if [ -n "$verifier" ]; then
	"$verifier" -verify-release "$work" -release-version "$version" || die 'release signature or metadata rejected; nothing was installed'
else
	public_key=RWQZfr8pZOLhNx/81iyyYi91cZMQTyJece9fX9OWIJoUqMPpN7eCYk/+
	digest=$(sha256sum "$work/SHA256SUMS" | awk '{print $1}')
	comment=$(sed -n '3s/^trusted comment: //p' "$work/SHA256SUMS.minisig")
	pattern=$(printf 'timestamp:[1-9][0-9]*\tfile:release:v%s:SHA256SUMS\tsha256:%s' "$(printf '%s' "$version" | sed 's/\./[.]/g')" "$digest")
	printf '%s\n' "$comment" | grep -Ex "$pattern" >/dev/null || die 'release signature role or digest rejected'
	if command -v openssl >/dev/null 2>&1; then
		# Only framing is decoded here; OpenSSL verifies both Ed25519 signatures.
		printf '%s' "$public_key" | openssl base64 -d -A >"$work/key.raw"
		sed -n '2p' "$work/SHA256SUMS.minisig" | openssl base64 -d -A >"$work/signature.raw"
		[ "$(wc -c <"$work/signature.raw")" -eq 74 ] || die 'invalid signature envelope'
		dd if="$work/key.raw" bs=1 skip=2 count=8 of="$work/key.id" 2>/dev/null
		dd if="$work/signature.raw" bs=1 skip=2 count=8 of="$work/signature.id" 2>/dev/null
		cmp -s "$work/key.id" "$work/signature.id" || die 'untrusted release key'
		{ printf '\060\052\060\005\006\003\053\145\160\003\041\000'; dd if="$work/key.raw" bs=1 skip=10 count=32 2>/dev/null; } >"$work/key.der"
		dd if="$work/signature.raw" bs=1 skip=10 count=64 of="$work/signature" 2>/dev/null
		algorithm=$(head -c 2 "$work/signature.raw")
		case "$algorithm" in
		Ed) input="$work/SHA256SUMS" ;;
		ED) openssl dgst -blake2b512 -binary -out "$work/prehash" "$work/SHA256SUMS"; input="$work/prehash" ;;
		*) die 'unsupported signature algorithm' ;;
		esac
		openssl pkeyutl -verify -pubin -keyform DER -inkey "$work/key.der" -rawin -in "$input" -sigfile "$work/signature" >/dev/null || die 'release signature rejected'
		{ cat "$work/signature"; printf '%s' "$comment"; } >"$work/comment"
		sed -n '4p' "$work/SHA256SUMS.minisig" | openssl base64 -d -A >"$work/comment.sig"
		openssl pkeyutl -verify -pubin -keyform DER -inkey "$work/key.der" -rawin -in "$work/comment" -sigfile "$work/comment.sig" >/dev/null || die 'release comment signature rejected'
	elif command -v minisign >/dev/null 2>&1; then
		minisign -Vm "$work/SHA256SUMS" -P "$public_key" || die 'release signature rejected'
	else
		say 'sora: first installation trusts HTTPS and checksums; install OpenSSL 3 or minisign first for independent package signature verification'
	fi
	(cd "$work" && awk '$2 == "release.json" {print; n++} END {if (n != 1) exit 1}' SHA256SUMS >metadata.expected && sha256sum -c --quiet metadata.expected) || die 'release metadata checksum rejected'
fi
for name in $files; do
	if [ -n "$verifier" ]; then
		size=$("$verifier" -verify-release "$work" -release-version "$version" -release-artifact "$name" -release-target "linux/$deb_arch") || die 'artifact metadata rejected'
	else
		# The authenticated table binds the package; bootstrap has a fixed ceiling.
		size=2147483648
	fi
	case "$size" in '' | *[!0-9]*) die 'invalid verifier size response' ;; esac
	if [ "${#size}" -gt 10 ] || [ "$size" -lt 1 ] || [ "$size" -gt 2147483648 ]; then die 'invalid verifier size response'; fi
	fetch "$name" "$size"
	if [ -n "$verifier" ] && [ "$(wc -c <"$work/$name")" -ne "$size" ]; then die 'signed package size mismatch'; fi
done

(
	cd "$work"
	for name in $files; do
		awk -v name="$name" 'length($1) == 64 && $1 !~ /[^0-9a-fA-F]/ && (substr($0, 67) == name || substr($0, 67) == "*" name) {print tolower($1) "  " name; count++} END {if (count != 1) exit 1}' SHA256SUMS >>expected || die "$name needs exactly one checksum"
	done
	sha256sum -c --quiet expected || die "a download does not match SHA256SUMS; nothing was installed"
)

set --
for name in $files; do
	set -- "$@" "$work/$name"
done
case "$manager" in
apt) $as_root apt-get install -y "$@" ;;
dnf) $as_root dnf install -y "$@" ;;
zypper) $as_root zypper --non-interactive install --allow-unsigned-rpm "$@" ;;
pacman)
	# Unlike apt/dnf, pacman -U does not fetch missing repository dependencies.
    deps="nftables iproute2 polkit libnetfilter_queue zlib gtk3 webkit2gtk-4.1 gst-plugins-good"
	# shellcheck disable=SC2086
	$as_root pacman -S --noconfirm --needed $deps
	$as_root pacman -U --noconfirm --needed "$@"
	;;
esac

say "sora: installed. The core runs as the sora-core service; open Sora from the applications menu."
