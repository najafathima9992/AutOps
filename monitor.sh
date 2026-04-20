#!/usr/bin/env bash
# ============================================================
# monitor.sh — AutoOps Monitor  |  Main Runner Script
# ============================================================
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$PROJECT_ROOT/config.cfg"
LOG="$PROJECT_ROOT/logs/health.log"
CHECKS_DIR="$PROJECT_ROOT/checks"

mkdir -p "$PROJECT_ROOT/logs" "$PROJECT_ROOT/reports"

if [[ ! -f "$CONFIG" ]]; then echo "[ERROR] config.cfg not found."; exit 1; fi
source "$CONFIG"

RESET="\033[0m"; BOLD="\033[1m"; CYAN="\033[1;36m"; WHITE="\033[1;37m"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║     🖥  AutoOps Monitor — Health Check    ║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo -e "${WHITE}  Run at: $(date '+%Y-%m-%d %H:%M:%S')${RESET}"
echo ""

echo "---------- RUN: $(date '+%Y-%m-%d %H:%M:%S') ----------" >> "$LOG"

echo -e "${BOLD}── System Checks ──────────────────────────${RESET}"
source "$CHECKS_DIR/cpu.sh"
source "$CHECKS_DIR/memory.sh"
source "$CHECKS_DIR/disk.sh"
source "$CHECKS_DIR/services.sh"
echo ""

echo -e "${BOLD}── Summary ─────────────────────────────────${RESET}"
printf "  %-12s %-12s %-12s %s\n" "CHECK" "VALUE" "THRESHOLD" "STATUS"
printf "  %-12s %-12s %-12s %s\n" "-----" "-----" "---------" "------"

color_status() { [[ "$1" == "PASS" ]] && echo "\033[1;32m" || echo "\033[1;31m"; }

C=$(color_status "$CPU_STATUS");  printf "  %-12s %-12s %-12s " "CPU"      "${CPU_USAGE}%"  "${CPU_THRESHOLD}%";  echo -e "${C}${CPU_STATUS}${RESET}"
C=$(color_status "$MEM_STATUS");  printf "  %-12s %-12s %-12s " "MEMORY"   "${MEM_USAGE}%"  "${MEMORY_THRESHOLD}%"; echo -e "${C}${MEM_STATUS}${RESET}"
C=$(color_status "$DISK_STATUS"); printf "  %-12s %-12s %-12s " "DISK"     "${DISK_USAGE}%" "${DISK_THRESHOLD}%"; echo -e "${C}${DISK_STATUS}${RESET}"
SVC_OVERALL=$([ "$SVC_ALERT" -eq 0 ] && echo "PASS" || echo "ALERT")
C=$(color_status "$SVC_OVERALL"); printf "  %-12s %-12s %-12s " "SERVICES" "${SVC_PASS}P/${SVC_ALERT}A" "all active"; echo -e "${C}${SVC_OVERALL}${RESET}"
echo ""

export CPU_USAGE CPU_STATUS CPU_THRESHOLD
export MEM_USAGE MEM_USED MEM_TOTAL MEM_STATUS MEMORY_THRESHOLD
export DISK_USAGE DISK_USED DISK_TOTAL DISK_STATUS DISK_THRESHOLD
export SVC_PASS SVC_ALERT SERVICES SVC_OVERALL

source "$PROJECT_ROOT/generate_report.sh"

echo ""
echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
echo ""
