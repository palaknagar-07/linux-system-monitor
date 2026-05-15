#!/bin/bash
# CPU monitoring module

get_cpu_usage() {
    local usage

    if is_macos; then
        usage=$(top -l 1 2>/dev/null | awk -F'[, ]+' '/CPU usage/ { idle=$7; sub(/%/, "", idle); printf "%.0f", 100 - idle }')
    elif is_linux; then
        usage=$(awk '/^cpu / { total=$2+$3+$4+$5+$6+$7+$8; idle=$5+$6; if (total > 0) printf "%.0f", 100 * (total - idle) / total }' /proc/stat 2>/dev/null)
    fi

    format_percent_status "$usage" 80 90
}
