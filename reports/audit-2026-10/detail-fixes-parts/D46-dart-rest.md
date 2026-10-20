# D46 — app/lib остаток Dart (коммиты b2e8d62 + 45fec12 роя, авторство перемешано гонкой)

## Врущий дефолт settings.dart — исправлен
- Было: геттер/сеттер autoSwitchOnDegrade есть, но ключа нет в _keys (allowList) → тумблер никогда не сохранялся.
- Стало: 'autoSwitchOnDegrade' добавлен в _keys. Эффект: настройка персистится.

## Мёртвое состояние obfs.dart — исправлен
- Было: set jitter(true) при fragment=false сохранял {jitter:true, fragment:false} — UI включён, а toProfile() джиттер молча не выставляет.
- Стало: включение jitter включает fragmentation; _load чинит старые записи. Инвариант «jitter ⇒ fragment» держится.

## Непрокинутые параметры sora.dart — исправлены
- updateObfs: при preset != null ветка else отбрасывала utls/fragment/jitter вопреки док-комменту → manual-поля применяются поверх пресета.
- buildPlan/pickMember: для profile-групп выбор всегда по пингу, игнорируя autoSelectMode и bandwidth → прокинуты bandwidth и autoSelect.

## Процессное
- Правки 3–4 ушли в 45fec12 роя (pathspec подхватил несбережённые ханки), b2e8d62 подхватил чужой ханк _activeChain — функционально всё в ветке, авторство перемешано; зафиксировано прозрачно.
- SDK нет — flutter analyze за dev-машиной.
