#!/usr/bin/env bash
# ============================================================
# fs_audit.sh — Filesystem Audit Script
# Author: Leo (DevOps Learning)
# Purpose: Quick health check of filesystem state
# Usage: ./fs_audit.sh [target_directory]
# ============================================================

# ── Разбор строки #!/usr/bin/env bash ──────────────────────
# #! = shebang: говорит ядру, каким интерпретатором запускать файл
# /usr/bin/env bash: найти bash через PATH (переносимо — работает везде)
# Альтернатива #!/bin/bash — жёстко задаёт путь (не всегда /bin/bash)
# ──────────────────────────────────────────────────────────

# set -e: exit immediately on error (остановиться при ошибке)
# set -u: treat unset variables as error (ошибка если переменная не задана)
# set -o pipefail: pipe fails if any command fails (не только последняя)
# Это "безопасный режим" — стандарт для production-скриптов
set -euo pipefail

# ── Переменные (Variables) ────────────────────────────────
TARGET_DIR="${1:-/}"          # первый аргумент или / по умолчанию
                               # ${1:-/} = "взять $1, а если не задан — использовать /"
REPORT_FILE="/tmp/fs_audit_$(date +%Y%m%d_%H%M%S).txt"
                               # date +%Y%m%d_%H%M%S → 20260304_161500
LARGE_FILE_THRESHOLD="100M"
RECENT_DAYS=1

# Цвета для вывода в терминал (ANSI color codes)
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color — сброс цвета

# ── Функции (Functions) ───────────────────────────────────

print_header() {
    # $1 = текст заголовка, переданный при вызове функции
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

print_ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
print_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Основная логика ───────────────────────────────────────

main() {
    echo "Filesystem Audit Report" | tee "$REPORT_FILE"
    echo "Generated: $(date)" | tee -a "$REPORT_FILE"
    echo "Host: $(hostname) | User: $(whoami)" | tee -a "$REPORT_FILE"
    # tee -a: писать в stdout И добавлять в файл (-a = append)

    # ── БЛОК 1: Использование дискового пространства ──────
    print_header "DISK USAGE (df -hT)"
    df -hT | grep -v tmpfs | grep -v loop | tee -a "$REPORT_FILE"

    # Проверяем разделы > 80% заполненности
    print_header "PARTITIONS > 80% USED"
    df -h | awk 'NR>1 && $5+0 > 80 {print $0}' | tee -a "$REPORT_FILE"
    # NR>1: пропустить заголовок (строка 1)
    # $5+0: взять 5-е поле (Use%), добавить 0 для числового сравнения
    # > 80: фильтр

    # ── БЛОК 2: Большие файлы ─────────────────────────────
    print_header "LARGE FILES (> ${LARGE_FILE_THRESHOLD}) in ${TARGET_DIR}"
    find "$TARGET_DIR" -type f -size +"$LARGE_FILE_THRESHOLD" \
        2>/dev/null \
        -exec ls -lh {} \; | \
        sort -k5 -rh | \
        head -20 | tee -a "$REPORT_FILE"
    # \ в конце строки = продолжение команды (line continuation)
    # sort -k5: сортировать по 5-му полю ls (размер)

    # ── БЛОК 3: Недавно изменённые файлы ─────────────────
    print_header "RECENTLY MODIFIED FILES (last ${RECENT_DAYS} day)"
    find /etc -type f -mtime -"$RECENT_DAYS" \
        2>/dev/null | tee -a "$REPORT_FILE"

    # ── БЛОК 4: Безопасность (Security Check) ────────────
    print_header "SECURITY: WORLD-WRITABLE FILES in /tmp"
    WORLD_WRITABLE=$(find /tmp -perm -o+w -type f 2>/dev/null | wc -l)
    if [ "$WORLD_WRITABLE" -gt 0 ]; then
        print_warn "$WORLD_WRITABLE world-writable files found in /tmp"
        find /tmp -perm -o+w -type f 2>/dev/null | tee -a "$REPORT_FILE"
    else
        print_ok "No world-writable files in /tmp"
    fi

    # ── БЛОК 5: SUID/SGID файлы ───────────────────────────
    print_header "SECURITY: SUID FILES (run as owner, not caller)"
    find /usr/bin /usr/sbin /bin /sbin -perm -4000 \
        2>/dev/null | tee -a "$REPORT_FILE"
    # -perm -4000: SUID bit установлен (запускается с правами владельца)
    # Примеры: /usr/bin/sudo, /usr/bin/passwd

    # ── ИТОГ ──────────────────────────────────────────────
    print_header "AUDIT COMPLETE"
    echo -e "${GREEN}Report saved to: ${REPORT_FILE}${NC}"
}

# ── Точка входа ───────────────────────────────────────────
# Вызываем main только если скрипт запущен напрямую
# (не если он sourced другим скриптом)
main "$@"
