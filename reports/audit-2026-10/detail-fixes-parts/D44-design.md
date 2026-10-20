# D44 — app/lib/src/design + theme (commit 9e0f89d)

## Контраст danger — провал WCAG AA, исправлен
- Было: light danger 0xFFE5332A на фоне — 3.99 (< 4.5); белый на danger-кнопке — 4.34; тёмный danger на raised — 4.33.
- Стало: light danger → 0xFFD02A22 (4.78–5.20); dark danger → 0xFFFF5D52 (4.61–6.50, осветлён — на mid-gray контраст растёт с яркостью).
- Эффект: все пары danger/текст ≥ 4.5 в обеих темах.

## Новый токен Palette.onDanger
- Было: destructive-кнопка — захардкоженный Colors.white; в тёмной теме 3.22.
- Стало: onDanger (light белый / dark чёрный), чёрный на тёмном danger — 6.52. Участвует в lerp.
- Эффект: убит хардкод, лейбл везде проходит AA.

## Семантические стили ошибок
- Было: 5 мест — инлайн `copyWith(color: palette.danger)`.
- Стало: Styles.dangerCaption/dangerSecondary/dangerStrong; все 5 мест переведены. Сырых красных в текстах не осталось.
- Эффект: единый источник error-стилей.

## Хардкоды → токены
- tour.dart: const Color(0xB3000000) в _Cutout (врал в тёмной теме) → Palette.scrim.
- menuTheme.shadowColor с ветвлением → palette.shadow.
- Эффект: тёмная тема больше не врёт.

## Попутно
- Починен висячий референс Styles.dangerCaption из параллельного коммита 0521ffb (addserver.dart).
- Осознанно оставлено: Colors.transparent, белый под QR (сканируемость), мёртвый overlayColor при opacity 0.
