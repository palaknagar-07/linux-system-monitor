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
source "$SCRIPT_DIR/modules/health.sh"

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
    RAM_BREAKDOWN_VALUE="$(get_ram_breakdown)"
    HEALTH_VALUE="$(get_health_score "$CPU_VALUE" "$RAM_VALUE" "$DISK_VALUE" "$BATTERY_VALUE" "$INTERNET_VALUE")"
    HEALTH_SIGNALS_VALUE="$(get_health_signals "$CPU_VALUE" "$RAM_VALUE" "$DISK_VALUE" "$BATTERY_VALUE" "$INTERNET_VALUE")"
    TOP_RAM_PROCESSES="$(get_top_ram_processes 3)"
    TOP_CPU_PROCESSES="$(get_top_cpu_processes 3)"
    TOP_RAM_APPS="$(get_top_ram_apps 3)"
    TOP_CPU_APPS="$(get_top_cpu_apps 3)"
}

render_ram_breakdown() {
    local label value

    echo -e "${YELLOW}RAM Breakdown (estimate):${NC}"
    if [ "$RAM_BREAKDOWN_VALUE" = "Unavailable" ] || [ -z "$RAM_BREAKDOWN_VALUE" ]; then
        echo "  Unavailable"
        return
    fi

    while IFS='|' read -r label value; do
        printf '  %-16s %6s GiB\n' "${label}:" "$value"
    done <<EOF
$RAM_BREAKDOWN_VALUE
EOF
}

render_health_signals() {
    local name status detail penalty

    echo -e "${YELLOW}Health Signals:${NC}"
    if [ -z "$HEALTH_SIGNALS_VALUE" ]; then
        echo "  Unavailable"
        return
    fi

    while IFS='|' read -r name status detail penalty; do
        printf '  %-8s %-9s - %s\n' "${name}:" "$status" "$detail"
    done <<EOF
$HEALTH_SIGNALS_VALUE
EOF
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
                '{
                    label = ($2 == 1) ? "process" : "processes"
                    confidence = ($5 == "high") ? "" : " [" $5 " confidence: " $6 "]"
                    printf "  %d. %s - %.1f%% %s across %d %s%s\n", NR, $1, $value_index, suffix, $2, label, confidence
                }'
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
    echo -e "${YELLOW}System Health:${NC} $(printf '%s' "$HEALTH_VALUE" | awk -F'|' '{ printf "%s/100 - %s", $1, $2 }')"
    echo

    echo -e "${YELLOW}Hostname:${NC}      $HOSTNAME_VALUE"
    echo -e "${YELLOW}OS:${NC}            $OS_VALUE"
    echo -e "${YELLOW}Uptime:${NC}        $UPTIME_VALUE"
    echo -e "${YELLOW}CPU Usage:${NC}     $CPU_VALUE"
    echo -e "${YELLOW}RAM Usage:${NC}     $RAM_VALUE"
    echo -e "${YELLOW}Disk Usage:${NC}    $DISK_VALUE"
    echo -e "${YELLOW}Battery:${NC}       $BATTERY_VALUE"
    echo -e "${YELLOW}Internet:${NC}      $INTERNET_VALUE"
    echo
    render_ram_breakdown
    echo
    render_health_signals
    echo
    render_app_list "Top Apps by RAM" "$TOP_RAM_APPS" "memory"
    render_app_list "Top Apps by CPU" "$TOP_CPU_APPS" "cpu"
    render_process_list "Top RAM Processes" "$TOP_RAM_PROCESSES" "memory"
    render_process_list "Top CPU Processes" "$TOP_CPU_PROCESSES" "cpu"

    echo -e "${CYAN}==============================${NC}"
}

ram_breakdown_json_key() {
    case "$1" in
        "App Memory")
            echo "app_memory_gib"
            ;;
        "Wired/System")
            echo "wired_system_gib"
            ;;
        "Compressed")
            echo "compressed_gib"
            ;;
        "Cache/Inactive")
            echo "cache_inactive_gib"
            ;;
        "Used")
            echo "used_gib"
            ;;
        "Buffers")
            echo "buffers_gib"
            ;;
        "Cache")
            echo "cache_gib"
            ;;
        "Free")
            echo "free_gib"
            ;;
        "Available")
            echo "available_gib"
            ;;
        *)
            printf '%s\n' "$1" | awk '{ key=tolower($0); gsub(/[^a-z0-9]+/, "_", key); gsub(/^_+|_+$/, "", key); print key "_gib" }'
            ;;
    esac
}

render_health_json() {
    local score label

    IFS='|' read -r score label <<EOF
$HEALTH_VALUE
EOF

    printf '  "health": {\n'
    printf '    "score": %s,\n' "$score"
    printf '    "label": "%s",\n' "$(json_escape "$label")"
    printf '    "signals": [\n'
    render_health_signals_json_array
    printf '    ]\n'
    printf '  },\n'
}

render_health_signals_json_array() {
    local first=1
    local name status detail penalty

    if [ -n "$HEALTH_SIGNALS_VALUE" ]; then
        while IFS='|' read -r name status detail penalty; do
            if [ "$first" -eq 0 ]; then
                printf ',\n'
            fi

            printf '      { "name": "%s", "status": "%s", "detail": "%s", "penalty": %s }' \
                "$(json_escape "$name")" "$(json_escape "$status")" "$(json_escape "$detail")" "$penalty"
            first=0
        done <<EOF
$HEALTH_SIGNALS_VALUE
EOF
        printf '\n'
    fi
}

render_ram_breakdown_json() {
    local first=1
    local label value key

    if [ "$RAM_BREAKDOWN_VALUE" = "Unavailable" ] || [ -z "$RAM_BREAKDOWN_VALUE" ]; then
        printf '  "ram_breakdown": null,\n'
        return
    fi

    printf '  "ram_breakdown": {\n'
    while IFS='|' read -r label value; do
        key="$(ram_breakdown_json_key "$label")"
        if [ "$first" -eq 0 ]; then
            printf ',\n'
        fi
        printf '    "%s": "%s"' "$(json_escape "$key")" "$(json_escape "$value")"
        first=0
    done <<EOF
$RAM_BREAKDOWN_VALUE
EOF
    printf '\n'
    printf '  },\n'
}

render_app_json_array() {
    local apps="$1"
    local value_type="$2"
    local first=1
    local name process_count cpu memory confidence reason

    if [ "$apps" != "Unavailable" ] && [ -n "$apps" ]; then
        while IFS='|' read -r name process_count cpu memory confidence reason; do
            if [ "$first" -eq 0 ]; then
                printf ',\n'
            fi

            if [ "$value_type" = "cpu" ]; then
                printf '    { "name": "%s", "process_count": %s, "cpu_percent": "%s", "memory_percent": "%s", "confidence": "%s", "reason": "%s" }' \
                    "$(json_escape "$name")" "$(json_escape "$process_count")" "$(json_escape "$cpu")" "$(json_escape "$memory")" "$(json_escape "$confidence")" "$(json_escape "$reason")"
            else
                printf '    { "name": "%s", "process_count": %s, "memory_percent": "%s", "cpu_percent": "%s", "confidence": "%s", "reason": "%s" }' \
                    "$(json_escape "$name")" "$(json_escape "$process_count")" "$(json_escape "$memory")" "$(json_escape "$cpu")" "$(json_escape "$confidence")" "$(json_escape "$reason")"
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
    render_health_json
    render_ram_breakdown_json
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
