#!/bin/bash
# Network monitoring module

check_internet() {
    local ping_count_flag="-c"
    local ping_timeout_flag="-W"
    local ping_timeout="2"

    if is_macos; then
        ping_timeout="2000"
    fi

    if ping "$ping_count_flag" 1 "$ping_timeout_flag" "$ping_timeout" 8.8.8.8 >/dev/null 2>&1; then
        if ping "$ping_count_flag" 1 "$ping_timeout_flag" "$ping_timeout" google.com >/dev/null 2>&1; then
            echo "Connected"
        else
            echo "Connected (DNS issue)"
        fi
    else
        echo "Disconnected"
    fi
}
