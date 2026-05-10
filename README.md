# Linux System Monitor

A modular Bash script to monitor system information on Linux/macOS systems. This project uses a plugin-based architecture with separate modules for different monitoring components.

## Features

- **Modular Architecture**: Organized system monitoring across separate modules
- CPU monitoring and usage tracking
- RAM usage monitoring
- Disk usage tracking
- Battery percentage display (on macOS)
- Network connectivity status
- System information display (hostname, OS, uptime)
- Color-coded output for better readability
- Centralized utility functions and color definitions

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
├── logs/                   # Application logs directory
├── screenshots/            # Screenshot storage
├── README.md              # This file
└── .gitignore             # Git ignore rules
```

## Requirements

- Bash shell (v4.0+)
- Standard Unix tools: `hostname`, `uname`, `uptime`, `top`, `df`, `ping`
- On macOS: `pmset` for battery info

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

## Output Example

```
==============================
      SYSTEM MONITOR
==============================
Hostname      : mycomputer
OS            : Darwin
Uptime        :  10:30  up 2 days, 14:25, 3 users, load averages: 1.50 1.40 1.35
CPU Usage     : 15.3%
RAM Used      : 8.5G / 16G
Disk Usage    : 45%
Battery       : 85%
Network       : Connected
==============================
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

## License

This project is open source. Feel free to use and modify as needed.