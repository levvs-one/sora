#!/bin/sh
# Run a previously authenticated copy, never a downloaded script pipe.
# SORA_VERIFIER names a previously trusted core, default /usr/bin/sora-core.
# Neither a downloaded script nor a downloaded verifier authenticates itself.
# Signature verification precedes package download and package-manager calls.
#
# SORA_VERSION=1.0.3 installs that release instead of the latest.
# SORA_DIST=<directory> installs packages already in that directory, with
# signed SHA256SUMS; CI uses an isolated verifier with a temporary test key.
set -eu

repo=https://github.com/levvs-one/sora

say() { printf '%s\n' "$*"; }
die() {
	printf 'sora: %s\n' "$*" >&2
	exit 1
}

verifier=${SORA_VERIFIER:-/usr/bin/sora-core}
case "$verifier" in /*) ;; *) die 'SORA_VERIFIER must be an absolute path to a previously trusted core' ;; esac
verifier=$(readlink -f -- "$verifier") || die 'could not resolve the trusted verifier'
[ -f "$verifier" ] && [ -x "$verifier" ] || die 'a previously authenticated sora-core verifier is required; see docs/security/release-signatures.md'
if [ -n "${SORA_DIST:-}" ]; then
	distribution=$(cd "$SORA_DIST" && pwd -P)
	case "$verifier" in "$distribution"/*) die 'do not trust a verifier supplied with the downloads' ;; esac
fi

case "$(uname -m)" in
x86_64 | amd64) deb_arch=amd64 rpm_arch=x86_64 arch_arch=x86_64 with_app=yes ;;
aarch64 | arm64) deb_arch=arm64 rpm_arch=aarch64 arch_arch=aarch64 with_app=no ;;
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

fetch() { curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"; }

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
if [ "$with_app" = yes ]; then
	files="$files $app"
else
	say "sora: this processor gets the core only; the app is built for x86_64"
fi

say "sora: installing $version with $manager"
verified=no
for name in SHA256SUMS SHA256SUMS.minisig $files; do
	case "$name" in
	SHA256SUMS | SHA256SUMS.minisig) ;;
	*) if [ "$verified" = no ]; then
		"$verifier" -verify-release "$work" -release-version "$version" || die 'release signature rejected; nothing was installed'
		verified=yes
	fi ;;
	esac
	if [ -n "${SORA_DIST:-}" ]; then
		cp "$SORA_DIST/$name" "$work/$name" || die "$name is not in $SORA_DIST"
	else
		fetch "$repo/releases/download/v$version/$name" "$work/$name" || die "could not download $name"
	fi
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
	deps="nftables iproute2 polkit libnetfilter_queue zlib"
	if [ "$with_app" = yes ]; then deps="$deps gtk3 webkit2gtk-4.1 gst-plugins-good"; fi
	# shellcheck disable=SC2086
	$as_root pacman -S --noconfirm --needed $deps
	$as_root pacman -U --noconfirm --needed "$@"
	;;
esac

say "sora: installed. The core runs as the sora-core service; open Sora from the applications menu."
