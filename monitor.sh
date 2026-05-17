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
source "$SCRIPT_DIR/modules/processes.sh"

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
    TOP_RAM_PROCESSES="$(get_top_ram_processes 3)"
    TOP_CPU_PROCESSES="$(get_top_cpu_processes 3)"
    TOP_RAM_APPS="$(get_top_ram_apps 3)"
    TOP_CPU_APPS="$(get_top_cpu_apps 3)"
}

render_app_list() {
    local title="$1"
    local apps="$2"
    local value_type="$3"
    local value_index
    local suffix

    if [ "$value_type" = "cpu" ]; then
        value_index=3
        suffix="CPU"
    else
        value_index=4
        suffix="RAM"
    fi

    echo -e "${YELLOW}${title}:${NC}"
    if [ "$apps" = "Unavailable" ] || [ -z "$apps" ]; then
        echo "  Unavailable"
    else
        printf '%s\n' "$apps" |
            awk -F'|' -v value_index="$value_index" -v suffix="$suffix" \
                '{ printf "  %d. %s - %.1f%% %s across %d process(es)\n", NR, $1, $value_index, suffix, $2 }'
    fi
}

render_process_list() {
    local title="$1"
    local processes="$2"
    local value_type="$3"
    local value_index
    local suffix

    if [ "$value_type" = "cpu" ]; then
        value_index=3
        suffix="CPU"
    else
        value_index=4
        suffix="RAM"
    fi

    echo -e "${YELLOW}${title}:${NC}"
    if [ "$processes" = "Unavailable" ] || [ -z "$processes" ]; then
        echo "  Unavailable"
    else
        printf '%s\n' "$processes" |
            awk -F'|' -v value_index="$value_index" -v suffix="$suffix" \
                '{ printf "  %d. %s (PID %s) - %.1f%% %s\n", NR, $1, $2, $value_index, suffix }'
    fi
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
    render_app_list "Top Apps by RAM" "$TOP_RAM_APPS" "memory"
    render_app_list "Top Apps by CPU" "$TOP_CPU_APPS" "cpu"
    render_process_list "Top RAM Processes" "$TOP_RAM_PROCESSES" "memory"
    render_process_list "Top CPU Processes" "$TOP_CPU_PROCESSES" "cpu"

    echo -e "${CYAN}==============================${NC}"
}

render_app_json_array() {
    local apps="$1"
    local value_type="$2"
    local first=1
    local name process_count cpu memory

    if [ "$apps" != "Unavailable" ] && [ -n "$apps" ]; then
        while IFS='|' read -r name process_count cpu memory; do
            if [ "$first" -eq 0 ]; then
                printf ',\n'
            fi

            if [ "$value_type" = "cpu" ]; then
                printf '    { "name": "%s", "process_count": %s, "cpu_percent": "%s", "memory_percent": "%s" }' \
                    "$(json_escape "$name")" "$(json_escape "$process_count")" "$(json_escape "$cpu")" "$(json_escape "$memory")"
            else
                printf '    { "name": "%s", "process_count": %s, "memory_percent": "%s", "cpu_percent": "%s" }' \
                    "$(json_escape "$name")" "$(json_escape "$process_count")" "$(json_escape "$memory")" "$(json_escape "$cpu")"
            fi

            first=0
        done <<EOF
$apps
EOF
        printf '\n'
    fi
}

render_process_json_array() {
    local processes="$1"
    local value_type="$2"
    local first=1
    local name pid cpu memory

    if [ "$processes" != "Unavailable" ] && [ -n "$processes" ]; then
        while IFS='|' read -r name pid cpu memory; do
            if [ "$first" -eq 0 ]; then
                printf ',\n'
            fi

            if [ "$value_type" = "cpu" ]; then
                printf '    { "name": "%s", "pid": "%s", "cpu_percent": "%s", "memory_percent": "%s" }' \
                    "$(json_escape "$name")" "$(json_escape "$pid")" "$(json_escape "$cpu")" "$(json_escape "$memory")"
            else
                printf '    { "name": "%s", "pid": "%s", "memory_percent": "%s", "cpu_percent": "%s" }' \
                    "$(json_escape "$name")" "$(json_escape "$pid")" "$(json_escape "$memory")" "$(json_escape "$cpu")"
            fi

            first=0
        done <<EOF
$processes
EOF
        printf '\n'
    fi
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
    printf '  "internet": "%s",\n' "$(json_escape "$INTERNET_VALUE")"
    printf '  "top_ram_apps": [\n'
    render_app_json_array "$TOP_RAM_APPS" "memory"
    printf '  ],\n'
    printf '  "top_cpu_apps": [\n'
    render_app_json_array "$TOP_CPU_APPS" "cpu"
    printf '  ],\n'
    printf '  "top_ram_processes": [\n'
    render_process_json_array "$TOP_RAM_PROCESSES" "memory"
    printf '  ],\n'
    printf '  "top_cpu_processes": [\n'
    render_process_json_array "$TOP_CPU_PROCESSES" "cpu"
    printf '  ]\n'
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
