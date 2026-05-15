#!/bin/bash
# Battery monitoring module

get_battery() {
    local battery

    if is_macos && command_exists pmset; then
        battery=$(pmset -g batt 2>/dev/null | awk -F'; *' '/%/ { gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/.*\t/, "", $1); print $1 " (" $2 ")"; exit }')
    elif is_linux; then
        local battery_dir
        for battery_dir in /sys/class/power_supply/BAT*; do
            if [ -r "$battery_dir/capacity" ]; then
                local capacity status
                capacity=$(cat "$battery_dir/capacity" 2>/dev/null)
                status=$(cat "$battery_dir/status" 2>/dev/null)
                battery="${capacity}% (${status:-Unknown})"
                break
            fi
        done
    fi

    if [ -n "$battery" ]; then
        echo "$battery"
    else
        echo "Unavailable"
    fi
}
