# Day 01 — Git Foundations

## Ключевые концепции / Key Concepts

| RU термин | EN термин | Объяснение |
|-----------|-----------|-----------|
| Область подготовки | Staging Area / Index | Промежуточная зона перед коммитом |
| Рабочая директория | Working Directory | Файлы как они есть на диске |
| Снимок | Snapshot | Состояние всех файлов в момент коммита |
| Указатель | Pointer / Reference | HEAD, ветки — это просто указатели на SHA |
| Слияние | Merge | Объединение истории двух веток |
| Перебазирование | Rebase | Перенос коммитов поверх другой базы |
| Форк | Fork | Копия чужого репо под своим аккаунтом |

## Команды

| Команда | Что делает |
|---------|-----------|
| `git add -p` | Интерактивный staging по кускам (patch mode) |
| `git diff --staged` | Diff между staging и последним коммитом |
| `git log --oneline --graph --all` | Граф истории всех веток |
| `git stash` | Спрятать незакоммиченные изменения во временный стек |
| `git restore --staged <file>` | Убрать файл из staging (не удаляет изменения) |
| `git show HEAD` | Показать содержимое последнего коммита |

## Bug DVPS-4: Permission denied (publickey)
**Симптом:** `git push` выдаёт `ERROR: Permission denied (publickey)`
**Причина:** remote URL использует HTTPS, а не SSH
**Диагностика:** `git remote -v` → видим `https://` вместо `git@`
**Fix:** `git remote set-url origin git@github.com:user/repo.git`
**Проверка:** `git remote -v` → должен показывать `git@`

---

## Bug DVPS-8: AMDGPU Errors in System Logs

**Severity Assessment (оценка критичности):**
- Desktop: WARN (не мешает работе)
- Production GPU server: CRITICAL

**Root Cause (корневая причина):**
- page fault = GPU пытается обратиться к памяти, которая уже освобождена
- Обычно виноват Firefox или Chromium (GPU-accelerated rendering)

**Impact:** non-critical on desktop, visual glitches possible

**Mitigation (временное решение):**
- Отключить GPU-ускорение в браузере
- Обновить драйвер: sudo apt install linux-firmware

**Status:** Known issue, monitoring only
