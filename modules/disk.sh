#!/bin/bash
# Disk monitoring module

get_disk_usage() {
    local usage

    usage=$(df -P / 2>/dev/null | awk 'NR==2 { gsub(/%/, "", $5); print $5 }')

    format_percent_status "$usage" 80 90
}
