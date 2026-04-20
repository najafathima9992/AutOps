#!/usr/bin/env bash
# ============================================================
# services.sh — Service Status Check
# Reads SERVICES list from config.cfg, checks each with
# systemctl is-active, prints PASS/ALERT, and logs results.
# ============================================================

# --- Resolve paths ------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG="$PROJECT_ROOT/config.cfg"
LOG="$PROJECT_ROOT/logs/health.log"

# --- Load configuration -------------------------------------
if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] config.cfg not found at $CONFIG"
    exit 1
fi
source "$CONFIG"

# --- Initialise counters ------------------------------------
SVC_PASS=0
SVC_ALERT=0
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

RESET="\033[0m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"

echo -e "  [SERVICES] Checking: ${YELLOW}${SERVICES}${RESET}"

# --- Loop through each service ------------------------------
for SVC in $SERVICES; do
    # systemctl is-active returns 'active' if running
    STATE=$(systemctl is-active "$SVC" 2>/dev/null || echo "unknown")

    if [[ "$STATE" == "active" ]]; then
        STATUS="PASS"
        COLOR=$GREEN
        (( SVC_PASS++ ))
    else
        STATUS="ALERT"
        COLOR=$RED
        (( SVC_ALERT++ ))
        # STATE might be 'inactive', 'failed', 'unknown' etc.
    fi

    echo -e "    └─ ${SVC}: ${COLOR}${STATE^^} — ${STATUS}${RESET}"
    echo "${TIMESTAMP} | SERVICE| ${SVC} is ${STATE} | ${STATUS}" | tee -a "$LOG" > /dev/null
done

# --- Summary line -------------------------------------------
echo -e "  [SERVICES] Result: ${GREEN}${SVC_PASS} PASS${RESET} / ${RED}${SVC_ALERT} ALERT${RESET}"

# --- Export for use by monitor.sh ---------------------------
export SVC_PASS SVC_ALERT
