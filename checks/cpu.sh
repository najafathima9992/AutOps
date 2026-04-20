#!/usr/bin/env bash
# ============================================================
# cpu.sh — CPU Usage Check
# Reads threshold from config.cfg, checks current CPU usage,
# prints PASS/ALERT status, and logs the result.
# ============================================================

# --- Resolve paths relative to this script's location -------
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

# --- Collect CPU usage (idle% subtracted from 100) ----------
# Uses /proc/stat for a 1-second sample — works on any Linux
read -r cpu user nice system idle iowait irq softirq steal \
    < <(grep '^cpu ' /proc/stat | awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9}')

sleep 1

read -r cpu2 user2 nice2 system2 idle2 iowait2 irq2 softirq2 steal2 \
    < <(grep '^cpu ' /proc/stat | awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9}')

PREV_IDLE=$((idle + iowait))
CURR_IDLE=$((idle2 + iowait2))
PREV_TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
CURR_TOTAL=$((user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2))

DIFF_IDLE=$((CURR_IDLE - PREV_IDLE))
DIFF_TOTAL=$((CURR_TOTAL - PREV_TOTAL))

# Guard against division by zero
if [[ $DIFF_TOTAL -eq 0 ]]; then
    CPU_USAGE=0
else
    CPU_USAGE=$(( (DIFF_TOTAL - DIFF_IDLE) * 100 / DIFF_TOTAL ))
fi

# --- Determine PASS / ALERT ---------------------------------
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [[ $CPU_USAGE -ge $CPU_THRESHOLD ]]; then
    STATUS="ALERT"
    COLOR="\033[1;31m"   # Bold red
else
    STATUS="PASS"
    Color="\033[1;32m"   # Bold green
    COLOR=$Color
fi

RESET="\033[0m"

# --- Print colour-coded result to terminal ------------------
echo -e "  [CPU]    Usage: ${COLOR}${CPU_USAGE}%${RESET}  (threshold: ${CPU_THRESHOLD}%)  --> ${COLOR}${STATUS}${RESET}"

# --- Append timestamped entry to health.log -----------------
echo "${TIMESTAMP} | CPU    | Usage: ${CPU_USAGE}% | Threshold: ${CPU_THRESHOLD}% | ${STATUS}" | tee -a "$LOG" > /dev/null

# --- Export for use by monitor.sh ---------------------------
export CPU_USAGE CPU_STATUS="$STATUS"
