#!/usr/bin/env bash
# ============================================================
# disk.sh — Disk Usage Check
# Reads threshold from config.cfg, checks root partition (/),
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

# --- Collect disk usage on root partition -------------------
# df -h gives human-readable; we strip the '%' and grab the 5th field
DISK_USAGE=$(df -h / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
DISK_USED=$(df -h  / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')

# Guard against empty read
if [[ -z "$DISK_USAGE" ]]; then
    echo "[ERROR] Could not read disk usage from 'df -h'"
    exit 1
fi

# --- Determine PASS / ALERT ---------------------------------
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [[ $DISK_USAGE -ge $DISK_THRESHOLD ]]; then
    STATUS="ALERT"
    COLOR="\033[1;31m"
else
    STATUS="PASS"
    COLOR="\033[1;32m"
fi

RESET="\033[0m"

# --- Print colour-coded result to terminal ------------------
echo -e "  [DISK]   Usage: ${COLOR}${DISK_USAGE}%${RESET}  (${DISK_USED} / ${DISK_TOTAL}, threshold: ${DISK_THRESHOLD}%)  --> ${COLOR}${STATUS}${RESET}"

# --- Append timestamped entry to health.log -----------------
echo "${TIMESTAMP} | DISK   | Usage: ${DISK_USAGE}% (${DISK_USED}/${DISK_TOTAL}) | Threshold: ${DISK_THRESHOLD}% | ${STATUS}" | tee -a "$LOG" > /dev/null

# --- Export for use by monitor.sh ---------------------------
export DISK_USAGE DISK_USED DISK_TOTAL DISK_STATUS="$STATUS"
