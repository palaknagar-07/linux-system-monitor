# Linux System Monitor

A modular Bash script to monitor system information on Linux and macOS systems. The project keeps each metric in its own module so it is easy to improve or replace one part without rewriting the whole monitor.

## Features

- Modular architecture across separate monitoring files
- Hostname, OS, and uptime display
- CPU, RAM, disk, battery, and internet status
- System health score with explainable health signals
- RAM breakdown estimate for apps/system/cache/free memory
- Top apps grouped from app bundle paths and parent process ownership
- Top 3 RAM-consuming processes
- Top 3 CPU-consuming processes
- macOS and Linux-aware metric collection where supported
- Graceful `Unavailable` output when a metric cannot be collected
- Color-coded terminal output
- `--watch` mode for live refreshes
- `--json` output for scripts and automation
- `--no-color` and `--no-clear` options for cleaner logs

## Project Structure

```
linux-system-monitor/
│
├── monitor.sh              # Main entry point script
│
├── modules/                # Monitoring modules
│   ├── cpu.sh             # CPU usage monitoring
│   ├── ram.sh             # Memory usage monitoring
│   ├── disk.sh            # Disk usage monitoring
│   ├── battery.sh         # Battery status monitoring
│   ├── network.sh         # Network connectivity monitoring
│   ├── health.sh          # Health score and signal calculation
│   ├── processes.sh       # Top process monitoring
│   └── system.sh          # System information display
│
├── utils/                  # Utility functions
│   ├── colors.sh          # Color definitions and styling
│   └── helpers.sh         # Helper functions
│
└── README.md              # This file
```

## Requirements

- Bash shell
- Standard Unix tools: `hostname`, `uname`, `uptime`, `df`, `ping`, `awk`, `sed`
- Process details use `ps`
- macOS: `top`, `vm_stat`, and `pmset` for CPU, memory, and battery details
- Linux: `/proc/stat`, `free`, and `/sys/class/power_supply` where available

## Installation

1. Clone the repository or download the project:
   ```bash
   cd linux-system-monitor
   ```

2. Make the main script executable:
   ```bash
   chmod +x monitor.sh
   ```

3. Make all module scripts executable:
   ```bash
   chmod +x modules/*.sh
   chmod +x utils/*.sh
   ```

## Usage

Run the main monitor script:
```bash
./monitor.sh
```

Run without colors or screen clearing:
```bash
./monitor.sh --no-color --no-clear
```

Refresh every 2 seconds:
```bash
./monitor.sh --watch 2
```

Print JSON:
```bash
./monitor.sh --json
```

Show all options:
```bash
./monitor.sh --help
```

## Output Example

```
==============================
      SYSTEM MONITOR
==============================
System Health: 100/100 - Excellent

Hostname:      mycomputer
OS:            Darwin
Uptime:        10:30  up 2 days, 14:25, 3 users, load averages: 1.50 1.40 1.35
CPU Usage:     15%
RAM Usage:     8.5 GiB / 16.0 GiB (53%)
Disk Usage:    45%
Battery:       85% (charging)
Internet:      Connected

RAM Breakdown (estimate):
  App Memory:         7.8 GiB
  Wired/System:       2.4 GiB
  Compressed:         1.1 GiB
  Cache/Inactive:     4.6 GiB
  Free:               7.4 GiB

Health Signals:
  CPU:     Good      - 15% usage
  RAM:     Good      - 53% usage
  Disk:    Excellent - 45% used
  Battery: Good      - 85% charging
  Network: Good      - Connected

Top Apps by RAM:
  1. Safari - 11.6% RAM across 4 processes
  2. Visual Studio Code - 6.2% RAM across 2 processes
  3. Unresolved WebKit Process - 4.8% RAM across 1 process [low confidence: webkit_owner_not_found]
Top Apps by CPU:
  1. Safari - 15.4% CPU across 4 processes
  2. Visual Studio Code - 10.1% CPU across 2 processes
  3. System: WindowServer - 6.4% CPU across 1 process
Top RAM Processes:
  1. Safari (PID 1234) - 8.5% RAM
  2. Code Helper (PID 5678) - 4.2% RAM
  3. WindowServer (PID 9101) - 3.1% RAM
Top CPU Processes:
  1. WindowServer (PID 9101) - 14.8% CPU
  2. Code Helper (PID 5678) - 10.1% CPU
  3. Safari (PID 1234) - 6.4% CPU
==============================
```

JSON example:
```json
{
  "hostname": "mycomputer",
  "os": "Darwin",
  "uptime": "10:30  up 2 days, 14:25, 3 users, load averages: 1.50 1.40 1.35",
  "cpu": "15%",
  "ram": "8.5 GiB / 16.0 GiB (53%)",
  "disk": "45%",
  "battery": "85% (charging)",
  "internet": "Connected",
  "health": {
    "score": 100,
    "label": "Excellent",
    "signals": [
      { "name": "CPU", "status": "Good", "detail": "15% usage", "penalty": 0 },
      { "name": "RAM", "status": "Good", "detail": "53% usage", "penalty": 0 },
      { "name": "Disk", "status": "Excellent", "detail": "45% used", "penalty": 0 },
      { "name": "Battery", "status": "Good", "detail": "85% charging", "penalty": 0 },
      { "name": "Network", "status": "Good", "detail": "Connected", "penalty": 0 }
    ]
  },
  "ram_breakdown": {
    "app_memory_gib": "7.8",
    "wired_system_gib": "2.4",
    "compressed_gib": "1.1",
    "cache_inactive_gib": "4.6",
    "free_gib": "7.4"
  },
  "top_ram_apps": [
    { "name": "Safari", "process_count": 4, "memory_percent": "11.6", "cpu_percent": "15.4", "confidence": "high", "reason": "parent_app_bundle" },
    { "name": "Visual Studio Code", "process_count": 2, "memory_percent": "6.2", "cpu_percent": "10.1", "confidence": "high", "reason": "app_bundle" },
    { "name": "Unresolved WebKit Process", "process_count": 1, "memory_percent": "4.8", "cpu_percent": "2.4", "confidence": "low", "reason": "webkit_owner_not_found" }
  ],
  "top_cpu_apps": [
    { "name": "Safari", "process_count": 4, "cpu_percent": "15.4", "memory_percent": "11.6", "confidence": "high", "reason": "parent_app_bundle" },
    { "name": "Visual Studio Code", "process_count": 2, "cpu_percent": "10.1", "memory_percent": "6.2", "confidence": "high", "reason": "app_bundle" },
    { "name": "System: WindowServer", "process_count": 1, "cpu_percent": "6.4", "memory_percent": "3.1", "confidence": "high", "reason": "known_system_process" }
  ],
  "top_ram_processes": [
    { "name": "Safari", "pid": "1234", "memory_percent": "8.5", "cpu_percent": "6.4" },
    { "name": "Code Helper", "pid": "5678", "memory_percent": "4.2", "cpu_percent": "10.1" },
    { "name": "WindowServer", "pid": "9101", "memory_percent": "3.1", "cpu_percent": "14.8" }
  ],
  "top_cpu_processes": [
    { "name": "WindowServer", "pid": "9101", "cpu_percent": "14.8", "memory_percent": "3.1" },
    { "name": "Code Helper", "pid": "5678", "cpu_percent": "10.1", "memory_percent": "4.2" },
    { "name": "Safari", "pid": "1234", "cpu_percent": "6.4", "memory_percent": "8.5" }
  ]
}
```

## Modules Overview

### modules/cpu.sh
Monitors CPU usage and provides real-time CPU performance metrics.

### modules/ram.sh
Tracks memory usage and displays RAM availability information.

### modules/disk.sh
Checks disk space usage on the root partition and mounted drives.

### modules/battery.sh
Displays battery percentage and charging status (macOS systems).

### modules/network.sh
Tests internet connectivity and network status.

### modules/health.sh
Calculates the overall system health score from CPU, RAM, disk, battery, and network status, then explains the score through per-metric health signals.

### modules/processes.sh
Shows the top RAM-consuming and CPU-consuming apps and processes. App grouping is evidence-based: the resolver checks macOS/Linux process data, extracts `.app` bundle ownership when present, traces parent process ownership for helpers, classifies exact system processes, and marks unresolved helper/WebKit processes with low confidence instead of guessing.

### modules/system.sh
Displays system information including hostname, OS, and uptime.

## Utilities

### utils/colors.sh
Provides color definitions and terminal styling utilities for consistent output formatting.

### utils/helpers.sh
Contains common helper functions used across different modules.

## Notes

Some restricted environments block system commands such as `top`, `ps`, or network access. When that happens, the monitor keeps running and prints `Unavailable` or `Disconnected` instead of crashing.

## License

This project is open source. Feel free to use and modify as needed.
