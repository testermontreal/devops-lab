#!/usr/bin/env bash
# =============================================================
# permissions_audit.sh
# Purpose: Detect insecure file permissions on Linux servers.
#          Run this after deployments and as part of security audits.
# Usage:   ./permissions_audit.sh [target_directory]
# Output:  Terminal report + /tmp/permissions_audit_TIMESTAMP.txt
# =============================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────
TARGET_DIR="${1:-/}"
REPORT_FILE="/tmp/permissions_audit_$(date +%Y%m%d_%H%M%S).txt"
ISSUES_FOUND=0

# ── Colors ─────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ── Helper functions ───────────────────────────────────────────
print_header() { echo -e "\n${BLUE}══ $1 ══${NC}" | tee -a "$REPORT_FILE"; }
print_ok()     { echo -e "${GREEN}[OK]${NC}    $1" | tee -a "$REPORT_FILE"; }
print_warn()   { echo -e "${YELLOW}[WARN]${NC}  $1" | tee -a "$REPORT_FILE"; ISSUES_FOUND=$((ISSUES_FOUND + 1)); }
print_crit()   { echo -e "${RED}[CRIT]${NC}  $1" | tee -a "$REPORT_FILE"; ISSUES_FOUND=$((ISSUES_FOUND + 1)); }

# ── Audit functions ────────────────────────────────────────────

check_world_writable() {
    print_header "WORLD-WRITABLE FILES (anyone can modify)"
    # -perm -o+w: the 'write' bit is set for 'others'
    # These files can be modified by any user — a classic attack vector
    local count
    count=$(find "$TARGET_DIR" -xdev -type f -perm -o+w 2>/dev/null | wc -l)
    # -xdev: do not cross filesystem boundaries (avoids /proc, /sys)

    if [ "$count" -gt 0 ]; then
        print_crit "$count world-writable files found:"
        find "$TARGET_DIR" -xdev -type f -perm -o+w 2>/dev/null \
          | head -20 \
          | tee -a "$REPORT_FILE"
    else
        print_ok "No world-writable files found"
    fi
}

check_suid_binaries() {
    print_header "SUID/SGID BINARIES (run as owner/group)"
    # SUID (-perm -4000): executes as file owner (often root)
    # SGID (-perm -2000): executes as file group
    # These are legitimate (passwd, sudo) but must be audited
    echo "Known SUID binaries — verify none are unexpected:" | tee -a "$REPORT_FILE"
    find /usr/bin /usr/sbin /bin /sbin -perm /6000 2>/dev/null \
      | xargs ls -la 2>/dev/null \
      | tee -a "$REPORT_FILE"
    # /6000 means: SUID OR SGID is set (bitwise OR search)
}

check_unowned_files() {
    print_header "UNOWNED FILES (no valid user or group)"
    # Files with UID/GID not in /etc/passwd or /etc/group
    # Left over after user deletion — potential orphaned attack surface
    local count
    count=$(find "$TARGET_DIR" -xdev \( -nouser -o -nogroup \) 2>/dev/null | wc -l)

    if [ "$count" -gt 0 ]; then
        print_warn "$count unowned files found:"
        find "$TARGET_DIR" -xdev \( -nouser -o -nogroup \) 2>/dev/null \
          | head -20 \
          | tee -a "$REPORT_FILE"
    else
        print_ok "No unowned files found"
    fi
}

check_sensitive_files() {
    print_header "SENSITIVE FILE PERMISSIONS"
    # These files must have strict permissions — check them explicitly

    local -A EXPECTED_PERMS
    EXPECTED_PERMS=(
        ["/etc/passwd"]="644"
        ["/etc/shadow"]="640"
        ["/etc/sudoers"]="440"
        ["/etc/ssh/sshd_config"]="600"
        ["/root"]="700"
    )

    for file in "${!EXPECTED_PERMS[@]}"; do
        if [ -e "$file" ]; then
            actual=$(stat -c "%a" "$file")
            expected="${EXPECTED_PERMS[$file]}"
            if [ "$actual" = "$expected" ]; then
                print_ok "$file has correct permissions ($actual)"
            else
                print_crit "$file has $actual (expected $expected)"
            fi
        fi
    done
}

check_scripts_executable() {
    print_header "SCRIPTS WITHOUT EXECUTE BIT"
    # Shell scripts that cannot run directly (require 'bash script.sh' workaround)
    local count
    count=$(find "${TARGET_DIR}" -name "*.sh" -type f ! -perm -u+x 2>/dev/null | wc -l)

    if [ "$count" -gt 0 ]; then
        print_warn "$count scripts missing execute bit:"
        find "${TARGET_DIR}" -name "*.sh" -type f ! -perm -u+x 2>/dev/null \
          | tee -a "$REPORT_FILE"
    else
        print_ok "All .sh scripts have execute bit set"
    fi
}

# ── Main ───────────────────────────────────────────────────────
main() {
    echo "Permissions Audit Report" | tee "$REPORT_FILE"
    echo "Generated: $(date)" | tee -a "$REPORT_FILE"
    echo "Target: ${TARGET_DIR}" | tee -a "$REPORT_FILE"
    echo "Host: $(hostname) | User: $(whoami)" | tee -a "$REPORT_FILE"

    check_world_writable
    check_suid_binaries
    check_unowned_files
    check_sensitive_files
    check_scripts_executable

    print_header "SUMMARY"
    if [ "$ISSUES_FOUND" -eq 0 ]; then
        print_ok "No issues found. Permissions look clean."
    else
        print_warn "Total issues found: $ISSUES_FOUND — review above and remediate."
    fi

    echo -e "\n${GREEN}Full report saved: ${REPORT_FILE}${NC}"
    # Exit with non-zero if issues found — useful for CI/CD pipelines
    exit "$ISSUES_FOUND"
}

main "$@"
