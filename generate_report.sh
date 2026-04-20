#!/usr/bin/env bash
# generate_report.sh — Builds reports/report.html from current metrics
# Called by monitor.sh after all checks have run and exported their vars.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$PROJECT_ROOT/logs/health.log"
REPORT="$PROJECT_ROOT/reports/report.html"

css_class() { [[ "$1" == "PASS" ]] && echo "pass" || echo "alert"; }

CPU_CLASS=$(css_class "$CPU_STATUS")
MEM_CLASS=$(css_class "$MEM_STATUS")
DISK_CLASS=$(css_class "$DISK_STATUS")
SVC_OVERALL=$([ "$SVC_ALERT" -eq 0 ] && echo "PASS" || echo "ALERT")
SVC_CLASS=$(css_class "$SVC_OVERALL")
SVC_TOTAL=$(( SVC_PASS + SVC_ALERT ))

GENERATED=$(date '+%A, %d %B %Y at %H:%M:%S %Z')

# Build last-10-log HTML
LAST_LOGS_HTML=""
while IFS= read -r line; do
    escaped="${line//</&lt;}"
    escaped="${escaped//>/&gt;}"
    if echo "$line" | grep -q "ALERT"; then
        LAST_LOGS_HTML+="<span class=\"alert\">${escaped}</span>"$'\n'
    elif echo "$line" | grep -q "PASS"; then
        LAST_LOGS_HTML+="<span class=\"pass\">${escaped}</span>"$'\n'
    else
        LAST_LOGS_HTML+="<span class=\"ts\">${escaped}</span>"$'\n'
    fi
done < <(tail -n 10 "$LOG")

# Write report
{
cat << 'HTML_HEAD'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AutoOps Monitor — Health Report</title>
  <style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body { font-family:'Segoe UI',system-ui,sans-serif; background:#0d1117; color:#c9d1d9; padding:2rem; }
    header { display:flex; align-items:center; gap:1rem; margin-bottom:2rem; border-bottom:1px solid #30363d; padding-bottom:1rem; }
    header h1 { font-size:1.6rem; color:#58a6ff; }
    header .ts-line { font-size:0.85rem; color:#8b949e; margin-top:0.2rem; }
    .badge { display:inline-block; padding:0.2rem 0.7rem; border-radius:999px; font-size:0.75rem; font-weight:700; letter-spacing:0.05em; }
    .badge.pass  { background:#1a4731; color:#3fb950; border:1px solid #3fb950; }
    .badge.alert { background:#4d1919; color:#f85149; border:1px solid #f85149; }
    h2 { color:#58a6ff; font-size:0.9rem; margin:1.5rem 0 0.8rem; text-transform:uppercase; letter-spacing:0.07em; }
    .cards { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:1rem; margin-bottom:1rem; }
    .card { background:#161b22; border:1px solid #30363d; border-radius:8px; padding:1.2rem 1.4rem; }
    .card.pass  { border-left:4px solid #3fb950; }
    .card.alert { border-left:4px solid #f85149; }
    .card .lbl  { font-size:0.72rem; color:#8b949e; text-transform:uppercase; letter-spacing:0.08em; }
    .card .val  { font-size:2rem; font-weight:700; margin:0.3rem 0; }
    .card.pass  .val { color:#3fb950; }
    .card.alert .val { color:#f85149; }
    .card .meta { font-size:0.78rem; color:#8b949e; margin-bottom:0.5rem; }
    table { width:100%; border-collapse:collapse; margin-bottom:1.5rem; font-size:0.88rem; }
    th { background:#161b22; color:#8b949e; text-align:left; padding:0.65rem 1rem; border-bottom:2px solid #30363d; font-weight:600; text-transform:uppercase; letter-spacing:0.06em; font-size:0.72rem; }
    td { padding:0.65rem 1rem; border-bottom:1px solid #21262d; }
    tr.pass  td { background:#0d1f14; }
    tr.alert td { background:#1f0d0d; }
    tr:hover td { filter:brightness(1.1); }
    td:first-child { font-weight:600; }
    .log-box { background:#0d1117; border:1px solid #30363d; border-radius:8px; padding:1rem 1.2rem; font-family:'Cascadia Code','Fira Code',monospace; font-size:0.78rem; color:#8b949e; white-space:pre-wrap; line-height:1.7; }
    .log-box .ts    { color:#58a6ff; }
    .log-box .pass  { color:#3fb950; }
    .log-box .alert { color:#f85149; }
    footer { margin-top:3rem; font-size:0.75rem; color:#484f58; text-align:center; }
  </style>
</head>
<body>
HTML_HEAD

echo "<header><div>"
echo "  <h1>🖥 AutoOps Monitor — Health Report</h1>"
echo "  <div class=\"ts-line\">Generated: ${GENERATED}</div>"
echo "</div></header>"

echo "<h2>Live Metrics</h2>"
echo "<div class=\"cards\">"

echo "  <div class=\"card ${CPU_CLASS}\">"
echo "    <div class=\"lbl\">CPU Usage</div>"
echo "    <div class=\"val\">${CPU_USAGE}%</div>"
echo "    <div class=\"meta\">Threshold: ${CPU_THRESHOLD}%</div>"
echo "    <span class=\"badge ${CPU_CLASS}\">${CPU_STATUS}</span>"
echo "  </div>"

echo "  <div class=\"card ${MEM_CLASS}\">"
echo "    <div class=\"lbl\">Memory Usage</div>"
echo "    <div class=\"val\">${MEM_USAGE}%</div>"
echo "    <div class=\"meta\">${MEM_USED}MB / ${MEM_TOTAL}MB &nbsp;|&nbsp; Threshold: ${MEMORY_THRESHOLD}%</div>"
echo "    <span class=\"badge ${MEM_CLASS}\">${MEM_STATUS}</span>"
echo "  </div>"

echo "  <div class=\"card ${DISK_CLASS}\">"
echo "    <div class=\"lbl\">Disk Usage (/)</div>"
echo "    <div class=\"val\">${DISK_USAGE}%</div>"
echo "    <div class=\"meta\">${DISK_USED} / ${DISK_TOTAL} &nbsp;|&nbsp; Threshold: ${DISK_THRESHOLD}%</div>"
echo "    <span class=\"badge ${DISK_CLASS}\">${DISK_STATUS}</span>"
echo "  </div>"

echo "  <div class=\"card ${SVC_CLASS}\">"
echo "    <div class=\"lbl\">Services</div>"
echo "    <div class=\"val\">${SVC_PASS}/${SVC_TOTAL}</div>"
echo "    <div class=\"meta\">${SVC_PASS} running &nbsp;|&nbsp; ${SVC_ALERT} down</div>"
echo "    <span class=\"badge ${SVC_CLASS}\">${SVC_OVERALL}</span>"
echo "  </div>"
echo "</div>"

echo "<h2>Check Results</h2>"
echo "<table>"
echo "  <thead><tr><th>Check</th><th>Current Value</th><th>Threshold</th><th>Status</th></tr></thead>"
echo "  <tbody>"
echo "    <tr class=\"${CPU_CLASS}\"><td>CPU Usage</td><td>${CPU_USAGE}%</td><td>${CPU_THRESHOLD}%</td><td><span class=\"badge ${CPU_CLASS}\">${CPU_STATUS}</span></td></tr>"
echo "    <tr class=\"${MEM_CLASS}\"><td>Memory Usage</td><td>${MEM_USAGE}% (${MEM_USED}MB / ${MEM_TOTAL}MB)</td><td>${MEMORY_THRESHOLD}%</td><td><span class=\"badge ${MEM_CLASS}\">${MEM_STATUS}</span></td></tr>"
echo "    <tr class=\"${DISK_CLASS}\"><td>Disk Usage (/)</td><td>${DISK_USAGE}% (${DISK_USED} / ${DISK_TOTAL})</td><td>${DISK_THRESHOLD}%</td><td><span class=\"badge ${DISK_CLASS}\">${DISK_STATUS}</span></td></tr>"
echo "    <tr class=\"${SVC_CLASS}\"><td>Services (${SERVICES})</td><td>${SVC_PASS} active / ${SVC_ALERT} down</td><td>All active</td><td><span class=\"badge ${SVC_CLASS}\">${SVC_OVERALL}</span></td></tr>"
echo "  </tbody>"
echo "</table>"

echo "<h2>Recent Log Entries (last 10)</h2>"
echo "<div class=\"log-box\">"
echo "$LAST_LOGS_HTML"
echo "</div>"

echo "<footer>AutoOps Monitor &nbsp;&middot;&nbsp; DevOps Engineering Track &nbsp;&middot;&nbsp; Automation &amp; Scripting Module</footer>"
echo "</body></html>"

} > "$REPORT"

echo -e "\033[1;36m  ✔ HTML report written to: ${REPORT}\033[0m"
