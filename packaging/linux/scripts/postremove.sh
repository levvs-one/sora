#!/bin/sh
set -eu
# The core removes its nftables table when it stops; a core that was killed
# could not, so the table is removed here as well. Nothing else of the system
# was changed by the package.
case "${1:-remove}" in
upgrade | 1) exit 0 ;;
esac
nft delete table inet sora 2>/dev/null || true
# The nfqws interceptor's table (core/engine/bypass: nftTable "sora_nfqws")
# gets the same treatment: a killed core could not remove it, and its rules
# would keep steering traffic into queues with no listener behind them.
nft delete table inet sora_nfqws 2>/dev/null || true
# Purge removes the secret store, the control token, and engine state:
# secrets must not survive uninstallation (SORA-L7). A plain remove keeps
# them so reinstalling does not lose subscriptions.
if [ "${1:-remove}" = purge ]; then
	rm -rf /var/lib/sora
fi
if [ -d /run/systemd/system ]; then
	systemctl daemon-reload
fi
