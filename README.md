# Linux System Monitor

A modular Bash script to monitor system information on Linux and macOS systems. The project keeps each metric in its own module so it is easy to improve or replace one part without rewriting the whole monitor.

## Features

- Modular architecture across separate monitoring files
- Hostname, OS, and uptime display
- CPU, RAM, disk, battery, and internet status
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
  "internet": "Connected"
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
