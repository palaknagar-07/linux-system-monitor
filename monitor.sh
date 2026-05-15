#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/utils/colors.sh"
source "$SCRIPT_DIR/utils/helpers.sh"

source "$SCRIPT_DIR/modules/system.sh"
source "$SCRIPT_DIR/modules/ram.sh"
source "$SCRIPT_DIR/modules/disk.sh"
source "$SCRIPT_DIR/modules/battery.sh"
source "$SCRIPT_DIR/modules/network.sh"
source "$SCRIPT_DIR/modules/cpu.sh"

WATCH_INTERVAL=""
OUTPUT_FORMAT="text"
CLEAR_SCREEN=1

show_help() {
    cat <<EOF
Usage: ./monitor.sh [options]

Options:
  --watch SECONDS  Refresh continuously every SECONDS.
  --json           Print machine-readable JSON.
  --no-color       Disable colored output.
  --no-clear       Do not clear the terminal before rendering.
  -h, --help       Show this help message.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --watch)
            WATCH_INTERVAL="${2:-}"
            if ! [[ "$WATCH_INTERVAL" =~ ^[0-9]+$ ]] || [ "$WATCH_INTERVAL" -lt 1 ]; then
                echo "Error: --watch requires a positive number of seconds." >&2
                exit 1
            fi
            shift 2
            ;;
        --json)
            OUTPUT_FORMAT="json"
            CLEAR_SCREEN=0
            shift
            ;;
        --no-color)
            disable_colors
            shift
            ;;
        --no-clear)
            CLEAR_SCREEN=0
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help >&2
            exit 1
            ;;
    esac
done

collect_metrics() {
    HOSTNAME_VALUE="$(get_hostname)"
    OS_VALUE="$(get_os)"
    UPTIME_VALUE="$(get_uptime)"
    CPU_VALUE="$(get_cpu_usage)"
    RAM_VALUE="$(get_ram_usage)"
    DISK_VALUE="$(get_disk_usage)"
    BATTERY_VALUE="$(get_battery)"
    INTERNET_VALUE="$(check_internet)"
}

render_text() {
    if [ "$CLEAR_SCREEN" -eq 1 ]; then
        clear
    fi

    echo -e "${CYAN}==============================${NC}"
    echo -e "${GREEN}      SYSTEM MONITOR${NC}"
    echo -e "${CYAN}==============================${NC}"

    echo -e "${YELLOW}Hostname:${NC}      $HOSTNAME_VALUE"
    echo -e "${YELLOW}OS:${NC}            $OS_VALUE"
    echo -e "${YELLOW}Uptime:${NC}        $UPTIME_VALUE"
    echo -e "${YELLOW}CPU Usage:${NC}     $CPU_VALUE"
    echo -e "${YELLOW}RAM Usage:${NC}     $RAM_VALUE"
    echo -e "${YELLOW}Disk Usage:${NC}    $DISK_VALUE"
    echo -e "${YELLOW}Battery:${NC}       $BATTERY_VALUE"
    echo -e "${YELLOW}Internet:${NC}      $INTERNET_VALUE"

    echo -e "${CYAN}==============================${NC}"
}

render_json() {
    printf '{\n'
    printf '  "hostname": "%s",\n' "$(json_escape "$HOSTNAME_VALUE")"
    printf '  "os": "%s",\n' "$(json_escape "$OS_VALUE")"
    printf '  "uptime": "%s",\n' "$(json_escape "$UPTIME_VALUE")"
    printf '  "cpu": "%s",\n' "$(json_escape "$CPU_VALUE")"
    printf '  "ram": "%s",\n' "$(json_escape "$RAM_VALUE")"
    printf '  "disk": "%s",\n' "$(json_escape "$DISK_VALUE")"
    printf '  "battery": "%s",\n' "$(json_escape "$BATTERY_VALUE")"
    printf '  "internet": "%s"\n' "$(json_escape "$INTERNET_VALUE")"
    printf '}\n'
}

render_once() {
    collect_metrics

    if [ "$OUTPUT_FORMAT" = "json" ]; then
        render_json
    else
        render_text
    fi
}

if [ -n "$WATCH_INTERVAL" ]; then
    while true; do
        render_once
        sleep "$WATCH_INTERVAL"
    done
else
    render_once
fi
