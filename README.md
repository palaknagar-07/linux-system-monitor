# Linux System Monitor

A modular Bash script to monitor system information on Linux and macOS systems. The project keeps each metric in its own module so it is easy to improve or replace one part without rewriting the whole monitor.

## Features

- Modular architecture across separate monitoring files
- Hostname, OS, and uptime display
- CPU, RAM, disk, battery, and internet status
- Top apps grouped across related processes
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
Hostname:      mycomputer
OS:            Darwin
Uptime:        10:30  up 2 days, 14:25, 3 users, load averages: 1.50 1.40 1.35
CPU Usage:     15%
RAM Usage:     8.5 GiB / 16.0 GiB (53%)
Disk Usage:    45%
Battery:       85% (charging)
Internet:      Connected
Top Apps by RAM:
  1. Safari/WebKit - 11.6% RAM across 4 processes
  2. VS Code - 6.2% RAM across 2 processes
  3. Docker - 4.8% RAM across 3 processes
Top Apps by CPU:
  1. Safari/WebKit - 15.4% CPU across 4 processes
  2. VS Code - 10.1% CPU across 2 processes
  3. WindowServer - 6.4% CPU across 1 process
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
  "top_ram_apps": [
    { "name": "Safari/WebKit", "process_count": 4, "memory_percent": "11.6", "cpu_percent": "15.4" },
    { "name": "VS Code", "process_count": 2, "memory_percent": "6.2", "cpu_percent": "10.1" },
    { "name": "Docker", "process_count": 3, "memory_percent": "4.8", "cpu_percent": "2.4" }
  ],
  "top_cpu_apps": [
    { "name": "Safari/WebKit", "process_count": 4, "cpu_percent": "15.4", "memory_percent": "11.6" },
    { "name": "VS Code", "process_count": 2, "cpu_percent": "10.1", "memory_percent": "6.2" },
    { "name": "WindowServer", "process_count": 1, "cpu_percent": "6.4", "memory_percent": "3.1" }
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

### modules/processes.sh
Shows the top RAM-consuming and CPU-consuming apps and processes. Apps are grouped from related processes so users can understand resource usage at the application level.

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
