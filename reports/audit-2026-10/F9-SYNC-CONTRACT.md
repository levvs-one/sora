# F9: контракт «приложение ↔ демон service/sync» (2026-10-20)

Канонический документ для роя. Источник правды по wire-формату — Go-пакет
`service/sync/pairing` (`Encode`/`Decode`); по HTTP API — `service/sync/api/http.go`.
Dart-сторона обязана реализовать парсер с побайтово идентичной валидацией.

## 1. QR payload пэйринга (канонический формат, версия 1)

```
sora-sync://pair?v=1&id=<deviceID>&pub=<base64url>&token=<base64url>&port=<int>
```

- `v=1` — версия формата. Другое значение → reject.
- `id` — device ID приглашающей стороны, 1..128 символов, обязателен.
- `pub` — эфемерный X25519 public key приглашающей стороны, ровно 32 байта,
  base64 **RawURLEncoding** (без паддинга). Другое → reject.
- `token` — rendezvous token, ровно 16 байт, base64 RawURLEncoding без паддинга.
- `port` — TCP-порт pairing-listener'а приглашающей стороны, 1..65535.
- Схема строго `sora-sync`, host строго `pair`. Лишние query-параметры игнорируются.
- Фрагмент (`#...`, даже пустой) → reject: каноническая форма его не содержит.
- Дублирующиеся query-ключи → reject: Go берёт первое значение, Dart
  (`Uri.queryParameters`) — последнее, стороны разошлись бы в ключе/токене.

**Единственный генератор QR — демон**: `POST /v1/pairing/start` → `{"qr_payload": "...", "expires_at": unix}`.
Dart НЕ генерирует ключи и НЕ собирает payload вручную (в Dart нет X25519 —
выдумывать key material запрещено). Сканирующая сторона: валидирует формат
локально (тем же правилом), затем передаёт **сырую строку** демону:
`POST /v1/pairing/join {"qr_payload": "<raw>"}` → `{"peer": {...}}`.
Демон декодирует через `pairing.Decode` (каноника), ищет пира по mDNS,
выполняет Noise_XX handshake, сверяет rendezvous token.

Тест-векторы (фиксированные, для кросс-проверки Dart; побайтово каноничны —
проверены `TestVectorT1Decodes`/`TestVectorsReject` в `pairing/pairing_test.go`).
Key material — байты 0..31 (pub) и 0..15 (token), base64url без паддинга.

- T1 (decode OK, re-encode даёт ту же строку):
  `sora-sync://pair?id=device-a&port=12345&pub=AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8&token=AAECAwQFBgcICQoLDA0ODw&v=1`
  → `id="device-a"`, `port=12345`, `pub[i]=i` (32 байта), `token[i]=i` (16 байт).
- Негативные (все → reject):
  - неверная схема: `http://pair?id=...&v=1` (и неверный host: `sora-sync://join?...`);
  - `v=2` и отсутствующий `v`;
  - `pub` 31 байт: `pub=AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHg` (42 символа);
  - `pub` не base64; `token` с паддингом (`...Dw==` — RawURLEncoding паддинг запрещает);
  - `token` 15 байт: `token=AAECAwQFBgcICQoLDA0O` (20 символов);
  - `port=0`, `port=65536`, `port=abc`;
  - пустой `id` (`id=`) и отсутствующий `id`.

## 2. Запуск и управление демоном (контракт для приложения)

Бинарь: `sora-sync` (рядом с `sora-core`: `/usr/bin/sora-sync` на Linux из
пакета, в каталоге приложения на Windows; Android — см. п.5).

CLI: `sora-sync --data-dir <user-data-dir>`.
Демон при старте:
- создаёт/читает `<dataDir>/api_token` (0600, bearer token, генерируется при первом запуске);
- слушает `127.0.0.1:0`, пишет `<dataDir>/http_addr` (`"127.0.0.1:PORT\n"`, 0600);
- печатает `device <id> (<name>) ready at <addr>`;
- завершается по SIGINT/SIGTERM (graceful shutdown).

Приложение:
1. Резолвит путь бинаря по платформе. Бинаря нет → экран показывает честное
   «синхронизация недоступна на этом устройстве», никакого театра.
2. Генерирует data dir пользователя (рядом с настройками приложения).
3. `Process.start(binary, ['--data-dir', dir])`; ждёт появления `http_addr`
   (таймаут ~10с); читает `api_token`; `GET /v1/status` с
   `Authorization: Bearer <token>` как health-check.
4. Завершает процесс при выходе приложения (SIGTERM → ждать → SIGKILL).
5. Один инстанс на data dir (lock-файл или проверка: если `http_addr` свежий
   и `/v1/status` отвечает — переиспользовать, а не спавнить второй).

## 3. HTTP API (localhost, Bearer token обязателен везде)

| Метод | Путь | Тело → ответ |
|---|---|---|
| GET | /v1/status | → `{"device_id","device_name","pairing_active","pairing_expires_at","peers"}` |
| POST | /v1/pairing/start | → `{"qr_payload","expires_at"}` (409 если сессия уже открыта) |
| POST | /v1/pairing/stop | → `{"ok":true}` |
| POST | /v1/pairing/join | `{"qr_payload"}` → `{"peer":{...}}` |
| GET | /v1/peers | → `{"peers":[{id,name,identity_key,paired_at,last_sync}]}` |
| DELETE | /v1/peers/{id} | revoke |
| POST | /v1/peers/{id}/sync | принудительная синхронизация документов |
| PUT/GET | /v1/documents/{kind}/{name}, GET /v1/documents | документы |

Ошибки: JSON `{"error": "..."}` с HTTP-статусом (см. `writeError`).

## 4. Честность E2E (обязательно)

- Источник правды о пирах — **демон** (`GET /v1/peers`). Локальный реестр
  приложения — только кэш, явно помеченный; «paired» показывается только
  после успешного `Join` (peer вернулся от демона).
- Секреты (подписки, пароли) — только внутри Noise_XX-канала демона.
  Демон никому не отправляет ничего, кроме paired-пиров по Noise_XX.
- Экран показывает реальные состояния: демон не запущен / запускается /
  pairing-сессия активна (TTL) / пиры / last_sync от демона / ошибки текстом.
- Что обещает экран («what syncs»: подписки, правила, настройки) — должно
  реально синхронизироваться через `sync` пакет демона. Если какой-то kind
  документов нельзя синхронизировать честно — убрать из UI, а не имитировать.

## 5. Платформенная честность

- Desktop (Linux/Windows): полный флоу через спавн бинаря.
- Android: Go-биnарь как child-процесс недоступен. Честное поведение —
  экран сообщает о недоступности (или альтернатива, которую Go-агент
  докажет рабочей, а не имитацией). Театр запрещён.
