#!/bin/sh
# Installs Sora on Linux in one command:
#
#   curl -fsSL https://github.com/levvs-one/sora/releases/latest/download/install.sh | sh
#
# It finds the latest release, downloads the packages for this distribution
# and processor, verifies the release signature on SHA256SUMS (minisign),
# checks the packages against the signed SHA256SUMS and installs
# them with the system's package manager, so updates and removal stay the
# package manager's too. Nothing is installed when the signature or a
# checksum does not match.
#
# SORA_VERSION=1.0.3 installs that release instead of the latest.
# SORA_DIST=<directory> installs packages already in that directory, with
# their SHA256SUMS and SHA256SUMS.minisig; CI checks the packages it built
# this way (CI must provide a .minisig made with its test key, or set
# SORA_MINISIGN_PUBKEY to that test key).
# SORA_MINISIGN_PUBKEY=<base64> overrides the embedded release public key
# (useful for CI self-tests with an ephemeral key).
set -eu

repo=https://github.com/levvs-one/sora

# --- Release signature trust anchor (SORA-H1) ---
# Minisign public key of the release signer, embedded at release time.
# PLACEHOLDER: the owner must run the key ceremony (see
# FIX-PLAN.md section 9, "Key ceremony") and replace this value with the
# real release public key. Until then installation refuses to proceed
# (fail-closed) instead of pretending the downloads are authentic.
SORA_RELEASE_PUBKEY=${SORA_MINISIGN_PUBKEY:-REPLACE-ME-AFTER-KEY-CEREMONY}

say() { printf '%s\n' "$*"; }
die() {
	printf 'sora: %s\n' "$*" >&2
	exit 1
}

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

fetch() { curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --connect-timeout 20 --max-time 600 -o "$2" "$1"; }

# Verifies the minisign signature of $1 (signed file) using $2 (signature
# file) and the embedded release public key. Dies on any failure:
# a missing key, a missing minisign binary, or a bad signature all abort
# the installation instead of silently skipping authentication (SORA-H1).
verify_signature() {
	_signed=$1 _sig=$2
	case "$SORA_RELEASE_PUBKEY" in
	'' | REPLACE-ME-AFTER-KEY-CEREMONY)
		die 'release signing is not configured yet: the minisign public key is still a placeholder. The owner must complete the key ceremony (FIX-PLAN.md, section 9) before releases can be installed.'
		;;
	esac
	command -v minisign >/dev/null 2>&1 || die 'minisign is required to verify the release signature but was not found in PATH'
	printf 'untrusted comment: sora release signing key\n%s\n' "$SORA_RELEASE_PUBKEY" >"$work/release.pub"
	chmod 600 "$work/release.pub"
	minisign -V -q -p "$work/release.pub" -m "$_signed" -x "$_sig" \
		|| die "signature verification failed for ${_signed##*/}; nothing was installed"
	say "sora: release signature verified"
}

if [ -n "${SORA_DIST:-}" ]; then
	version=${SORA_VERSION:?SORA_VERSION is needed with SORA_DIST}
else
	if [ -z "${SORA_VERSION:-}" ]; then
		# The latest release redirects to its tag; no API call, no rate limit.
		latest=$(curl -fsSLI --proto '=https' --retry 3 --connect-timeout 20 --max-time 60 -o /dev/null -w '%{url_effective}' "$repo/releases/latest") \
			|| die "could not reach $repo/releases/latest"
		version=${latest##*/v}
		case "$version" in
		[0-9]*.[0-9]*.[0-9]*) ;;
		*) die "could not tell the latest release from $latest" ;;
		esac
	else
		version=$SORA_VERSION
	fi
fi

# A version from the environment is trusted no further than the redirect
# above: it still has to look like a release before it becomes file names.
# The first pattern rejects anything outside the version alphabet outright;
# the second keeps the dotted-numeric shape the file names assume.
case "$version" in
*[!0-9A-Za-z.~+-]* | [!0-9]* | *[!0-9A-Za-z])
	die "SORA_VERSION='$version' is not a release version"
	;;
[0-9]*.[0-9]*.[0-9]*) ;;
*) die "SORA_VERSION='$version' is not a release version" ;;
esac

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
for name in SHA256SUMS SHA256SUMS.minisig $files; do
	if [ -n "${SORA_DIST:-}" ]; then
		cp "$SORA_DIST/$name" "$work/$name" || die "$name is not in $SORA_DIST"
	else
		fetch "$repo/releases/download/v$version/$name" "$work/$name" || die "could not download $name"
	fi
done

# Authenticate the checksum manifest BEFORE trusting any hash in it.
verify_signature "$work/SHA256SUMS" "$work/SHA256SUMS.minisig"

(
	cd "$work"
	for name in $files; do
		# Accept both sha256sum layouts: text mode ("<hash>  <name>") and
		# binary mode ("<hash> *<name>"), like every other SHA256SUMS reader
		# in the tree (the Dart updater, sora-update, install.ps1). The old
		# pattern demanded two spaces before the optional "*", so a
		# binary-mode manifest was rejected here alone.
		grep -E " [ *]$name\$" SHA256SUMS >>expected || die "$name is not in SHA256SUMS"
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
# The packages' integrity is established by the signed SHA256SUMS above;
# do not weaken the chain by telling the package manager to skip its
# own signature check (SORA-H1).
zypper) $as_root zypper --non-interactive install "$@" ;;
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
