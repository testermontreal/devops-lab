⚡ Git — Cheatsheet (День 1)

# SSH setting
ssh-keygen -t ed25519 -C "email" -f ~/.ssh/id_ed25519_github
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_ed25519_github
chmod 600 ~/.ssh/config
ssh -T git@github.com

# Initialization and configuration
git init -b main
git config --local user.name "Name"
git config --local user.email "email"

# Daily Workflow
git status (gs) → git add . / git add -p → git diff --staged
→ git commit -m "type(scope): description" → git push

# Conventional commits
feat - feature
chore - routine tasks
fix - fix bug
docs - documentation
test - testing
For DevOps:
perf -perfomance
ci - changes in CI/CD
build - chenges in build configuration
revert - when it nededed undo previous commit

# Branching
git checkout -b DVPS-X/feat/name   # создать + переключиться
git branch                          # список веток (* = текущая)
git checkout main && git pull       # вернуться и обновить
git branch -d ветка                 # удалить локально
git push origin --delete ветка      # удалить на remote

# History and diagnostics
git log --oneline --graph --all (gl)
git show HEAD                  # содержимое последнего коммита
git diff HEAD~1                # что изменилось с прошлого коммита
git remote -v                  # проверить URL (должен быть git@)
git remote set-url origin git@github.com:user/repo.git  # исправить URL



⚡ Linux FHS — Cheatsheet (День 2)

# Навигация и исследование
ls -lah /etc           # все файлы с размерами
ls -laht /var/log      # по времени, свежие сверху
stat /etc/passwd       # полная метаинформация + timestamps
file /usr/bin/python3  # тип файла (ELF binary, script, etc.)
which git              # где находится бинарник
type ls                # alias, builtin или file?

# find — поиск файлов
find /etc -name "*.conf"              # по имени
find /var/log -size +10M              # большие файлы
find /etc -mtime -1                   # изменённые за 24 часа
find /tmp -perm -o+w -type f         # world-writable (security!)
find / -perm -4000 2>/dev/null       # SUID файлы
find /etc -type f -exec grep -l "ssh" {} \;  # файлы содержащие "ssh"

# Дисковое пространство
df -hT | grep -v tmpfs | grep -v loop  # реальные разделы
du -sh ~                               # размер домашней директории
du -h --max-depth=1 /var | sort -rh | head -10  # топ поддиректорий

# Текстовые инструменты
cat -n файл                    # с номерами строк
less /var/log/syslog           # постраничный просмотр
tail -f /var/log/auth.log      # live monitoring
head -20 /var/log/syslog       # первые 20 строк

# grep — поиск по содержимому
grep -rn "pattern" /etc/       # рекурсивно с номерами строк
grep -v "^#" файл | grep -v "^$"  # убрать комментарии и пустые строки
grep -E "error|warn" /var/log/syslog  # OR-паттерн
grep -c "pattern" файл         # посчитать совпадения
journalctl -b 0 -p err         # системные ошибки с последней загрузки

# Потоки (Streams)
команда > файл       # stdout в файл (перезаписать)
команда >> файл      # stdout в файл (добавить)
команда 2>/dev/null  # выбросить stderr
команда &> файл      # stdout + stderr в файл
cmd1 | cmd2          # stdout cmd1 → stdin cmd2
cmd | tee файл       # и в файл, и на экран

| RU термин                    | EN термин                           | Определение                                          |
| ---------------------------- | ----------------------------------- | ---------------------------------------------------- |
| Область подготовки           | Staging Area / Index                | Зона между рабочей директорией и репо в Git          |
| Снимок                       | Snapshot                            | Состояние всех файлов в момент коммита               |
| Указатель                    | Pointer / Reference                 | HEAD и ветки — файлы, содержащие SHA-хэш             |
| Слияние                      | Merge                               | Объединение истории двух веток                       |
| Перебазирование              | Rebase                              | Перенос коммитов поверх другой базы                  |
| Иерархия файловой системы    | FHS — Filesystem Hierarchy Standard | Стандарт расположения директорий в Unix              |
| Виртуальная файловая система | Virtual Filesystem (VFS)            | /proc, /sys — не на диске, генерируются ядром        |
| Файловый дескриптор          | File Descriptor (fd)                | Целое число — идентификатор открытого файла/потока   |
| Стандартный поток            | Standard Stream                     | stdin (0), stdout (1), stderr (2)                    |
| Перенаправление              | Redirection                         | >, >>, 2>, &> — куда идёт вывод команды              |
| Конвейер                     | Pipeline / Pipe                     | \| — соединение stdout → stdin между командами       |
| Права доступа                | File Permissions                    | rwxrwxrwx — owner, group, others                     |
| SUID                         | Set User ID bit                     | Файл выполняется с правами владельца, не вызывающего |
| Жёсткая ссылка               | Hard Link                           | Второе имя для того же inode                         |
| Символическая ссылка         | Symbolic Link / Symlink             | Файл-указатель на другой путь                        |
| Inode                        | Inode                               | Структура данных ядра: метаданные файла без имени    |
| Вложенный документ           | Heredoc                             | << 'EOF' — многострочный ввод в скрипте              |
| Shebang                      | Shebang                             | #!/usr/bin/env bash — интерпретатор для скрипта      |


| Вопрос                    | Одна фраза-ответ (EN)                                                                                                                      |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| What is the staging area? | "A middle layer between working directory and repository — lets you craft precise commits instead of committing everything at once."       |
| merge vs rebase?          | "Merge preserves history with a merge commit; rebase rewrites commits onto a new base for a linear history. Never rebase public branches." |
| What is /proc?            | "A virtual filesystem generated by the kernel in real time — not stored on disk. It exposes process information and kernel parameters."    |
| How to find large files?  | "find / -type f -size +100M 2>/dev/null — redirecting stderr to /dev/null suppresses permission denied errors."                            |
| What is a pipe?           | "Connects stdout of one command to stdin of the next, enabling powerful data transformation chains without temp files."                    |

