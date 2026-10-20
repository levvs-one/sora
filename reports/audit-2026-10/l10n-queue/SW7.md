# l10n queue — SW7: custom servers (AddServerScreen + servers section)

New `S` keys referenced by `app/lib/src/ui/addserver.dart` and
`app/lib/src/ui/servers.dart`. English is the source; Russian translations
provided. Placeholders use the ARB `{name}` convention with types noted.

Revision note (swarm-review): the Dart stubs were realigned to the actual
`proto/sora/custom/v1/custom.proto` — `CustomServer.credentials` is a single
write-only string (no username/password split), the protocol is the
`CustomProtocol` enum (vless/vmess/trojan/shadowsocks/wireguard only), and
`TestCustomServer` tests only a saved server by id. The add form therefore has
no pre-save "Test" button: reachability is tested from the server row in the
list after saving. Keys `customServerUsername`, `customServerPassword`,
`customServerTestOk`, `customServerUnreachable` were dropped as unused.

| Key | en | ru | Notes |
|---|---|---|---|
| `customServerAdd` | Add custom server | Добавить свой сервер | Screen title, buttons |
| `customServers` | My servers | Мои серверы | Section title on the servers screen |
| `customServerBadge` | custom | свой | Pill badge on user-added server rows |
| `customServerName` | Name | Название | Field label |
| `customServerNameHint` | E.g. My VPS | Например: мой VPS | Field hint |
| `customServerProtocol` | Protocol | Протокол | Dropdown label |
| `customServerAddress` | Address | Адрес | Field label |
| `customServerAddressHint` | example.com or 192.0.2.1 | example.com или 192.0.2.1 | Field hint |
| `customServerPort` | Port | Порт | Field label |
| `customServerPortHint` | 443 | 443 | Field hint |
| `customServerCredentials` | Credentials | Данные для входа | Label of the single write-only secret field (UUID, password, key, ...) |
| `customServerOptional` | Optional | Необязательно | Caption next to optional field labels |
| `customServerTest` | Test | Проверить | Tooltip on the per-row test button (tests the saved server by id) |
| `customServerShowSecret` | Show secret | Показать секрет | Tooltip on the reveal icon |
| `customServerHideSecret` | Hide secret | Скрыть секрет | Tooltip on the hide icon |
| `customServerNameRequired` | Enter a name | Введите название | Validation |
| `customServerAddressRequired` | Enter the server address | Введите адрес сервера | Validation |
| `customServerAddressInvalid` | Invalid address | Некорректный адрес | Validation |
| `customServerPortInvalid` | Port must be a number from 1 to 65535 | Порт — число от 1 до 65535 | Validation |
| `customServerDeleteConfirm` | Delete server “{name}”? | Удалить сервер «{name}»? | `{name}`: String — confirm dialog question |
| `customServerEmptyHint` | Add a server manually: address, port and protocol | Добавьте сервер вручную: адрес, порт и протокол | Empty-state detail under the add tile |

ARB snippets (en):

```json
"customServerDeleteConfirm": "Delete server “{name}?”",
"@customServerDeleteConfirm": { "placeholders": { "name": { "type": "String" } } },
```

ARB snippets (ru):

```json
"customServerDeleteConfirm": "Удалить сервер «{name}»?",
"@customServerDeleteConfirm": { "placeholders": { "name": { "type": "String" } } },
```
