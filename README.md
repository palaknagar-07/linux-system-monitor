# Linux System Monitor

A simple Bash script to monitor basic system information on Linux/macOS systems.

## Features

- Displays hostname and operating system
- Shows system uptime
- Monitors RAM usage
- Checks disk usage on root partition
- Displays battery percentage (on macOS)
- Tests internet connectivity

## Requirements

- Bash shell
- Standard Unix tools: `hostname`, `uname`, `uptime`, `top`, `df`, `ping`
- On macOS: `pmset` for battery info

## Usage

1. Make the script executable:
   ```bash
   chmod +x monitor.sh
   ```

2. Run the script:
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
RAM Used      : 8.5G
Disk Usage    : 45%
Battery       : 85%
Internet      : Connected
==============================
```

## License

This project is open source. Feel free to use and modify as needed.