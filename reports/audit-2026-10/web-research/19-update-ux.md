# 19. UX обновлений десктоп-приложений (Sparkle и др.)

Дата: 2026-10-19. Метод: 8 веб-запросов (browser.search) + официальная документация Sparkle, приоритет источникам 2025–2026.
Контекст sora: уже есть автообновление с проверкой SHA256 (приложение + служба `sora-core`), Windows 10 1809+/11 x64, Linux x64 (deb/rpm/Arch). Сервис работает с правами LocalSystem/`sora` — обновление затрагивает привилегированный компонент.

## 1. Что нашёл

### 1.1. macOS: Sparkle 2 — эталон вне App Store
- Золотой стандарт для приложений вне Mac App Store: фоновые проверки, установка при выходе, диалог с changelog. ([инди-плейбук 2026](https://erseltrhn.medium.com/shipping-a-notarized-sparkle-updated-macos-app-in-2026-the-indie-playbook-5df44d4cdda9), [обзор публикации в 2026](https://forasoft.medium.com/how-to-publish-desktop-apps-on-macos-in-2026-electron-notarization-beyond-0f680c91bff9))
- Безопасность: EdDSA (ed25519) подписи каждого архива (`SUPublicEDKey` в Info.plist, приватный ключ в кейчейне, вне сервера раздач); опционально **подписанный appcast-фид** (`SURequireSignedFeed` + `SUVerifyUpdateBeforeExtraction`) — защищает и от подмены релиз-ноутов; ротация ключей поддерживается. ([документация Sparkle](https://sparkle-project.org/documentation/))
- **Delta-обновления из коробки**: `generate_appcast` автоматически генерирует `*.delta`-патчи между версиями (bsdiff-ядро, формат v4 в Sparkle 2.7, lzma); при неуспехе патча — автоматический fallback на полный архив. ([документация по дельтам](https://sparkle-project.org/documentation/delta-updates/))
- **Phased rollout**: нативная поддержка поэтапного раскатывания через appcast; Atlassian опенсорснул свой инструмент постепенных релизов для SourceTree поверх Sparkle+fastlane. ([GitHub Sparkle](https://github.com/sparkle-project/Sparkle), [Atlassian](https://www.atlassian.com/blog/sourcetree/open-source-announcement-phased-releases-for-sparkle-based-macos-apps))
- Каналы (stable/beta), пометки critical/major, atomic-safe установка. Урок инди-разработчиков 2026: автоматизировать релизный скрипт рано, хранить приватный ключ вне досягаемости, тестировать обновление на чистой VM. ([инди-плейбук 2026](https://erseltrhn.medium.com/shipping-a-notarized-sparkle-updated-macos-app-in-2026-the-indie-playbook-5df44d4cdda9))

### 1.2. Windows: Squirrel / WinSparkle / свой апдейтер
- **Squirrel.Windows**: установка в `%LocalAppData%`, `Update.exe` управляет жизненным циклом, версионные папки `app-{version}`, `RELEASES`-манифест на сервере, **delta-пакеты** (`-delta.nupkg`), события `--squirrel-install/--squirrel-updated/--squirrel-obsolete` (15 секунд на обработчик, синхронно, без UI). ([обзор Squirrel](https://deepwiki.com/electron/windows-installer/4.1-squirrel.windows-overview), [что такое Squirrel](https://www.advancedinstaller.com/what-is-squirrel-framework.html))
- **WinSparkle** — порт Sparkle под Windows, но по сути лишь скачивает установщик (пользователь всё равно кликает мастер), без 64-битной истории в старых версиях — для VPN-клиента с привилегированным сервисом это слабый вариант. ([обсуждение](https://sublimetext.userecho.com/communities/1/topics/2158-automatic-updates-on-windows-using-winsparkle))
- Для системного сервиса (как `sora-core` под LocalSystem) ни MSIX/Store, ни Squirrel в user-контексте не подходят: нужен собственный установщик с **одной эскалацией UAC** и транзакционной заменой файлов сервиса (переименовать → заменить → перезапустить службу → проверить, что встала).

### 1.3. Linux: не бороться с пакетным менеджером
- Консенсус 2025–2026: нативные пакеты (apt/dnf/pacman) — самый быстрый и доверенный путь; Flatpak — OSTree-дельты из коробки, обновления через `flatpak update`; Snap — автообновления 4 раза в день (контролируемые); AppImage — только ручная замена (AppImageUpdate с дельтами всё ещё alpha). ([сравнение форматов](https://hamradio.my/why-linux-users-avoid-flatpak/), [гайд AppImage 2026](https://www.fosslinux.com/111271/the-ultimate-guide-to-appimage-management-on-linux.htm), [Flatpak/Flathub 2026](https://www.fosslinux.com/157752/flathub-flatpak-complete-guide.htm))
- Антипаттерн: in-app самозамена бинарников, установленных через deb/rpm — конфликт с пакетным менеджером, сломанные зависимости, гнев пользователей. Правильно: **определять источник установки** и адаптироваться (deb/rpm → уведомлять и делегировать менеджеру пакетов; portable/tarball → собственный апдейтер с дельтами).

### 1.4. Delta-обновления: техника
- Chrome: Courgette/Zucchini (дизассемблирование PE/ELF → bsdiff) сжимает патч с ~6.7% до ~0.76% размера; позволило докатить обновления до 100% пользователей за <10 дней. Play Store использует bsdiff для APK с 2016 года; zsync — блочные дельты через .zsync-метафайл. ([Wikipedia](https://en.wikipedia.org/wiki/Delta_update), [Deltas diffed](https://www.hydraulic.dev/blog/20-deltas-diffed.html))
- Практичный минимум без дизассемблирования: генерировать bsdiff/xdelta3-патчи от N−1 и N−2 к N на сервере, клиент скачивает подходящий, иначе — полный архив. Дельты критичны там, где трафик дорог/медленен — т.е. ровно у аудитории VPN-клиента в цензурируемых регионах.

### 1.5. Staged rollout: страховка от плохого релиза
- Стандарт: 1% → 10% → 50% → 100%, пауза/откат при регрессии крашей. Для десктопа без сторов — когортность на клиенте (хеш install-ID) или серверный гейтинг манифеста; автопауза по телеметрии крашей. ([сравнение staged vs full](https://capgo.app/blog/staged-rollouts-vs-full-releases-comparison/), [UXCam 2026](https://uxcam.com/blog/app-versioning-best-practices/?ref=blog.arfadia.com))
- Для VPN-клиента это важнее, чем для обычного приложения: битый релиз ломает пользователям **сам инструмент доступа в интернет**, которым они скачали бы фикс.

### 1.6. UX: тихие vs явные, changelog, откат
- Консенсус: фоновые проверки + фоновая загрузка + установка при выходе/перезапуске; явный диалог — только для major/critical с **конкретным changelog** («исправлен краш при…», а не «улучшения стабильности»); пункт «Проверить обновления»; не прерывать активную сессию. Принудительное обновление — только для критических security-патчей. ([UXCam 2026](https://uxcam.com/blog/app-versioning-best-practices/?ref=blog.arfadia.com), [практики обновлений](https://blog.truegeometry.com/api/exploreHTML/545eb5f8cbe832846405fa738bdd91b.exploreHTML))
- Откат: держать предыдущую версию; автооткат при провале health-check новой версии; ручная кнопка «Вернуться к предыдущей версии». ([гайд по стабильности](https://windowsforum.com/threads/windows-updates-rollbacks-and-stability-practical-guidance.397304/), [чек-лист обновлений](https://hackmd.io/@u7K5BBHBSLetIvzt0MF2Pg/how-to-update-software-without-breaking-anything-a-practical-checklist))
- Уважение к лимитным соединениям: опция «качать обновления только по безлимитному соединению»; офлайн-установщики полных пакетов. ([практики](https://blog.truegeometry.com/api/exploreHTML/545eb5f8cbe832846405fa738bdd91b.exploreHTML))

## 2. Что sora должен перенять

| # | Рекомендация | Почему | Эффект | Сложность |
|---|---|---|---|---|
| 1 | **Асимметричные подписи (Ed25519/minisign) манифеста и артефактов вместо/поверх SHA256**; публичный ключ зашит в приложение; план ротации ключей | SHA256 проверяет целостность, но не аутентичность: скомпрометированный сервер раздаст вредоносный бинарник с «правильным» SHA256. У sora уже запланирован minisign для расширений — сделать единую историю подписей для обновлений и `.soraext` | high | S |
| 2 | **Подписанный манифест обновлений** (аналог `SURequireSignedFeed`): подпись покрывает версии, хеши и release notes | Закрывает подмену метаданных обновления при компрометации CDN/зеркала | high | S |
| 3 | **Staged rollout 1% → 10% → 50% → 100% с автопаузой по телеметрии** (когорта = хеш install-ID; серверный гейтинг манифеста) | Битый релиз VPN-клиента = пользователи без интернета и без способа скачать фикс. Это главная страховка | high | M |
| 4 | **Атомарная установка + автооткат**: хранить N−1, health-check новой версии при первом запуске (ядро стартует? туннель поднимается?), при провале — откат и репорт | Прямое следствие №3 на клиенте; у Squirrel/Sparkle это встроено, у sora надо сделать руками | high | M |
| 5 | **Не разрывать активную VPN-сессию**: загрузка в фоне, установка при выходе/по подтверждению; обновление службы `sora-core` — одна UAC-эскалация, транзакционная замена, проверка рестарта службы | Обновление не должно ронять туннель посреди работы; сломанная служба под LocalSystem = переустановка вручную | high | M |
| 6 | **Delta-обновления** (bsdiff/xdelta3 от N−1/N−2, fallback на полный пакет) | Аудитория в цензурируемых регионах часто на медленном/дорогом трафике; бинарники Flutter+Go немаленькие | medium | M |
| 7 | **Каналы stable/beta(/nightly)** с opt-in в настройках | Борьба с DPI требует быстрых итераций; энтузиасты возьмут beta и дадут фидбек до stable-раскатки; питает staged rollout | medium | S |
| 8 | **Экран «Что нового» с конкретным changelog из подписанного манифеста** (не «улучшения и исправления») | Доверие + меньше «а зачем обновляться»; у Sparkle это `description` в appcast | medium | S |
| 9 | **Linux: определять источник установки** (deb/rpm → делегировать пакетному менеджеру, уведомлять; portable → свой апдейтер) | Самозамена файлов из deb/rpm — конфликт с менеджером пакетов и путь к сломанным установкам | high | S |
| 10 | **«Вернуться к предыдущей версии» в настройках** (ручной откат в один клик) | Дешёвая страховка поверх автоотката; пользователи прощают баги, когда есть кнопка «назад» | medium | S |
| 11 | **Update-over-VPN fallback**: если сервер обновлений недоступен напрямую (DPI), качать через собственный туннель sora | В цензурируемых регионах сам апдейт-сервер могут блочить; конкуренты так не делают — дифференциатор | medium | M |
| 12 | **Уважение к лимитным соединениям** + явный пункт «Проверить обновления» + фоновая проверка раз в сутки с backoff | Гигиена; 2026-й год, пользователи это замечают | low | S |
| 13 | **Authenticode-подпись Windows-артефактов** (уже в owner-actions) + репутация SmartScreen | Без подписи — предупреждения SmartScreen при каждом обновлении, эрозия доверия | high | S (орг.) |

### macOS (перспектива, P2)
Когда дойдёт до macOS — не изобретать: **Sparkle 2** (EdDSA, дельты, phased rollout, каналы, signed feed, sandboxing). Это буквально чек-лист выше в готовом виде.

## 3. Антипаттерны (чего не делать)
- Самописный апдейтер без асимметричных подписей («у нас же HTTPS») — см. п.1 выше.
- Принудительный рестарт/установка поверх активной VPN-сессии.
- In-app замена файлов, принадлежащих deb/rpm.
- WinSparkle-подобный флоу «скачал установщик — кликай мастер» для сервиса под LocalSystem: нужен тихий привилегированный установщик, а не интерактивный мастер.
- Релиз на 100% пользователей в день выхода без канареек.
