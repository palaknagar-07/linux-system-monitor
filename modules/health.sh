#!/bin/bash
# System health scoring module

get_health_label() {
    local score="$1"

    if [ "$score" -ge 90 ]; then
        echo "Excellent"
    elif [ "$score" -ge 75 ]; then
        echo "Good"
    elif [ "$score" -ge 60 ]; then
        echo "Fair"
    elif [ "$score" -ge 40 ]; then
        echo "Warning"
    else
        echo "Critical"
    fi
}

get_usage_penalty() {
    local value="$1"
    local warning_start="$2"
    local critical_start="$3"
    local max_start="$4"

    if [ -z "$value" ]; then
        echo 0
    elif [ "$value" -ge "$max_start" ]; then
        echo 30
    elif [ "$value" -ge "$critical_start" ]; then
        echo 20
    elif [ "$value" -ge "$warning_start" ]; then
        echo 10
    else
        echo 0
    fi
}

get_resource_signal_label() {
    local penalty="$1"
    local excellent_on_zero="${2:-0}"
    local value="${3:-}"

    if [ -z "$value" ]; then
        echo "Unknown"
    elif [ "$penalty" -ge 30 ]; then
        echo "Critical"
    elif [ "$penalty" -ge 20 ]; then
        echo "Warning"
    elif [ "$penalty" -ge 10 ]; then
        echo "Fair"
    elif [ "$excellent_on_zero" -eq 1 ]; then
        echo "Excellent"
    else
        echo "Good"
    fi
}

get_battery_penalty() {
    local battery_value="$1"
    local percent
    local battery_lower

    percent="$(extract_percent "$battery_value")"
    battery_lower="$(printf '%s\n' "$battery_value" | tr '[:upper:]' '[:lower:]')"

    case "$battery_lower" in
        *"(charging)"*|*"(charged)"*|*"(finishing charge)"*|*"(not charging)"*)
            echo 0
            return
            ;;
    esac

    if [ -z "$percent" ]; then
        echo 0
    elif [ "$percent" -lt 15 ]; then
        echo 15
    elif [ "$percent" -lt 30 ]; then
        echo 5
    else
        echo 0
    fi
}

get_battery_signal_label() {
    local penalty="$1"

    if [ "$penalty" -ge 15 ]; then
        echo "Critical"
    elif [ "$penalty" -gt 0 ]; then
        echo "Warning"
    else
        echo "Good"
    fi
}

get_network_penalty() {
    local internet_value="$1"

    case "$internet_value" in
        "Connected")
            echo 0
            ;;
        *"DNS issue"*)
            echo 5
            ;;
        "Disconnected")
            echo 10
            ;;
        *)
            echo 0
            ;;
    esac
}

get_network_signal_label() {
    local penalty="$1"

    if [ "$penalty" -ge 10 ]; then
        echo "Warning"
    elif [ "$penalty" -gt 0 ]; then
        echo "Warning"
    else
        echo "Good"
    fi
}

get_health_score() {
    local cpu_value="$1"
    local ram_value="$2"
    local disk_value="$3"
    local battery_value="$4"
    local internet_value="$5"
    local cpu_percent ram_percent disk_percent score

    cpu_percent="$(extract_percent "$cpu_value")"
    ram_percent="$(extract_percent "$ram_value")"
    disk_percent="$(extract_percent "$disk_value")"

    score=100
    score=$((score - $(get_usage_penalty "$cpu_percent" 70 85 95)))
    score=$((score - $(get_usage_penalty "$ram_percent" 70 85 95)))
    score=$((score - $(get_usage_penalty "$disk_percent" 80 90 95)))
    score=$((score - $(get_battery_penalty "$battery_value")))
    score=$((score - $(get_network_penalty "$internet_value")))

    if [ "$score" -lt 0 ]; then
        score=0
    fi

    printf '%s|%s\n' "$score" "$(get_health_label "$score")"
}

get_health_signals() {
    local cpu_value="$1"
    local ram_value="$2"
    local disk_value="$3"
    local battery_value="$4"
    local internet_value="$5"
    local cpu_percent ram_percent disk_percent penalty

    cpu_percent="$(extract_percent "$cpu_value")"
    ram_percent="$(extract_percent "$ram_value")"
    disk_percent="$(extract_percent "$disk_value")"

    penalty="$(get_usage_penalty "$cpu_percent" 70 85 95)"
    printf 'CPU|%s|%s|%s\n' "$(get_resource_signal_label "$penalty" 0 "$cpu_percent")" "$(format_usage_detail "$cpu_percent" "usage")" "$penalty"

    penalty="$(get_usage_penalty "$ram_percent" 70 85 95)"
    printf 'RAM|%s|%s|%s\n' "$(get_resource_signal_label "$penalty" 0 "$ram_percent")" "$(format_usage_detail "$ram_percent" "usage")" "$penalty"

    penalty="$(get_usage_penalty "$disk_percent" 80 90 95)"
    printf 'Disk|%s|%s|%s\n' "$(get_resource_signal_label "$penalty" 1 "$disk_percent")" "$(format_usage_detail "$disk_percent" "used")" "$penalty"

    penalty="$(get_battery_penalty "$battery_value")"
    printf 'Battery|%s|%s|%s\n' "$(get_battery_signal_label "$penalty")" "$(format_battery_detail "$battery_value")" "$penalty"

    penalty="$(get_network_penalty "$internet_value")"
    printf 'Network|%s|%s|%s\n' "$(get_network_signal_label "$penalty")" "$internet_value" "$penalty"
}

format_usage_detail() {
    local percent="$1"
    local noun="$2"

    if [ -n "$percent" ]; then
        printf '%s%% %s' "$percent" "$noun"
    else
        printf 'Unavailable'
    fi
}

format_battery_detail() {
    local battery_value="$1"

    if [ "$battery_value" = "Unavailable" ] || [ -z "$battery_value" ]; then
        echo "Unavailable"
    else
        printf '%s\n' "$battery_value" | sed 's/[()]//g'
    fi
}
