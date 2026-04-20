# 🚀 Automated Server Health Monitor with Cron

## 📌 Project Overview

This project is a **DevOps-style automation system** that monitors server health, logs system metrics, and generates a daily HTML report.

It simulates real-world **production monitoring**, including:

* CPU, Memory, Disk usage checks
* Service status monitoring
* Automated logging
* HTML dashboard report
* Cron-based scheduling

---

## 🧠 Key Features

✅ Modular Bash scripts
✅ Config-driven thresholds
✅ Real-time system monitoring
✅ Centralized logging (`health.log`)
✅ HTML report generation
✅ Automated execution using cron

---

## 🏗️ Architecture Diagram

```
                ┌───────────────┐
                │   Cron Jobs   │
                └──────┬────────┘
                       │
                       ▼
               ┌───────────────┐
               │  monitor.sh   │
               └──────┬────────┘
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   cpu.sh       memory.sh      disk.sh
        ▼             ▼             ▼
        └─────── services.sh ───────┘
                       │
                       ▼
               ┌───────────────┐
               │ health.log    │
               └───────────────┘
                       │
                       ▼
               ┌───────────────┐
               │ report.html   │
               └───────────────┘
                       │
                       ▼
                   NGINX
```

---

## 📂 Project Structure

```
health-monitor/
├── monitor.sh              ← Main runner (orchestrator)
├── generate_report.sh      ← HTML report builder
├── config.cfg              ← All thresholds & settings
│
├── checks/
│   ├── cpu.sh              ← CPU usage via /proc/stat
│   ├── memory.sh           ← RAM usage via free -m
│   ├── disk.sh             ← Disk usage via df -h /
│   └── services.sh         ← Service status via systemctl
│
├── reports/
│   └── report.html         ← Auto-generated (output file)
│
└── logs/
    └── health.log          ← Persistent timestamped log
```

---

## ⚙️ Configuration (config.cfg)

```bash
CPU_THRESHOLD=80
MEMORY_THRESHOLD=75
DISK_THRESHOLD=90
SERVICES="sshd crond nginx"
```

---

## ▶️ How to Run

```bash
chmod +x monitor.sh checks/*.sh
./monitor.sh
```

---

## 📊 Sample Output

```
[CPU]    Usage: 25%  --> PASS
[MEM]    Usage: 60%  --> PASS
[DISK]   Usage: 70%  --> PASS
[SERVICES] sshd nginx crond --> PASS
```

---

## 🌐 HTML Report

Generated at:

```
reports/report.html
```

Served via NGINX:

```
http://<server-ip>/reports/report.html
```

---

## ⏰ Cron Automation

Edit crontab:

```bash
crontab -e
```

Add:

```bash
*/5 * * * * /home/ec2-user/health-monitor/monitor.sh >> /home/ec2-user/health-monitor/logs/health.log 2>&1
0 8 * * * /home/ec2-user/health-monitor/monitor.sh
```

---

## 📜 Logging

View logs:

```bash
tail -f logs/health.log
```

---

## 🛠️ Tools Used

* Bash
* Cron
* NGINX
* Linux system utilities (`top`, `df`, `free`, `systemctl`)

---


