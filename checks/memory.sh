#!/usr/bin/env bash
# ============================================================
# memory.sh — Memory Usage Check
# Reads threshold from config.cfg, checks current RAM usage,
# prints PASS/ALERT status, and logs the result.
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

# --- Collect memory usage using free -m ---------------------
# Output line:  Mem: total used free shared buff/cache available
read -r _ TOTAL USED _ _ _ _ \
    < <(free -m | grep '^Mem:')

# Guard against missing data
if [[ -z "$TOTAL" || "$TOTAL" -eq 0 ]]; then
    echo "[ERROR] Could not read memory info from 'free -m'"
    exit 1
fi

MEM_USAGE=$(( USED * 100 / TOTAL ))

# --- Determine PASS / ALERT ---------------------------------
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [[ $MEM_USAGE -ge $MEMORY_THRESHOLD ]]; then
    STATUS="ALERT"
    COLOR="\033[1;31m"
else
    STATUS="PASS"
    COLOR="\033[1;32m"
fi

RESET="\033[0m"

# --- Print colour-coded result to terminal ------------------
echo -e "  [MEM]    Usage: ${COLOR}${MEM_USAGE}%${RESET}  (${USED}MB / ${TOTAL}MB, threshold: ${MEMORY_THRESHOLD}%)  --> ${COLOR}${STATUS}${RESET}"

# --- Append timestamped entry to health.log -----------------
echo "${TIMESTAMP} | MEMORY | Usage: ${MEM_USAGE}% (${USED}MB/${TOTAL}MB) | Threshold: ${MEMORY_THRESHOLD}% | ${STATUS}" | tee -a "$LOG" > /dev/null

# --- Export for use by monitor.sh ---------------------------
export MEM_USAGE MEM_USED=$USED MEM_TOTAL=$TOTAL MEM_STATUS="$STATUS"
