# D23 — packaging/scripts (commit 8d1b8aa, 8 файлов)

## Проверено, менять не нужно
- packaging/linux/sora-update: set -eu, die, TOCTOU-защита symlink-race, semver-валидатор, downgrade-защита. Идемпотентен.
- packaging/engines/fetch.sh: digest-чек каждого файла, fail-closed на подпись (engines.sig).
- packaging/zapret/build.sh: scratch-копия, install поверх. Digest tpws/nfqws не нужен (core проверяет только движки из engines.digests).
- Версии нигде не захардкожены (env/redirect/engines.lock); имена файлов согласованы.

## Правки
1. packaging/install/install.ps1: latest брался через GitHub API (rate-limit для анонимных) → чтение redirect …/releases/latest через BaseResponse.ResponseUri, как в install.sh. Эффект: установка не падает от 403; единая логика.
2. packaging/install/install.sh: `latest=$(curl …)` без проверки → `|| die "could not reach …"`. Эффект: понятная ошибка вместо молчаливого выхода.
3. packaging/linux/scripts/preremove.sh / postremove.sh: не было set -e → set -eu. Эффект: ошибки не глотаются.
4. packaging/linux/scripts/postinstall.sh: set -e → set -eu. Консистентность.
5. postremove.sh: отступ 4 пробела → таб (косметика, единственный неоднородный).
6. packaging/engines/fetch.sh: usage-комментарий перечислял только 2 арх. → все четыре.
7. app/test/fixtures/releases/install.sh: repo=…/sora-client (старое имя) → levvs-one/sora; хэш SHA256SUMS пересчитан, sha256sum -c проходит.

Все sh прошли sh -n/bash -n; ps1 проверен вручную (тулчейна нет).
