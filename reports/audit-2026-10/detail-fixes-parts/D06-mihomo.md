# D6 — core/engine/mihomo (commit 94f9e30)

## rule-providers: формат по URL — дыры, исправлены
- Было: секция генерилась (ffdf453), но формат определялся наивным HasSuffix по полному URL: URL с query (`ads.mrs?v=2`) падал в `format: text` — mihomo парсил бинарник как текст и падал на старте; `.srs` (sing-box binary) тоже маппился в text — тихая битая фича (mihomo читает только yaml/text/mrs).
- Стало: registerRuleProvider парсит URL через net/url, расширение из пути без query/fragment, регистронезависимо; `.srs` отклоняется на рендере с понятной ошибкой.
- Эффект: битый конфиг не доезжает до движка. Тесты TestBuildRulesStripsQueryFromRuleSetFormat / TestBuildRulesRejectsSingBoxBinaryRuleSet — PASS.

## Hysteria2 up/down
- Было/стало: уже закрыто 27a1d77 (up/down в buildProxy, ноль → ключ опущен). Добавлен негативный тест TestRenderHysteria2OmitsZeroBandwidth — PASS.

## Наблюдения (не чинены)
1. Врущий валидатор: engine/fields.go Tun.validate() отвергает MTU > 1500, а оба рендера используют 9000 как дефолт. План с явным MTU=9000 отвергается, хотя рендер ставит его сам. → передано D7.
2. Тихий фолбэк 223.5.5.5 (AliDNS), когда DNS включён без резолверов — историческое поведение; sing-box фолбэкается на local, xray — localhost. Менять на ошибку — продуктовое решение → на суд владельца.
